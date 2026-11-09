#!/usr/bin/env bash
# Usage: scripts/test.sh full|fast   (called by `make test` / `make test-fast`)
#
# Finds every Python (pyproject.toml) and JS/TS (package.json) project up to two
# levels deep and runs its tests. Output stays short on purpose so agents can read
# it: one line per suite, and failures as a single greppable "ERROR: ..." line.
# Full output goes to agent_logs/.
#
# fast mode: Python runs `pytest -x -m "not slow"`; JS runs the `test:fast`
# script if package.json has one, else `test`. Mark slow tests to keep fast mode
# under ~2 minutes.
set -uo pipefail

MODE="${1:-full}"
case "$MODE" in full|fast) ;; *) echo "usage: $0 full|fast" >&2; exit 2 ;; esac

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT" || exit 1
mkdir -p agent_logs
LOG="$ROOT/agent_logs/test-$MODE-$(date +%Y%m%d-%H%M%S).log"
: >"$LOG"

ran=0
failed=0

run() { # run <name> <dir> <command...>
  local name=$1 dir=$2
  shift 2
  ran=$((ran + 1))
  echo "=== $name ($dir): $*" >>"$LOG"
  if (cd "$dir" && "$@") >>"$LOG" 2>&1; then
    echo "ok     $name ($dir)"
  else
    echo "ERROR: $name failed in $dir; details in ${LOG#"$ROOT"/}"
    failed=$((failed + 1))
  fi
}

find_projects() { # find_projects <marker-file>
  find . -maxdepth 3 -name "$1" -not -path '*/node_modules/*' -not -path './.git/*' \
    -not -path './.beads/*' -not -path './night/*' | sort | while read -r f; do dirname "$f"; done
}

# Python (uv)
for dir in $(find_projects pyproject.toml); do
  if [ "$MODE" = fast ]; then
    run pytest "$dir" uv run pytest -q -x -m "not slow"
  else
    run pytest "$dir" uv run pytest -q
  fi
done

# JS / TS (pnpm if there's a pnpm lockfile, else npm)
for dir in $(find_projects package.json); do
  if [ -f "$dir/pnpm-lock.yaml" ]; then pm=pnpm; else pm=npm; fi
  if [ ! -d "$dir/node_modules" ]; then
    if [ "$pm" = pnpm ]; then
      (cd "$dir" && pnpm install --frozen-lockfile) >>"$LOG" 2>&1
    elif [ -f "$dir/package-lock.json" ]; then
      (cd "$dir" && npm ci) >>"$LOG" 2>&1
    else
      (cd "$dir" && npm install) >>"$LOG" 2>&1
    fi
  fi
  script="test"
  if [ "$MODE" = fast ] && grep -q '"test:fast"' "$dir/package.json"; then script=test:fast; fi
  run "$pm $script" "$dir" "$pm" run "$script"
done

# Shell tests: every executable tests/*.sh is its own suite
if [ -d tests ]; then
  for t in tests/*.sh; do
    [ -f "$t" ] && [ -x "$t" ] || continue
    run "$(basename "$t")" . "./$t"
  done
fi

if [ "$ran" -eq 0 ]; then
  echo "WARNING: no test suites found yet (add a pyproject.toml or package.json with tests)"
  exit 0
fi

echo "$ran suite(s), $failed failed"
[ "$failed" -eq 0 ]
