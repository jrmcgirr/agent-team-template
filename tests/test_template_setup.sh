#!/usr/bin/env bash
# After scripts/new-project.sh has run, no __PLACEHOLDER__ from the template may be left.
# In the template itself (no beads database yet) there is nothing to check.
set -euo pipefail
cd "$(dirname "$0")/.."
[ -f .beads/metadata.json ] || exit 0
left=$(git grep -nE '__(REPO|REPO_OWNER|REPO_NAME|PROJECT|LEAD|COORDINATOR|BEAD_[A-Z_]+)__' -- . \
  ':!scripts/new-project.sh' ':!tests/test_template_setup.sh' ':!README.md' || true)
if [ -n "$left" ]; then
  echo "ERROR: template placeholders left; run scripts/new-project.sh or fill them by hand: $(head -3 <<<"$left" | tr '\n' ' ')"
  exit 1
fi
