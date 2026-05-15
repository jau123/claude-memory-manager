<h1 align="center">Claude Memory Manager</h1>

<p align="center">
  <strong>一个方法论 skill,教 Claude Code <em>怎么</em>沉淀记忆 —— 由你决定<em>什么时候</em>沉淀。</strong>
  <br>
  <sub>为严肃、长期迭代的开发场景设计,上下文宝贵,记忆累积可达数月。</sub>
</p>

<p align="center">
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-lightgrey?style=flat-square" alt="MIT"></a>
  <img src="https://img.shields.io/badge/Platform-Claude_Code-orange?style=flat-square" alt="Claude Code">
  <img src="https://img.shields.io/badge/Storage-Zero-green?style=flat-square" alt="Zero storage">
  <img src="https://img.shields.io/badge/Hooks-None-blue?style=flat-square" alt="No hooks">
</p>

<p align="center">
  <a href="README.md">English</a> | <strong>中文</strong>
</p>

<p align="center">
  <a href="#为什么有这个">为什么</a> &bull;
  <a href="#设计哲学">设计哲学</a> &bull;
  <a href="#快速开始">快速开始</a> &bull;
  <a href="#触发方式">触发方式</a>
</p>

---

## 为什么有这个

Claude Code 是严肃开发场景。**上下文容量宝贵,记忆会累积数月。**

业界主流方案(Codex、OpenClaw,以及大多数 RAG 框架)走的是"自动记忆一切"路线 —— 系统自己决定记什么、何时记、记多少。对长期迭代的严肃项目,这意味着上下文被污染、无法审计、悄然漂移没人察觉。

我们走相反的路。**由你决定**什么值得沉淀。这个 skill 教 Claude *怎么*写得规范,让记忆库在几个月后仍然找得到、看得懂、信得过。

## 设计哲学

### 触发,不主动

Skill 只在你开口时启动 —— "记一下今天的发现" / "复盘" / "看看有什么值得记的" —— 永远不在后台默默工作。进入你记忆库的每一条都是**有意为之**。

### 沉淀,不堆积

每个关键节点 —— 修完一个 bug、对抗审查得出非显然结论、长 debug 后复盘 —— 才形成一条结构化的记忆。不是系统觉得该记,而是**你**判断这条值得留下。

### 体检,不强制

一个 bash 脚本随时给你一份健康报告:多少条违反规范、多少文件超载、多少索引过期。**没有 hook 阻塞工作流**,只是一个可观察的数字。

### Skill 负责"怎么写"

命名怎么定、何时 update 何时拆、什么时候建索引层 —— 这些 Claude 跨 session 容易写得不一致。Skill 把判断标准打包好,让 Claude 半年后新 session 里仍然写得统一。

## 快速开始

```bash
git clone https://github.com/jau123/claude-memory-manager.git ~/code/claude-memory-manager

mkdir -p ~/.claude/skills/memory-management/templates
cp ~/code/claude-memory-manager/SKILL.md ~/.claude/skills/memory-management/SKILL.md
cp ~/code/claude-memory-manager/templates/audit-memory.template.sh \
   ~/.claude/skills/memory-management/templates/
```

每个项目的具体配置(audit 脚本 + CLAUDE.md 协议 + MEMORY.md 速查段) → [INSTALL.md](INSTALL.md)

## 触发方式

直接说人话 —— Claude 自动匹配关键词:

| 你说... | Skill 做什么 |
|---|---|
| *"记一下今天那个坑"* / *"Record that bug"* | 写一条新的结构化记忆 |
| *"复盘"* / *"开发完了看看有什么值得记的"* | 回顾本次 session,挑出值得保留的 |
| *"更新这条 memory"* / *"修正那个结论"* | 判断 update 已有还是拆出新文件 |
| *"audit memory"* / *"体检记忆库"* | 跑健康检查脚本,报告合规率 |
| *"从零起步"* / *"Bootstrap from zero"* | 新项目搭索引 / schema / 速查段 |

不用敲 `/skill` 命令。

## 健康检查

记忆库开始感觉乱时,跑一下 audit 脚本,几秒钟告诉你:

- 多少文件命名不规范
- 多少条记忆缺关键上下文
- 多少文件长到需要拆
- 多少索引段需要建 hub
- 多少索引链接失效

只是软提示,不阻塞任何东西。修不修由你决定。

## 文件结构

```
claude-memory-manager/
├── SKILL.md                  # Skill 本体
├── INSTALL.md                # 安装步骤
├── references/               # 设计文档、schema、audit 细节
├── templates/                # 可移植的 bash 健康检查脚本
└── examples/                 # 三个真实项目浓缩的示范
```

## 什么场景不适合

Claude.ai 网页闲聊、一次性脚本、没有长期维护周期的项目 —— 内置的 auto memory 已经够用。本 skill 的价值随项目寿命增长。

## License

MIT
