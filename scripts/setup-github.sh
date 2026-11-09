#!/usr/bin/env bash
# One-time GitHub setup for a project made from the agent team template. Run after
# scripts/new-project.sh and `git push origin main`:
#
#   scripts/setup-github.sh [teammate-github-login ...]
#
# - protects main: changes only by PR, the CI check `test` must pass, admins included,
#   no force pushes or deletion (0 approvals, so a reviewed PR can be merged by its human)
# - creates the `night` branch from main for the overnight swarm
# - deletes head branches after merge
# - invites each login given as a collaborator with push access
# Protecting a private repo's branches needs GitHub Pro, Team or an organization plan.
set -euo pipefail
cd "$(dirname "$0")/.."

repo=$(gh repo view --json nameWithOwner -q .nameWithOwner)
echo "repo $repo"

gh api -X PUT "repos/$repo/branches/main/protection" --input - >/dev/null <<'JSON'
{
  "required_status_checks": {"strict": false, "contexts": ["test"]},
  "enforce_admins": true,
  "required_pull_request_reviews": {"required_approving_review_count": 0},
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false
}
JSON
echo "ok     main protected (PR + green 'test' check, admins included)"

if gh api "repos/$repo/branches/night" >/dev/null 2>&1; then
  echo "ok     night branch already exists"
else
  sha=$(gh api "repos/$repo/git/ref/heads/main" -q .object.sha)
  gh api "repos/$repo/git/refs" -f ref=refs/heads/night -f sha="$sha" >/dev/null
  echo "ok     night branch created at ${sha:0:7}"
fi

gh repo edit "$repo" --delete-branch-on-merge >/dev/null
echo "ok     head branches are deleted after merge"

for login in "$@"; do
  gh api -X PUT "repos/$repo/collaborators/$login" -f permission=push >/dev/null
  echo "ok     invited $login (push)"
done
