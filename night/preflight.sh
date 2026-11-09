#!/usr/bin/env bash
# Checks a night container's setup without claiming work or registering an identity.
# Run with: night/launch.sh preflight
# Prints one line per check: ok / FAIL / skip. Exits non-zero if anything failed.
set -uo pipefail

fails=0
ok()   { echo "ok    $*"; }
fail() { echo "FAIL  $*"; fails=$((fails + 1)); }
skip() { echo "skip  $*"; }

# 1. Environment
for v in REPO GH_TOKEN BEADHUB_PROJECT BEADHUB_API_KEY; do
  if [ -n "${!v:-}" ]; then ok "env $v is set"; else fail "env $v is empty (night/night.env)"; fi
done
if [ -n "${CLAUDE_CODE_OAUTH_TOKEN:-}${ANTHROPIC_API_KEY:-}" ]; then
  ok "env Claude credential is set"
else
  fail "env CLAUDE_CODE_OAUTH_TOKEN or ANTHROPIC_API_KEY must be set"
fi

# 2. Firewall: blocked off-list, open to what the agent needs
if curl -s --max-time 5 https://example.com >/dev/null; then
  fail "firewall: example.com is reachable (should be blocked)"
else
  ok "firewall: example.com blocked"
fi
for url in https://api.github.com/zen https://api.anthropic.com https://app.beadhub.ai https://registry.npmjs.org https://pypi.org/simple/; do
  code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 10 "$url")
  if [ "$code" != "000" ]; then ok "firewall: $url reachable ($code)"; else fail "firewall: $url unreachable"; fi
done

# 3. GitHub token: repo access, push permission, night branch, PR read
if [ -n "${GH_TOKEN:-}" ] && [ -n "${REPO:-}" ]; then
  if perms=$(gh api "repos/$REPO" --jq '.permissions.push' 2>&1); then
    if [ "$perms" = "true" ]; then ok "GH_TOKEN can push to $REPO"; else fail "GH_TOKEN can read $REPO but not push"; fi
  else
    fail "GH_TOKEN can't read $REPO: $perms"
  fi
  if gh api "repos/$REPO/branches/night" --jq .name >/dev/null 2>&1; then ok "night branch exists"; else fail "night branch missing"; fi
  if gh pr list -R "$REPO" -L 1 >/dev/null 2>&1; then ok "GH_TOKEN can list PRs"; else fail "GH_TOKEN can't list PRs (needs Pull requests: read/write)"; fi
  if gh run list -R "$REPO" -L 1 >/dev/null 2>&1; then ok "GH_TOKEN can read CI runs"; else fail "GH_TOKEN can't read CI runs (needs Actions: read)"; fi

  # 4. Clone over HTTPS and bootstrap the beads database the way loop.sh does
  tmp=$(mktemp -d)
  gh auth setup-git >/dev/null 2>&1
  git config --global url."https://github.com/".insteadOf "git@github.com:"
  git config --global --add url."https://github.com/".insteadOf "ssh://git@github.com/"
  if git clone -q "https://github.com/$REPO.git" "$tmp/repo" 2>"$tmp/err"; then
    ok "git clone over HTTPS"
    # Save the list first: grep -q exits early and, under pipefail, would fail the pipeline.
    if (cd "$tmp/repo" && bd bootstrap >"$tmp/bd.log" 2>&1 && bd list --status=open --json >"$tmp/list.json" 2>/dev/null) \
       && grep -q '"id"' "$tmp/list.json"; then
      ok "bd bootstrap over HTTPS sees the beads"
    else
      fail "bd bootstrap over HTTPS: $(tail -3 "$tmp/bd.log" | sed $'s/\x1b\\[[0-9;]*[A-Za-z]//g' | tr '\r\n' '  ')"
    fi
  else
    fail "git clone over HTTPS: $(tail -2 "$tmp/err" | tr '\n' ' ')"
  fi
  rm -rf "$tmp"
else
  skip "GitHub checks (GH_TOKEN or REPO not set)"
fi

# 5. Claude credential works (one tiny request)
if [ -n "${CLAUDE_CODE_OAUTH_TOKEN:-}${ANTHROPIC_API_KEY:-}" ]; then
  out=$(timeout 120 claude -p "Reply with exactly the word OK and nothing else." 2>&1 | tail -1)
  if [ "$out" = "OK" ]; then ok "claude -p answers"; else fail "claude -p: ${out:0:200}"; fi
else
  skip "Claude check (no credential)"
fi

# 6. BeadHub reachability. Registration (bdh :init with BEADHUB_API_KEY) is tested
#    for real by the first `night/launch.sh 1`, since it creates an identity.
code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 10 https://app.beadhub.ai/api/v1/status)
if [ "$code" != "000" ]; then ok "BeadHub API reachable ($code)"; else fail "BeadHub API unreachable"; fi

echo
if [ "$fails" -eq 0 ]; then echo "preflight passed"; else echo "preflight: $fails check(s) failed"; fi
[ "$fails" -eq 0 ]
