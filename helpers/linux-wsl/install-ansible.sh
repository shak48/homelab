#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

# 1) Minimal prerequisites for pipx + Python runtime
sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get install -y --no-install-recommends \
  curl\
  wget\
  python3 \
  python3-venv \
  python3-pip \
  pipx \
  ca-certificates

# 0) Make sure we're NOT root
whoami

# 3) (Re)install Ansible for YOUR user with pipx
pipx ensurepath >/dev/null 2>&1 || true
pipx uninstall ansible >/dev/null 2>&1 || true
pipx install --include-deps ansible --force

# 4) Verify
ansible --version

# Enable VSCODE wsl extension
code .
