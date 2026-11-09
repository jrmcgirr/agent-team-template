#!/usr/bin/env bash
# Copies scripts/team-rules.md into AGENTS.md and CLAUDE.md, right after each file's
# first heading block (or replacing the existing TEAM-RULES block). The two files are
# separate, not symlinked, so this keeps them in step.
set -euo pipefail
cd "$(dirname "$0")/.."
python3 - "$@" <<'PY'
import pathlib, re
rules = pathlib.Path("scripts/team-rules.md").read_text().strip() + "\n"
block = re.compile(r"<!-- TEAM-RULES:START.*?<!-- TEAM-RULES:END -->\n?", re.S)
for name in ("AGENTS.md", "CLAUDE.md"):
    p = pathlib.Path(name)
    text = p.read_text()
    if block.search(text):
        text = block.sub(lambda _: rules, text)
    else:
        # insert before the second "## " / "<!--" section, i.e. after the intro paragraph(s)
        m = re.search(r"^(## |<!-- BEGIN)", text, re.M)
        i = m.start() if m else len(text)
        text = text[:i] + rules + "\n" + text[i:]
    p.write_text(text)
    print("updated", name)
PY
