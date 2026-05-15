<h1 align="center">Claude Memory Manager</h1>

<p align="center">
  <strong>策展,而非堆积。</strong>
  <br>
  一个 Claude Code skill,让项目记忆库在数月迭代中始终可审计、命名一致、不漂移。
</p>

<p align="center">
  <a href="https://github.com/jau123/claude-memory-manager/stargazers"><img src="https://img.shields.io/github/stars/jau123/claude-memory-manager?style=flat-square&color=yellow" alt="Stars"></a>
  <a href="https://github.com/jau123/claude-memory-manager/commits/main"><img src="https://img.shields.io/github/last-commit/jau123/claude-memory-manager?style=flat-square" alt="Last commit"></a>
  <img src="https://img.shields.io/badge/Claude_Code-2.1%2B-orange?style=flat-square" alt="Claude Code 2.1+">
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-lightgrey?style=flat-square" alt="MIT"></a>
</p>

<p align="center">
  <a href="README.md">English</a> | <strong>中文</strong>
</p>

<p align="center">
  <a href="#效果">效果</a> &bull;
  <a href="#安装">安装</a> &bull;
  <a href="#首次使用">首次使用</a> &bull;
  <a href="#与其他方案对比">对比</a> &bull;
  <a href="SKILL.md">Skill</a>
</p>

---

## 效果

87 个文件的真实记忆库,跑一次 audit 前后对比:

```
              整理前                              整理后
   ─────────────────────────────       ─────────────────────────────
   合规率:           12%         →     合规率:           99%
   命名违规:         31           →     命名违规:          0
   缺关键上下文:     18           →     缺关键上下文:      1
   索引断链:          8           →     索引断链:          0
   单文件超载:       42           →     需拆分提示:        3
   grep 找一条耗时:  5+ 分钟       →     grep 找一条耗时:  ~10 秒

   ⚠️  无法信任、无法检索的       →     ✓  跨数月仍可审计、
       记忆膨胀                            可检索的知识库
```

Skill 自身不记录任何东西。**你**触发,**它**按规范写。

## 为什么

长期项目的记忆条目会像代码库里的死代码一样默默堆积 —— 直到搜索失效。三个月后,你分不清哪条还成立、哪些是彼此的重复、哪个文件里有上季度那个 bug 的答案。

Claude Code 自带的 auto-memory 对短期项目够用。对长期项目,你需要 **schema、audit、有意触发的纪律**。这个 skill 把三者打包。

## 工作方式

- **触发型,从不自动**。"记一下"、"复盘"、"audit memory" —— 仅此而已。
- **每个节点一条**。每条按 3 种类型(feedback / reference / project)schema 写,Claude 跨 session 保持一致。
- **审计脚本,不用 hook**。一个 bash 一次性告诉你哪里不对。不阻塞任何工作流。
- **零存储**。记忆始终在 `~/.claude/projects/<slug>/memory/` —— 纯 markdown,git 友好,完全属于你。

## 安装

一行:

```bash
git clone https://github.com/jau123/claude-memory-manager.git && \
  mkdir -p ~/.claude/skills/memory-management/templates && \
  cp claude-memory-manager/SKILL.md ~/.claude/skills/memory-management/ && \
  cp claude-memory-manager/templates/audit-memory.template.sh \
     ~/.claude/skills/memory-management/templates/
```

**验证** —— 打开任意 Claude Code session,说一句:

> "audit memory"

如果 Claude 主动去找 `scripts/audit-memory.sh`(或提示你复制模板到项目里),说明 skill 已生效。

每个项目的详细配置(audit 脚本 + CLAUDE.md hook)→ [INSTALL.md](INSTALL.md)

## 首次使用

Skill 通过自然语言激活,不需要敲 `/` 命令。

```
你: "记一下今天那个 wildcard bug"
→ Claude 写一条 feedback_*.md:文件名、frontmatter、Why 段、How to apply。

你: "复盘"
→ Claude 回顾最近 session,挑出 3–5 个候选,问你保留哪些。

你: "audit memory"
→ 跑 scripts/audit-memory.sh,报告合规率,列出需要拆分的文件。
```

完整触发关键词参考 → [SKILL.md](SKILL.md)

## 与其他方案对比

|  | 触发 | 审计 | 记录什么 |
|---|---|---|---|
| Codex / OpenClaw / RAG 框架 | 自动,不透明 | 无 | 系统自己决定 |
| Claude Code 内置 auto-memory | 自动 | 无 | 每个 session 的结论 |
| **claude-memory-manager** | **你说的触发词** | **一行命令的脚本** | **只有你确认的** |

前两条路是为"帮你记下一切"优化。这个 skill 是为"只记你说要记的,六个月后仍能审计"优化。

## 仓库内容

| 文件 | 用途 |
|---|---|
| [`SKILL.md`](SKILL.md) | Skill 本体 —— 6 条规则、5 个模式、schema、自检清单。复制到 `~/.claude/skills/memory-management/` |
| [`templates/audit-memory.template.sh`](templates/audit-memory.template.sh) | 可移植的健康检查脚本。每个项目复制一份,改一行路径 |
| [`references/design-philosophy.md`](references/design-philosophy.md) | 为什么这样设计、拒绝过的方案、试过又放弃的方案 |
| [`references/schema.md`](references/schema.md) | 命名 + frontmatter + 段落规范的详细版 |
| [`references/audit-tool-guide.md`](references/audit-tool-guide.md) | 审计脚本的选项、输出含义、自定义方法 |
| [`examples/`](examples/) | 三个浓缩自真实项目的范例 —— 每种类型一个 |

## 什么场景不适合

- 项目 < 1 个月或记忆条目 < 10 条 —— 内置 auto-memory 已足够
- 想要语义搜索 / RAG 检索 —— 不是同类工具
- 想要后台默默消化历史 session —— 也不是同类工具

本 skill 的价值随**项目寿命**和**条目数量**增长。低于阈值时,引入这套规范的开销不划算。

## License

[MIT](LICENSE) · Issues / PR 欢迎 [`jau123/claude-memory-manager`](https://github.com/jau123/claude-memory-manager/issues)
