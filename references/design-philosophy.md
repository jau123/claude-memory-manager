# Design Philosophy

Trade-offs behind a few non-obvious choices.

## Why a skill, not a memory file

Memory files are content (what got recorded). Schema and workflow are rules about how to record. Putting the rules inside the memory library produces three problems:

1. Topic files in the memory directory don't auto-load. Claude won't read a `_schema.md` on session start, so the rules silently desync.
2. The rules live alongside the content they govern, which is harder to maintain than separating them.
3. No cross-project reuse: memory directories are per-project; rules in one project don't apply to the next.

Skills (`~/.claude/skills/`) solve all three: triggered by description keywords (official mechanism), user-level (reused across projects), and structurally separate from the content they govern.

## Why no hooks, no enforcement

Common alternative designs and why they were rejected:

| Approach | Problem |
|---|---|
| `PreToolUse` hook + `exit 2` | Claude Code has no auto-retry; a blocked write in a batch flow aborts the whole batch and data is lost |
| `PostToolUse` hook tweaking cache-control | Can only warn, not block — equivalent to a post-hoc audit |
| `settings.json` schema enforcement | `.claude/` is usually gitignored; config doesn't travel across worktrees |

Claude follows a soft schema reliably when the schema is visible in the session. A quick-reference at the top of `MEMORY.md` plus a few well-formed examples is enough; the audit catches the drift that still occurs.

## Why the Why section accepts synonyms

The required `## Why` was originally strict. In real libraries, contributors gravitate to whichever heading reads naturally in the surrounding language — `## Why`, `## Root cause`, `## 根因`, `## 原因`, `## 教训`, or a bold inline `**Why**:`.

Two options:

- **Force one canonical heading** → contributors work around it, the rule becomes dead weight, and audit compliance starts to mean nothing.
- **Accept the synonyms** → the audit regex covers the common variants, the rule stays meaningful.

The skill takes the second path. The schema exists to make the reason easy to find; policing the heading isn't worth the workarounds.

## Why two layers of overload defense (Rule 6)

Single-file size is the obvious failure mode, but a flat index becomes its own bottleneck once a group passes ~15 entries. Claude scans the group's descriptions in one pass; misses become routine.

| Layer | Failure mode | Threshold |
|---|---|---|
| **Single file** | One file accumulates multiple independent topics; the MEMORY.md description can no longer summarize all of them; Claude misses sub-topics | > 100 lines or ≥ 5 H2 sections |
| **Group in the index** | A group grows past ~15 entries; scanning misses rise; tasks repeat work that's already recorded | ≥ 15 entries |

Mitigation: split single-file overload into a new file; replace a flat group with a hub-memory page that maps the sub-topics.

## Why "soft warning, no hard block"

Audit prints a compliance number and a violation list. It doesn't fix files and it doesn't block writes. The rationale:

- LLM-generated content will never hit 100% on any schema. Targeting 100% breeds workarounds (renamed sections, padded prose) and the metric loses meaning.
- Hard blocks at write time destroy batch flows. Claude doesn't auto-retry on a denied tool call, so the first write gets blocked and the rest of the batch is silently abandoned.

95% or higher is the healthy band. Below 85% warrants a schema change or migration.
