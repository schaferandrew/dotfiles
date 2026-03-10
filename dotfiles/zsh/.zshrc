# ~/.zshrc
# Production-ready shell config for AI-assisted development.
# Safe to source multiple times.

# --- PATH setup ---
if [[ "$(uname)" == "Darwin" ]]; then
  if [ -x "/opt/homebrew/bin/brew" ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ -x "/usr/local/bin/brew" ]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
fi
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

# --- Colors ---
export TERM=xterm-256color
if [[ "$(uname)" == "Darwin" ]]; then
  export CLICOLOR=1
  export LSCOLORS=ExGxBxDxCxegedabagacad
else
  alias ls='ls --color=auto'
  if command -v dircolors >/dev/null 2>&1; then
    eval "$(dircolors -b)"
  fi
fi
alias grep='grep --color=auto'
alias diff='diff --color=auto'
# Colored man pages
export LESS_TERMCAP_mb=$'\e[1;31m'
export LESS_TERMCAP_md=$'\e[1;36m'
export LESS_TERMCAP_me=$'\e[0m'
export LESS_TERMCAP_se=$'\e[0m'
export LESS_TERMCAP_so=$'\e[01;33m'
export LESS_TERMCAP_ue=$'\e[0m'
export LESS_TERMCAP_us=$'\e[1;32m'

# --- Tool initialization ---

# nvm
export NVM_DIR="$HOME/.nvm"
if [ -s "$NVM_DIR/nvm.sh" ]; then
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
