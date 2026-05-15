<h1 align="center">Claude Memory Manager</h1>

<p align="center">
  A Claude Code skill that keeps your project's memory library searchable after months of accumulation.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Claude_Code-2.1%2B-orange?style=flat-square" alt="Claude Code 2.1+">
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-lightgrey?style=flat-square" alt="MIT"></a>
</p>

<p align="center">
  <strong>English</strong> | <a href="README.zh-CN.md">中文</a>
</p>

---

## Why

After a few months of work, the memory library is hard to search. You can't tell which entries are still current, which duplicate each other, or which file holds the answer to last quarter's bug.

Claude Code's built-in auto-memory works fine on short projects. For longer ones, this skill enforces a naming schema, runs an audit script over the library, and only writes when you explicitly trigger it.

## How It Works

- **Phrase-triggered.** "Record this", "audit memory", "review session". Nothing else writes.
- **One entry per checkpoint.** Each note follows a 3-type schema (feedback / reference / project) Claude applies consistently across sessions.
- **Audit script, no hooks.** A bash one-shot reports what's wrong. Nothing blocks your workflow.
- **Plain markdown, on disk.** Memory stays in `~/.claude/projects/<slug>/memory/`. Git-friendly.

## Effect

- One topic per file means Claude lands on the right entry on the first lookup, not after several near-misses.
- A deduplicated library loads fewer files per session, freeing context for the work itself.

Sample audit output:

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

## Install

### Tell Claude

Paste this into any Claude Code session:

```
Install the claude-memory-manager skill from
https://github.com/jau123/claude-memory-manager
```

Claude handles the rest. To verify, say `"audit memory"` in a new session.

<details>
<summary>Or install manually</summary>

```bash
git clone https://github.com/jau123/claude-memory-manager.git && \
  mkdir -p ~/.claude/skills/memory-management/templates && \
  cp claude-memory-manager/SKILL.md ~/.claude/skills/memory-management/ && \
  cp claude-memory-manager/templates/audit-memory.template.sh \
     ~/.claude/skills/memory-management/templates/
```

Per-project audit script + CLAUDE.md memory protocol → [INSTALL.md](INSTALL.md)

</details>

## First Use

The skill activates from natural language. No slash command.

```
You: "Record today's wildcard bug fix"
→ Claude writes one feedback_*.md entry: filename, frontmatter,
  Why section, How-to-apply.

You: "Review the session"
→ Claude walks recent session, surfaces 3–5 candidates, asks
  which to keep.

You: "Audit memory"
→ Runs scripts/audit-memory.sh, reports compliance, lists files
  that need splitting.
```

Full trigger reference → [SKILL.md](SKILL.md)

## vs Built-in Auto-Memory

|  | Trigger | Audit | What gets recorded |
|---|---|---|---|
| Claude Code built-in auto-memory | Automatic | None | Per-session conclusions |
| **claude-memory-manager** | **User phrase** | **One-command script** | **Only what you confirm** |

For semantic retrieval over chunked storage, look at vector-backed tools like Mem0, Letta, or Zep.

## Limits

- **Single-project scope.** One memory directory per skill instance; no cross-project consolidation.
- **No semantic ranking.** The audit is pattern matching (grep + filename + frontmatter); it won't catch "two files describe the same concept in different words."
- **Bash + standard Unix tools.** Tested on macOS bash 3.2 and Linux bash 5.x; Windows / git-bash untested.
- **No concurrency safety.** Don't run the audit while another session is mid-write.
- **Overkill for small libraries.** Below ~10 entries or a month of project age, the built-in auto-memory is sufficient and the schema overhead doesn't pay off.

## License

[MIT](LICENSE) · Issues and PRs welcome at [`jau123/claude-memory-manager`](https://github.com/jau123/claude-memory-manager/issues).
