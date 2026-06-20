---
name: omnigent-branch-runtime
description: Syncs this Omnigent fork with upstream while preserving the local/runtime-workflow operating branch, and runs Omnigent from feature branches against the stable local server without promoting the server. Use when the user says to sync, pull, fetch, merge, or update from upstream; when testing Omnigent patches, branch behavior, host/runner/client changes; or when the user says to test a branch without restarting omnigent.service.
---

# Omnigent Branch Runtime

## Rule

Do not restart `omnigent.service` or run `./scripts/update.sh` for branch testing.
Those commands promote the always-on server to the current branch.

This repo's local operating branch is `local/runtime-workflow`. `main` is only
the fast-forward mirror of `upstream/main`. For sync-only tasks, fast-forward
`main`, merge it into `local/runtime-workflow`, push both branches to `origin`,
and leave the checkout on `local/runtime-workflow`. Do not leave the checkout
on `main`.

When applying a patch or starting new Omnigent work, the base branch is
`upstream/main`. Do not branch from the current feature branch unless the user
explicitly says to continue it. First switch local `main` to `upstream/main` by
fast-forward only:

```bash
git fetch upstream main
git switch main
git merge --ff-only upstream/main
git switch -c fix/descriptive-name
```

If the fast-forward fails, stop and ask. Apply the patch or edit after creating
that feature branch.

For a sync-only task, do not create a feature branch and do not run contributor
gates. Use this exact sequence, including the fork push:

```bash
git fetch upstream main
git switch main
git merge --ff-only upstream/main
git switch local/runtime-workflow
git merge --no-edit main
git push origin main local/runtime-workflow
git status --short --branch
```

For branch testing, run the branch as a separate host/client/runner against the
stable server with this skill's bundled helper:

```bash
.agents/skills/omnigent-branch-runtime/scripts/branch-omnigent host
.agents/skills/omnigent-branch-runtime/scripts/branch-omnigent codex
.agents/skills/omnigent-branch-runtime/scripts/branch-omnigent claude --use-native-config
.agents/skills/omnigent-branch-runtime/scripts/branch-omnigent polly
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
git fetch upstream main
git switch main
git merge --ff-only upstream/main
git switch -c fix/something
git apply /path/to/patch.diff
uv sync --extra all --extra dev
.agents/skills/omnigent-branch-runtime/scripts/branch-omnigent host
```

Leave the host running, then choose that branch host in the web UI.

Sync the upstream mirror without starting work:

```bash
git fetch upstream main
git switch main
git merge --ff-only upstream/main
git switch local/runtime-workflow
git merge --no-edit main
git push origin main local/runtime-workflow
git status --short --branch
```

Report the mirror commit, merge commit, fork push result, and clean status.
Stop there.

If the fork push is blocked because the local pre-push `gitleaks` hook scans
mirrored upstream history, verify any new local commits with a narrow
`gitleaks git --log-opts=...` scan. If those local commits are clean, complete
the fork sync with `git push --no-verify origin main local/runtime-workflow`
and report the bypass plainly.

Close every sync-only task by asking exactly one follow-up question:

```text
Do you want me to promote the always-on Omnigent server to this branch now?
```

Do not run `./scripts/update.sh` or restart `omnigent.service` unless the user
explicitly answers yes.

Start a branch CLI session:

```bash
.agents/skills/omnigent-branch-runtime/scripts/branch-omnigent codex
.agents/skills/omnigent-branch-runtime/scripts/branch-omnigent claude --use-native-config
```

Promote only after deciding the stable server should run this branch. On this
machine, use the local promotion wrapper so the public host daemon is reset
after the server restart and stale offline branch-test hosts are removed from
the picker:

```bash
~/.agents/scripts/omnigent-promote-current
```

Manual fallback:

```bash
./scripts/update.sh
systemctl --user restart omnigent.service
systemctl --user restart omnigent-public-host.service
systemctl --user is-active omnigent.service omnigent-public-host.service omnigent-public-host-watchdog.timer
```

For branch-test closeout, ask whether to promote/restart before running those
commands. Never infer promotion from a successful sync or branch test. Never
start or restart the public host through a detached `omnigent host` launcher.
The public host is part of the service graph. The local watchdog timer is part
of that graph too: it treats `/v1/hosts` as the truth and restarts
`omnigent-public-host.service` if the process is still alive but the primary
host disappears from the picker. Promotion is incomplete unless
`omnigent-public-host.service` and `omnigent-public-host-watchdog.timer` are
active and `/v1/hosts` shows the primary host online with no stale offline
branch hosts.

## Live Verification Cleanup

Any throwaway harness, agent, host, runner, session, worktree, shim, or process
created for verification must be cleaned up before closeout. This is part of the
verification task.

For public server checks, verify no throwaway sessions or local harness
processes remain:

```bash
curl -sS http://omnigent-om.nadicode.ai/v1/sessions
ps -eo pid,ppid,stat,lstart,cmd | rg -i ' pi( |$)|/pi( |$)|throwaway|verification'
```

Archive or delete throwaway sessions through the server API, stop throwaway
processes, and report any intentionally retained process or session by id. Do
not leave one-off `pi`, Codex, Claude, or probe sessions in the public picker
after branch or live-server verification.
