# Night dry run (bead `__BEAD_NIGHT_DRY_RUN__`)

One night container, one small bead (`__BEAD_NIGHT_TEST__`), end to end. About an hour,
mostly waiting. Do it after the team dry run, a day or two before the first real night.

## 1. Get three credentials (15 min)

Put them in `night/night.env` (copy `night/night.env.example`; the real file is gitignored).

**`GH_TOKEN`**: a fine-grained personal access token at
https://github.com/settings/personal-access-tokens/new
- Resource owner: `__REPO_OWNER__`. Repository access: **only `__REPO__`**
- Repository permissions: **Contents: read and write**, **Pull requests: read and write**,
  **Actions: read** (Metadata: read is added automatically)
- Expiration: 7 days

`main` is protected (PR plus green CI, admins included), so this token can't change
`main` even though it's yours. Night agents merge into `night` only.

**`CLAUDE_CODE_OAUTH_TOKEN`** or **`ANTHROPIC_API_KEY`** (set one)
- `claude setup-token` gives a long-lived token on your subscription. The night run
  then counts against your plan's usage limits, and hitting them stops the agents.
- An API key from a Console workspace with a **spend limit** gives a hard dollar cap
  instead. That's the safer choice for an unattended night.

**`BEADHUB_API_KEY`**: this is the open question the dry run answers. Look in the
BeadHub dashboard (project `__PROJECT__`) for an API key that can register new
workspaces. If there isn't one, ask in BeadHub's project or issues how scripted agents
should authenticate.

## 2. Preflight (5 min, no work done, no identity created)

```bash
night/launch.sh preflight
```

It builds the image, turns on the firewall, and checks each item with one line
(`ok` / `FAIL` / `skip`): env vars; the firewall blocks `example.com` but reaches GitHub,
Anthropic, BeadHub, npm and PyPI; the token can push, sees the `night` branch, PRs and CI
runs; a clone and `bd bootstrap` over HTTPS see the beads; `claude -p` answers. Fix
every `FAIL` before going on.

## 3. Bring `night` up to date

The `night` branch only moves when you move it. Before every night run:

```bash
git fetch origin
git log --oneline origin/main..origin/night   # must be empty: no unreviewed night work left
git push origin origin/main:refs/heads/night  # fast-forward night to main
```

## 3b. Clear stale claims

A container that stopped mid-bead leaves the bead assigned to its old alias, and new
agents won't take over another agent's claim. Before every night run, check `bdh :status`
and `bdh list --status=in_progress` for `night-*` holders, and release each one:

```bash
bdh update <id> --assignee "" --status open --force && bdh dolt push   # --force: only for abandoned claims (container stopped)
```

Note that `night/NIGHT_PROMPT.md` is read from the `night` branch, not from your working
copy: prompt changes take effect only after they're merged to `main` and `night` is
fast-forwarded (step 3). `loop.sh` and the firewall are baked into the image from your
working copy at launch.

Each run registers new aliases like `night-1-1106-1626` (month, day, then UTC time),
because BeadHub won't reuse an alias.

## 4. Run one agent (20–40 min)

```bash
night/launch.sh 1
night/launch.sh logs night-1      # loop log; per-session logs are inside the container
```

Watch for these, in order:

| Step | Where to see it |
|---|---|
| Firewall on | first line of the log: `firewall: on (...)` |
| `bd bootstrap` and `bdh :init` succeed without prompts | log; `night-1` shows in `bdh :status` |
| Claims `__BEAD_NIGHT_TEST__` | `bdh :status` / `bdh show __BEAD_NIGHT_TEST__` |
| Opens a PR into `night` | `gh pr list --base night` |
| CI green, merged at the tested commit | `gh pr view <n>` |
| Bead closed | `bdh show __BEAD_NIGHT_TEST__` |
| Loop stops: "no night-ok beads ready; stopping" | log; the container exits |

Kill switch at any point: `night/launch.sh stop`.

## 5. Pass criteria (from the bead)

- PR merged into `night` by `night-1`, `__BEAD_NIGHT_TEST__` closed, loop stopped by itself
- `git fsck` clean in your clone after `git fetch`
- Note: wall time for the bead, and its cost (Console usage, or `/usage` for a subscription)

Then review `git diff origin/main origin/night`. If it's good, merge `night` into
`main` by PR, pinned to the commit you reviewed. That's the morning handback, rehearsed.

## If something fails

| Symptom | Likely cause |
|---|---|
| `firewall check failed` at start | Docker didn't get `NET_ADMIN`/`NET_RAW`; use `night/launch.sh`, not plain `docker run` |
| A domain the agent needs is blocked | add it to `ALLOWED_DOMAINS` in `night/init-firewall.sh` (for example a model or package host the stack uses) |
| `bdh :init` prompts or fails | wrong `BEADHUB_API_KEY`, or the alias is taken (launch.sh adds a run id) |
| Sessions end within seconds: "claim rejected" | a stale claim from an old alias; see 3b. The loop stops after 3 such sessions |
| `sync failed (403)` in session logs | `BEADHUB_API_KEY` still set after init; `loop.sh` unsets it |
| `bd bootstrap` fails over HTTPS | the `insteadOf` rewrite in `loop.sh` didn't apply to Dolt's git remote; note the error |
| `gh pr merge` refused | the token is missing Pull requests: write, or the PR's head moved after testing |
| Container exits immediately | `night/launch.sh logs night-1`; usually a missing env var |

Emergency only: `NIGHT_FIREWALL=off` in `night.env` turns the firewall off, so you can
tell whether it's the cause. Don't leave it off for a real night.

## Sizing the real night

Each container gets 2 CPUs and 4 GB (`night/launch.sh`). Pick the agent count from what
Docker Desktop has, leaving about 1 CPU and 2 GB spare:

| Docker Desktop allocation | Night agents |
|---|---|
| 8 CPUs / 16 GB | 3 |
| 14 CPUs / 28 GB | 6 |

The other limit is cost and rate limits, not hardware: multiply the dry run's cost per
bead by the beads you expect overnight.
