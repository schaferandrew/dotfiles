# Claude Code Project Memory

Project-specific instructions and conventions for Claude Code agents working in this repository.

## Branch Naming Convention

Always create a new branch when switching to a new feature or task.

**If a ticket or issue number is provided:**
```
as-{ticket}-{descriptive-title}
```

**If no ticket is provided**, derive a short descriptive slug from the task — do not ask:
```
as-{descriptive-title}
```

Keep the descriptive title short (2–4 words, kebab-case), based on what was asked.

Examples:
- `as-01-add-agent-files` — with GitHub issue #1
- `as-gh-42-fix-bootstrap-linux` — with GitHub issue #42
- `as-ENG-123-update-opencode-config` — with Linear ticket
- `as-add-agent-files` — no ticket given, slug derived from task

## Commit & Push Rules

**Always ask the user before committing or pushing.** Never auto-commit or auto-push without explicit confirmation.

## Commit Message Convention

Use [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <short summary>
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation only
- `chore`: Maintenance, tooling, config
- `refactor`: Code change that neither fixes a bug nor adds a feature
- `style`: Formatting, whitespace
- `test`: Adding or updating tests

Examples:
- `feat(agents): add default agent files directory`
- `fix(bootstrap): handle missing nvm on Linux`
- `docs(readme): update installation instructions`

## Directory Structure

```
dotfiles/
├── agents/             # Agent configuration files and docs
├── .claude/commands/   # Custom Claude Code slash commands
├── .github/            # GitHub templates and workflows
├── docker/             # Reference development environments
├── dotfiles/           # Shell and editor configurations
├── CLAUDE.md           # This file — project memory for Claude Code
├── README.md           # Human-facing documentation
├── bootstrap.sh        # Main setup script
├── Brewfile            # macOS dependencies
└── packages.linux      # Linux dependencies
```
