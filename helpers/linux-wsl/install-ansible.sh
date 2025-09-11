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

# 1) Nuke any root-owned pipx Ansible that might confuse things
sudo -H bash -lc 'pipx uninstall ansible >/dev/null 2>&1 || true'
sudo rm -rf /root/.local/share/pipx/venvs/ansible /root/.local/bin/ansible* 2>/dev/null || true

# 2) Ensure your PATH includes ~/.local/bin for both login and interactive shells
grep -qxF 'export PATH="$HOME/.local/bin:$PATH"' ~/.bashrc   || echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
grep -qxF 'export PATH="$HOME/.local/bin:$PATH"' ~/.profile || echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.profile
# apply now for current shell
export PATH="$HOME/.local/bin:$PATH"
hash -r

# 3) (Re)install Ansible for YOUR user with pipx
pipx ensurepath >/dev/null 2>&1 || true
pipx uninstall ansible >/dev/null 2>&1 || true
pipx install --include-deps ansible --force

# 4) Verify
echo "PATH=$PATH"
command -v ansible
ansible --version

# Enable VSCODE wsl extension
code .
