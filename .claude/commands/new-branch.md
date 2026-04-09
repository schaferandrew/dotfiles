Create a new git branch following the project naming convention.

**If a ticket or issue number was provided with the task**, use it:
```
as-{ticket}-{descriptive-title}
```

**If no ticket was provided**, derive a short descriptive slug from the task — do not ask the user for one:
```
as-{descriptive-title}
```

Keep the descriptive title short (2–4 words, kebab-case), based on the task at hand.

Steps:
1. Determine the branch name from the above rules (no prompting if ticket is absent).
2. Show the branch name and run: `git checkout -b {branch-name}`
3. Confirm success and remind the user to push with `-u origin` when ready.

Examples:
- `as-01-add-agent-files`
- `as-gh-42-fix-bootstrap-linux`
- `as-ENG-123-update-opencode-config`
- `as-add-agent-files` (no ticket)
