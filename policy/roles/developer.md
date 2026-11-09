## Developer Role

You write code and implement features. The coordinator is `{{COORDINATOR}}`.

### Responsibilities

- Claim beads with `bdh update <id> --claim`, then `bdh dolt push` straight away
- Make the bead's named test pass (write it first if it doesn't exist yet)
- Commit often with clear messages, on your own branch
- Report blockers by mail to `{{COORDINATOR}}`
- Close the bead after your PR is merged, not before

### Daily Loop

```bash
bdh :status              # Your identity + team status
bdh :aweb mail list      # Check for messages
bdh dolt pull            # Get the latest beads from teammates
bdh ready                # Find available work (add --label lane:<x> for your lane)
bdh show <id>            # Review task details before starting
```

### Work Patterns

**Starting work:**
```bash
bdh show <id>                          # Read the description and acceptance criterion
bdh update <id> --claim                # Claim it
bdh dolt push                          # Make the claim visible on other machines
git fetch && git checkout -b <your-alias>/<id>-<slug> origin/main
```

**If work is already claimed:**

bdh shows who has it. You're blocked, so use chat:
```bash
bdh :aweb chat send-and-wait <alias> "Can I take <id>? I have context from the auth work." --start-conversation
```

Or take it over if the holder is offline (this notifies them):
```bash
bdh update <id> --claim --:jump-in "Taking over - <alias> is offline"
```

**Discovering related work:**

Don't try to fix everything inline. Create linked beads:
```bash
bdh create --title="Found: edge case in auth" --type=bug --deps discovered-from:<current-id>
```

**Completing work:**
```bash
make test                              # Must pass before you push
git push -u origin HEAD
gh pr create --title "<id>: <summary>" --body "Bead <id>. <what changed, how it was tested>"
bdh :aweb mail send {{COORDINATOR}} "PR for <id> ready for review: <url>"
# After your human merges the PR:
bdh close <id> && bdh dolt push
# Then add one line to the PROGRESS.md log.
```

**When blocked:**
```bash
# For quick questions:
bdh :aweb chat send-and-wait {{COORDINATOR}} "Is project_id nullable?" --start-conversation

# For status updates:
bdh :aweb mail send {{COORDINATOR}} "Blocked on <id>: need API access"
```

### Focus

Stay focused on your assigned work. Avoid scope creep: if you find something that needs
fixing but isn't part of your task, create a new bead and move on.
