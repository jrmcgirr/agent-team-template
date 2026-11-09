# Coordinator alias and team roles
The coordinator's alias is `{{COORDINATOR}}`. There is no agent called `coordinator`:
whenever you'd mail or chat "the coordinator", send it to `{{COORDINATOR}}`.

```bash
bdh :aweb mail send {{COORDINATOR}} "Blocked on <id>: <reason>"
bdh :aweb chat send-and-wait {{COORDINATOR}} "<question>" --start-conversation
```

Roles on this team:
- **coordinator** plans, assigns and unblocks work. It owns `contracts/`.
- **developer / backend / frontend** implement beads in their lane.
- **tester** writes the tests that make beads verifiable and `night-ok`.
- **reviewer** reviews PRs before a human merges them.
- **sentry** watches CI, stale claims and stuck PRs, and raises alarms. It doesn't write features.

`bdh :status` shows every agent's alias, role and what it's working on. The team rules
at the top of `CLAUDE.md` / `AGENTS.md` (bead loop, branches, merging) apply to every role.
