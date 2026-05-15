# Claude Memory Management

> **教 Claude 怎么写好 memory,而不是替它写 memory**

一个用户级 skill,管理 Claude Code 的人工 memory 知识库。教 Claude **决定**记什么 / 怎么写 / 何时更新 / 何时拆分,让记忆系统不漂移、不臃肿、找得到。

## 这是什么

如果你用 Claude Code 超过 3 个月、跑过 3+ 项目、`~/.claude/projects/*/memory/` 已经堆了 30+ 文件,你大概率遇到过这些痛点:

- 新 session Claude 凭印象写 memory,命名不一致(`feedback_` / `notes_` / `bug-fix_` 各种)
- 同主题踩坑被记了 3 次,因为 Claude 不知道已经有了
- 单文件膨胀到 200+ 行,塞了 8 个不相关主题
- MEMORY.md 索引 description 太模糊,Claude 凭它命中不了具体场景
- 半年后回头看记忆系统一团乱,不知道从哪整理

**本 skill 解决的是上面这些问题**。它**不存储任何东西**(memory 还是 Claude 自己写),它教 Claude **怎么写得好**。

## 这不是什么

- ❌ **不是 RAG / vector store**(那是 [claude-mem](https://github.com/thedotmack/claude-mem) / [Letta](https://www.letta.com/) 路线)
- ❌ **不是自动 memory consolidator**(那是 [dream-skill](https://github.com/grandamenium/dream-skill) / Anthropic AutoDream)
- ❌ **不是 CLAUDE.md improver**(那是 Anthropic 官方 [`claude-md-management`](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/claude-md-management))
- ❌ **不强制任何规范**(没有 PreToolUse hook 阻塞工作流)

它是**方法论 skill**:把"如何写好 markdown 知识库"的判断标准、决策树、检查清单做成 Claude 可调用的工具。

## 5 个设计原则

1. **记忆是事实,方法在 skill** — memory file 装"我踩过 X",skill 装"如何决定 X 该不该被记"
2. **承认 LLM 漂移,不强制反而靠 self-consistency 工作** — 实测合规率自然 ≥ 93%,加强制反而引入 dead rule 和工作流阻塞
3. **接受中英文混合 schema** — `## Why` / `## 根因` / `## 教训` 都识别,跟着真实写法走
4. **单文件 + 单组双层超载防御**(Rule 6) — 防臃肿,给具体阈值(>100 行 / ≥5 H2 / ≥15 entry)
5. **配套 audit 脚本事后体检,不阻塞工作** — soft warning + 合规率指标

详细背景:[references/design-philosophy.md](references/design-philosophy.md)

## 跟其他方案的差异

| | **本 skill** | Anthropic `claude-md-improver` | [claude-mem](https://github.com/thedotmack/claude-mem) | [Letta](https://www.letta.com/) / [Mem0](https://mem0.ai/) | [dream-skill](https://github.com/grandamenium/dream-skill) |
|---|---|---|---|---|---|
| **类型** | 方法论 skill | CLAUDE.md 评分 + 改进 skill | RAG infrastructure | Agent memory framework | Auto-consolidator |
| **管什么** | MEMORY.md + memory 子文件 | CLAUDE.md | 自动捕获 + 向量检索 | Episodic / Semantic / Procedural | 24h Stop hook 跑 consolidation |
| **存储位置** | 不存储,只教写 | N/A | SQLite + Chroma | 框架内部 | N/A |
| **强制层** | 零(soft warning) | 零 | 零(自动) | 自动 | Hook 强制 |
| **用户可读 memory** | ✅ markdown 全可读 | ✅(CLAUDE.md) | ⚠️(部分 markdown) | ❌(机器消费) | ✅ markdown |
| **跨项目复用** | ✅ 用户级 skill | ✅ 用户级 skill | ✅ CLI | ✅ 框架 | ✅ skill |
| **audit 工具** | ✅ bash 脚本 | ❌ | ❌ | ❌ | ❌ |
| **命名 schema** | ✅(feedback/reference/project)| ❌ | ❌ | ❌ | ❌ |
| **超载阈值** | ✅ Rule 6 双层 | ❌(明确说 No size limits) | ❌ | ❌ | ❌ |

**唯一同时具备**(a)用户级跨项目 +(b)决策方法论 +(c)bash audit 脚本 +(d)零 hook 软触发 **的 skill**。

## 适用场景

✅ **适合**:
- 重度 Claude Code 用户(3+ 项目 / 3+ 个月使用)
- 多人协作 + 想让项目知识库进 git review 的团队
- 不喜欢"黑盒自动 memory",想要人工可审计知识库的工程师
- 跨项目带方法论,不想每个项目重新建立 schema 的人

❌ **不适合**:
- 一次性 vibe-coding 项目(用官方 auto memory 就够)
- 想要 RAG / vector retrieval 自动语义搜索的(用 claude-mem / Mem0)
- 企业团队想要中心化向量库方案

## 为什么没有 Codex 版

调查过(2026-05 Codex docs):
- Codex `~/.codex/memories/` **不鼓励人工编辑**(官方文档明确说 "don't rely on editing them by hand as your primary control surface")
- Codex `AGENTS.md` **每个目录只读一个文件**,**不支持 `@import`** 引用语法
- Codex 没有"多 memory 文件 + 索引"的体系

本 skill 的核心(命名 schema / MEMORY.md 索引 / Rule 6 拆分 / audit 跨文件体检)**在 Codex 上无落地点**。强行适配是给 Codex 用户假象,所以不做。

如果你是 Codex 用户想要类似方法论,**本 skill 的设计哲学**([references/design-philosophy.md](references/design-philosophy.md))仍可参考,但工具不能直接用。

## Install

```bash
git clone https://github.com/jau123/claude-memory-manager.git ~/code/claude-memory-manager

mkdir -p ~/.claude/skills/memory-management
cp ~/code/claude-memory-manager/SKILL.md \
   ~/.claude/skills/memory-management/SKILL.md
```

完整步骤(包括 audit 脚本 + 给项目装协议)→ [INSTALL.md](INSTALL.md)

## Usage

装完后,以下用户输入会触发 skill:

| 你说 | Skill 做什么 |
|---|---|
| "记一下今天那个 X 坑" | 直接走新建 memory 流程(命名 / frontmatter / Why) |
| "复盘 / 开发完了看有什么值得记的" | 候选评估决策树筛 |
| "更新这个 memory" / "修正 X 结论" | update 已有 vs 新建判断 |
| "改 schema / 加新 type" | 必读历史踩坑清单(防重复犯错) |
| "audit memory" | 跑 audit 脚本看合规率 |
| "新项目零记忆起步" | bootstrap 流程(分组阈值 / CLAUDE.md 协议) |

跟 Claude 聊天时不需要显式 `/skill`,Claude 看 description 关键词自动匹配。

## File Structure

```
claude-memory-manager/
├── README.md                          # 你正在看的
├── LICENSE                            # MIT-0
├── SKILL.md                           # 主 skill 文件(装到 ~/.claude/skills/memory-management/)
├── INSTALL.md                         # 安装步骤
├── references/
│   ├── design-philosophy.md           # 为什么这样设计 / 拒绝过的方案
│   ├── schema.md                      # 命名 / frontmatter / Why 段 / Rule 6 规范
│   └── audit-tool-guide.md            # audit 脚本详细使用
├── templates/
│   └── audit-memory.template.sh       # bash 体检脚本,复制到项目 scripts/
└── examples/                          # 标准范例(真实项目浓缩版)
    ├── feedback-example.md            # ✅ feedback 类示范
    ├── reference-example.md           # ✅ reference 类示范
    └── project-example.md             # ✅ project 类示范
```

## Validated by

本 skill 经过 4 轮独立反馈迭代:

1. **meigen 项目**(主项目,86 文件) — frontmatter 100% / feedback Why 93% baseline
2. **反滥用上下文子任务** — 反馈 Mode 1 触发场景太窄(只覆盖"开发完后"),已加单次决策处置
3. **OpenClaw 项目**(独立项目,13 文件) — 反馈跨项目 audit 脚本路径硬编码 + 中文冒号兼容 + 命名规范漏检,已修
4. **3 轮对抗性 subagent 审查** — 暴露 hook 配置错位 / settings 位置 / topic file 不自动加载等设计陷阱,已避开

## Roadmap

- **v1.0**(当前):Claude Code 完整支持
- **v1.x**(假设):
  - 一键迁移工具(legacy 项目 memory 自动改名 + 补 frontmatter)
  - VS Code extension(IDE 内体检 + lint)
  - 跨项目 search(grep 多个项目的 memory)

## Contributing

Issues 和 PR 欢迎。本 skill 的设计原则之一是"承认 LLM 漂移",所以:

- ✅ **欢迎**:新 type 提议 / 新 Rule 提议 / audit 检查项扩展 / 真实踩坑案例
- ❌ **不欢迎**:加强制 hook / 自动消化 / RAG retrieval — 那是别的项目的方向

## License

MIT-0(MIT No Attribution)— 用就用,不需要署名。
