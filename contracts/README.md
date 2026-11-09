# Contracts

Shared types, API schemas and stubbed interfaces that the lanes build against. Write
them in hours 0–2, before agents start building features.

Rules:

- Only the coordinator (or its human) changes files here. To ask for a change,
  mail the coordinator: `bdh :aweb mail send <coordinator-alias> "..." --subject "contract change"`.
- Code implements and imports these; it doesn't redefine them in other places.
- Contracts are frozen overnight.

Suggested contents once the stack is chosen: `api.openapi.yaml` (or a typed client
schema), `types.ts` / `types.py` for shared models, and stub implementations that
return fixed data so frontend and backend can work in parallel.
