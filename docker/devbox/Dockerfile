FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y \
  openssh-server \
  curl git zsh tmux vim ripgrep bash-completion \
  nodejs npm python3 python3-pip \
  build-essential \
  && rm -rf /var/lib/apt/lists/*
RUN mkdir /var/run/sshd
RUN echo 'root:changeme' | chpasswd
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
# Starship
RUN curl -sS https://starship.rs/install.sh | sh -s -- --yes
WORKDIR /workspace
EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]
