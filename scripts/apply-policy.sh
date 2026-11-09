#!/usr/bin/env bash
# Push policy/roles/*.md and policy/invariants/*.md to the BeadHub project policy.
# Substitutes {{KEY}} placeholders from policy/team.env. Adds roles and invariants
# that don't exist yet and edits the ones that do.
#   scripts/apply-policy.sh [--dry-run]
set -euo pipefail
cd "$(dirname "$0")/.."

DRY=false
[ "${1:-}" = "--dry-run" ] && DRY=true

render() { # render <file>: substitute {{KEY}} from team.env
  python3 - "$1" <<'PY'
import pathlib, re, sys
env = dict(l.split("=", 1) for l in pathlib.Path("policy/team.env").read_text().split() if "=" in l)
text = pathlib.Path(sys.argv[1]).read_text()
def sub(m):
    if m.group(1) not in env: sys.exit(f"ERROR: {{{{{m.group(1)}}}}} not set in policy/team.env")
    return env[m.group(1)]
sys.stdout.write(re.sub(r"\{\{([A-Z_]+)\}\}", sub, text))
PY
}

current=$(bdh :policy --only-selected=false --json 2>/dev/null)
roles=$(jq -r '.policy.roles | keys[]' <<<"$current")

for f in policy/roles/*.md; do
  name=$(basename "$f" .md)
  body=$(render "$f")
  if grep -qx "$name" <<<"$roles"; then
    [ "$(jq -r --arg r "$name" '.policy.roles[$r].playbook_md' <<<"$current")" = "$body" ] && { echo "unchanged role $name"; continue; }
    echo "edit role $name"
    $DRY || bdh :policy edit --role "$name" --playbook - <<<"$body" >/dev/null
  else
    echo "add role $name"
    $DRY || bdh :policy add --role --name "$name" --playbook - <<<"$body" >/dev/null
  fi
done

for f in policy/invariants/*.md; do
  rendered=$(render "$f")
  title=$(head -1 <<<"$rendered" | sed 's/^# *//')
  guidance=$(tail -n +2 <<<"$rendered")
  # match an existing invariant by title, since BeadHub assigns the id
  id=$(jq -r --arg t "$title" '.policy.invariants[] | select(.title == $t) | .id' <<<"$current")
  if [ -n "$id" ]; then
    [ "$(jq -r --arg i "$id" '.policy.invariants[] | select(.id == $i) | .body_md' <<<"$current")" = "$guidance" ] && { echo "unchanged invariant $id"; continue; }
    echo "edit invariant $id ($title)"
    $DRY || bdh :policy edit --invariant "$id" --guidance - <<<"$guidance" >/dev/null
  else
    echo "add invariant: $title"
    $DRY || bdh :policy add --invariant --title "$title" --guidance - <<<"$guidance" >/dev/null
  fi
done

$DRY || { echo; bdh :policy --only-selected=false --json 2>/dev/null | jq -r '"policy v\(.policy.version): roles \(.policy.roles | keys | join(", ")); \(.policy.invariants | length) invariants"'; }
