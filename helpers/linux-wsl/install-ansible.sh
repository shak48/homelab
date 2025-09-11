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
# 2) Determine the REAL user (handles if script run with or without sudo)
TARGET_USER="${SUDO_USER:-$USER}"

# 3) Do user-scoped work as the real user
sudo -u "$TARGET_USER" -H bash -lc '
  set -euo pipefail
  # Ensure ~/.local/bin on PATH for future logins and now
  grep -q '\''export PATH="$HOME/.local/bin:$PATH"'\'' "$HOME/.profile" || \
    echo '\''export PATH="$HOME/.local/bin:$PATH"'\'' >> "$HOME/.profile"
  export PATH="$HOME/.local/bin:$PATH"

  # Clean any stale installs and (re)install Ansible
  pipx ensurepath >/dev/null 2>&1 || true
  pipx uninstall ansible >/dev/null 2>&1 || true
  pipx install --include-deps ansible

  ansible --version
'

source ~/.bashrc

# 4) Verify
which ansible
ansible --version

# Enable VSCODE wsl extension
code .
