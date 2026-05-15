# Audit Tool Guide

`audit-memory.sh` 体检脚本详细使用 + 输出解读 + 常见问题。

## 用途

跑一次输出当前项目 memory 系统的合规率报告 + 违规列表 + 信号级提示。**不修改任何文件**,不阻塞工作流,纯体检。

## 安装

```bash
# 从 skill repo 复制模板到你的项目
cp /path/to/claude-memory-manager/templates/audit-memory.template.sh \
   <你的项目>/scripts/audit-memory.sh

# 改路径(必须):脚本顶部 MEMORY_DIR
# 默认 ~/.claude/projects/<project-slug>/memory/
# slug = 项目绝对路径 / 替换成 -
# 例:/Users/foo/Project/bar → -Users-foo-Project-bar

chmod +x <你的项目>/scripts/audit-memory.sh
```

或者用环境变量:
```bash
export CLAUDE_MEMORY_DIR=~/.claude/projects/<你的项目 slug>/memory
bash scripts/audit-memory.sh
```

## 运行

```bash
bash scripts/audit-memory.sh
```

预计输出:

```
========================================
Memory 体检报告 (2026-05-15)
========================================
总文件数: 87

🔴 严重违规
  缺 frontmatter:        0
  frontmatter 字段缺:    0
  feedback 缺 Why:       1
  命名违规:              0
  MEMORY.md 断链:        0

🟡 提示
  单文件超载(Rule 6):     51
  大组超 15 条(建议 hub): 2
  30 天未触:             18
  存在但 MEMORY.md 没索引: 0

## feedback 缺 Why
  - feedback_xxx.md
...
硬规则合规率: 98.9%  (违规 1 / 总 87)
目标: ≥95%
```

## 检查项详解

### 硬规则(🔴 严重违规,直接影响合规率)

| 检查项 | 含义 | 修法 |
|---|---|---|
| **缺 frontmatter** | 文件开头没 `---` 起的 YAML 段 | 加 frontmatter(参考 SKILL.md Mode 2 步骤 3) |
| **frontmatter 字段缺** | name / description / type 任一缺失 | 补齐 |
| **feedback 缺 Why** | type=feedback 文件没原因解释段 | 加 ## Why 或同义中文(## 根因 / ## 教训 / ## 原因 / ## 为什么)/ 加粗行内 |
| **命名违规** | 文件名不符合 `<type>_<topic>.md`(type ∈ feedback/reference/project/user) | 重命名 |
| **MEMORY.md 断链** | 索引引用了不存在的文件 | 删除断链或恢复文件 |

### 信号级(🟡 提示,不算违规)

| 检查项 | 含义 | 行动 |
|---|---|---|
| **单文件超载(Rule 6)** | > 100 行 或 ≥ 5 个 H2 段 | 考虑拆分(见 SKILL.md Rule 6) |
| **大组超 15 条** | MEMORY.md 某分组 entry ≥ 15 | 考虑建 hub memory 聚合入口 |
| **30 天未触** | 文件 mtime > 30 天前 | 评估是否过期 / 内容仍有效 |
| **MEMORY.md 没索引** | 文件存在但索引没引用 | 加到 MEMORY.md 索引或归档 |

## Why 段正则覆盖范围

audit 接受多种"原因解释"写法:

| 写法 | 例子 |
|---|---|
| `## Why` | `## Why` |
| 中文同义词 | `## 根因` / `## 教训` / `## 原因` / `## 为什么` |
| 英文同义词 | `## Root cause` |
| 加粗行内 | `**Why**:` / `**根因**:` / `**为什么**:` |
| 中英文冒号 | 上述都接受 `:` 或 `:` |

## 合规率阈值

| 区间 | 含义 | 行动 |
|---|---|---|
| **≥ 95%** | 健康 | 维持现状,soft warning 模式 |
| **85% - 95%** | 边缘 | 优先补违规列表中的硬规则 |
| **< 85%** | 失控 | 系统性 review,可能要 schema 调整或迁移 |

## 常见问题

### Q1: 合规率为什么不是 100% 目标?

LLM 系统不存在零违规。强行追 100% 会引入:
- dead rule(规避手段:用同义词绕过)
- 工作流阻塞(batch 写 memory 中途失败丢数据)
- schema 跟现实脱节(documentation rot)

**95% 是 healthy baseline,不是终极目标**。

### Q2: 30 天未触的文件该删吗?

不一定。`mtime > 30d` 是信号,不是违规:
- 长期有效的 SDK bug / 架构决策 → 30 天没改正常
- 临时状态 / 过期信息 → 应该归档或删除

需要逐个人审。

### Q3: 单文件超载报警了 51 个怎么办?

新项目从 0 开始,Rule 6 自然遵守。
**已有项目存量违规** → 优先看 5 个最重要的(看大组 + 高频访问)逐个评估拆分。其他维持现状,新写时遵守 Rule 6 即可。

### Q4: 大组超 15 条建 hub 怎么做?

参考 SKILL.md Rule 6 历史踩坑案例 "单组超载" 段。简单步骤:
1. 写 `reference_<topic>_hub.md` 主题入口文件
2. 文件内组织 9-20 个相关 memory 的 `[[name]]` 索引 + 主题地图 + 何时来这里查
3. MEMORY.md 该大组下只保留 1 行指向 hub,其他 entry 移到 hub 文件内

### Q5: audit 报"feedback 缺 Why" 但我明明写了原因解释?

检查是否用了非标准标题(比如 `## 背景` / `## 教训(从普适到具体)` / 普通段落开头说"为什么...")。Audit 正则覆盖常见同义词,但太花的标题需要改成标准形式之一。

或者改 audit 脚本第 86 行的正则,接受你的项目特定标题写法。

## 自定义扩展

audit 脚本是 bash,容易改:

- 加新 type:第 56 行 `^(feedback|reference|project|user)_` 加新 type
- 改 Rule 6 阈值:第 95 行 `lines > 100` / `h2_count >= 5`
- 改大组超载阈值:第 134 行 `count >= 15`
- 改 Why 段正则:第 86 行
