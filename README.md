<h1 align="center">Claude Memory Manager</h1>

<p align="center">
  <strong>A methodology skill that teaches Claude Code <em>how</em> to record memories — you decide <em>when</em>.</strong>
  <br>
  <sub>Built for serious development — when a project iterates for months, the memory library accumulates drift and outdated entries.</sub>
</p>

<p align="center">
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-lightgrey?style=flat-square" alt="MIT"></a>
  <img src="https://img.shields.io/badge/Platform-Claude_Code-orange?style=flat-square" alt="Claude Code">
  <img src="https://img.shields.io/badge/Storage-Zero-green?style=flat-square" alt="Zero storage">
  <img src="https://img.shields.io/badge/Hooks-None-blue?style=flat-square" alt="No hooks">
</p>

<p align="center">
  <strong>English</strong> | <a href="README.zh-CN.md">中文</a>
</p>

<p align="center">
  <a href="#why-this-exists">Why</a> &bull;
  <a href="#design-philosophy">Philosophy</a> &bull;
  <a href="#quick-start">Quick Start</a> &bull;
  <a href="#how-to-trigger">Trigger</a>
</p>

---

## Why This Exists

Claude Code is for serious development. **Context is precious. Memory accumulates over months.**

Most existing systems (Codex, OpenClaw, and most RAG-style frameworks) take an "auto-recall everything" path — the system silently decides what to remember, when, and how. For long-running serious projects, that means context pollution, no audit trail, and gradual drift no one notices.

We go the other way. **You** decide what's worth sedimenting. The skill teaches Claude *how* to write it well so months later it's still findable, readable, and trustworthy.

## Design Philosophy

### Triggered, not automatic

The skill activates only when you say so — "record what we learned today" / "wrap-up review" / "anything worth sedimenting?" — and never runs in the background. What enters your memory library is always intentional.

### Sediment, don't accumulate

Each meaningful checkpoint — a bug fixed, a non-obvious decision, a long debug — becomes one structured note. Not because the system felt like saving something, but because *you* decided this is worth keeping.

### Audit, don't enforce

A bash script gives you a one-shot health check whenever you want it: how many entries violate conventions, how many files have grown too large, how many indexes are stale. **No hooks block your workflow.** Just a number to watch.

### The skill teaches the *how*

Naming, structure, when to update vs split, when to create an index — these are decisions Claude tends to make inconsistently across sessions. The skill packages the judgment so Claude writes uniformly, even six months later in a fresh session.

## Quick Start

```bash
git clone https://github.com/jau123/claude-memory-manager.git ~/code/claude-memory-manager

mkdir -p ~/.claude/skills/memory-management/templates
cp ~/code/claude-memory-manager/SKILL.md ~/.claude/skills/memory-management/SKILL.md
cp ~/code/claude-memory-manager/templates/audit-memory.template.sh \
   ~/.claude/skills/memory-management/templates/
```

Per-project setup (audit script + CLAUDE.md protocol + MEMORY.md cheatsheet) → [INSTALL.md](INSTALL.md)

## How to Trigger

Just say what you mean — Claude matches keywords automatically:

| You say... | Skill does... |
|---|---|
| *"Record that wildcard bug"* / *"记一下今天的坑"* | Writes one new structured note |
| *"Wrap-up review"* / *"复盘 / 开发完了"* | Walks through recent session, picks what's worth keeping |
| *"Update this memory"* / *"Fix that conclusion"* | Decides whether to update in place or split out |
| *"Audit memory"* | Runs the health-check script, reports compliance |
| *"Bootstrap from zero"* | Sets up the index, schema, and cheatsheet for a new project |

No `/skill` command needed.

## Health Check

When your memory library starts feeling tangled, run the audit script. It tells you in seconds:

- Files that don't follow naming conventions
- Entries missing essential context
- Files that have grown too long and need splitting
- Index sections that need a hub
- Index links that don't resolve

Soft warnings only. Nothing blocks. You decide what to fix.

## File Structure

```
claude-memory-manager/
├── SKILL.md                  # The skill itself
├── INSTALL.md                # Setup walkthrough
├── references/               # Design notes, schema, audit details
├── templates/                # Portable bash health-check script
└── examples/                 # Three real-world condensed notes
```

## When This Doesn't Fit

Casual Claude.ai web chats, one-off scripts, or projects without a long maintenance horizon — built-in auto memory already serves you fine. The value of this skill scales with project lifespan.

## License

MIT
