<h1 align="center">Claude Memory Manager</h1>

<p align="center">
  <strong>Curate, don't accumulate.</strong>
  <br>
  A Claude Code skill that keeps your project's memory library auditable, named consistently, and free of drift — for months, not days.
</p>

<p align="center">
  <a href="https://github.com/jau123/claude-memory-manager/stargazers"><img src="https://img.shields.io/github/stars/jau123/claude-memory-manager?style=flat-square&color=yellow" alt="Stars"></a>
  <a href="https://github.com/jau123/claude-memory-manager/commits/main"><img src="https://img.shields.io/github/last-commit/jau123/claude-memory-manager?style=flat-square" alt="Last commit"></a>
  <img src="https://img.shields.io/badge/Claude_Code-2.1%2B-orange?style=flat-square" alt="Claude Code 2.1+">
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-lightgrey?style=flat-square" alt="MIT"></a>
</p>

<p align="center">
  <strong>English</strong> | <a href="README.zh-CN.md">中文</a>
</p>

<p align="center">
  <a href="#demo">Demo</a> &bull;
  <a href="#install">Install</a> &bull;
  <a href="#first-use">First Use</a> &bull;
  <a href="#vs-alternatives">vs Alternatives</a> &bull;
  <a href="SKILL.md">Skill</a>
</p>

---

## Demo

What changes after one audit pass on a real 87-file memory library:

```
                Before                              After
   ─────────────────────────────       ─────────────────────────────
   Compliance:        12%        →     Compliance:        99%
   Naming violations: 31         →     Naming violations:  0
   Missing context:   18         →     Missing context:    1
   Broken index:       8         →     Broken index:       0
   Oversized files:   42         →     Surfaced for split: 3
   Time to grep "X":  5+ min     →     Time to grep "X":  ~10s

   ⚠️  Untrusted, ungrep-able    →     ✓  Auditable, navigable
       memory growth                       across months
```

The skill does no recording on its own. **You** trigger; **it** writes uniformly.

## Why

Long-running projects accumulate memory entries the same way codebases accumulate dead code — silently, until search stops working. By month 3, you can't tell which entries are still true, which are duplicates of each other, or which file holds the answer to *that bug last quarter*.

Claude Code's built-in auto-memory works for short projects. For longer ones, you need a **schema, an audit, and a discipline of intentional capture**. This skill packages all three.

## How It Works

- **Triggered by phrase, never automatic.** "Record this", "复盘", "audit memory" — and nothing else.
- **One entry per checkpoint.** Each note follows a 3-type schema (feedback / reference / project) Claude applies consistently across sessions.
- **Audit script, never hooks.** A bash one-shot tells you what's wrong. Nothing blocks your workflow.
- **Zero storage.** Memory stays in `~/.claude/projects/<slug>/memory/` — plain markdown, git-friendly, fully yours.

## Install

One command:

```bash
git clone https://github.com/jau123/claude-memory-manager.git && \
  mkdir -p ~/.claude/skills/memory-management/templates && \
  cp claude-memory-manager/SKILL.md ~/.claude/skills/memory-management/ && \
  cp claude-memory-manager/templates/audit-memory.template.sh \
     ~/.claude/skills/memory-management/templates/
```

**Verify** — open any Claude Code session and say:

> "audit memory"

If Claude offers to run `scripts/audit-memory.sh` (or asks you to copy the template into your project), the skill is live.

Per-project setup (audit script + CLAUDE.md hook) → [INSTALL.md](INSTALL.md)

## First Use

The skill activates from natural language. No slash command.

```
You: "记一下今天那个 wildcard bug"
→ Claude writes one feedback_*.md entry: filename, frontmatter, Why section, How-to-apply.

You: "复盘"
→ Claude walks recent session, surfaces 3–5 candidates, asks which to keep.

You: "audit memory"
→ Runs scripts/audit-memory.sh, reports compliance, lists files that need splitting.
```

Full trigger reference → [SKILL.md](SKILL.md)

## vs Alternatives

|  | Trigger | Audit | What gets recorded |
|---|---|---|---|
| Codex / OpenClaw / RAG frameworks | Automatic, opaque | None | Whatever the system decides |
| Claude Code built-in auto-memory | Automatic | None | Per-session conclusions |
| **claude-memory-manager** | **User phrase** | **One-command script** | **Only what you confirm** |

The first two paths optimize for "remember everything for me." This skill optimizes for "remember exactly what I tell you to, in a way I can audit in six months."

## What's in This Repo

| File | Purpose |
|---|---|
| [`SKILL.md`](SKILL.md) | The skill itself — 6 rules, 5 modes, schema, self-check. Drop into `~/.claude/skills/memory-management/`. |
| [`templates/audit-memory.template.sh`](templates/audit-memory.template.sh) | Portable health-check script. Copy per project, edit one path. |
| [`references/design-philosophy.md`](references/design-philosophy.md) | Why this design, what was rejected, what was tried and discarded. |
| [`references/schema.md`](references/schema.md) | The naming + frontmatter + section conventions, in detail. |
| [`references/audit-tool-guide.md`](references/audit-tool-guide.md) | Audit script options, output meaning, customization. |
| [`examples/`](examples/) | Three condensed real-world entries — one per type. |

## When This Doesn't Fit

- Project < 1 month old or memory library < 10 entries — built-in auto-memory is enough.
- You want semantic search / RAG retrieval — different category of tool.
- You want background consolidation that runs while you sleep — also different category.

The value of this skill scales with **project lifespan** and **entry count**. Below the threshold, the overhead isn't worth it.

## License

[MIT](LICENSE) · Issues and PRs welcome at [`jau123/claude-memory-manager`](https://github.com/jau123/claude-memory-manager/issues).
