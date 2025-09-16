#!/usr/bin/env bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

# =========================
# Config (override via env)
# =========================
REPO_URL="${REPO_URL:-git@github.com:shak48/homelab.git}"
REPO_DIR="${REPO_DIR:-$HOME/src/homelab}"

WIN_SHARE="${WIN_SHARE:-\\\\192.168.10.120\\Shahriar}"   # drvfs path
WIN_MNT="${WIN_MNT:-/mnt/winshare}"
SSH_SRC_SUBDIR="${SSH_SRC_SUBDIR:-.ssh.bak}"             # inside the share
SSH_DEST="${SSH_DEST:-$HOME/.ssh}"

LOG_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/homelab-setup"

# ================
# Small utilities
# ================
log(){ printf '[*] %s\n' "$*"; }
die(){ printf '[!] %s\n' "$*" >&2; exit 1; }

# ==========
# Logging
# ==========
setup_logging(){
  mkdir -p "$LOG_DIR"
  local log_file="$LOG_DIR/setup-$(date +%Y%m%d-%H%M%S).log"
  ln -sfn "$log_file" "$LOG_DIR/latest.log"
  exec > >(tee -a "$log_file") 2>&1
  log "Logging to: $log_file"
}

# =========================
# Base packages + security
# =========================
install_base_packages(){
  log "Updating and installing base tools…"
  sudo apt-get update -y
  sudo apt-get upgrade -y
  sudo apt-get install -y --no-install-recommends \
    unattended-upgrades \
    ansible openssh-client git \
    ca-certificates
}

configure_unattended_upgrades(){
  log "Configuring unattended-upgrades…"
  sudo tee /etc/apt/apt.conf.d/20auto-upgrades >/dev/null <<'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
EOF

  . /etc/os-release
  if [ "${ID:-}" = "ubuntu" ]; then
    sudo tee /etc/apt/apt.conf.d/50unattended-upgrades >/dev/null <<'EOF'
Unattended-Upgrade::Origins-Pattern {
  "origin=Ubuntu,archive=${distro_codename}-security";
};
Unattended-Upgrade::Automatic-Reboot "false";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
EOF
  else
    sudo tee /etc/apt/apt.conf.d/50unattended-upgrades >/dev/null <<'EOF'
Unattended-Upgrade::Origins-Pattern {
  "origin=Debian,codename=${distro_codename}-security,label=Debian-Security";
};
Unattended-Upgrade::Automatic-Reboot "false";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
EOF
  fi

  if command -v systemctl >/dev/null 2>&1; then
    sudo systemctl enable --now apt-daily.timer apt-daily-upgrade.timer || true
    sudo systemctl start unattended-upgrades.service || true
  fi
}

# =======================
# SSH keys from Windows
# =======================
mount_win_share(){
  # Optional: skip by exporting SKIP_WIN_SHARE=1
  [ "${SKIP_WIN_SHARE:-0}" = "1" ] && { log "Skipping mount of Windows share."; return; }
  log "Mounting Windows share to copy SSH keys…"
  sudo mkdir -p "$WIN_MNT"
  sudo mount -t drvfs "$WIN_SHARE" "$WIN_MNT"
}

umount_win_share(){
  [ "${SKIP_WIN_SHARE:-0}" = "1" ] && return
  sudo umount "$WIN_MNT" 2>/dev/null || true
}

copy_ssh_keys(){
  [ "${SKIP_WIN_SHARE:-0}" = "1" ] && { log "Skipping SSH key copy from share."; return; }

  local src="$WIN_MNT/$SSH_SRC_SUBDIR"
  [ -d "$src" ] || die "Expected SSH backup dir not found: $src"

  log "Copying SSH keys from $src to $SSH_DEST…"
  mkdir -p "$SSH_DEST"
  cp -a "$src"/. "$SSH_DEST"/

  chown -R "$(id -u)":"$(id -g)" "$SSH_DEST"
  chmod -R u=rwX,go= "$SSH_DEST"/

  # Minimal GitHub SSH config
  cat > "$SSH_DEST/config" <<'EOF'
Host github.com
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519
  IdentitiesOnly yes
  StrictHostKeyChecking accept-new
EOF
  chmod 600 "$SSH_DEST/config"
}

test_github_ssh(){
  log "Testing GitHub SSH…"
  set +e
  local out rc
  out=$(ssh -T git@github.com 2>&1); rc=$?
  set -e
  echo "$out" | grep -qi 'successfully authenticated' \
    || die "GitHub SSH auth failed (rc=$rc): $out"
  log "GitHub SSH ok."
}

# ===============
# Git identity
# ===============
git_identity(){
  if ! git config --global user.email >/dev/null 2>&1; then
    git config --global user.email \"rumie.kabir@gmail.com\"
  fi
  if ! git config --global user.name >/dev/null 2>&1; then
    git config --global user.name \"Shahriar Kabir\"
  fi
}

# ===========================
# Clone + track all branches
# ===========================
clone_or_update_repo(){
  log "Cloning/updating repo…"
  mkdir -p "$(dirname "$REPO_DIR")"

  if [ -d "$REPO_DIR/.git" ]; then
    git -C "$REPO_DIR" config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"
    # Unshallow if needed
    [ -f "$REPO_DIR/.git/shallow" ] && git -C "$REPO_DIR" fetch --unshallow --tags || true
    git -C "$REPO_DIR" fetch --prune --tags --all
    git -C "$REPO_DIR" pull --ff-only
  else
    git clone "$REPO_URL" "$REPO_DIR"
    git -C "$REPO_DIR" config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"
    git -C "$REPO_DIR" fetch --prune --tags --all
  fi
}

checkout_dev_if_exists(){
  if git -C "$REPO_DIR" ls-remote --exit-code --heads origin dev >/dev/null 2>&1; then
    git -C "$REPO_DIR" rev-parse --verify dev >/dev/null 2>&1 \
      || git -C "$REPO_DIR" switch -c dev --track origin/dev
  fi
}

# =========
# Cleanup
# =========
apt_cleanup(){
  log "Cleaning up APT caches…"
  sudo apt-get autoremove -y
  sudo apt-get autoclean -y
}

run_ansible_and_open_vscode(){
  log "Running Ansible bootstrap…"
  cd "$REPO_DIR/ansible"
  ansible-playbook playbooks/ansible-host/setup-shell.yml --ask-vault-pass

  if command -v code >/dev/null 2>&1; then
    log "Opening folder in VS Code (WSL)…"
    code "$REPO_DIR"
  fi
}

create_vault_pass(){
  log "Creating ansible/.ansible/vault-pass…"
  mkdir -p "$REPO_DIR/ansible/.ansible"
  touch "$REPO_DIR/ansible/.ansible/vault-pass"
}

# =========
# Main
# =========
main(){
  setup_logging
  install_base_packages
  configure_unattended_upgrades

  mount_win_share
  trap umount_win_share EXIT
  copy_ssh_keys
  test_github_ssh
  git_identity

  clone_or_update_repo
  checkout_dev_if_exists

  ls -al "$REPO_DIR" || true
  apt_cleanup
  create_vault_pass
  run_ansible_and_open_vscode

  log "Control node setup complete."
}

main "$@"
