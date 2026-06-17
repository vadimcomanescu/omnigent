# Omnigent Agent Notes

This repo has two different workflows. Keep them separate.

This fork's default operating branch is `local/runtime-workflow`. Use that as
the starting checkout for local agents and runtime instructions. Do not use it
as the base for upstream PR code; upstream PR branches start from
`upstream/main` as described below.

Start every local task by confirming the checkout:

```bash
git branch --show-current
```

If the current branch is `main` and the task is not explicitly "sync the
upstream mirror", switch back before doing anything else:

```bash
git switch local/runtime-workflow
```

Do not leave this repo on `main` after a sync-only task. `main` exists to mirror
`upstream/main`; it does not contain this fork's local operating procedures.
After fast-forwarding `main`, return to `local/runtime-workflow` and merge
`main` into it so the local operating branch keeps the current upstream code and
lockfile.

For normal Omnigent development and upstream PR work, follow
`CONTRIBUTING.md`: use the repo virtualenv, `uv sync --extra all --extra dev`,
`uv run ...`, and the documented test/lint gates.

For this machine's installed `omnigent` and `omni` commands, this checkout is
installed as an editable `uv tool`. That is a local runtime adapter for testing
the current branch through the globally available CLI; it is not a replacement
for the contributor dev environment or upstream test gates. Do not rerun the
curl installer for local development.

Use the one repo-local procedure:

```bash
./scripts/update.sh
```

What `./scripts/update.sh` does:

- On `main`, fast-forwards from `upstream/main`, then reinstalls the editable
  tool.
- On any other branch, reinstalls the current checkout without syncing.
- Verifies the installed CLI imports `omnigent`, `omnigent_client`, and
  `omnigent_ui_sdk` from this checkout.

Branch rule: keep `main` as the upstream mirror, do fixes on feature branches,
run `./scripts/update.sh` from the branch you want the global CLI/server to use,
then rebase or fast-forward against `upstream/main` before proposing changes.

For a sync-only request, do exactly this, including the fork push:

```bash
git fetch upstream main
git switch main
git merge --ff-only upstream/main
git switch local/runtime-workflow
git merge --no-edit main
git push origin main local/runtime-workflow
git status --short --branch
```

Do not run `uv sync`, `pytest`, `npm test`, `npm run lint`, or frontend builds
for a sync-only request. Those are contributor validation gates for code
changes, not proof that the mirror, fork, and local workflow branch were
updated.

If the fork push is blocked because the local pre-push `gitleaks` hook scans
mirrored upstream history, verify any new local commits with a narrow
`gitleaks git --log-opts=...` scan. If those local commits are clean, complete
the fork sync with `git push --no-verify origin main local/runtime-workflow`
and report the bypass plainly.

## Agent skills

### Issue tracker

Issues are tracked in GitHub for this fork unless a task explicitly targets
upstream. See `docs/agents/issue-tracker.md`.

### Triage labels

Use the default five-label triage vocabulary. See
`docs/agents/triage-labels.md`.

### Domain docs

This is a single-context repo. Read `CONTEXT.md` first, especially the branch
operating model. See `docs/agents/domain.md`.

## Branch Runtime Testing

Do not restart `omnigent.service` just to test a branch. That promotes the
always-on server to the branch.

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

If the fast-forward fails, stop and ask. Then apply the patch or make the edit
on the new feature branch.

For branch testing, run the current checkout as a separate host/client/runner
against the configured stable server with the skill's bundled helper:

```bash
.agents/skills/omnigent-branch-runtime/scripts/branch-omnigent host
.agents/skills/omnigent-branch-runtime/scripts/branch-omnigent codex
.agents/skills/omnigent-branch-runtime/scripts/branch-omnigent claude --use-native-config
.agents/skills/omnigent-branch-runtime/scripts/branch-omnigent polly
```

The helper uses the repo `.venv` when present, otherwise `uv run`; it injects a
branch-specific host identity, isolates daemon state, and refuses `server` so it
cannot accidentally start a replacement server. The matching agent skill is in
`.agents/skills/omnigent-branch-runtime/SKILL.md`; its scripts live under
`.agents/skills/omnigent-branch-runtime/scripts/`.

Live verification cleanup is part of the task. If a temporary harness, agent,
host, runner, session, worktree, shim, or process is created only to verify a
fix, remove it before reporting done. For public server checks, verify both
surfaces are clean:

```bash
curl -sS http://omnigent-om.nadicode.ai/v1/sessions
ps -eo pid,ppid,stat,lstart,cmd | rg -i ' pi( |$)|/pi( |$)|throwaway|verification'
```

Archive or delete throwaway sessions through the server API, stop throwaway
processes, and report any intentionally retained session or process by id. Do
not leave one-off `pi`, Codex, Claude, or probe sessions in the public picker
as a side effect of testing.

Use `./scripts/update.sh` plus the service restart only when the user explicitly
asks to promote the always-on server to the current branch. On this machine,
prefer the local wrapper:

```bash
~/.agents/scripts/omnigent-promote-current
```

It reinstalls the editable tool, restarts `omnigent.service`, resets the public
host daemon, prunes stale offline branch-test hosts from the local picker, and
verifies `/v1/hosts`. Do not restart the server without also resetting the
public host daemon through the local-service procedure. Promotion is not done if
the host picker shows stale offline branch hosts.

If you must do it manually, restart the server after reinstalling, then follow
`~/.agents/docs/local-services.md` to reset and verify the public host daemon:

```bash
systemctl --user restart omnigent.service
```

## Local Runtime Reference

This machine runs Omnigent from this checkout as a user systemd service.

Host-specific URLs, IPs, DNS, Caddy routes, and systemd unit details belong in
`~/.agents/docs/local-services.md`, not this repo. Do not commit private
machine routing values here.

Start a console session against the configured shared server with an explicit
entry point:

```bash
omnigent polly
omnigent codex
omnigent claude --use-native-config
```

For automation and smoke tests, do not rely on bare `omnigent`; depending on the
current defaults, it may enter first-run/default-agent selection or the local
daemon path. Use an explicit entry point instead.
