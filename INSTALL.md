# Install

## Prerequisites

- Claude Code v2.1+ (auto-memory support)
- macOS / Linux / WSL (audit script is bash)

## Install the skill (user-level, shared across projects)

```bash
git clone https://github.com/jau123/claude-memory-manager.git ~/code/claude-memory-manager

mkdir -p ~/.claude/skills/memory-management
cp ~/code/claude-memory-manager/SKILL.md \
   ~/.claude/skills/memory-management/SKILL.md

# Optional: copy the audit script template
mkdir -p ~/.claude/skills/memory-management/templates
cp ~/code/claude-memory-manager/templates/audit-memory.template.sh \
   ~/.claude/skills/memory-management/templates/audit-memory.template.sh
```

## Verify

In any Claude Code session, say `"audit memory"` or `"record this learning"`. Claude should reach for the `memory-management` skill.

## Optional: per-project audit script

```bash
# Inside your project
mkdir -p scripts
cp ~/.claude/skills/memory-management/templates/audit-memory.template.sh \
   scripts/audit-memory.sh

# Required: edit MEMORY_DIR at the top of the script.
# Default location: ~/.claude/projects/<project-slug>/memory/
# slug = absolute project path with / replaced by -
# Example: /Users/foo/Project/bar → -Users-foo-Project-bar

# Find your slug
ls ~/.claude/projects/ | grep -i <your-project-name>

chmod +x scripts/audit-memory.sh
bash scripts/audit-memory.sh
```

## Optional: project memory protocol in CLAUDE.md

Add this at the top of the project's `CLAUDE.md` so Claude reaches for the skill on memory writes:

```markdown
## Memory

For memory writes / updates / schema changes → use the `memory-management` skill.

- Quick rules: top of MEMORY.md
- Audit: `bash scripts/audit-memory.sh`
```

## Optional: MEMORY.md quick-reference

In your project's `MEMORY.md`, add a ~25-line quick-rules block at the top (see `SKILL.md` Mode 5 step 2 for the template). This is the single most effective step to keep new sessions on-schema.

## Upgrade

```bash
cd ~/code/claude-memory-manager
git pull

cp SKILL.md ~/.claude/skills/memory-management/SKILL.md
cp templates/audit-memory.template.sh \
   ~/.claude/skills/memory-management/templates/audit-memory.template.sh

# If you customized scripts/audit-memory.sh in a project, merge by hand.
```

## Uninstall

```bash
rm -rf ~/.claude/skills/memory-management/

# Optionally:
# - delete per-project scripts/audit-memory.sh
# - remove the Memory section from project CLAUDE.md
# - the MEMORY.md quick-reference block is harmless to leave in place
```
