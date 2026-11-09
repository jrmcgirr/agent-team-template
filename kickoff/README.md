# Kickoff kit

For the first two hours of a project.

1. **0:00–0:30, humans:** read the challenge together and fill in [`BRIEF.md`](BRIEF.md):
   the challenge, success criteria, idea, demo moment, stack, and team and lanes.
2. **0:30, coordinator:** in the coordinator's Claude Code session (`__COORDINATOR__`), run
   `/kickoff`. It drafts `DEMO.md`, `ARCHITECTURE.md`, `contracts/`, the
   `PROGRESS.md` state, `.env.example`, a short `README.md` and `kickoff/backlog.json`,
   then stops for your review. Meanwhile someone finishes the skeleton bead (`__BEAD_SKELETON__`).
3. **Review (about 15 minutes):** read the drafts and the backlog table. Ask for changes.
4. **Approve:** the coordinator creates the beads
   (`python3 scripts/beads-from-json.py kickoff/backlog.json --apply`) and opens the PR.
   A human merges it once CI is green.
5. **Go:** everyone starts their worktree agents, which pick up work with
   `bdh ready --label lane:<lane>`.

[`backlog.example.json`](backlog.example.json) shows what good beads look like. The
skill's full instructions are in `.claude/skills/kickoff/SKILL.md`.
