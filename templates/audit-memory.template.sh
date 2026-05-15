#!/usr/bin/env bash
# Memory 系统体检脚本(通用模板,memory-management skill 配套)
# 用法: bash scripts/audit-memory.sh
#
# === 复制到你项目后必改 ===
# 把下面 MEMORY_DIR 改成你项目的 auto memory 路径
# 默认路径:~/.claude/projects/<project-slug>/memory/
# slug = 项目绝对路径将 / 替换为 -
# 例:/Users/foo/Project/bar → -Users-foo-Project-bar
# ==========================
#
# 检查项(硬规则):
# - frontmatter 完整(name / description / type)
# - feedback 类必含 Why 段(接受 ## Why / ## 根因 / ## 教训 / ## 原因 / ## 为什么 / Root cause 中英冒号)
# - 文件名 <type>_<topic>.md(type ∈ feedback/reference/project/user)
# - MEMORY.md 索引完整性
#
# 检查项(信号级):
# - 单文件超 100 行 / ≥ 5 个 H2 段(Rule 6 拆分触发线)
# - MEMORY.md 大组 ≥ 15 条 entry(建议建 hub memory)
# - 30 天未触碰文件

set -u

# 优先用环境变量,fallback 写死路径(用户必须改这一行)
MEMORY_DIR="${CLAUDE_MEMORY_DIR:-$HOME/.claude/projects/CHANGEME/memory}"
HUB="$MEMORY_DIR/reference_memory_system.md"
INDEX="$MEMORY_DIR/MEMORY.md"

if [ ! -d "$MEMORY_DIR" ]; then
  echo "❌ memory 目录不存在: $MEMORY_DIR"
  echo "提示:修改本脚本顶部 MEMORY_DIR 或导出环境变量 CLAUDE_MEMORY_DIR"
  exit 1
fi

# ===== 必填字段列表 =====
# 字段稳定(name / description / type),硬编码维护成本 < 自动 grep 复杂度
# 如未来加字段,需同步改:此处 + SKILL.md schema 段 + MEMORY.md 速查段
REQUIRED_FIELDS=("name" "description" "type")

# ===== 统计 =====
total=0
missing_fm=0      # 缺 frontmatter
missing_field=0   # frontmatter 字段缺
missing_why=0     # feedback 缺 Why
bad_name=0        # 文件名不符合 <type>_<topic>.md
oversize=0        # 单文件 > 100 行或 > 4 个 H2 段
orphan_30d=0      # 30 天未触
broken_index=0    # MEMORY.md 引用了不存在的文件
not_indexed=0     # memory 文件存在但 MEMORY.md 没引用

declare -a missing_fm_list missing_field_list missing_why_list bad_name_list oversize_list orphan_30d_list broken_index_list not_indexed_list

# ===== 逐文件检查 =====
shopt -s nullglob
for f in "$MEMORY_DIR"/*.md; do
  fname=$(basename "$f")

  # 跳过索引文件本身
  [ "$fname" = "MEMORY.md" ] && continue

  total=$((total + 1))

  # 0. 文件命名规范:<type>_<topic>.md
  # 允许 type: feedback | reference | project | user (user 是部分项目用,兼容)
  if ! echo "$fname" | grep -qE '^(feedback|reference|project|user)_[a-z0-9_]+\.md$'; then
    bad_name=$((bad_name + 1))
    bad_name_list+=("$fname → 应改成 <type>_<topic>.md")
  fi

  # 1. frontmatter 存在
  if ! head -1 "$f" | grep -q '^---$'; then
    missing_fm=$((missing_fm + 1))
    missing_fm_list+=("$fname")
    continue  # 没 frontmatter 后续字段检查跳过
  fi

  # 提取 frontmatter 段(--- 到下一个 ---)
  fm=$(awk '/^---$/{c++; if(c==2) exit; next} c==1' "$f")

  # 2. 必填字段
  for field in "${REQUIRED_FIELDS[@]}"; do
    if ! echo "$fm" | grep -qE "^[[:space:]]*${field}:"; then
      missing_field=$((missing_field + 1))
      missing_field_list+=("$fname → 缺 $field")
      break  # 同文件只报一次
    fi
  done

  # 3. feedback 类必含 ## Why
  type=$(echo "$fm" | grep -oE 'type:\s*\w+' | head -1 | sed 's/type:[[:space:]]*//')
  if [ "$type" = "feedback" ]; then
    # 接受多种 Why 写法(中英文同义词 + 中英文冒号):
    # - ## Why / ## 为什么 / ## 根因 / ## 原因 / ## 教训 / ## Root cause(可带 : 或 :)
    # - **Why**: / **Why**: / **根因**: / **根因**: 等
    if ! grep -qiE '^(##\s+(Why|为什么|根因|原因|教训|Root\s+[Cc]ause)[:：]?|\*\*(Why|根因|为什么)(\*\*[:：]|[:：]\*\*)|Why[:：])' "$f"; then
      missing_why=$((missing_why + 1))
      missing_why_list+=("$fname")
    fi
  fi

  # 3.5 单文件超载(Rule 6):> 100 行 或 ≥ 5 个 H2 段
  lines=$(wc -l < "$f")
  h2_count=$(grep -cE '^##[^#]' "$f")
  if [ "$lines" -gt 100 ] || [ "$h2_count" -ge 5 ]; then
    oversize=$((oversize + 1))
    oversize_list+=("$fname (${lines}行 / ${h2_count} 个 H2)")
  fi

  # 4. 30 天未触
  mtime_days=$(( ( $(date +%s) - $(stat -f %m "$f" 2>/dev/null || stat -c %Y "$f") ) / 86400 ))
  if [ "$mtime_days" -gt 30 ]; then
    orphan_30d=$((orphan_30d + 1))
    orphan_30d_list+=("$fname (${mtime_days}d)")
  fi

  # 5. MEMORY.md 是否引用
  slug="${fname%.md}"
  if [ -f "$INDEX" ]; then
    if ! grep -q "$slug" "$INDEX"; then
      not_indexed=$((not_indexed + 1))
      not_indexed_list+=("$fname")
    fi
  fi
