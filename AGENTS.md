# Omnigent Agent Notes

This checkout backs local `omnigent` and `omni` commands through an editable
`uv tool` install. Do not rerun the curl installer for local development.

Use the one repo-local procedure:

```bash
./scripts/update.sh
```

What it does:

- On `main`, fast-forwards from `upstream/main`, then reinstalls the editable
  tool.
- On any other branch, reinstalls the current checkout without syncing.
- Verifies the installed CLI imports `omnigent`, `omnigent_client`, and
  `omnigent_ui_sdk` from this checkout.

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

Do not use bare `omnigent` for this machine service; it follows the local daemon
path instead of targeting the shared server.
