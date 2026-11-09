#!/usr/bin/env bash
# Start N overnight agents, one container each.
#   night/launch.sh 3            # starts night-1..night-3
#   night/launch.sh stop         # kill switch: stops every night container
#   night/launch.sh logs night-2 # follow one agent's loop log
#   night/launch.sh preflight    # check tokens, firewall and bootstrap without starting work
#
# Needs night/night.env (copy night/night.env.example; never commit it).
set -euo pipefail
cd "$(dirname "$0")"

case "${1:-}" in
  stop)
    docker ps -q --filter label=__PROJECT__-night | xargs -r docker stop
    exit 0 ;;
  logs)
    docker logs -f "${2:?usage: launch.sh logs night-N}"
    exit 0 ;;
  preflight)
    [ -f night.env ] || { echo "ERROR: night/night.env missing (copy night.env.example)" >&2; exit 1; }
    docker build -q -t __PROJECT__-night . >/dev/null
    exec docker run --rm --cap-add NET_ADMIN --cap-add NET_RAW --env-file night.env \
      __PROJECT__-night bash /home/agent/preflight.sh ;;
  ''|*[!0-9]*)
    echo "usage: $0 <count> | stop | logs <name> | preflight" >&2
    exit 2 ;;
esac

[ -f night.env ] || { echo "ERROR: night/night.env missing (copy night.env.example)" >&2; exit 1; }

docker build -t __PROJECT__-night .
# BeadHub aliases can't be reused, so each run gets its own (night-1-1107-2215, ...).
run_id=$(date +%m%d-%H%M)
for i in $(seq 1 "$1"); do
  name="night-$i"
  docker rm -f "$name" >/dev/null 2>&1 || true
  docker run -d --name "$name" --label __PROJECT__-night \
    --env-file night.env -e BEADHUB_ALIAS="$name-$run_id" \
    --cap-add NET_ADMIN --cap-add NET_RAW \
    --memory 4g --cpus 2 \
    __PROJECT__-night
  echo "started $name (BeadHub alias $name-$run_id)"
  sleep 20 # stagger starts so agents don't race for the same first bead
done
echo "Watch: bdh :status   |   Kill switch: night/launch.sh stop"
