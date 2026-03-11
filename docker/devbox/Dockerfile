FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Base system packages
RUN apt-get update && apt-get install -y \
    bash \
    bash-completion \
    git \
    curl \
    wget \
    vim \
    tmux \
    tree \
    jq \
    ripgrep \
    ffmpeg \
    sudo \
    unzip \
    build-essential \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# GitHub CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg && \
    chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    | tee /etc/apt/sources.list.d/github-cli.list > /dev/null && \
    apt-get update && apt-get install -y gh && \
    rm -rf /var/lib/apt/lists/*

# Non-root user
ARG USERNAME=dev
RUN useradd -m -s /bin/bash -G sudo $USERNAME && \
    echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER $USERNAME
WORKDIR /home/$USERNAME

# nvm + Node LTS
ENV NVM_DIR=/home/$USERNAME/.nvm
RUN curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash && \
    . "$NVM_DIR/nvm.sh" && \
    nvm install --lts && \
    nvm use --lts && \
    npm install -g pnpm

# pyenv + Python latest stable 3.x
ENV PYENV_ROOT=/home/$USERNAME/.pyenv
ENV PATH="$PYENV_ROOT/bin:$PYENV_ROOT/shims:$PATH"
RUN curl -fsSL https://pyenv.run | bash && \
    eval "$(pyenv init -)" && \
    PYTHON_VERSION=$(pyenv install --list | grep -E '^\s+3\.[0-9]+\.[0-9]+$' | tail -1 | tr -d ' ') && \
    pyenv install "$PYTHON_VERSION" && \
    pyenv global "$PYTHON_VERSION"

# pipx + baseline tools
RUN pip install --user pipx && \
    python3 -m pipx ensurepath && \
    python3 -m pipx install pre-commit && \
    python3 -m pipx install ruff

# starship prompt
RUN curl -fsSL https://starship.rs/install.sh | sh -s -- --yes

# Dotfiles
COPY --chown=$USERNAME:$USERNAME dotfiles/ /home/$USERNAME/.config-src/

RUN cp /home/$USERNAME/.config-src/git/.gitconfig /home/$USERNAME/.gitconfig && \
    mkdir -p /home/$USERNAME/.config && \
    cp /home/$USERNAME/.config-src/starship/starship.toml /home/$USERNAME/.config/starship.toml

# Bash config
RUN echo '. /etc/bash_completion' >> ~/.bashrc && \
    echo 'eval "$(starship init bash)"' >> ~/.bashrc && \
    echo '[ -f "$HOME/.secrets/env" ] && source "$HOME/.secrets/env"' >> ~/.bashrc

# Secrets placeholder
RUN mkdir -p ~/.secrets && chmod 700 ~/.secrets && \
    touch ~/.secrets/env && chmod 600 ~/.secrets/env

CMD ["bash"]
