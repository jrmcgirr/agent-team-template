#!/usr/bin/env bash
# `make help` must list both the test and test-fast targets.
set -euo pipefail
cd "$(dirname "$0")/.."
out=$(make help)
for t in test test-fast; do
  echo "$out" | grep -Eq "^ +$t( |$)" || { echo "ERROR: make help does not list $t"; exit 1; }
done
