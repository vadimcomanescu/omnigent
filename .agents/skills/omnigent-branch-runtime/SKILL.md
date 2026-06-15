---
name: omnigent-branch-runtime
description: Runs Omnigent from a feature branch against the stable local server without promoting the server. Use when testing Omnigent patches, branch behavior, host/runner/client changes, or when the user says to test a branch without restarting omnigent.service.
---

# Omnigent Branch Runtime

## Rule

Do not restart `omnigent.service` or run `./scripts/update.sh` for branch testing.
Those commands promote the always-on server to the current branch.

For branch testing, run the branch as a separate host/client/runner against the
stable server:

```bash
./scripts/branch-omnigent host
./scripts/branch-omnigent codex
./scripts/branch-omnigent claude --use-native-config
./scripts/branch-omnigent polly
```

## What The Helper Does

- Uses `.venv/bin/omnigent` when present, otherwise `uv run omnigent ...`, so
  code comes from the current checkout.
- Injects a deterministic branch host identity, so it does not replace the stable host.
- Uses an isolated `OMNIGENT_DATA_DIR`, so daemon records do not conflict.
- Uses the configured global server, or `OMNIGENT_BRANCH_SERVER` if set.
- Refuses `server`, because branch tests must not accidentally start/promote the server.

## Workflows

Test a patch from the branch:

```bash
git switch -c fix/something
git apply /path/to/patch.diff
uv sync --extra all --extra dev
./scripts/branch-omnigent host
```

Leave the host running, then choose that branch host in the web UI.

Start a branch CLI session:

```bash
./scripts/branch-omnigent codex
./scripts/branch-omnigent claude --use-native-config
```

Promote only after deciding the stable server should run this branch:

```bash
./scripts/update.sh
systemctl --user restart omnigent.service
```
