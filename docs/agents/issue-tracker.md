# Issue Tracker: GitHub

Issues and PRDs for this fork live in GitHub Issues. Use the `gh` CLI for issue
operations, and pass the repository explicitly when the target matters.

Default local tracker:

```bash
gh issue list -R vadimcomanescu/omnigent
gh issue view <number> -R vadimcomanescu/omnigent --comments
gh issue create -R vadimcomanescu/omnigent --title "..." --body "..."
gh issue comment <number> -R vadimcomanescu/omnigent --body "..."
gh issue edit <number> -R vadimcomanescu/omnigent --add-label "..."
```

If a task explicitly targets upstream Omnigent work, use:

```bash
gh issue list -R omnigent-ai/omnigent
```

Do not infer that an upstream sync requires issue tracker work. A sync-only task
is a git mirror update, not an issue workflow.
