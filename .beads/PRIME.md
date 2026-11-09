# BeadHub Workspace

> Always use `bdh` (not `bd`) — it coordinates work across agents.

**Start every session:**
```bash
bdh :status    # your identity + team status
bdh :policy        # READ AND FOLLOW
bdh ready          # find work
```

**Before ending session:**
```bash
git status
git add <files>
bdh sync
git commit -m "..."
bdh sync
git push
```

---

[bd prime] If this output is truncated by your host, read the full persisted hook output before continuing; it may contain project memories and session rules not visible in the preview.

# Beads Workflow Context

> **Context Recovery**: Run `bdh prime` after compaction, clear, or new session
> Hooks auto-call this in Claude Code and Codex when a beads workspace is resolved

# 🚨 SESSION CLOSE PROTOCOL 🚨

**CRITICAL**: Before saying "done" or "complete", you MUST run this checklist:

```
[ ] 1. bdh close <id1> <id2> ...   (close completed issues)
[ ] 2. run quality gates        (tests, linters, builds when relevant)
[ ] 3. git status               (check what changed)
[ ] 4. report handoff           (changed files, validation, proposed commit if authorized)
```

**Note:** This is an ephemeral branch (no upstream). Do not push it unless the user or orchestrator explicitly says to.

## Core Rules
- **Default**: Use beads for ALL task tracking (`bdh create`, `bdh ready`, `bdh close`)
- **Prohibited**: Do NOT use TodoWrite, TaskCreate, or markdown files for task tracking
- **Workflow**: Create beads issue BEFORE writing code, mark in_progress when starting
- **Memory**: Use `bdh remember "insight"` for persistent knowledge across sessions. Do NOT use MEMORY.md files — they fragment across accounts. Search with `bdh memories <keyword>`.
- Persistence you don't need beats lost context
- Profile model: conservative/minimal report handoff; team-maintainer may commit only when explicitly enabled
- Git workflow: conservative by default on ephemeral branches
- Session management: check `bdh ready` for available work

## Essential Commands

### Finding Work
- `bdh ready` - Show issues ready to work (no blockers)
- `bdh list --status=open` - All open issues
- `bdh list --status=in_progress` - Your active work
- `bdh show <id>` - Detailed issue view with dependencies

### Creating & Updating
- `bdh create --title="Summary of this issue" --description="Why this issue exists and what needs to be done" --type=task|bug|feature --priority=2` - New issue
  - Priority: 0-4 or P0-P4 (0=critical, 2=medium, 4=backlog). NOT "high"/"medium"/"low"
- `bdh create ... --parent=<id>` - Hierarchical child (task under epic, subtask under task; inherits parent labels)
- `bdh update <id> --claim` - Claim work
- `bdh unclaim <id>` - Release stuck issue (agent crashed)
- `bdh update <id> --assignee=username` - Assign to someone
- `bdh update <id> --if-assignee=<expected> --assignee=<new>` - Atomic reassign: applies only if the assignee still matches (--if-status=<expected> guards status; --if-assignee='' requires unassigned). Mismatch exits non-zero with nothing written — never retry blindly
- `bdh update <id> --title/--description/--notes/--design` - Update fields inline
- `bdh close <id>` - Mark complete
- `bdh close <id1> <id2> ...` - Close multiple issues at once (more efficient)
- `bdh close <id> --reason="explanation"` - Close with reason
- **Tip**: When creating multiple issues/tasks/epics, use parallel subagents for efficiency
- **WARNING**: Do NOT use `bdh edit` - it opens $EDITOR (vim/nano) which blocks agents

### Dependencies & Blocking
- `bdh dep add <issue> <depends-on>` - Add dependency (issue depends on depends-on)
- `bdh blocked` - Show all blocked issues
- `bdh show <id>` - See what's blocking/blocked by this issue

### Sync & Collaboration
- `bdh dolt pull` - Pull beads updates from Dolt remote
- `bdh dolt push` - Push beads to Dolt remote
- `bdh search <query>` - Search issues by keyword

### Project Health
- `bdh stats` - Project statistics (open/closed/blocked counts)
- `bdh doctor` - Check for issues (sync problems, missing hooks)
- `bdh doctor --check=conventions` - Check for convention drift (lint, stale, orphans)

### Quality Tools
- `bdh create --validate` - Check description has required sections
- `bdh create --acceptance="criteria"` - Set acceptance criteria (checked by --validate)
- `bdh create --design="decisions"` - Record design decisions
- `bdh create --notes="context"` - Add supplementary notes
- `bdh config set validation.on-create warn` - Auto-validate on every create
- `bdh lint` - Check existing issues for missing sections

### Lifecycle & Hygiene
- `bdh defer <id> --until="date"` - Defer work to a future date
- `bdh supersede <id> --with=<new-id>` - Mark issue as superseded
- `bdh close <id> --suggest-next` - Show newly unblocked issues after closing
- `bdh stale` - Find issues with no recent activity
- `bdh orphans` - Find issues with broken dependencies
- `bdh preflight` - Pre-PR checks (lint, stale, orphans)
- `bdh human <id>` - Flag for human decision (list/respond/dismiss)

### Structured Workflows
- `bdh formula list` - See available workflow templates
- `bdh mol pour <name>` - Start structured workflow from formula

## Common Workflows

**Starting work:**
```bash
bdh ready           # Find available work
bdh show <id>       # Review issue details
bdh update <id> --claim  # Claim it
```

**Completing work:**
```bash
bdh close <id1> <id2> ...    # Close all completed issues at once
bd dolt pull                # Pull latest beads from main
git status                  # Report changed files and proposed commit; wait for authority
# Merge to main locally only when the active instructions grant that authority
```

**Creating dependent work:**
```bash
# Run bdh create commands in parallel (use subagents for many items)
bdh create --title="Implement feature X" --description="Why this issue exists and what needs to be done" --type=feature
bdh create --title="Write tests for X" --description="Why this issue exists and what needs to be done" --type=task
bdh dep add beads-yyy beads-xxx  # Tests depend on Feature (Feature blocks tests)
```

> **Note**: AGENTS.md and CLAUDE.md are independent files (not symlinked and not sharing an inode). Mirror substantive edits across both, or symlink one to the other.

