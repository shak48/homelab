#!/usr/bin/env bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

# --- logging ---
LOG_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/homelab-setup"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/setup-$(date +%Y%m%d-%H%M%S).log"
ln -sfn "$LOG_FILE" "$LOG_DIR/latest.log"
exec > >(tee -a "$LOG_FILE") 2>&1
log() { printf '[*] %s\n' "$*"; }

log "Logging to: $LOG_FILE"

# --- base packages (Debian/Ubuntu) ---
log "Updating and installing base tools…"
sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get install -y --no-install-recommends \
  unattended-upgrades apt-listchanges fail2ban \
  ansible openssh-client git \
  ca-certificates

# --- unattended upgrades ---
log "Configuring unattended-upgrades (non-interactive)…"
sudo tee /etc/apt/apt.conf.d/20auto-upgrades >/dev/null <<'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
EOF

. /etc/os-release
if [ "${ID:-}" = "ubuntu" ]; then
  sudo tee /etc/apt/apt.conf.d/50unattended-upgrades >/dev/null <<'EOF'
Unattended-Upgrade::Origins-Pattern {
  "origin=Ubuntu,archive=${distro_codename}-security";
  // Uncomment for regular updates too:
  // "origin=Ubuntu,archive=${distro_codename}-updates";
};
Unattended-Upgrade::Automatic-Reboot "false";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
EOF
else
  sudo tee /etc/apt/apt.conf.d/50unattended-upgrades >/dev/null <<'EOF'
Unattended-Upgrade::Origins-Pattern {
  "origin=Debian,codename=${distro_codename}-security,label=Debian-Security";
  // Optional regular updates:
  // "origin=Debian,codename=${distro_codename}-updates";
};
Unattended-Upgrade::Automatic-Reboot "false";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
EOF
fi

# --- enable services (if systemd available) ---
log "Enabling services if systemd is available…"
if command -v systemctl >/dev/null 2>&1; then
  sudo systemctl enable --now unattended-upgrades || true
  sudo systemctl enable --now fail2ban || true
else
  log "systemd not detected; skipping service enable/now."
fi

# --- minimal fail2ban hardening for SSH (if SSH present) ---
if [ -f /etc/ssh/sshd_config ]; then
  sudo mkdir -p /etc/fail2ban/jail.d
  sudo tee /etc/fail2ban/jail.d/sshd.local >/dev/null <<'EOF'
[sshd]
enabled = true
# tune bantime/findtime/maxretry as needed
EOF
  command -v systemctl >/dev/null 2>&1 && sudo systemctl restart fail2ban || true
fi

# --- verify ansible (system-wide) ---
log "Verifying Ansible…"
ansible --version

# --- copy ~/.ssh from Windows mapped drive (fix perms after copy) ---
WIN_SRC='\\192.168.10.120\Shahriar\.ssh.bak'
#SRC_WSL="$(wslpath -u "$WIN_SRC")"
DEST="$HOME/.ssh"

log "Syncing SSH keys from $WIN_SRC → $DEST …"
mkdir -p "$DEST"
cp -a "$WIN_SRC"/ "$DEST"/ || true
# fix permissions so SSH won't complain
chmod 700 "$DEST" || true
find "$DEST" -type f -exec chmod 600 {} \; || true
find "$DEST" -type f -name '*.pub' -exec chmod 644 {} \; || true
[ -f "$DEST/known_hosts" ] && chmod 644 "$DEST/known_hosts" || true
log "~/.ssh permissions normalized."

# --- fetch repo (dev branch) ---
REPO_URL="${REPO_URL:-git@github.com:shak48/homelab.git}"
REPO_DIR="${REPO_DIR:-$HOME/src/home-lab}"
REPO_BRANCH="${REPO_BRANCH:-dev}"

log "Fetching repo $REPO_URL → $REPO_DIR (branch: $REPO_BRANCH)…"
mkdir -p "$(dirname "$REPO_DIR")"
git -C "$REPO_DIR" fetch origin "$REPO_BRANCH" 2>/dev/null \
  && git -C "$REPO_DIR" checkout -B "$REPO_BRANCH" --track "origin/$REPO_BRANCH" \
  && git -C "$REPO_DIR" pull --ff-only \
  || { rm -rf "$REPO_DIR"; git clone --depth=1 --branch "$REPO_BRANCH" "$REPO_URL" "$REPO_DIR"; }

cd "$REPO_DIR"
ls -al
# --- open in VS Code if available (WSL) ---
if command -v code >/dev/null 2>&1; then
  log "Opening folder in VS Code (WSL)…"
  code .
fi

# --- cleanup ---
log "Cleaning up APT caches…"
sudo apt-get autoremove -y
sudo apt-get autoclean -y

log "✅ Control node setup complete."
