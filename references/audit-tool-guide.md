# Audit Tool Guide

Detailed usage and output reference for `audit-memory.sh`.

## What It Does

Runs a one-shot compliance report on the project's memory library. Reports violations; doesn't modify files or block any workflow.

## Install

```bash
# Copy the template from this repo into your project
cp /path/to/claude-memory-manager/templates/audit-memory.template.sh \
   <your-project>/scripts/audit-memory.sh

# Required: edit MEMORY_DIR at the top of the script
# Default location: ~/.claude/projects/<project-slug>/memory/
# slug = absolute project path with / replaced by -
# Example: /Users/foo/Project/bar → -Users-foo-Project-bar

chmod +x <your-project>/scripts/audit-memory.sh
```

Alternatively, set the env var:

```bash
export CLAUDE_MEMORY_DIR=~/.claude/projects/<your-slug>/memory
bash scripts/audit-memory.sh
```

## Run

```bash
bash scripts/audit-memory.sh
```

Expected output:

```
Memory audit · 2026-05-15 · 132 files

Hard checks (must be zero):
  missing frontmatter        0
  frontmatter fields         0
  feedback missing Why       1
  naming violations          0
  broken MEMORY.md links     0

Soft signals:
  oversized files           78
  groups over 15 entries     3
  untouched 30+ days        31
  not in MEMORY.md           0

## feedback missing Why
  - feedback_xxx.md

Hard-rule compliance: 99.2%  (1 violation / 132 files)
Target: 95% or higher
```

## Check Reference

### Hard checks (count against compliance)

| Check | Meaning | Fix |
|---|---|---|
| **missing frontmatter** | File doesn't open with a `---` YAML block | Add frontmatter (see SKILL.md Mode 2 step 3) |
| **frontmatter fields** | Missing `name`, `description`, or `type` | Add the missing field |
| **feedback missing Why** | A `type: feedback` file has no Why section | Add `## Why` or an accepted synonym (see below) |
| **naming violations** | Filename doesn't match `<type>_<topic>.md` (type ∈ feedback / reference / project / user) | Rename |
| **broken MEMORY.md links** | Index references a file that no longer exists | Remove the link or restore the file |

### Soft signals (informational)

| Check | Meaning | Action |
|---|---|---|
| **oversized files** | > 100 lines or ≥ 5 H2 sections | Consider splitting (see SKILL.md Rule 6) |
| **groups over 15 entries** | A group in MEMORY.md has ≥ 15 entries | Consider a hub memory page |
| **untouched 30+ days** | File mtime older than 30 days | Review for staleness |
| **not in MEMORY.md** | File exists but isn't indexed | Add to MEMORY.md or archive |

## Accepted Forms of the "Why" Section

The audit recognizes several writing styles for the required Why on feedback files:

| Style | Example |
|---|---|
| Standard | `## Why` |
| English synonym | `## Root cause` |
| Chinese synonyms | `## 根因` / `## 教训` / `## 原因` / `## 为什么` |
| Bold inline | `**Why**:` / `**根因**:` |
| Either colon | ASCII `:` or full-width `:` accepted |

## Compliance Bands

| Range | Meaning | Action |
|---|---|---|
| **≥ 95%** | Healthy | Maintain; soft-warning mode is enough |
| **85% – 95%** | Marginal | Clear the hard violations first |
| **< 85%** | Out of control | Systemic review; possibly a schema change or migration |

## FAQ

### Q: 30+ days untouched — should I delete those files?

Not automatically. `mtime > 30d` is a signal, not a violation:

- Long-lived SDK bugs / architectural decisions naturally don't change for months
- Temporary state / outdated info should be archived or deleted

Review case by case.

### Q: I get "feedback missing Why" but I wrote the reason in prose?

Check whether you used a non-standard heading (e.g. `## Background`, `## Context`, or a plain paragraph starting with "The reason is…"). The audit regex covers common synonyms — if your heading is unusual, either rename to a standard form, or extend the regex in the script (see the comment block near the `grep -qiE` line for Why-section detection).

### Q: How do I build a hub memory when a group exceeds 15 entries?

1. Create `reference_<topic>_hub.md` as the topic entry file
2. Inside that file: collect 9–20 related memory files as `[[name]]` links + a topic map + "when to come here"
3. In MEMORY.md, replace the group's entry list with a single line pointing to the hub

## Customization

The audit script is plain bash. Common edits, with the corresponding section near the top of the script:

- **Add a new type**: extend the regex under "Filename convention"
- **Change Rule 6 thresholds**: edit the line count / H2 count under "Oversize"
- **Change the group-size threshold**: edit the entry-count check under "Oversize groups in MEMORY.md"
- **Extend Why-section detection**: edit the regex under "feedback type must have ## Why"
