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
  unattended-upgrades \
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
  // "origin=Ubuntu,archive=${distro_codename}-updates";
};
Unattended-Upgrade::Automatic-Reboot "false";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
EOF
else
  sudo tee /etc/apt/apt.conf.d/50unattended-upgrades >/dev/null <<'EOF'
Unattended-Upgrade::Origins-Pattern {
  "origin=Debian,codename=${distro_codename}-security,label=Debian-Security";
  // "origin=Debian,codename=${distro_codename}-updates";
};
Unattended-Upgrade::Automatic-Reboot "false";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
EOF
fi

# --- enable services (if systemd available) ---
log "Enabling services if systemd is available…"
if command -v systemctl >/dev/null 2>&1; then
  # On systemd systems the timers run upgrades; start them if present.
  sudo systemctl enable --now apt-daily.timer apt-daily-upgrade.timer || true
  sudo systemctl start unattended-upgrades.service || true
else
  log "systemd not detected; skipping timer/service enables."
fi

# --- verify ansible (system-wide) ---
log "Verifying Ansible…"
ansible --version

# --- copy SSH keys from Windows share (drvfs) ---
WIN_SHARE='\\\\192.168.10.120\\Shahriar'
MNT='/mnt/winshare'
DEST="$HOME/.ssh"

sudo mkdir -p "$MNT"
sudo mount -t drvfs "$WIN_SHARE" "$MNT"
cleanup() { sudo umount "$MNT" 2>/dev/null || true; }
trap cleanup EXIT

mkdir -p "$DEST"
cp -a "$MNT/.ssh.bak"/. "$DEST"/

# ensure ownership + strict perms (dirs 700, files 600)
chown -R "$(id -u)":"$(id -g)" "$DEST"
chmod -R u=rwX,go= "$DEST"/

# write minimal SSH config for GitHub
cat > "$DEST/config" <<'EOF'
Host github.com
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519
  IdentitiesOnly yes
  StrictHostKeyChecking accept-new
EOF
chmod 600 "$DEST/config"

# safe GitHub SSH test under set -e (GitHub exits 1 on success)
set +e
_out=$(ssh -T git@github.com 2>&1); _rc=$?
set -e
if ! printf '%s' "$_out" | grep -qi 'successfully authenticated'; then
  log "GitHub SSH auth failed (rc=$_rc): $_out"
  exit 1
fi
log "GitHub SSH ok: $_out"

# Ensure Git identity is set up
if ! git config --global user.email >/dev/null 2>&1; then
  echo "[hint] Run: git config --global user.email \"rumie.kabir@gmail.com\""
fi
if ! git config --global user.name >/dev/null 2>&1; then
  echo "[hint] Run: git config --global user.name \"Shahriar Kabir\""
fi

# --- fetch repo (default branch) ---
REPO_URL="${REPO_URL:-git@github.com:shak48/homelab.git}"
REPO_DIR="${REPO_DIR:-$HOME/src/homelab}"
mkdir -p "$(dirname "$REPO_DIR")"

if [ -d "$REPO_DIR/.git" ]; then
  log "Updating repo…"
  git -C "$REPO_DIR" pull --ff-only
else
  log "Cloning repo…"
  trap 'rm -rf "$REPO_DIR"; exit 1' ERR
  git clone --depth=1 "$REPO_URL" "$REPO_DIR"
  trap - ERR
fi

cd "$REPO_DIR"
ls -al

# open in VS Code if available (WSL)
if command -v code >/dev/null 2>&1; then
  log "Opening folder in VS Code (WSL)…"
  code .
fi

# --- cleanup ---
log "Cleaning up APT caches…"
sudo apt-get autoremove -y
sudo apt-get autoclean -y

log "Run Ansible to bootstrap user .bashrc"
cd ansible
ansible-playbook playbooks/ansible-host/setup-shell.yml -b -K 

log "Control node setup complete."
