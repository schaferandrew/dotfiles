Create a new git branch following the project naming convention.

Branch format: `as-{ticket}-{descriptive-title}`

Steps:
1. Ask the user for the ticket number (GitHub issue # or Linear ticket ID) if not provided. If there's no ticket, ask for a short descriptive slug.
2. Ask for or confirm the descriptive title (kebab-case, concise).
3. Show the full branch name for confirmation before creating it.
4. Run: `git checkout -b as-{ticket}-{descriptive-title}`
5. Confirm success and remind the user to push with `-u origin` when ready.

Example branch names:
- `as-01-add-default-agent-files`
- `as-gh-42-fix-bootstrap-linux`
- `as-ENG-123-update-opencode-config`
