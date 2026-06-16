# Omnigent Context

## Operating Model

This checkout has a local operating branch:

- `local/runtime-workflow` is the default branch for local agents, local runtime
  instructions, helper scripts, and machine-specific workflow documentation.
- `main` is only the fast-forward mirror of `upstream/main`.
- `main` is not the normal working branch on this machine.

Before doing work in this repo, confirm the current branch. If the checkout is
on `main` and the task is not explicitly a mirror sync, switch to
`local/runtime-workflow` before reading procedures or making decisions.

## Sync-Only Requests

When the user asks to pull, merge, or sync upstream, the task is to update the
mirror branch, merge it into the local operating branch, and stay on the local
operating branch:

```bash
git fetch upstream main
git switch main
git merge --ff-only upstream/main
git switch local/runtime-workflow
git merge --no-edit main
```

Stop there unless the user explicitly asks to promote the runtime or validate a
code change. Do not run dependency syncs or language gates for a mirror sync.

This merge is required. Without it, `local/runtime-workflow` can keep an older
`uv.lock`, and a later `uv sync` on the correct operating branch will downgrade
the `.venv` to that older lockfile.

## Development Requests

For upstream PR work or code patches:

1. Start from the current upstream mirror.
2. Create a feature branch from `main`.
3. Apply the change.
4. Run the relevant contributor gates from `CONTRIBUTING.md`.

For branch runtime testing, use the bundled helper under
`.agents/skills/omnigent-branch-runtime/`. It runs the branch against the stable
server without promoting the always-on service.

## Runtime Promotion

Do not restart `omnigent.service` or run `./scripts/update.sh` as a side effect
of inspecting or testing a branch. Those actions promote the global CLI/server
runtime to the current checkout. Use them only when the user explicitly asks to
promote the runtime.

## Local Infrastructure Boundary

Private machine details, including URLs, IPs, DNS, Caddy routes, systemd units,
sudoers rules, and host runner scripts, do not belong in this repo. Keep them in
`~/.agents/docs/`, `~/.agents/scripts/`, or the actual system location.
