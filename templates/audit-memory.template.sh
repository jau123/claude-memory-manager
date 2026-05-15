#!/usr/bin/env bash
# Memory library health check (companion to the memory-management skill)
# Usage: bash scripts/audit-memory.sh
#
# === Edit before first run ===
# Change MEMORY_DIR below to your project's auto-memory path.
# Default location: ~/.claude/projects/<project-slug>/memory/
# slug = absolute project path with / replaced by -
# Example: /Users/foo/Project/bar → -Users-foo-Project-bar
# =============================
#
# Hard checks:
# - Frontmatter complete (name / description / type)
# - feedback type must have a Why section
#   (accepts ## Why / ## Root cause / ## 根因 / ## 教训 / ## 原因 / ## 为什么)
# - Filename pattern <type>_<topic>.md (type ∈ feedback / reference / project / user)
# - MEMORY.md index integrity
#
# Soft signals:
# - Single file > 100 lines or ≥ 5 H2 sections (Rule 6 split trigger)
# - MEMORY.md group ≥ 15 entries (hub-page candidate)
# - File untouched for 30+ days

set -u

# Prefer env var; fall back to hard-coded path (you must edit this line)
MEMORY_DIR="${CLAUDE_MEMORY_DIR:-$HOME/.claude/projects/CHANGEME/memory}"
HUB="$MEMORY_DIR/reference_memory_system.md"
INDEX="$MEMORY_DIR/MEMORY.md"

if [ ! -d "$MEMORY_DIR" ]; then
  echo "Memory directory not found: $MEMORY_DIR" >&2
  echo "Edit MEMORY_DIR at the top of this script, or export CLAUDE_MEMORY_DIR." >&2
  exit 1
fi

# ===== Required frontmatter fields =====
# Fields are stable (name / description / type). Hard-coded list is simpler
# than dynamic discovery. If you add a field, update: this list + SKILL.md
# schema section + MEMORY.md quick-reference.
REQUIRED_FIELDS=("name" "description" "type")

# ===== Counters =====
total=0
missing_fm=0       # missing frontmatter
missing_field=0   # frontmatter field missing
missing_why=0     # feedback type missing Why
bad_name=0         # filename does not match <type>_<topic>.md
oversize=0         # > 100 lines or ≥ 5 H2 sections
orphan_30d=0       # untouched 30+ days
broken_index=0     # MEMORY.md references a file that does not exist
not_indexed=0      # file exists but not referenced in MEMORY.md

declare -a missing_fm_list missing_field_list missing_why_list bad_name_list oversize_list orphan_30d_list broken_index_list not_indexed_list

# ===== Per-file checks =====
shopt -s nullglob
for f in "$MEMORY_DIR"/*.md; do
  fname=$(basename "$f")

  # Skip the index file itself
  [ "$fname" = "MEMORY.md" ] && continue

  total=$((total + 1))

  # 0. Filename convention: <type>_<topic>.md
  # Accepted types: feedback | reference | project | user (user is legacy in some projects)
  if ! echo "$fname" | grep -qE '^(feedback|reference|project|user)_[a-z0-9_]+\.md$'; then
    bad_name=$((bad_name + 1))
    bad_name_list+=("$fname (should be <type>_<topic>.md)")
  fi

  # 1. Frontmatter present
  if ! head -1 "$f" | grep -q '^---$'; then
    missing_fm=$((missing_fm + 1))
    missing_fm_list+=("$fname")
    continue  # No frontmatter → skip field checks
  fi

  # Extract frontmatter block (--- to next ---)
  fm=$(awk '/^---$/{c++; if(c==2) exit; next} c==1' "$f")

  # 2. Required fields
  for field in "${REQUIRED_FIELDS[@]}"; do
    if ! echo "$fm" | grep -qE "^[[:space:]]*${field}:"; then
      missing_field=$((missing_field + 1))
      missing_field_list+=("$fname (missing $field)")
      break  # Report once per file
    fi
  done

  # 3. feedback type must have ## Why
  type=$(echo "$fm" | grep -oE 'type:\s*\w+' | head -1 | sed 's/type:[[:space:]]*//')
  if [ "$type" = "feedback" ]; then
    # Accepted forms:
    # - ## Why / ## Root cause / ## 为什么 / ## 根因 / ## 原因 / ## 教训
    # - **Why**: / **根因**: etc (both ASCII : and Chinese :)
    if ! grep -qiE '^(##\s+(Why|Root\s+[Cc]ause|为什么|根因|原因|教训)[:：]?|\*\*(Why|根因|为什么)(\*\*[:：]|[:：]\*\*)|Why[:：])' "$f"; then
      missing_why=$((missing_why + 1))
      missing_why_list+=("$fname")
    fi
  fi

  # 3.5 Oversize (Rule 6): > 100 lines or ≥ 5 H2 sections
  lines=$(wc -l < "$f")
  h2_count=$(grep -cE '^##[^#]' "$f")
  if [ "$lines" -gt 100 ] || [ "$h2_count" -ge 5 ]; then
    oversize=$((oversize + 1))
    oversize_list+=("$fname (${lines} lines / ${h2_count} H2)")
  fi

  # 4. Untouched 30+ days
  mtime_days=$(( ( $(date +%s) - $(stat -f %m "$f" 2>/dev/null || stat -c %Y "$f") ) / 86400 ))
  if [ "$mtime_days" -gt 30 ]; then
    orphan_30d=$((orphan_30d + 1))
    orphan_30d_list+=("$fname (${mtime_days}d)")
  fi

  # 5. Referenced in MEMORY.md?
  slug="${fname%.md}"
  if [ -f "$INDEX" ]; then
    if ! grep -q "$slug" "$INDEX"; then
      not_indexed=$((not_indexed + 1))
      not_indexed_list+=("$fname")
    fi
  fi
