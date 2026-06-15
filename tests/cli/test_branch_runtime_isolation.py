from __future__ import annotations

import importlib


def test_host_pid_path_honors_omnigent_data_dir(
    monkeypatch,
    tmp_path,
) -> None:
    """Branch/worktree runtimes must not reuse the stable daemon registry."""

    monkeypatch.setenv("OMNIGENT_DATA_DIR", str(tmp_path / "branch-data"))

    import omnigent.cli as cli

    reloaded = importlib.reload(cli)

    assert reloaded._HOST_PID_PATH == tmp_path / "branch-data" / "host.pid"


def test_load_existing_host_id_honors_env_identity(monkeypatch) -> None:
    """Daemon records and readiness checks must match the env-selected host."""

    monkeypatch.setenv("OMNIGENT_HOST_ID", "host_branch")
    monkeypatch.setenv("OMNIGENT_HOST_NAME", "branch-host")

    import omnigent.cli as cli

    assert cli._load_existing_host_id() == "host_branch"
