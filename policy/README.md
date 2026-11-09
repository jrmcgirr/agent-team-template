# BeadHub policy source

The BeadHub project policy (role playbooks and team-wide invariants) lives on the
server and is shown to agents by `bdh :policy`. These files are its source of truth.
Edit them here, then apply:

```bash
scripts/apply-policy.sh            # push every role and invariant to BeadHub
scripts/apply-policy.sh --dry-run  # show what it would do
```

- `team.env` sets values substituted into the files, such as `{{COORDINATOR}}` (the
  coordinator's alias). If the coordinator changes, edit it there and re-apply.
- `roles/<name>.md` is one role playbook. The file name is the role name.
- `invariants/<id>.md` is one invariant. The first line is `# <Title>`, the rest is the guidance.

Roles: coordinator, developer, backend, frontend, reviewer, tester, sentry.
