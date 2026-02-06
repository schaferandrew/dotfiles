# ~/.zshrc
# Production-ready shell config for AI-assisted development.
# Safe to source multiple times.

# --- PATH setup ---
# Homebrew (Apple Silicon + Intel)
if [ -x "/opt/homebrew/bin/brew" ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x "/usr/local/bin/brew" ]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

# User-local binaries
export PATH="$HOME/.local/bin:$PATH"

# pnpm
export PNPM_HOME="$HOME/Library/pnpm"
export PATH="$PNPM_HOME:$PATH"

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
if [ -s "$(brew --prefix nvm 2>/dev/null)/nvm.sh" ]; then
  # shellcheck disable=SC1091
  source "$(brew --prefix nvm)/nvm.sh"
fi

# pyenv
if command -v pyenv >/dev/null 2>&1; then
  eval "$(pyenv init -)"
fi

# starship
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

# fzf
if [ -s "$(brew --prefix fzf 2>/dev/null)/shell/completion.zsh" ]; then
  # shellcheck disable=SC1091
  source "$(brew --prefix fzf)/shell/completion.zsh"
fi
if [ -s "$(brew --prefix fzf 2>/dev/null)/shell/key-bindings.zsh" ]; then
  # shellcheck disable=SC1091
  source "$(brew --prefix fzf)/shell/key-bindings.zsh"
fi

# zoxide
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

# --- Aliases ---
# Agent optimization: prefer rg and fd
alias grep="rg"