done

# ===== MEMORY.md references that point to non-existent files =====
if [ -f "$INDEX" ]; then
  while IFS= read -r ref; do
    f="$MEMORY_DIR/$ref"
    if [ ! -f "$f" ]; then
      broken_index=$((broken_index + 1))
      broken_index_list+=("$ref")
    fi
  done < <(grep -oE '\([a-z_]+\.md\)' "$INDEX" | sed 's/[()]//g' | sort -u)
fi

# ===== Oversize groups in MEMORY.md (≥ 15 entries → consider hub page) =====
declare -a oversized_groups
if [ -f "$INDEX" ]; then
  while IFS=$'\t' read -r group count; do
    if [ "$count" -ge 15 ]; then
      oversized_groups+=("$group ($count entries)")
    fi
  done < <(awk '
    /^## /{ if(g) print g"\t"c; g=$0; sub(/^## /, "", g); c=0; next }
    /^- /{ if(g) c++ }
    END{ if(g) print g"\t"c }
  ' "$INDEX")
fi

# ===== Report =====
echo "Memory audit · $(date +%Y-%m-%d) · $total files"
echo
echo "Hard checks (must be zero):"
printf "  missing frontmatter       %3d\n" "$missing_fm"
printf "  frontmatter fields        %3d\n" "$missing_field"
printf "  feedback missing Why      %3d\n" "$missing_why"
printf "  naming violations         %3d\n" "$bad_name"
printf "  broken MEMORY.md links    %3d\n" "$broken_index"
echo
echo "Soft signals:"
printf "  oversized files           %3d\n" "$oversize"
printf "  groups over 15 entries    %3d\n" "${#oversized_groups[@]}"
printf "  untouched 30+ days        %3d\n" "$orphan_30d"
printf "  not in MEMORY.md          %3d\n" "$not_indexed"
echo

# ===== Detail listing (if any violations) =====
print_list() {
  local title="$1"; shift
  local items=("$@")
  if [ ${#items[@]} -gt 0 ]; then
    echo "## $title"
    for item in "${items[@]}"; do
      echo "  - $item"
    done
    echo
  fi
}

print_list "Missing frontmatter"                              "${missing_fm_list[@]:-}"
print_list "Frontmatter fields missing"                       "${missing_field_list[@]:-}"
print_list "feedback missing Why"                             "${missing_why_list[@]:-}"
print_list "Naming violations"                                "${bad_name_list[@]:-}"
print_list "Broken MEMORY.md links"                           "${broken_index_list[@]:-}"
print_list "Not referenced in MEMORY.md (possible orphans)"   "${not_indexed_list[@]:-}"
print_list "Oversized (>100 lines or ≥5 H2, consider split)"  "${oversize_list[@]:-}"
print_list "Groups over 15 entries (consider hub page)"       "${oversized_groups[@]:-}"
# 30+ day untouched list is noisy; uncomment if you want it.
# print_list "Untouched 30+ days" "${orphan_30d_list[@]:-}"

# ===== Hard-rule compliance =====
hard_violations=$((missing_fm + missing_field + missing_why + bad_name + broken_index))
compliance=$(awk "BEGIN { printf \"%.1f\", (1 - $hard_violations/$total) * 100 }")
echo "Hard-rule compliance: $compliance%  ($hard_violations violations / $total files)"
echo "Target: 95% or higher"
if [ "$hard_violations" -gt 0 ]; then
  threshold=$(awk "BEGIN { print ($hard_violations / $total > 0.05) }")
  if [ "$threshold" = "1" ]; then
    echo "Compliance below 95% — review the violations above."
  fi
fi
