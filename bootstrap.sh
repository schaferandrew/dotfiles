#!/usr/bin/env bash
set -euo pipefail

# Production bootstrap for macOS dotfiles.
# Safe to re-run; will converge installed state.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BREWFILE="$ROOT_DIR/Brewfile"

log() { printf "\n==> %s\n" "$*"; }
warn() { printf "\n[WARN] %s\n" "$*"; }

# --- Homebrew ---
install_homebrew() {
  if command -v brew >/dev/null 2>&1; then
    return
  fi
  log "Installing Homebrew"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # Shell environment for current session
  if [ -x "/opt/homebrew/bin/brew" ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ -x "/usr/local/bin/brew" ]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
}

# --- Brew packages ---
install_brew_bundle() {
  log "Installing Brewfile packages"
  brew bundle --file "$BREWFILE"
}

install_cask_if_possible() {
  local cask="$1"
  if brew list --cask "$cask" >/dev/null 2>&1; then
    return
  fi
  if brew info --cask "$cask" >/dev/null 2>&1; then
    log "Installing cask: $cask"
    if ! brew install --cask "$cask"; then
      warn "Failed to install cask: $cask"
    fi
  else
    warn "Cask not available: $cask"
  fi
}

install_formula_if_possible() {
  local formula="$1"
  if brew list "$formula" >/dev/null 2>&1; then
    return
  fi
  if brew info "$formula" >/dev/null 2>&1; then
    log "Installing formula: $formula"
    if ! brew install "$formula"; then
      warn "Failed to install formula: $formula"
    fi
  else
    warn "Formula not available: $formula"
  fi
}

# --- Node / pnpm ---
install_node() {
  log "Installing Node LTS via nvm"
  export NVM_DIR="$HOME/.nvm"
  mkdir -p "$NVM_DIR"

  # Source nvm from Homebrew
  if [ -s "$(brew --prefix nvm 2>/dev/null)/nvm.sh" ]; then
    # shellcheck disable=SC1091
    source "$(brew --prefix nvm)/nvm.sh"
  else
    warn "nvm not found; skipping Node install"
    return
  fi

  nvm install --lts
  nvm use --lts

  log "Installing pnpm"
  npm install -g pnpm
}

# --- Python ---
install_python() {
  log "Installing latest stable Python 3 via pyenv"
  if ! command -v pyenv >/dev/null 2>&1; then
    warn "pyenv not found; skipping Python install"
    return
  fi

  local latest
  latest=$(pyenv install -l | sed 's/^ *//' | grep -E '^3\.[0-9]+\.[0-9]+$' | tail -1)

  if [ -z "$latest" ]; then
    warn "Could not determine latest Python 3 version"
    return
  fi

  if ! pyenv versions --bare | grep -q "^${latest}$"; then
    pyenv install "$latest"
  fi
  pyenv global "$latest"

  log "Upgrading pip and installing pipx"
  python3 -m pip install --upgrade pip
  python3 -m pip install --upgrade pipx
  python3 -m pipx ensurepath

  # Install baseline pipx tools (idempotent)
  log "Installing pipx tools"
  python3 -m pipx install --force pre-commit
  python3 -m pipx install --force ruff
}

# --- Opencode CLI ---
install_opencode_cli() {
  if command -v opencode >/dev/null 2>&1; then
    return
  fi

  log "Installing Opencode CLI (best-effort)"
  if brew info opencode >/dev/null 2>&1; then
    brew install opencode || true
  elif brew info opencode-cli >/dev/null 2>&1; then
    brew install opencode-cli || true
  else
    warn "Opencode CLI not available via Homebrew"
    warn "Install manually from the official Opencode docs"
  fi
}

# --- Secrets ---
ensure_secrets() {
  log "Creating secrets template"
  mkdir -p "$HOME/.secrets"
  chmod 700 "$HOME/.secrets"

  local secrets_file="$HOME/.secrets/env"
  if [ ! -f "$secrets_file" ]; then
    cat <<'SECRETS' > "$secrets_file"
OPENROUTER_API_KEY=
ANTHROPIC_API_KEY=
OPENAI_API_KEY=
GOOGLE_GEMINI_API_KEY=
OPENCODEZEN_API_KEY=
GITHUB_TOKEN=
SECRETS
  fi
  chmod 600 "$secrets_file"
}

install_dotfiles() {
  log "Copying dotfiles"
  cp "$ROOT_DIR/dotfiles/zsh/.zshrc" "$HOME/.zshrc"
  # Copy .gitconfig (not symlink) so bootstrap can write user identity without modifying the repo
  cp "$ROOT_DIR/dotfiles/git/.gitconfig" "$HOME/.gitconfig"
  mkdir -p "$HOME/.config"
  cp "$ROOT_DIR/dotfiles/starship/starship.toml" "$HOME/.config/starship.toml"
}

# --- Git identity ---
configure_git_user() {
  log "Configuring Git identity"

  local current_name current_email
  current_name=$(git config --global user.name 2>/dev/null || true)
  current_email=$(git config --global user.email 2>/dev/null || true)

  if [ -n "$current_name" ] && [ -n "$current_email" ]; then
    printf "  Current git user: %s <%s>\n" "$current_name" "$current_email"
    read -rp "  Keep current git identity? [Y/n] " keep
    if [[ "${keep,,}" =~ ^(y|yes|)$ ]]; then
      return
    fi
  fi

  read -rp "  Enter your full name for git commits: " git_name
  read -rp "  Enter your email for git commits: " git_email

  if [ -z "$git_name" ] || [ -z "$git_email" ]; then
    warn "Name or email was empty; skipping git identity configuration"
    return
  fi

  git config --global user.name "$git_name"
  git config --global user.email "$git_email"
  printf "  Git identity set to: %s <%s>\n" "$git_name" "$git_email"
}

# --- Opencode config ---
install_opencode_config() {
  log "Generating Opencode config"
  mkdir -p "$HOME/.config/opencode"
  cp "$ROOT_DIR/dotfiles/opencode/opencode.template.jsonc" "$HOME/.config/opencode/opencode.jsonc"
}

# --- Validation ---
validate_env() {
  log "Validating environment"
  local missing=0

  for cmd in git gh curl wget jq rg fzf zoxide eza bat tmux vim fd starship; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      warn "Missing command: $cmd"
      missing=1
    fi
  done

  if [ "$missing" -ne 0 ]; then
    warn "Some commands are missing. Re-run bootstrap after fixing Homebrew issues."
  fi
}

# --- Main ---
main() {
  install_homebrew
  install_brew_bundle

  # GUI / AI tools
  install_cask_if_possible "visual-studio-code"
  install_cask_if_possible "cursor"
  install_cask_if_possible "docker"
  install_formula_if_possible "ollama"

  install_node
  install_python
  install_opencode_cli

  ensure_secrets
  install_dotfiles
  configure_git_user
  install_opencode_config
  validate_env

  log "Post-install steps"
  cat <<'POST'
1) Add SSH key (if needed):
   ssh-keygen -t ed25519 -C "user_email_here"
   pbcopy < ~/.ssh/id_ed25519.pub
   Then add the key to GitHub.

2) Open ~/.secrets/env and add API keys.

3) Start Docker Desktop and Ollama (first-run prompts may appear).

4) For LM Studio: install manually if desired (not auto-installed).

5) Restart your terminal or run: source ~/.zshrc
POST
}

main "$@"
