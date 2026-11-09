#!/usr/bin/env bash
# Runs inside one night container. Clones the repo, registers a BeadHub identity,
# then restarts a headless Claude session with NIGHT_PROMPT.md until the timer ends.
#
# Env (from the --env-file that launch.sh passes):
#   REPO=owner/name   GH_TOKEN   CLAUDE_CODE_OAUTH_TOKEN (or ANTHROPIC_API_KEY)
#   BEADHUB_PROJECT   BEADHUB_API_KEY   BEADHUB_ALIAS (set by launch.sh)
#   NIGHT_HOURS (default 8)   SESSION_TIMEOUT (default 45m)
set -uo pipefail

: "${REPO:?}" "${GH_TOKEN:?}" "${BEADHUB_PROJECT:?}" "${BEADHUB_ALIAS:?}"
END=$(( $(date +%s) + ${NIGHT_HOURS:-8} * 3600 ))
WS=/home/agent/workspace

log() { echo "[$(date +%H:%M:%S) $BEADHUB_ALIAS] $*"; }

# Git over HTTPS with the token, including the ssh-style URLs that beads' sync.remote uses.
gh auth setup-git
git config --global url."https://github.com/".insteadOf "git@github.com:"
git config --global --add url."https://github.com/".insteadOf "ssh://git@github.com/"
git config --global user.name "$BEADHUB_ALIAS (night agent)"
git config --global user.email "$BEADHUB_ALIAS@night.invalid"

git clone "https://github.com/$REPO.git" "$WS"
cd "$WS" || exit 1
git switch night
bd bootstrap
if ! bdh :init --project "$BEADHUB_PROJECT" --alias "$BEADHUB_ALIAS" --role developer \
  --human "night-shift" ${BEADHUB_API_KEY:+--api-key "$BEADHUB_API_KEY"}; then
  log "ERROR: bdh :init failed; not starting without a BeadHub identity"
  exit 1
fi
# The env key is a project/service key: it can register, but while it's set bdh acts as the
# service identity and coordination calls get 403. Use the workspace's own key from now on.
unset BEADHUB_API_KEY

mkdir -p agent_logs
n=0
while [ "$(date +%s)" -lt "$END" ]; do
  n=$((n + 1))
  # Start every session from a clean, current night branch and ledger.
  git fetch --quiet origin
  git switch --quiet night && git reset --quiet --hard origin/night && git clean -fdq
  bdh dolt pull >/dev/null 2>&1 || log "WARN: dolt pull failed"

  log "session $n starting"
  started=$(date +%s)
  timeout "${SESSION_TIMEOUT:-45m}" claude --dangerously-skip-permissions -p "$(cat night/NIGHT_PROMPT.md)" \
    &>"agent_logs/session-$(date +%Y%m%d-%H%M%S).log"
  log "session $n exited with $?"

  # Sessions that end within 2 minutes did no real work (claim rejected, nothing to do,
  # an error). Three in a row means something's stuck: stop instead of looping all night.
  if [ $(( $(date +%s) - started )) -lt 120 ]; then
    short=$(( ${short:-0} + 1 ))
    if [ "$short" -ge 3 ]; then
      log "3 short sessions in a row; stopping (check the session logs and bdh :status)"
      bdh :aweb mail send "${NIGHT_ALERT_ALIAS:-alice}" "$BEADHUB_ALIAS stopped: 3 sessions in a row did no work" >/dev/null 2>&1 || true
      break
    fi
  else
    short=0
  fi

  # If nothing is left to do, stop instead of burning tokens.
  if ! bdh ready --label night-ok --json 2>/dev/null | grep -q '"id"'; then
    log "no night-ok beads ready; stopping"
    break
  fi
  sleep 10
done
log "done"
