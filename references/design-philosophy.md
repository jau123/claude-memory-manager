# Design Philosophy

为什么这个 skill 是这样设计的 — 决策背景 + 拒绝方案 + 替代权衡。

## 核心观点:**记忆是事实,方法在 skill**

Claude Code 的 auto memory 系统是给 Claude **自己**写的笔记(踩过的坑、学到的模式、当前项目状态)。memory file 装"我踩过 X"。

但 **"如何决定 X 该不该被记 / 怎么写 / 怎么组织"** 是另一类知识 — **方法**,不是事实。

把方法塞进 memory file(比如做一个 `memory/_schema.md`)的 3 个问题:

1. **topic file 不自动加载** — Claude 每次 session 启动不会主动读 schema,凭印象写
2. **类别错误** — schema 是"如何记忆"的规范,memory 是"已经记的内容",混在一起
3. **跨项目复用难** — 项目级文件不会跨项目共享

把方法做成 **skill** 解决全部 3 个问题:
- skill 通过 description 关键词触发(官方机制,可靠)
- skill 在 `~/.claude/skills/` 用户级,跨项目复用
- 跟 memory 分开 = 关注点分离

## 第二观点:**LLM 天然漂移,不强制反而靠 self-consistency 工作**

主流方案试图用 **hook + 强制 schema** 控制 Claude 行为。我们试过,发现:

| 强制方案 | 问题 |
|---|---|
| PreToolUse hook + exit 2 | Claude 没自动重试机制,batch 写 memory 时第一个被 block 后整个流程放弃 → 丢数据 |
| PostToolUse hook 改 cache-control | Claude Code 中不能 block,只能 warn,效果跟 audit 事后体检差不多 |
| settings.json 强制 schema | 项目级 `.claude/` 经常在 `.gitignore`,配置不进 git 不跨 worktree |

**实测发现**:即便没有强制层,Claude 自发遵守规范的比例已经很高(meigen 项目实测 frontmatter 100% / Why 段 93%)。原因是 Claude 看到 MEMORY.md 顶部速查段 + 现有 memory 文件的写法,自己会跟随。

所以本 skill 的设计是:
- **不用 hook 强制**
- **靠 description 触发 + self-consistency**
- **配 audit 脚本事后体检**,不阻塞写入

## 第三观点:**承认中英文混合 schema**

最初严格要求 `## Why` 标题,实测 87 个 memory 文件大量用 `## 根因` / `## 教训` / `## 原因` / `**Why**:` 加粗行内 — 实际是"内容质量好但格式不统一"。

**反应有两种**:
- (a) 强制统一为 `## Why` → dead rule,会被规避
- (b) 接受同义词 → schema 跟现实对齐

选 (b)。`audit` 脚本正则同时识别中英文同义词 + 加粗变体 + 中英文冒号。

**教训**:schema 不是 LLM 必须遵守的法律,是**让 LLM 主动跟随的约定**。约定越接近自然写法,跟随率越高。

## 第四观点:**单文件 + 单组双层超载防御**(Rule 6)

只防"单文件超载"不够。实测发现两层都会失控:

| 层级 | 失控表现 | 触发线 |
|---|---|---|
| **单文件** | 134 行塞 8 个独立主题,MEMORY.md description 概括不全 → Claude 命中不了子主题 | > 100 行 或 ≥ 5 个 H2 段 |
| **单组(MEMORY.md 索引层)** | 一个大组 20+ entry,Claude 扫索引时遗漏率高,处理任务时重复造轮子 | 组内 ≥ 15 条 entry |

防御方案:
- 单文件超载 → 拆出新 file
- 单组超载 → 建 hub memory(段索引)替代扁平索引

## 第五观点:**audit 脚本是事后体检,不是强制**

很多 schema 方案做成 lint 强制,失败就阻塞。本 skill 的 audit:

- **soft warning**:输出违规列表,不修改文件,不阻塞工作
- **目标合规率 ≥95%**:实测项目自然合规 93%,补几个边缘到 ≥95% 即可,不追求 100%
- **跨项目模板可复用**:`templates/audit-memory.template.sh` 占位路径,复制到任意项目改 MEMORY_DIR 即可

理由:LLM 系统不存在 100% 合规。强制做到 100% 反而引入 dead rule(规避手段)和工作流阻塞(batch 写丢数据)。soft warning + 体检指标足够。

## 拒绝过的方案

| 方案 | 拒绝理由 |
|---|---|
| **memory/_schema.md 作为权威源** | topic file 不自动加载,Claude 不主动读 |
| **PreToolUse hook exit 2 强制** | batch 写场景丢数据;且 `.claude/` gitignored 时配置不跨 worktree |
| **`if: "Write(memory/*.md)"` hook glob** | `if:` 字段是 permission rule 语法不是 file glob,无效 |
| **每条 memory 必须 ## Why + ## How to apply 严格段** | 实测 How to apply 段实际填充率 < 16%,dead rule 玷污 schema 可信度 |
| **手动维护 changelog 段** | 用户对自动化警惕,changelog 必死,改用 `git log` 作为演进历史 |
| **CLAUDE.md 顶部加详细 schema 段** | 跟 skill / MEMORY.md 三处同步漂移风险;只放精华索引 + 指向 skill |

## 验证方式

本 skill 经过三阶段实测:

1. **meigen 项目**(主项目,86 文件)— frontmatter 100% / feedback Why 93% baseline
2. **反滥用上下文**(子任务)— 反馈 Mode 1 触发场景太窄(只覆盖"开发完后"),已修
3. **OpenClaw 项目**(另一个项目,13 文件)— 反馈跨项目 audit 脚本路径硬编码,已通用化

每轮反馈都让 skill 演进。当前版本是第 4 轮迭代。

## 相关思考

- 跟 LangChain memory module 的区别:**它们装事实,我们管方法**
- 跟 hook-based 强制方案的区别:**我们承认 LLM 漂移并配套体检,而非强制**
- 跟 OpenClaw skills-creator 的区别:**那是 meta-skill 教如何写 skill,本 skill 是 meta-memory 教如何管记忆**
