# macOS Dotfiles + Bootstrap (AI Dev Workstation)

Production-quality dotfiles repo and bootstrap system for a senior software engineer building an AI-assisted development workstation.

## Quick Start
1. Clone this repo.
2. Run:
   ```bash
   ./bootstrap.sh
   ```
3. Enter API keys in `~/.secrets/env`.
4. Log into required apps (GitHub, Cursor, VS Code, Docker Desktop).

## What This Installs
- CLI tooling via Homebrew (`Brewfile`)
- Node LTS via `nvm`
- `pnpm` global
- Python latest stable 3.x via `pyenv`
- `pipx` and baseline tools (`pre-commit`, `ruff`)
- Docker Desktop (cask)
- Ollama (local models)
- VS Code and Cursor (casks)
- Opencode CLI (best-effort install)
- Zsh configuration, git config, starship prompt
- Opencode config generated at `~/.config/opencode/opencode.jsonc`

## Secrets Management
- Bootstrap creates `~/.secrets/env` with empty placeholders.
- Permissions are locked down:
  - `chmod 700 ~/.secrets`
  - `chmod 600 ~/.secrets/env`
- Never store real secrets in git.

Example:
```bash
OPENROUTER_API_KEY=
ANTHROPIC_API_KEY=
OPENAI_API_KEY=
GOOGLE_GEMINI_API_KEY=
OPENCODEZEN_API_KEY=
GITHUB_TOKEN=
```

## Opencode Configuration
Template lives at `dotfiles/opencode/opencode.template.jsonc` and is copied to:
- `~/.config/opencode/opencode.jsonc`

Supports:
- Local models via Ollama
- OpenRouter models via `OPENROUTER_API_KEY`
- Anthropic models via `ANTHROPIC_API_KEY`

Update the model list in the template if you want different defaults.

## SSH Keys (Manual)
Bootstrap does **not** generate SSH keys. If you need one:
```bash
ssh-keygen -t ed25519 -C "user_email_here"
pbcopy < ~/.ssh/id_ed25519.pub
```
Add the key to GitHub.

## Manual Fallbacks
- Cursor:
  - If Homebrew cask is unavailable, download from the official Cursor site.
- Docker Desktop:
  - If the cask fails, download from the official Docker Desktop site.
- LM Studio:
  - Not auto-installed. Add it manually if you want it.

## Repo Structure
```
Brewfile
bootstrap.sh
dotfiles/
  zsh/.zshrc
  git/.gitconfig
  starship/starship.toml
  opencode/opencode.template.jsonc
README.md
```

## Notes
- `bootstrap.sh` is safe to re-run. It will skip copying dotfiles that already exist on the machine so your local customizations are preserved. Remove a dotfile first if you want to re-copy the default from this repo.
- Do not commit secrets or private keys.
