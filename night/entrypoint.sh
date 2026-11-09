#!/usr/bin/env bash
# Container entrypoint, runs as root: turn on the firewall, keep its IP list fresh,
# then drop to the unprivileged `agent` user for the actual work.
#   (no args)        run the night loop
#   <command...>     run that command as the agent instead (e.g. preflight.sh)
set -euo pipefail

if [ "${NIGHT_FIREWALL:-on}" = "off" ]; then
  echo "WARNING: firewall disabled (NIGHT_FIREWALL=off)" >&2
else
  /usr/local/bin/init-firewall.sh
  ( while sleep 600; do /usr/local/bin/init-firewall.sh --refresh >/dev/null 2>&1 || true; done ) &
fi

if [ "$#" -eq 0 ]; then set -- bash /home/agent/loop.sh; fi
cd /home/agent
exec setpriv --reuid=agent --regid=agent --init-groups --inh-caps=-all --bounding-set=-all \
  env HOME=/home/agent USER=agent "$@"
