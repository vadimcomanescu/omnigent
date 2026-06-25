---
name: omnigent-upstream-pr
description: Workflow for contributing a fix to upstream Omnigent (omnigent-ai/omnigent) from this fork (vadimcomanescu/omnigent). Use when opening a PR against upstream Omnigent, deciding which branch to base an Omnigent change on, cherry-picking a fix out of local/runtime-workflow for upstream, or filling the Omnigent PR template. Pairs with omnigent-branch-runtime.
---

# Contributing to Upstream Omnigent

Authoritative source: this repo's `CONTRIBUTING.md`. It states two hard rules,
"Branch from `main`" and "Sign off your commits with `git commit -s`" (DCO),
and asks you to open an issue first for larger changes.

Use this workflow for bugs discovered while syncing, reinstalling, restarting,
or promoting the local runtime. Do not land those bug fixes directly on
`local/runtime-workflow`; that branch is the local operating branch, not the
delivery branch for upstream code.

## Branch model (do not violate)

- `upstream` = omnigent-ai/omnigent (fetch only; push DISABLED).
- `origin` = this fork (vadimcomanescu/omnigent).
- `local/runtime-workflow` is PRIVATE operating scaffolding. It carries personal
  commits ahead of upstream, so NEVER base an upstream PR on it; a PR cut from
  it drags in every personal commit and breaks "keep changes focused".
- `main` is only the fast-forward mirror of `upstream/main`, and the ONLY valid
  PR base. Keep it 0-ahead of `upstream/main` at all times. Never commit
  personal files to `main`.
- Personal tooling lives under `.agents/` (a path upstream does not track) on
  `local/runtime-workflow`, never on `main` and never on upstream-tracked files
  (e.g. root `AGENTS.md`, `examples/**`).

## Per-contribution workflow

1. Sync `main` and branch a focused topic branch off it, in a worktree so the
   primary checkout stays on `local/runtime-workflow`:
   ```bash
   git fetch upstream main
   git worktree add -b fix/<topic> ../omnigent.wt/<topic> upstream/main
   cd ../omnigent.wt/<topic>
   ```
   In-place alternative: `git switch main && git merge --ff-only upstream/main
   && git switch -c fix/<topic>`. If the fast-forward fails, stop and ask.
2. Make the change AND its required test. Per CONTRIBUTING: a behaviour change
   under `omnigent/` ships with a test; a BUG FIX adds a test that FAILS before
   the fix and passes after; new user-facing functionality MUST include an e2e
   happy-path test. Mirror the suite: `omnigent/<area>/` -> `tests/<area>/`.
   Keep the change minimal (YAGNI) and factor shared behaviour once (DRY).
3. Sign off every commit; keep them small and focused:
   ```bash
   git commit -s -m "fix(<area>): <what>"
   ```
4. Run the full gate before pushing, and name the commands you ran:
   ```bash
   uv run pytest
   uv run ruff check . && uv run ruff format --check .
   uv run pre-commit run --all-files
   ```
5. For a larger change open the issue first, then push and open the PR against
   upstream `main`:
   ```bash
   gh issue create --repo omnigent-ai/omnigent --title "<bug>" --body "<repro + file:line>"
   git push -u origin fix/<topic>
   gh pr create --repo omnigent-ai/omnigent --base main \
     --head vadimcomanescu:fix/<topic>
   ```
   Fill the WHOLE PR template (Related issue `Closes #NNN`, Summary, Type of
   change, Test coverage, Coverage rationale). Leave every checkbox and section
   in place: the `PR Template` CI check (`validate.py`) fails if required rows
   are removed. One issue per PR.
6. Keep the PR current by REBASING onto upstream, not merging:
   ```bash
   git fetch upstream main && git rebase upstream/main && git push --force-with-lease
   ```
7. Do not merge. Maintainers merge upstream PRs.

## Pulling a fix out of local/runtime-workflow

Do not PR the whole branch. Cherry-pick the single relevant commit onto a fresh
topic branch off `main`:
```bash
git fetch upstream main
git switch main && git merge --ff-only upstream/main
git switch -c fix/<topic>
git cherry-pick <sha>
```

## Gotchas

- The pre-push `gitleaks` hook scans mirrored upstream history and can block a
  fork push. Verify only your new commits with a narrow
  `gitleaks git --log-opts=...` scan; if clean, push with `--no-verify` and say
  so plainly.
- Never include secrets, internal URLs, tailnet/host paths, or private config
  in an upstream PR. Scan the diff before pushing.
- Worktree cleanup at closeout: `git worktree remove ../omnigent.wt/<topic>`.
