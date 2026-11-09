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
