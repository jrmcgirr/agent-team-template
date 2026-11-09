# Teammate onboarding (about 15 minutes)

Do this on your own machine before the project starts. You can paste this file into Claude Code
and have it walk you through, but approve each command yourself.

## 0. Before you start

- Accept the GitHub invite to `__REPO__`.
- Join the BeadHub project `__PROJECT__` at https://app.beadhub.ai (__LEAD__ sends the invite).
- Install Claude Code, `gh` (and `gh auth login`), Docker if you might host the night run.

## 1. Install the tools (pinned to the versions the team tested)

```bash
# beads (bd) 1.3.4 and bdh 0.12.3, macOS arm64 shown; swap darwin_arm64 for your platform
mkdir -p ~/.local/bin
curl -fsSL https://github.com/gastownhall/beads/releases/download/v1.3.4/beads_1.3.4_darwin_arm64.tar.gz | tar -xz -C ~/.local/bin bd
curl -fsSL https://github.com/awebai/bdh/releases/download/v0.12.3/bdh_0.12.3_darwin_arm64.tar.gz | tar -xz -C ~/.local/bin bdh
bd --version   # expect 1.3.4
```

## 2. Clone and get the shared backlog

```bash
git clone git@github.com:__REPO__.git && cd __REPO_NAME__
bd bootstrap          # pulls the beads database from refs/dolt/data
bd list --status=open # you should see the seeded beads
```

## 3. Register your main workspace

Pick an alias like `<you>-<lane>` (for example `sam-frontend`) and a role:
`backend`, `frontend` or `developer` to build, `tester` to write the tests that make beads
verifiable, `reviewer` to review PRs, or `sentry` to watch CI and stale work on a loop.
`__COORDINATOR__` is the coordinator. See `policy/` for every playbook.

```bash
bdh :init --project __PROJECT__ --alias <you>-<lane> --role <role> --human "<Your Name>"
bdh :status   # you, plus everyone else's agents
bdh :policy   # read your role's playbook
```

This writes `.beadhub` and `.aw/` (both gitignored) and stores your API key in
`~/.config/aw/config.yaml`. Never commit them.

## 4. Extra agents

Every extra agent gets its own worktree, branch and identity:

```bash
bdh :add-worktree <role> --alias <you>-<lane>-2
# then open a new Claude Code session in ../__REPO_NAME__-<you>-<lane>-2
```

## 5. Check it works

- `bdh :status` lists every teammate's agents.
- Send a test mail: `bdh :aweb mail send <someone> "hello from <alias>"`.
- `make test` passes (before the skeleton exists it runs only the shell tests in `tests/`).

Then read the team rules at the top of `CLAUDE.md`. They're the same in `AGENTS.md`.

## 6. Team dry run (the "Dry run: two machines" bead)

Once two or more teammates are onboarded, run this together on a throwaway branch, with
at least two machines. Tick every item; anything that fails gets fixed before real work.

- [ ] **Claims.** Agent A claims a bead and runs `bdh dolt push`. On machine B, after
  `bdh dolt pull`, `bdh ready` no longer lists it and `bdh :status` shows A holding it.
  B's attempt to claim the same bead is rejected.
- [ ] **Locks.** A locks a shared file (`bdh :aweb lock <path>`). B sees the lock in
  `bdh :aweb locks`. A releases it.
- [ ] **Mail.** A mails B; B's agent gets the notification and reads it with
  `bdh :aweb mail open <alias>`.
- [ ] **Chat.** A runs `bdh :aweb chat send-and-wait <B> "ping" --start-conversation`; B
  answers with `send-and-wait`; A ends with `send-and-leave`.
- [ ] **Escalate.** An agent runs `bdh :escalate` on a test bead, and the humans see it.
- [ ] **Worktree beads.** In a folder made by `bdh :add-worktree`, `bdh ready` lists the
  same beads as the main clone, and a claim made there shows up in the main clone and on the
  other machine after `bdh dolt push` / `pull`.
- [ ] **Worktree dependencies.** A fresh worktree installs its own dependencies
  (`uv sync`, `npm` or `pnpm install`) and `make test` passes there without touching the
  main clone's `.venv` or `node_modules`.
- [ ] **PR loop.** An agent opens a PR titled `<bead-id>: ...`, CI goes green, a human
  merges it with `gh pr merge <n> --squash --match-head-commit <sha>`, and the agent closes
  the bead. A direct `git push origin main` is rejected.
- [ ] **Clean up.** Release or close the test beads; `git fsck` is clean in every clone.
  Note the `bdh` version that passed and roughly how many tokens an agent used per hour.
