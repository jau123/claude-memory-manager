# Install

## 前置要求

- Claude Code v2.1.59+(支持 auto memory)
- macOS / Linux / WSL(audit 脚本是 bash)

## 安装 skill(用户级,跨项目复用)

```bash
# clone 本仓库
git clone https://github.com/jau123/claude-memory-manager.git ~/code/claude-memory-manager

# 复制 skill 到 Claude Code 用户级 skill 目录
mkdir -p ~/.claude/skills/memory-management
cp ~/code/claude-memory-manager/SKILL.md \
   ~/.claude/skills/memory-management/SKILL.md

# 复制 audit 模板(可选)
mkdir -p ~/.claude/skills/memory-management/templates
cp ~/code/claude-memory-manager/templates/audit-memory.template.sh \
   ~/.claude/skills/memory-management/templates/audit-memory.template.sh
```

## 验证 skill 已加载

打开任意 Claude Code session,跑 `/skill list`(或者随便聊一句 "记一下今天的发现"),Claude 应该会触发 `memory-management` skill。

## 给你的项目装 audit 脚本(可选,推荐)

```bash
# 在你的项目根目录
mkdir -p scripts
cp ~/.claude/skills/memory-management/templates/audit-memory.template.sh \
   scripts/audit-memory.sh

# 改路径:把脚本顶部 MEMORY_DIR 改成你项目的 auto memory 路径
# 默认 ~/.claude/projects/<project-slug>/memory/
# slug = 项目绝对路径 / 替换为 -
# 例:/Users/foo/Project/bar → -Users-foo-Project-bar

# 找到你项目的 slug:
ls ~/.claude/projects/ | grep -i <你的项目名>

# 改完测试
chmod +x scripts/audit-memory.sh
bash scripts/audit-memory.sh
```

## 给项目加 Memory 写入协议(可选,推荐)

在项目 CLAUDE.md 顶部加这段(让 Claude 主动触发本 skill):

```markdown
## Memory 管理

涉及 memory 写入 / 更新 / schema 调整时 → 使用 `memory-management` skill。

- 速查规则:MEMORY.md 顶部 ⭐⭐⭐ 段
- 体检合规率:`bash scripts/audit-memory.sh`
```

## 给项目 MEMORY.md 加速查精华段(强烈推荐)

参考 `~/.claude/skills/memory-management/SKILL.md` Mode 5 步骤 2,在你项目 MEMORY.md 顶部加 ~25 行硬规则速查段。这是治"新 session Claude 凭印象写"的关键一步。

## 升级

```bash
cd ~/code/claude-memory-manager
git pull
# 复制最新 skill
cp SKILL.md ~/.claude/skills/memory-management/SKILL.md
cp templates/audit-memory.template.sh \
   ~/.claude/skills/memory-management/templates/audit-memory.template.sh
# 项目 audit 脚本若有自定义改动,自己 merge
```

## 卸载

```bash
rm -rf ~/.claude/skills/memory-management/
# 项目级 audit 脚本自己删
# CLAUDE.md 顶部 Memory 段删
# MEMORY.md 顶部速查段保留(不影响功能)
```
