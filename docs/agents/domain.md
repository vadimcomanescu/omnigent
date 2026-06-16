# Domain Docs

This is a single-context repo for agent-skill consumers.

Read before planning or editing:

1. `CONTEXT.md`
2. `AGENTS.md`
3. Relevant ADRs under `docs/adr/` if that directory exists
4. The task-specific source files

`CONTEXT.md` is mandatory operating context for this repo because it explains
the local branch model:

- `local/runtime-workflow` is the default local operating branch.
- `main` is only the fast-forward mirror of `upstream/main`.
- Sync-only work must merge the updated `main` into `local/runtime-workflow`
  and leave the checkout on `local/runtime-workflow`.

Do not treat a missing file on `main` as missing from the repo's local workflow.
If a local procedure, helper, or skill is expected but absent, check whether the
checkout is on `main`; if so, switch back to `local/runtime-workflow` before
continuing.

Use `CONTRIBUTING.md` gates for actual code changes and upstream PR work. Do not
run those gates merely to prove that `main` was fast-forwarded and merged into
`local/runtime-workflow`.
