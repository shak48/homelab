#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

echo "Installing base packages..."
sudo apt-get update -y
sudo apt-get install -yq \
  ca-certificates \
  curl \
  git \
  bash-completion \
  python3 \
  python3-venv \
  python3-pip \
  pipx \
  openssh-client \
  wget \
  tar \
  xz-utils \
  unzip \
  apt-transport-https \
  lsb-release \
  gnupg

echo "Configuring pipx path..."
pipx ensurepath || true
# shellcheck disable=SC1090
. ~/.bashrc 2>/dev/null || true

echo "Installing Ansible user-scoped with pipx..."
if ! command -v ansible >/dev/null 2>&1; then
  pipx install ansible
  pipx inject ansible argcomplete || true
  activate-global-python-argcomplete || true
fi

echo "Installing Ansible collections (if requirements.yml exists)..."
if [[ -f requirements.yml ]]; then
  ansible-galaxy collection install -r requirements.yml --force
fi

echo "Bootstrap completed."
ansible --version