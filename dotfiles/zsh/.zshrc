# ~/.zshrc
# Production-ready shell config for AI-assisted development.
# Safe to source multiple times.

# --- PATH setup ---
if [[ "$(uname)" == "Darwin" ]]; then
  # Homebrew (Apple Silicon + Intel)
  if [ -x "/opt/homebrew/bin/brew" ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ -x "/usr/local/bin/brew" ]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
fi

# User-local binaries
export PATH="$HOME/.local/bin:$PATH"


# --- Secrets loading ---
# Never commit secrets. This only loads if the file exists.
if [ -f "$HOME/.secrets/env" ]; then
  set -a
  # shellcheck disable=SC1090
  source "$HOME/.secrets/env"
  set +a
fi

# --- Editor defaults ---
export EDITOR=vim
export VISUAL=vim

# --- Tool initialization ---

# nvm
export NVM_DIR="$HOME/.nvm"
if [[ "$(uname)" == "Darwin" ]]; then
  # Cache brew prefix once to avoid repeated slow calls (~200ms each)
  _brew_prefix="$(brew --prefix 2>/dev/null)"
  if [ -n "$_brew_prefix" ] && [ -s "$_brew_prefix/opt/nvm/nvm.sh" ]; then
    # shellcheck disable=SC1091
    source "$_brew_prefix/opt/nvm/nvm.sh"
  fi
  unset _brew_prefix
elif [ -s "$NVM_DIR/nvm.sh" ]; then
  # shellcheck disable=SC1091
  source "$NVM_DIR/nvm.sh"
fi

# rbenv
if command -v rbenv >/dev/null 2>&1; then
  eval "$(rbenv init - zsh)"
fi

# starship
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

# --- Aliases ---
alias search="rg"
