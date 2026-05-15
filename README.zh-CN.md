<h1 align="center">Claude Memory Manager</h1>

<p align="center">
  一个 Claude Code skill,让项目记忆库在数月迭代后仍然可以被搜到。
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Claude_Code-2.1%2B-orange?style=flat-square" alt="Claude Code 2.1+">
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-lightgrey?style=flat-square" alt="MIT"></a>
</p>

<p align="center">
  <a href="README.md">English</a> | <strong>中文</strong>
</p>

---

## 为什么

项目跑几个月后,记忆库就难搜了。你分不清哪条还成立,也不知道上季度那个 bug 的答案藏在哪个文件里。

Claude Code 的 auto-memory(v2.1.59+)把记忆写成 plain markdown,放在 `~/.claude/projects/<slug>/memory/`,你可以读、改、版本控制。它**没**强制结构:不规定命名、没必填字段、不要求 feedback 类必有 "why" 段。这个 skill 加上这些规范,再配一个 bash 审计脚本查漂移。

## 工作方式

- **在 auto-memory 之上加 schema**。`<type>_<topic>.md` 命名 + 必填 frontmatter(name / description / type)+ feedback 类必含 Why 段。auto-memory 仍然在写,skill 让 Claude 按规范写。
- **触发词管理**。"audit memory" 跑审计脚本,"复盘" 回顾 session 挑值得记的。
- **soft warning,不用 hook**。审计报漂移,不拦写入。
- **纯 markdown,落地磁盘**。可读可改可 grep 可 git。skill 不加数据库不加守护进程。

## 效果

- 一个主题一个文件,Claude 第一次查就命中,不用过几个近似条目。
- 去重后的库每次 session 加载的文件更少,context 留给真正在做的事。

审计脚本示例输出:

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

Hard-rule compliance: 99.2%  (1 violation / 132 files)
```

## 安装

### 让 Claude 装

把下面这句贴进任意 Claude Code session:

```
Install the claude-memory-manager skill from
https://github.com/jau123/claude-memory-manager
```

剩下交给 Claude。验证:开新 session 说一句 `"audit memory"`。

<details>
<summary>或手动安装</summary>

```bash
git clone https://github.com/jau123/claude-memory-manager.git && \
  mkdir -p ~/.claude/skills/memory-management/templates && \
  cp claude-memory-manager/SKILL.md ~/.claude/skills/memory-management/ && \
  cp claude-memory-manager/templates/audit-memory.template.sh \
     ~/.claude/skills/memory-management/templates/
```

项目级配置(audit 脚本 + CLAUDE.md memory 段)→ [INSTALL.md](INSTALL.md)

</details>

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

## 与内置 auto-memory 对比

|  | Schema | 审计 | 长期效果 |
|---|---|---|---|
| 只用 auto-memory | 无(Claude 自己决定) | 无 | 文件累积但无命名 / 内容规范 |
| **加这个 skill** | 3 种类型 + 必填字段 + feedback 必有 Why | 一行命令的脚本 | 库保持可审计、可搜 |

要在 chunk 化的存储上做语义检索,看 Mem0 / Letta / Zep 这类向量后端。

## 限制

- **单项目作用域**。每个 skill 实例只盯一个 memory 目录,无跨项目合并。
- **无语义排序**。审计基于模式匹配(grep + 命名 + frontmatter),识别不了"两个文件用不同词描述同一概念"。
- **依赖 bash + 标准 Unix 工具**。在 macOS bash 3.2 + Linux bash 5.x 上测过;Windows / git-bash 没测。
- **无并发保护**。别在另一个 session 正在写记忆时跑 audit。
- **小项目不必要**。少于 ~10 条 entry 或不到一个月的项目用内置 auto-memory 即可,schema 开销不划算。

## License

[MIT](LICENSE) · Issues / PR 欢迎 [`jau123/claude-memory-manager`](https://github.com/jau123/claude-memory-manager/issues)
