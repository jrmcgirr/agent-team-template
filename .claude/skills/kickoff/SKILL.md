---
name: kickoff
description: Hour-0 kickoff for this repo. Turns kickoff/BRIEF.md (challenge, idea, stack, lanes) into DEMO.md, ARCHITECTURE.md, contracts/, the PROGRESS.md state, .env.example and a validated bead backlog, for the humans to review before anything is created. Use when the user says kickoff, "the challenge is out", "plan the build", or asks to turn the brief into a backlog. Run it in the coordinator's workspace.
---

# Project kickoff

You're the coordinator. The humans have read the challenge and written
`kickoff/BRIEF.md`. Turn it into what the agents need to start: a demo target, a
one-page architecture, contracts, and a first wave of beads. **Target 30 minutes.**
The humans review your drafts. Nothing is created in BeadHub and nothing merges until
they approve.

## 0. Set up

```bash
bdh :status                       # you should be the coordinator
bdh dolt pull
bdh update __BEAD_KICKOFF__ --claim && bdh dolt push   # the kickoff bead
git fetch && git checkout -b <your-alias>/kickoff origin/main
```

Read `kickoff/BRIEF.md`, `PROGRESS.md`, `contracts/README.md`, and the team rules at
the top of `CLAUDE.md`. If the challenge, idea, stack, or team and lanes are missing or
`?`, **ask the user now** in one message listing every gap. Don't guess these four.
Smaller gaps you can fill with a sensible default; flag them in step 7.

## 1. DEMO.md (write this first)

Copy `.claude/skills/kickoff/templates/DEMO.md` to `DEMO.md` and fill it in
from the brief. The click path is the spec: 4–8 steps, each naming the lane that makes
it work. The demo moment must be on it. Write fallbacks for every external dependency.
Check the success criteria: each one should be visible somewhere on the click path, or
covered in the pitch.

## 2. ARCHITECTURE.md

Copy `.claude/skills/kickoff/templates/ARCHITECTURE.md` to `ARCHITECTURE.md`
and fill it in. Keep it to about one page. Most important is the **lanes and ownership
table**: every directory belongs to exactly one lane, so parallel agents never edit the
same files. Choose a directory layout that makes this true (for example `web/`, `api/`,
`ai/`), and match it to what the skeleton bead (`__BEAD_SKELETON__`) creates. Check that
bead's status and branch first, since someone else may be building it right now.

Record the decisions you made (stack details, layout, libraries) as one line each.

## 3. contracts/

Write the shared interfaces in the chosen stack, just enough for the click path:
- **The API schema**: an OpenAPI file, or typed request/response definitions (zod or
  TypeScript types, or pydantic models), for every call in the demo
- **Shared domain types**
- **Stubs**: a fake implementation of each API call returning fixed, realistic data, so
  the frontend can build against it before the backend exists

Keep it small. Contracts that try to cover everything get changed constantly, and every
change ripples through all the lanes.

## 4. Backlog

Write `kickoff/backlog.json` (schema below), then validate it:

```bash
python3 scripts/beads-from-json.py kickoff/backlog.json        # dry run: validates and prints the plan
```

Fix every error and re-run until it's clean. Rules for good beads:
- **Under an hour each.** Split by acceptance criterion if bigger.
- **The acceptance criterion names the test**, for example "`test_create_trip_returns_201`
  in `api/tests/test_trips.py` passes", not "trips work".
- **Only the first wave.** About 5–8 beads per lane, covering the first 3–4 hours,
  ordered along the demo click path. More beads get added as the team learns. Don't plan
  the whole project now.
- **Dependencies** wherever one bead needs another's output. A bead that only needs a
  contract doesn't depend on its implementation; it uses the stub.
- **`night_ok: true`** only if a test fully proves it is done and it's not UI look, copy
  or demo polish.
- **Priority 0** for anything on the demo path; 1 for supporting work; 2–3 for nice-to-haves.
- Include a **tester** bead per lane ("write tests for <x> against contracts") and one
  **demo-data seed** bead.
- Existing beads can be dependencies by id (for example `__BEAD_SKELETON__`).

```json
{
  "beads": [
    {
      "key": "api-create-trip",
      "title": "POST /trips creates a trip from the contract schema",
      "description": "Why it exists and what to build. Mention the contract file and directory.",
      "acceptance": "test_create_trip_returns_201 in api/tests/test_trips.py passes",
      "lane": "backend",
      "priority": 0,
      "type": "task",
      "night_ok": true,
      "deps": ["__BEAD_SKELETON__"]
    }
  ]
}
```

`key` is a short slug you choose. Other beads in the file refer to it in `deps`.

## 5. Small files

- `PROGRESS.md`: fill in "Current state" (theme, stack, lanes and owners, demo URL if known).
- `.env.example`: every env var the architecture needs, with empty values and a comment each.
- `README.md`: replace the template's README with three lines for now (what it is, how to
  run it, where the demo is). It gets polished before the demo.

## 6. Check your own work

- Every step of the DEMO.md click path is covered by at least one bead.
- Every directory in ARCHITECTURE.md has an owning lane, and no bead edits another lane's directory.
- Every lane has ready work at the start (a bead with no unfinished dependencies).
- The dry run is clean, and its per-lane counts look balanced against the people and agents in the brief.

## 7. Stop for review

Don't create beads or open the PR yet. Show the humans:
1. A five-line summary: the idea, the demo moment, the stack, the lanes.
2. The dry-run table from `beads-from-json.py`.
3. Every default you chose for a gap in the brief, and your open questions.
4. The files to read: `DEMO.md`, `ARCHITECTURE.md`, `contracts/`.

Make the changes they ask for, and re-run the dry run after each change to the backlog.

## 8. After they approve

```bash
python3 scripts/beads-from-json.py kickoff/backlog.json --apply   # creates the beads, pushes the beads database
git add DEMO.md ARCHITECTURE.md contracts PROGRESS.md .env.example README.md kickoff
git commit -m "Kickoff: demo, architecture, contracts, backlog"
git push -u origin HEAD
gh pr create --title "__BEAD_KICKOFF__: kickoff plan" --body "Demo, architecture, contracts and first-wave backlog."
```

A human merges the PR once CI is green. Then:
- `bdh close __BEAD_KICKOFF__ && bdh dolt push`
- Mail every agent in `bdh :aweb who` with: "Backlog is live. Read ARCHITECTURE.md and
  DEMO.md, then `bdh ready --label lane:<your lane>`."
- Assign the first bead of each lane with `bdh update <id> --assignee <alias>` if the brief names owners.
