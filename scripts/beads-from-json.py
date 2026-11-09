#!/usr/bin/env python3
"""Create a backlog of beads from a JSON file, with dependencies.

    python3 scripts/beads-from-json.py kickoff/backlog.json          # validate + print plan
    python3 scripts/beads-from-json.py kickoff/backlog.json --apply  # create beads, push

File format: {"beads": [{key, title, description, acceptance, lane, priority, type,
night_ok, deps}]}. `deps` holds keys from the same file or existing bead ids. See
.claude/skills/kickoff/SKILL.md for the rules.

--apply creates beads in dependency order through `bdh create`, records key -> id in
<file>.ids.json, and skips keys already recorded there, so it can be re-run after a
partial failure. It finishes with `bdh dolt push` unless --no-push is given.
"""
from __future__ import annotations

import argparse
import json
import re
import os
import subprocess
import sys
from collections import Counter
from pathlib import Path

KEY_RE = re.compile(r"^[a-z0-9][a-z0-9-]{1,40}$")
TYPES = {"task", "feature", "bug", "chore"}
NO_NIGHT_LANES = {"frontend", "ui", "demo", "design"}
CLI = os.environ.get("BEADS_CLI", "bdh")  # set BEADS_CLI=bd only for testing against a local database


def load(path: Path) -> list[dict]:
    data = json.loads(path.read_text())
    beads = data["beads"] if isinstance(data, dict) else data
    if not isinstance(beads, list) or not beads:
        sys.exit(f"ERROR: {path} has no beads")
    return beads


def bead_exists(bead_id: str) -> bool:
    r = subprocess.run(["bd", "show", bead_id, "--json"], capture_output=True, text=True)
    return r.returncode == 0


def validate(beads: list[dict]) -> tuple[list[str], list[str]]:
    errors, warnings = [], []
    keys = [b.get("key") for b in beads]
    for k, n in Counter(keys).items():
        if n > 1:
            errors.append(f"duplicate key {k!r}")
    keyset = set(keys)
    checked_ids: dict[str, bool] = {}

    for i, b in enumerate(beads):
        where = f"bead {i + 1} ({b.get('key', '?')})"
        for field in ("key", "title", "description", "acceptance", "lane"):
            if not str(b.get(field, "")).strip():
                errors.append(f"{where}: missing {field}")
        if b.get("key") and not KEY_RE.match(b["key"]):
            errors.append(f"{where}: key must be a lowercase slug like 'api-create-trip'")
        if len(b.get("title", "")) > 90:
            warnings.append(f"{where}: title is over 90 characters")
        if not re.search(r"\btests?\b|test_|\.test\.|\.spec\.|make test", b.get("acceptance", ""), re.I):
            errors.append(f"{where}: acceptance doesn't name a test")
        p = b.get("priority", 2)
        if not (isinstance(p, int) and 0 <= p <= 4):
            errors.append(f"{where}: priority must be an integer 0-4")
        if b.get("type", "task") not in TYPES:
            errors.append(f"{where}: type must be one of {sorted(TYPES)}")
        if b.get("night_ok") and str(b.get("lane", "")).lower() in NO_NIGHT_LANES:
            warnings.append(f"{where}: night_ok on lane {b['lane']!r}; is a test really the only check needed?")
        for d in b.get("deps", []) or []:
            if d == b.get("key"):
                errors.append(f"{where}: depends on itself")
            elif d in keyset:
                continue
            else:
                if d not in checked_ids:
                    checked_ids[d] = bead_exists(d)
                if not checked_ids[d]:
                    errors.append(f"{where}: dependency {d!r} is neither a key in this file nor an existing bead")
    return errors, warnings


def topo_order(beads: list[dict]) -> list[dict]:
    by_key = {b["key"]: b for b in beads}
    order, state = [], {}

    def visit(k: str, path: list[str]) -> None:
        if state.get(k) == "done":
            return
        if state.get(k) == "visiting":
            sys.exit("ERROR: dependency cycle: " + " -> ".join(path + [k]))
        state[k] = "visiting"
        for d in by_key[k].get("deps", []) or []:
            if d in by_key:
                visit(d, path + [k])
        state[k] = "done"
        order.append(by_key[k])

    for b in beads:
        visit(b["key"], [])
    return order