done

# ===== MEMORY.md 引用但文件不存在 =====
if [ -f "$INDEX" ]; then
  while IFS= read -r ref; do
    # 提取 [text](file.md) 里的 file.md
    f="$MEMORY_DIR/$ref"
    if [ ! -f "$f" ]; then
      broken_index=$((broken_index + 1))
      broken_index_list+=("$ref")
    fi
  done < <(grep -oE '\([a-z_]+\.md\)' "$INDEX" | sed 's/[()]//g' | sort -u)
fi

# ===== 6. 大组密度检查(MEMORY.md 每个 ## 组条目数 ≥ 15 提醒建 hub)=====
declare -a oversized_groups
if [ -f "$INDEX" ]; then
  # 用 awk 找出每个 ## 段下的 entry 数
  while IFS=$'\t' read -r group count; do
    if [ "$count" -ge 15 ]; then
      oversized_groups+=("$group ($count 条)")
    fi
  done < <(awk '
    /^## /{ if(g) print g"\t"c; g=$0; sub(/^## /, "", g); c=0; next }
    /^- /{ if(g) c++ }
    END{ if(g) print g"\t"c }
  ' "$INDEX")
fi

# ===== 输出报告 =====
echo "========================================"
echo "Memory 体检报告 ($(date +%Y-%m-%d))"
echo "========================================"
echo "总文件数: $total"
echo
echo "🔴 严重违规"
printf "  缺 frontmatter:        %d\n" "$missing_fm"
printf "  frontmatter 字段缺:    %d\n" "$missing_field"
printf "  feedback 缺 Why:       %d\n" "$missing_why"
printf "  命名违规:              %d\n" "$bad_name"
printf "  MEMORY.md 断链:        %d\n" "$broken_index"
echo
echo "🟡 提示"
printf "  单文件超载(Rule 6):     %d\n" "$oversize"
printf "  大组超 15 条(建议 hub): %d\n" "${#oversized_groups[@]}"
printf "  30 天未触:             %d\n" "$orphan_30d"
printf "  存在但 MEMORY.md 没索引: %d\n" "$not_indexed"
echo

# ===== 详细列表(如有违规)=====
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

print_list "缺 frontmatter"           "${missing_fm_list[@]:-}"
print_list "frontmatter 字段缺"       "${missing_field_list[@]:-}"
print_list "feedback 缺 Why"          "${missing_why_list[@]:-}"
print_list "命名违规"                 "${bad_name_list[@]:-}"
print_list "MEMORY.md 断链"           "${broken_index_list[@]:-}"
print_list "MEMORY.md 没索引(可能孤儿)"  "${not_indexed_list[@]:-}"
print_list "单文件超载(>100行或≥5个H2,建议拆)" "${oversize_list[@]:-}"
print_list "大组超 15 条(建议建 hub memory)"  "${oversized_groups[@]:-}"
# 30 天未触不打详情(太多噪音),需要时取消下面注释
# print_list "30 天未触" "${orphan_30d_list[@]:-}"

# ===== 合规率(硬规则:frontmatter / 字段 / Why / 命名 / 断链)=====
hard_violations=$((missing_fm + missing_field + missing_why + bad_name + broken_index))
compliance=$(awk "BEGIN { printf \"%.1f\", (1 - $hard_violations/$total) * 100 }")
echo "========================================"
echo "硬规则合规率: $compliance%  (违规 $hard_violations / 总 $total)"
echo "目标: ≥95%"
if [ "$hard_violations" -gt 0 ]; then
  threshold=$(awk "BEGIN { print ($hard_violations / $total > 0.05) }")
  if [ "$threshold" = "1" ]; then
    echo "⚠️  合规率 < 95%,建议人工 review 上面违规列表"
  fi
fi
echo "========================================"
