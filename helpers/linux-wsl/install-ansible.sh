#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

# 1) Minimal prerequisites for pipx + Python runtime
sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get install -y --no-install-recommends \
  wget\
  python3 \
  python3-venv \
  python3-pip \
  pipx \
  ca-certificates
# 3) Install Ansible (latest stable) in an isolated environment
#    --include-deps avoids partial installs on some distros
# 3) Install Ansible as YOUR user (not root)
pipx ensurepath
pipx install --include-deps ansible --force

source ~/.bashrc

# 4) Verify
which ansible
ansible --version

# Enable VSCODE wsl extension
code .
