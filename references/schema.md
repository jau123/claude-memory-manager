# Memory Schema

Claude Code 人工维护 memory 知识库的规范。本文件是 SKILL.md schema 段的权威来源。

## 文件命名

`<type>_<topic>[_<modifier>].md` 全小写下划线。

| Type 前缀 | 用途 | 必含信息 |
|---|---|---|
| `feedback_` | 学到的踩坑(SDK bug / 平台限制 / 用户偏好 / 设计教训) | 原因 + 何时复用 |
| `reference_` | 主题深度参考 / 标准方法 / 业界对照 / 复用 pipeline | 描述性内容,无强制段 |
| `project_` | 状态性事实(架构快照 / 进行中工作 / 经济学分析 / 决策记录) | 描述性内容,无强制段 |
| `user_` | (可选)项目跨成员个人偏好 / 角色信息 | 描述性内容,无强制段 |

## 必填 frontmatter

```yaml
---
name: kebab-case-slug
description: 场景关键词 + 核心结论
type: feedback | reference | project | user
---
```

- `name`:跟文件名对齐(去 type 前缀),kebab-case
- `description`:**Claude 凭它判断是否读本文件的唯一依据**,必须场景关键词 + 结论混合
- `type`:平铺 `type:` 或嵌套 `metadata.type:` 都接受(优先平铺)

## feedback 类必含原因

任一形式:

| 形式 | 例 |
|---|---|
| 标准段 | `## Why` |
| 中文同义段 | `## 根因` / `## 教训` / `## 原因` / `## 为什么` |
| 英文同义段 | `## Root cause` |
| 加粗行内 | `**Why**:` / `**根因**:` |
| 中英文冒号 | 上述都接受 `:` 或 `:` |

**关键**:原因段保护未来对抗审查不重新质疑同一决策(已踩过 3 次坑)。

## feedback 类必含"何时复用"

任一形式:

- 单独 `## How to apply` 段
- description 含场景关键词(隐含触发场景即可)

实测大多数好的 description 本身就是"何时复用"的浓缩。

## description 风格

混合(场景关键词 + 核心结论),让 LLM 凭 description 命中"X 场景查 Y 结论"。

| ✅ 好 | ❌ 坏 |
|---|---|
| `浏览器端 supabase.from() mutation 在 tab 切换后死锁,必须用 fetch() 调 REST API` | `Supabase 相关问题` |
| `CF Image Transformations 失败 7 天缓存 / cf-resized err= / FavoriteCard retry pattern` | `图片有时显示不出来` |
| `RLS 策略必须用 (SELECT auth.uid()) 包装,否则每行重复求值` | `RLS 性能优化` |

**判定标准**:LLM 读 description 时能立刻知道"X 场景下要查的 Y 结论"。

## 何时新建 vs update

| 情况 | 动作 |
|---|---|
| 同主题新发现 / 修正 / 数据更新 | **update 已有文件**,加段或加 changelog 段 |
| 主题正交(不属于任何现有 feedback)| 新建文件 |
| 已有结论被推翻 | 旧文件顶部加 `⚠️ Superseded by [[new-file]]`,新文件正文写"取代 [[old]] 的什么部分" |

## 单文件 / 单组超载防御(Rule 6)

| 信号 | 行动 |
|---|---|
| 已有 file > 100 行,且要加的新内容跟原主题正交 | 拆出新 file |
| 已有 file ≥ 5 个 H2 顶层段,且新内容属于第 6 个独立主题 | 拆出新 file |
| 加段后总长度跨过 150 行 | 评估是否拆 |
| 索引层某大组 entry ≥ 15 | 建 hub memory 替代扁平索引 |

**为什么管单组超载**:LLM 凭索引扫 description 命中,组内 15+ 条凭一次扫描有遗漏率。建 hub 后,组索引只一行指向 hub,hub 内做主题地图。

## 分组冻结

- 索引文件(MEMORY.md)**禁止新建分组**
- 已有分组从中选最相近
- 跨主题用 `(亦见 hub-X)` 末尾注释跨引用

## 替代旧结论

旧 file 顶部:`⚠️ Superseded by [[new-file]]`
新 file 正文:"取代 [[old]] 的 X 部分"

## 评估指标

| 指标 | 目标 | 工具 |
|---|---|---|
| frontmatter 合规率 | ≥ 95% | `audit-memory.sh` |
| feedback Why 段合规率 | ≥ 90% | 同上 |
| 命名规范合规率 | ≥ 95% | 同上 |
| 索引断链 | 0 | 同上 |
| 单文件超载 | 信号级(逐个评估) | 同上 |
| 单组超载 | 信号级(建 hub) | 同上 |

合规率 < 95% 不要追 100%。LLM 系统不存在零违规,追 100% 会引入 dead rule。
