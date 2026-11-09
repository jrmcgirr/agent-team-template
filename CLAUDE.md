# Project Instructions for AI Agents

This file provides instructions and context for AI coding agents working on this project.

<!-- TEAM-RULES:START (source: scripts/team-rules.md; run scripts/sync-team-rules.sh after editing) -->
## Team rules (read first; these override the generic Beads guidance below)

**Profile: team-maintainer.** This repo opts in: agents may commit, push their own
branches, open PRs, close beads and run `bdh dolt push` without asking. Nobody pushes to
`main` directly. `main` is protected and needs green CI.

**One agent, one workspace.** Every agent has its own clone or worktree
(`bdh :add-worktree <role>`) and its own BeadHub alias. Never run `bdh` or edit files
in another agent's folder.

**Start of every session.** Read `PROGRESS.md` (current state), `ARCHITECTURE.md` (what
we're building and which directories your lane owns) and `DEMO.md` (what the demo has to show).

**Bead loop**
1. `bdh dolt pull`, then `bdh ready` (filter by your lane: `bdh ready --label lane:<x>`).
2. `bdh update <id> --claim`, then `bdh dolt push` straight away so other machines see the claim.
3. `git fetch && git checkout -b <alias>/<bead-id>-<slug> origin/main`.
4. `make test-fast` while working and `make test` before every push.
5. Open a PR titled `<bead-id>: <summary>`. Your human reviews and merges it, pinned to the
   SHA they reviewed: `gh pr merge <n> --squash --match-head-commit <sha>`.
6. After the merge: `bdh close <id>`, `bdh dolt push`, and add one line to the `PROGRESS.md` log.

**Beads.** Each bead takes under an hour. Split anything bigger by acceptance criterion.
Every bead names the test that proves it's done. Labels: `lane:<name>` for its lane, plus
`night-ok` if a test fully verifies it.

**Boundaries.** `contracts/` is changed only by the coordinator; mail them to ask for a
change. Stay in your lane's directories; check `bdh :aweb locks` before you edit shared files.

**Roles.** `__COORDINATOR__` is the coordinator; mail it, not "coordinator". Your role's playbook is in
`bdh :policy`; its source is `policy/` (edit there, then run `scripts/apply-policy.sh`).

**Talking.** Use mail for status and non-blocking questions. Use chat only when you're
blocked and the other agent is working. After two failed attempts, write what you tried
on the bead and run `bdh :escalate`.

**Test output.** Keep it to a few lines. Write failures as one line starting with `ERROR:`
and put full logs in `agent_logs/`.

**Secrets.** Never commit `.beadhub`, `.aw/`, `night/night.env`, `.env` files or API keys.
<!-- TEAM-RULES:END -->

<!-- BEGIN BEADS INTEGRATION v:1 profile:minimal hash:1105d646 -->
## Beads Issue Tracker

This project uses **bd (beads)** for issue tracking. Run `bdh prime` to see full workflow context and commands.

### Quick Reference

```bash
bdh ready              # Find available work
bdh show <id>          # View issue details
bdh update <id> --claim  # Claim work
bdh close <id>         # Complete work
```

### Rules

- Use `bdh` for ALL task tracking — do NOT use TodoWrite, TaskCreate, or markdown TODO lists
- Run `bdh prime` for detailed command reference and session close protocol
- Use `bdh remember` for persistent knowledge — do NOT use MEMORY.md files

**Architecture in one line:** issues live in a local Dolt DB; sync uses `refs/dolt/data` on your git remote; `.beads/issues.jsonl` is a passive export. See https://github.com/gastownhall/beads/blob/main/docs/core-concepts/sync-concepts.md for details and anti-patterns.

## Agent Context Profiles

The managed Beads block is task-tracking guidance, not permission to override repository, user, or orchestrator instructions.

- **Conservative (default)**: Use `bdh` for task tracking. Do not run git commits, git pushes, or Dolt remote sync unless explicitly asked. At handoff, report changed files, validation, and suggested next commands.
- **Minimal**: Keep tool instruction files as pointers to `bdh prime`; use the same conservative git policy unless active instructions say otherwise.
- **Team-maintainer**: Only when the repository explicitly opts in, agents may close beads, run quality gates, commit, and push as part of session close. A current "do not commit" or "do not push" instruction still wins.

## Session Completion

This protocol applies when ending a Beads implementation workflow. It is subordinate to explicit user, repository, and orchestrator instructions.

1. **File issues for remaining work** - Create beads for anything that needs follow-up
2. **Run quality gates** (if code changed) - Tests, linters, builds
3. **Update issue status** - Close finished work, update in-progress items
4. **Handle git/sync by active profile**:
   ```bash
   # Conservative/minimal/default: report status and proposed commands; wait for approval.
   git status

   # Team-maintainer opt-in only, unless current instructions forbid it:
   git pull --rebase
   git push
   git status
   ```
5. **Hand off** - Summarize changes, validation, issue status, and any blocked sync/commit/push step

**Critical rules:**
- Explicit user or orchestrator instructions override this Beads block.
- Do not commit or push without clear authority from the active profile or the current user request.
- If a required sync or push is blocked, stop and report the exact command and error.
<!-- END BEADS INTEGRATION -->


## Build & Test

_Add your build and test commands here_

```bash
make test-fast   # quick deterministic sample, run while working
make test        # full suite; CI runs this on every PR
```

`scripts/test.sh` finds every `pyproject.toml` / `package.json` project and runs its tests.

## Architecture Overview

See `ARCHITECTURE.md` (components, which lane owns which directory, contracts, decisions)
and `DEMO.md` (the click path everything serves). Both are written at kickoff with the
`/kickoff` skill from `kickoff/BRIEF.md`.

## Conventions & Patterns

The team rules at the top of this file, plus anything recorded under "Decisions" in `ARCHITECTURE.md`.

<!-- BEADHUB:START -->
## BeadHub Coordination Rules

This project uses `bdh` for multi-agent coordination and issue tracking, `bdh` is a wrapper on top of `bd` (beads). Commands starting with : like `bdh :status` are managed by `bdh`. Other commands are sent to `bd`.

You are expected to work and coordinate with a team of agents. ALWAYS prioritize the team vs your particular task.

You will see notifications telling you that other agents have written mails or chat messages, or are waiting for you. NEVER ignore notifications. It is rude towards your fellow agents. Do not be rude.

Your goal is for the team to succeed in the shared project.

The active project policy as well as the expected behaviour associated to your role is shown via `bdh :policy`.

## Start Here (Every Session)

```bash
bdh :policy    # READ CAREFULLY and follow diligently
bdh :status    # who am I? (alias/workspace/role) + team status
bdh ready      # find unblocked work
```

Use `bdh :help` for bdh-specific help.

## Rules

- Always use `bdh` (not `bd`) so work is coordinated
- Default to mail (`bdh :aweb mail list|open|send`) for coordination; use chat (`bdh :aweb chat pending|open|send-and-wait|send-and-leave|history|extend-wait`) when you need a conversation with another agent.
- Respond immediately to WAITING notifications — someone is blocked.
- Notifications are for YOU, the agent, not for the human.
- Don't overwrite the work of other agents without coordinating first.
- ALWAYS check what other agents are working on with bdh :status which will tell you which beads they have claimed and what files they are working on (reservations).
- `bdh` derives your identity from the `.beadhub` file in the current worktree. If you run it from another directory you will be impersonating another agent, do not do that.
- Prioritize good communication — your goal is for the team to succeed

## Using mail

Mail is fire-and-forget — use it for status updates, handoffs, and non-blocking questions.

```bash
bdh :aweb mail send <alias> "message"                         # Send a message
bdh :aweb mail send <alias> "message" --subject "API design"  # With subject
bdh :aweb mail list                                           # Check your inbox
bdh :aweb mail open <alias>                                   # Read & acknowledge
```

## Using chat

Chat sessions are persistent per participant pair. Use `--start-conversation` when initiating a new exchange (longer wait timeout).

**Starting a conversation:**
```bash
bdh :aweb chat send-and-wait <alias> "question" --start-conversation
```

**Replying (when someone is waiting for you):**
```bash
bdh :aweb chat send-and-wait <alias> "response"
```

**Final reply (you don't need their answer):**
```bash
bdh :aweb chat send-and-leave <alias> "thanks, got it"
```

**Other commands:**
```bash
bdh :aweb chat pending          # List conversations with unread messages
bdh :aweb chat open <alias>     # Read unread messages
bdh :aweb chat history <alias>  # Full conversation history
bdh :aweb chat extend-wait <alias> "need more time"  # Ask for patience
```
<!-- BEADHUB:END -->