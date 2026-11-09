#!/usr/bin/env bash
# One-time setup for a repo created from the agent team template. Run it from the
# root of a fresh clone (origin must point at the new GitHub repo):
#
#   scripts/new-project.sh [--project <slug>] [--lead "<Name>"] [--coordinator <alias>]
#
#   --project      BeadHub project slug and bead id prefix (default: the repo name)
#   --lead         the human who runs the project (default: git config user.name)
#   --coordinator  the coordinator agent's alias (default: alice)
#
# It fills the __PLACEHOLDERS__ in the docs, creates this repo's beads database
# (bd init), seeds the starter beads from kickoff/starter-backlog.json and commits.
# It pushes nothing: the last lines tell you what to push and what to run next.
set -euo pipefail
cd "$(dirname "$0")/.."

project="" lead="" coordinator="alice"
while [ $# -gt 0 ]; do
  case "$1" in
    --project) project=${2:?}; shift 2 ;;
    --lead) lead=${2:?}; shift 2 ;;
    --coordinator) coordinator=${2:?}; shift 2 ;;
    -h|--help) sed -n '2,14p' "$0"; exit 0 ;;
    *) echo "ERROR: unknown argument $1 (see --help)" >&2; exit 2 ;;
  esac
done

die() { echo "ERROR: $*" >&2; exit 1; }

[ -f .beads/metadata.json ] && die "this repo is already set up (.beads/metadata.json exists)"
command -v bd >/dev/null || die "bd is not installed (see ONBOARDING.md step 1)"
[ -z "$(git status --porcelain)" ] || die "commit or stash your changes first"

url=$(git config --get remote.origin.url) || die "no origin remote; clone the new repo from GitHub first"
repo=$(sed -E 's#^(git@github\.com:|ssh://git@github\.com/|https://github\.com/)##; s#\.git$##' <<<"$url")
[[ "$repo" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]] || die "origin $url is not a GitHub repo"
owner=${repo%%/*} name=${repo#*/}

[ -n "$project" ] || project=$(tr '[:upper:]_.' '[:lower:]--' <<<"$name")
[[ "$project" =~ ^[a-z0-9][a-z0-9-]*$ ]] || die "--project must be a lowercase slug like 'trip-planner'"
[ -n "$lead" ] || lead=$(git config user.name || true)
[ -n "$lead" ] || die "pass --lead \"<Name>\""
[[ "$coordinator" =~ ^[a-z0-9][a-z0-9-]*$ ]] || die "--coordinator must be a lowercase alias"

echo "repo $repo, project $project, lead $lead, coordinator $coordinator"

# Replace __KEY__ placeholders in every tracked text file except this script, the
# test that checks for leftovers, and README.md (the template's own docs, replaced at kickoff).
fill() { # fill KEY=value ...
  git ls-files -z -- . ':!scripts/new-project.sh' ':!tests/test_template_setup.sh' ':!README.md' |
    python3 -c '
import pathlib, sys
pairs = [a.split("=", 1) for a in sys.argv[1:]]
for f in sys.stdin.read().split("\0"):
    p = pathlib.Path(f)
    if not f or not p.is_file():
        continue
    try:
        text = p.read_text()
    except UnicodeDecodeError:
        continue
    new = text
    for k, v in pairs:
        new = new.replace(f"__{k}__", v)
    if new != text:
        p.write_text(new)
' "$@"
}

# 1. Names
fill REPO="$repo" REPO_OWNER="$owner" REPO_NAME="$name" PROJECT="$project" LEAD="$lead" COORDINATOR="$coordinator"
git add -A
git commit -q -m "Set up $project from the agent team template"
base=$(git rev-parse HEAD)

# 2. Beads database. bd init commits by itself and rewrites the agent instruction
#    files for plain bd; keep the template's bdh versions of everything outside .beads/.
log=$(mktemp)
bd init --prefix "$project" --non-interactive >"$log" 2>&1 || { cat "$log" >&2; die "bd init failed"; }
rm -f "$log"
git reset -q --soft "$base"   # fold bd's own commit into ours
git diff --name-only "$base" -- . ':!.beads' | while read -r f; do
  if git cat-file -e "$base:$f" 2>/dev/null; then git checkout "$base" -- "$f"; else git rm -q -f -- "$f"; fi
done
git add -A
git diff --cached --quiet || git commit -q -m "bd init: beads database for $project"

# 3. Starter beads, then put their ids into the docs that mention them
BEADS_CLI=bd python3 scripts/beads-from-json.py kickoff/starter-backlog.json --apply --no-push
ids=kickoff/starter-backlog.ids.json
id() { python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))[sys.argv[2]])' "$ids" "$1"; }
fill BEAD_KICKOFF="$(id kickoff)" BEAD_SKELETON="$(id skeleton)" \
     BEAD_NIGHT_DRY_RUN="$(id night-dry-run)" BEAD_NIGHT_TEST="$(id night-test)"
rm -f "$ids"
git add -A
git commit -q -m "Seed the starter beads"

echo
echo "Done. Check the result (git log -3 --stat, bd list), then:"
echo "  git push origin main          # the setup commits"
echo "  bd dolt push                  # the beads database (refs/dolt/data)"
echo "  scripts/setup-github.sh       # protect main, create the night branch"
echo "Then follow README.md from step 3: the BeadHub project, bdh :init as $coordinator, scripts/apply-policy.sh."