def print_plan(order: list[dict], ids: dict[str, str]) -> None:
    print(f"{'#':>3}  {'key':<28} {'lane':<10} {'P':<2} {'night':<5} {'deps':<30} title")
    for n, b in enumerate(order, 1):
        deps = ",".join(b.get("deps", []) or []) or "-"
        mark = f" [exists: {ids[b['key']]}]" if b["key"] in ids else ""
        print(f"{n:>3}  {b['key']:<28} {b['lane']:<10} {b.get('priority', 2):<2} "
              f"{'yes' if b.get('night_ok') else '':<5} {deps[:30]:<30} {b['title']}{mark}")
    lanes = Counter(b["lane"] for b in order)
    ready = Counter(b["lane"] for b in order if not b.get("deps"))
    print()
    print("per lane: " + ", ".join(f"{l} {n} ({ready.get(l, 0)} with no deps)" for l, n in sorted(lanes.items())))
    print(f"night-ok: {sum(1 for b in order if b.get('night_ok'))} of {len(order)}")


def create(b: dict, ids: dict[str, str]) -> str:
    labels = [f"lane:{b['lane']}"] + (["night-ok"] if b.get("night_ok") else [])
    deps = [ids.get(d, d) for d in (b.get("deps", []) or [])]
    cmd = [CLI, "create", "--title", b["title"], "--description", b["description"],
           "--acceptance", b["acceptance"], "--type", b.get("type", "task"),
           "--priority", str(b.get("priority", 2)), "--labels", ",".join(labels), "--json"]
    if deps:
        cmd += ["--deps", ",".join(deps)]
    r = subprocess.run(cmd, capture_output=True, text=True)
    out = r.stdout
    try:
        obj = json.loads(out[out.index("{"):])
    except (ValueError, json.JSONDecodeError):
        sys.exit(f"ERROR: couldn't parse bdh output for {b['key']}:\n{out}\n{r.stderr}")
    if obj.get("rejected"):
        sys.exit(f"ERROR: BeadHub rejected {b['key']}: {json.dumps(obj)[:500]}")
    inner = obj.get("bd_stdout") if isinstance(obj.get("bd_stdout"), dict) else obj
    bead_id = inner.get("id")
    if r.returncode != 0 or not bead_id:
        sys.exit(f"ERROR: creating {b['key']} failed (exit {r.returncode}):\n{out[:800]}\n{r.stderr[:800]}")
    return bead_id


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("file", type=Path)
    ap.add_argument("--apply", action="store_true", help="create the beads (default: dry run)")
    ap.add_argument("--no-push", action="store_true", help="with --apply: skip the final dolt push")
    args = ap.parse_args()

    beads = load(args.file)
    errors, warnings = validate(beads)
    for w in warnings:
        print(f"WARNING: {w}")
    if errors:
        for e in errors:
            print(f"ERROR: {e}")
        sys.exit(f"\n{len(errors)} error(s); nothing created")

    order = topo_order(beads)
    ids_path = args.file.with_suffix(".ids.json")
    ids = json.loads(ids_path.read_text()) if ids_path.exists() else {}
    print_plan(order, ids)

    if not args.apply:
        print("\nDry run only. Re-run with --apply to create these beads.")
        return

    print()
    for b in order:
        if b["key"] in ids:
            continue
        ids[b["key"]] = create(b, ids)
        ids_path.write_text(json.dumps(ids, indent=2) + "\n")  # save after each, for resume
        print(f"created {ids[b['key']]}  {b['key']}")
    print(f"\n{len(ids)} beads recorded in {ids_path}")
    if args.no_push:
        return
    push = subprocess.run([CLI, "dolt", "push"], capture_output=True, text=True)
    if push.returncode == 0:
        print("beads database pushed")
    else:
        print(f"WARNING: `{CLI} dolt push` failed; run it by hand:\n{(push.stderr or push.stdout)[-400:]}")


if __name__ == "__main__":
    main()
