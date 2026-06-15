# Omnigent Agent Notes

This repo has two different workflows. Keep them separate.

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

## Branch Runtime Testing

Do not restart `omnigent.service` just to test a branch. That promotes the
always-on server to the branch.

When applying a patch or starting new Omnigent work, start from an updated
upstream mirror unless the user explicitly says to continue the current branch:

```bash
git fetch upstream main
git switch main
git merge --ff-only upstream/main
git switch -c fix/descriptive-name
```

Then apply the patch or make the edit on that feature branch.

For branch testing, run the current checkout as a separate host/client/runner
against the configured stable server:

```bash
./scripts/branch-omnigent host
./scripts/branch-omnigent codex
./scripts/branch-omnigent claude --use-native-config
./scripts/branch-omnigent polly
```

The helper uses the repo `.venv` when present, otherwise `uv run`; it injects a
branch-specific host identity, isolates daemon state, and refuses `server` so it
cannot accidentally start a replacement server. The matching agent skill is in
`.agents/skills/omnigent-branch-runtime/SKILL.md`.

Use `./scripts/update.sh` plus `systemctl --user restart omnigent.service` only
when the user explicitly asks to promote the always-on server to the current
branch.

If a server is already running, restart it after reinstalling:

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
