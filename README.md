# Agent team template

A starting repo for a few people, each running several Claude Code agents, building one
project together. The agents share a backlog and talk to each other through
[BeadHub](https://app.beadhub.ai) (`bdh`, a coordination layer over
[Beads](https://github.com/gastownhall/beads) `bd`), and an optional overnight swarm of
sandboxed agents keeps working while the humans sleep.

Once your project's kickoff runs, its `/kickoff` skill replaces this README with your own.

## What's in it

| Path | What it does |
|---|---|
| `CLAUDE.md`, `AGENTS.md` | Team rules every agent reads first: the bead loop, branches, PRs, boundaries, talking |
| `policy/` | Role playbooks (coordinator, developer, backend, frontend, reviewer, tester, sentry) pushed to BeadHub by `scripts/apply-policy.sh` |
| `ONBOARDING.md` | Teammate setup in about 15 minutes, plus the team dry-run checklist |
| `kickoff/`, `.claude/skills/kickoff/` | Hour-0 kit: humans fill in `BRIEF.md`, the coordinator runs `/kickoff` to draft `DEMO.md`, `ARCHITECTURE.md`, `contracts/` and a validated backlog |
| `scripts/beads-from-json.py` | Turns a backlog JSON file into beads with lanes, priorities and dependencies |
| `scripts/test.sh`, `Makefile` | `make test` / `make test-fast` find and run every Python, JS and shell suite, with short agent-friendly output |
| `.github/workflows/ci.yml` | CI runs `make test` on every PR and on `main` and `night` |
| `night/` | Overnight swarm: Docker containers with a default-deny egress firewall that take `night-ok` beads and merge into the `night` branch only |
| `PROGRESS.md`, `contracts/` | The running log, and the shared interfaces only the coordinator edits |

## Start a new project

You need `gh`, `bd` 1.3.4 and `bdh` 0.12.3 (install commands in `ONBOARDING.md` step 1).

1. On GitHub, click **Use this template** and create the new repo (private is fine). Then
   clone it and run the setup from the clone:

   ```bash
   gh repo create <owner>/<name> --private --template <this-template-repo> --clone
   cd <name>
   scripts/new-project.sh --lead "<Your Name>"   # optional: --project <slug> --coordinator <alias>
   ```

   It fills in the repo, project, lead and coordinator names, creates the beads database
   with `bd init`, seeds 8 starter beads (onboarding, the two dry runs, the night test bead,
   skeleton, kickoff, deploy, demo) and commits. It pushes nothing.

2. Push, then set up GitHub:

   ```bash
   git push origin main
   bd dolt push
   scripts/setup-github.sh <teammate-login> ...   # protects main, creates night, invites teammates
   ```

3. In BeadHub (https://app.beadhub.ai), make sure a project with the same slug as
   `--project` (the repo name by default) exists, and invite your teammates to it.

4. Register the coordinator in this clone and push the role playbooks:

   ```bash
   bdh :init --project <slug> --alias alice --role coordinator --human "<Your Name>"   # or your --coordinator alias
   scripts/apply-policy.sh
   bdh :policy   # check the roles are there
   ```

5. Send teammates `ONBOARDING.md`. Then run the team dry run (`ONBOARDING.md` step 6) and,
   if you'll use the overnight swarm, the night dry run (`night/DRY_RUN.md`).

6. When the work starts: fill in `kickoff/BRIEF.md` and run `/kickoff` in the coordinator's
   Claude Code session.

## Changing the template

Edit this repo directly. Keep anything project-specific out: use the `__REPO__`,
`__PROJECT__`, `__LEAD__`, `__COORDINATOR__` and `__BEAD_*__` placeholders that
`scripts/new-project.sh` fills in, and add new ones to that script and to
`tests/test_template_setup.sh`.
