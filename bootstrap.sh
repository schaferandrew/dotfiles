#!/usr/bin/env bash
set -euo pipefail

# Bootstrap for macOS and Debian/Ubuntu Linux dotfiles.
# Safe to re-run; will converge installed state.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BREWFILE="$ROOT_DIR/Brewfile"
LINUX_PACKAGES="$ROOT_DIR/packages.linux"

log()  { printf "\n==> %s\n" "$*"; }
warn() { printf "\n[WARN] %s\n" "$*"; }

# --- OS detection ---
detect_os() {
  if [[ "$(uname)" == "Darwin" ]]; then
    echo "macos"
  elif [[ -f /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    if [[ "${ID:-}" == "debian" || "${ID:-}" == "ubuntu" || "${ID_LIKE:-}" == *"debian"* ]]; then
      echo "debian"
    else
      echo "unknown"
    fi
  else
    echo "unknown"
  fi
}

OS="$(detect_os)"

if [[ "$OS" == "unknown" ]]; then
  warn "Unsupported OS. Only macOS and Debian/Ubuntu Linux are supported."
  exit 1
fi

# ============================================================
# macOS — Homebrew
# ============================================================

install_homebrew() {
  [[ "$OS" != "macos" ]] && return
  command -v brew >/dev/null 2>&1 && return
  log "Installing Homebrew"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  if [ -x "/opt/homebrew/bin/brew" ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ -x "/usr/local/bin/brew" ]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
}

install_brew_bundle() {
  [[ "$OS" != "macos" ]] && return
  log "Installing Brewfile packages"
  brew bundle --file "$BREWFILE"
}

install_cask_if_possible() {
  [[ "$OS" != "macos" ]] && return
  local cask="$1"
  brew list --cask "$cask" >/dev/null 2>&1 && return
  if brew info --cask "$cask" >/dev/null 2>&1; then
    log "Installing cask: $cask"
    brew install --cask "$cask" || warn "Failed to install cask: $cask"
  else
    warn "Cask not available: $cask"
  fi
}

install_formula_if_possible() {
  [[ "$OS" != "macos" ]] && return
  local formula="$1"
  brew list "$formula" >/dev/null 2>&1 && return
  if brew info "$formula" >/dev/null 2>&1; then
    log "Installing formula: $formula"
    brew install "$formula" || warn "Failed to install formula: $formula"
  else
    warn "Formula not available: $formula"
  fi
}

# ============================================================
# Linux — apt + curl-based tools
# ============================================================

install_apt_packages() {
  [[ "$OS" != "debian" ]] && return
  log "Updating apt and installing packages"
  sudo apt-get update -qq
  mapfile -t pkgs < <(grep -v '^#' "$LINUX_PACKAGES" | grep -v '^[[:space:]]*$')
  [[ ${#pkgs[@]} -gt 0 ]] && sudo apt-get install -y "${pkgs[@]}"
}

install_gh_linux() {
  [[ "$OS" != "debian" ]] && return
  command -v gh >/dev/null 2>&1 && return
  log "Installing GitHub CLI (gh)"
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
  sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
  sudo apt-get update -qq
  sudo apt-get install -y gh
}

install_starship_linux() {
  [[ "$OS" != "debian" ]] && return
  command -v starship >/dev/null 2>&1 && return
  log "Installing Starship prompt"
  curl -sS https://starship.rs/install.sh | sh -s -- --yes
}

install_uv_linux() {
  [[ "$OS" != "debian" ]] && return
  command -v uv >/dev/null 2>&1 && return
  log "Installing uv (Python package manager)"
  curl -LsSf https://astral.sh/uv/install.sh | sh
  export PATH="$HOME/.local/bin:$PATH"
}

install_ollama_linux() {
  [[ "$OS" != "debian" ]] && return
  command -v ollama >/dev/null 2>&1 && return
  log "Installing Ollama"
  curl -fsSL https://ollama.ai/install.sh | sh
}

install_pyenv_linux() {
  [[ "$OS" != "debian" ]] && return
  command -v pyenv >/dev/null 2>&1 && return
  log "Installing pyenv"
  curl -fsSL https://pyenv.run | bash
  export PYENV_ROOT="$HOME/.pyenv"
  export PATH="$PYENV_ROOT/bin:$PATH"
  eval "$(pyenv init -)"
}

# ============================================================
# Shared — Node / pnpm
# ============================================================

install_node() {
  log "Installing Node LTS via nvm"
  export NVM_DIR="$HOME/.nvm"
  mkdir -p "$NVM_DIR"

  if [[ "$OS" == "macos" ]]; then
    local nvm_brew_prefix
    nvm_brew_prefix="$(brew --prefix nvm 2>/dev/null)" || true
    if [ -n "$nvm_brew_prefix" ] && [ -s "$nvm_brew_prefix/nvm.sh" ]; then
      # shellcheck disable=SC1091
      source "$nvm_brew_prefix/nvm.sh"
    else
      warn "nvm not found via Homebrew; skipping Node install"
      return
    fi
  else
    if [ ! -s "$NVM_DIR/nvm.sh" ]; then
      log "Installing nvm"
      curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    fi
    # shellcheck disable=SC1091
    source "$NVM_DIR/nvm.sh"
  fi

  nvm install --lts
  nvm use --lts

  log "Installing pnpm"
  npm install -g pnpm
}

# ============================================================
# Shared — Python
# ============================================================

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

  pyenv versions --bare | grep -q "^${latest}$" || pyenv install "$latest"
  pyenv global "$latest"
  eval "$(pyenv init -)"

  log "Upgrading pip and installing pipx"
  python3 -m pip install --upgrade pip
  python3 -m pip install --upgrade pipx
  python3 -m pipx ensurepath

  log "Installing pipx tools"
  python3 -m pipx install --force pre-commit
  python3 -m pipx install --force ruff
}

# ============================================================
# Shared — Opencode CLI
# ============================================================

install_opencode_cli() {
  command -v opencode >/dev/null 2>&1 && return
  log "Installing Opencode CLI (best-effort)"
  if [[ "$OS" == "macos" ]]; then
    if brew info opencode >/dev/null 2>&1; then
      brew install opencode || true
    elif brew info opencode-cli >/dev/null 2>&1; then
      brew install opencode-cli || true
    else
      warn "Opencode CLI not available via Homebrew; install manually: npm install -g opencode-ai"
    fi
  else
    if command -v npm >/dev/null 2>&1; then
      npm install -g opencode-ai || warn "Failed to install opencode-ai via npm"
    else
      warn "npm not found; install manually after Node is set up: npm install -g opencode-ai"
    fi
  fi
}

# ============================================================
# Shared — Secrets, dotfiles, git identity, opencode config
# ============================================================

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

copy_if_missing() {
  local src="$1" dest="$2"
  mkdir -p "$(dirname "$dest")"
  if [ -f "$dest" ]; then
    warn "$dest already exists; skipping (remove to re-copy)"
  else
    cp "$src" "$dest"
  fi
}

install_dotfiles() {
  log "Copying dotfiles"
  copy_if_missing "$ROOT_DIR/dotfiles/zsh/.zshrc"             "$HOME/.zshrc"
  copy_if_missing "$ROOT_DIR/dotfiles/bash/.bashrc"           "$HOME/.bashrc"
  copy_if_missing "$ROOT_DIR/dotfiles/git/.gitconfig"         "$HOME/.gitconfig"
  copy_if_missing "$ROOT_DIR/dotfiles/starship/starship.toml" "$HOME/.config/starship.toml"
}

configure_git_user() {
  log "Configuring Git identity"
  local current_name current_email
  current_name=$(git config --global user.name 2>/dev/null || true)
  current_email=$(git config --global user.email 2>/dev/null || true)

  if [ -n "$current_name" ] && [ -n "$current_email" ]; then
    printf "  Current git user: %s <%s>\n" "$current_name" "$current_email"
    read -rp "  Keep current git identity? [Y/n] " keep
    case "$keep" in
      [nN]*) ;;
      *) return ;;
    esac
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

install_opencode_config() {
  log "Generating Opencode config"
  copy_if_missing "$ROOT_DIR/dotfiles/opencode/opencode.template.jsonc" "$HOME/.config/opencode/opencode.jsonc"
}

validate_env() {
  log "Validating environment"
  local missing=0
  for cmd in git gh curl wget jq rg fzf zoxide eza bat tmux vim fd starship; do
    command -v "$cmd" >/dev/null 2>&1 || { warn "Missing command: $cmd"; missing=1; }
  done
  if [ "$missing" -ne 0 ]; then
    [[ "$OS" == "macos" ]] \
      && warn "Some commands are missing. Re-run bootstrap after fixing Homebrew issues." \
      || warn "Some commands are missing. Re-run bootstrap after fixing install issues."
  fi
}

post_install_message() {
  local git_email
  git_email=$(git config --global user.email 2>/dev/null || echo "your_email@example.com")
  log "Post-install steps"
  if [[ "$OS" == "macos" ]]; then
    cat <<POST
1) Add SSH key (if needed):
   ssh-keygen -t ed25519 -C "$git_email"
   pbcopy < ~/.ssh/id_ed25519.pub
   Then add the key to GitHub.

2) Open ~/.secrets/env and add API keys.

3) Start Docker Desktop and Ollama (first-run prompts may appear).

4) For LM Studio: install manually if desired (not auto-installed).

5) Restart your terminal or run: source ~/.zshrc
POST
  else
    cat <<POST
1) Add SSH key (if needed):
   ssh-keygen -t ed25519 -C "$git_email"
   cat ~/.ssh/id_ed25519.pub
   Then add the key to GitHub.

2) Open ~/.secrets/env and add API keys.

3) Start Ollama if needed: ollama serve

4) Restart your terminal or run: source ~/.zshrc
POST
  fi
}

# ============================================================
# Main
# ============================================================

main() {
  log "Detected OS: $OS"

  # macOS — each function no-ops on other platforms
  install_homebrew
  install_brew_bundle
  install_cask_if_possible "visual-studio-code"
  install_cask_if_possible "cursor"
  install_cask_if_possible "docker"
  install_formula_if_possible "ollama"

  # Linux — each function no-ops on other platforms
  install_apt_packages
  install_gh_linux
  install_starship_linux
  install_uv_linux
  install_ollama_linux
  install_pyenv_linux

  # Shared
  install_node
  install_python
  install_opencode_cli
  ensure_secrets
  install_dotfiles
  configure_git_user
  install_opencode_config
  validate_env

  post_install_message
}

main "$@"
