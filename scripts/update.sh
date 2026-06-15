#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

command -v git >/dev/null || fail "git is required"
command -v uv >/dev/null || fail "uv is required"

[ -f pyproject.toml ] && grep -q '^name = "omnigent"$' pyproject.toml ||
  fail "$ROOT is not the Omnigent repo"

git remote get-url upstream >/dev/null 2>&1 ||
  git remote add upstream git@github.com:omnigent-ai/omnigent.git
git remote set-url --push upstream DISABLED >/dev/null 2>&1 || true

if [ "$(git branch --show-current)" = "main" ]; then
  git diff --quiet || fail "tracked working tree changes exist; commit or stash them first"
  git diff --cached --quiet || fail "staged changes exist; commit or stash them first"
  git fetch upstream main
  git merge --ff-only upstream/main
fi

uv tool install \
  --force \
  --reinstall \
  --refresh-package omnigent \
  --python "$(tr -d '[:space:]' < .python-version)" \
  --editable "$ROOT"

omnigent --version
omnigent --help >/dev/null

CLI_PATH="$(command -v omnigent)"
TOOL_PYTHON="$(sed -n '1s/^#!//p' "$CLI_PATH")"
[ -x "$TOOL_PYTHON" ] || fail "could not resolve tool Python from $CLI_PATH"

"$TOOL_PYTHON" - "$ROOT" "$(git rev-parse HEAD)" <<'PY'
import importlib
import pathlib
import sys

root = pathlib.Path(sys.argv[1]).resolve()
expected_sha = sys.argv[2]

for name in ("omnigent", "omnigent_client", "omnigent_ui_sdk"):
    module = importlib.import_module(name)
    path = pathlib.Path(module.__file__).resolve()
    print(f"{name}: {path}")
    if root != path and root not in path.parents:
        raise SystemExit(f"{name} imports from {path}, expected under {root}")

from omnigent import _build_info

print(f"build_sha: {_build_info.COMMIT_SHA}")
if _build_info.COMMIT_SHA != expected_sha:
    raise SystemExit(f"build sha mismatch: {_build_info.COMMIT_SHA} != {expected_sha}")
PY

echo "done"
