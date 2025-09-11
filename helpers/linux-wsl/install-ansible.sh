#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

type log >/dev/null 2>&1 || log() { printf '[*] %s\n' "$*"; }

log "Installing basic security tools..."

sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get install -y --no-install-recommends \
  curl\
  wget\
  python3 \
  python3-venv \
  python3-pip \
  pipx \
  ca-certificates \
  unattended-upgrades \
  apt-listchanges \
  fail2ban


log "Configuring unattended-upgrades preferences (non-interactive)..."
sudo tee /etc/apt/apt.conf.d/20auto-upgrades >/dev/null <<'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
EOF

. /etc/os-release
if [ "${ID:-}" = "ubuntu" ]; then
  sudo tee /etc/apt/apt.conf.d/50unattended-upgrades >/dev/null <<'EOF'
Unattended-Upgrade::Origins-Pattern {
        "origin=Ubuntu,archive=${distro_codename}-security";
        // Optional: enable regular updates too (comment out if you want security only)
        // "origin=Ubuntu,archive=${distro_codename}-updates";
};
Unattended-Upgrade::Automatic-Reboot "false";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
EOF
else
  # Debian
  sudo tee /etc/apt/apt.conf.d/50unattended-upgrades >/dev/null <<'EOF'
Unattended-Upgrade::Origins-Pattern {
        "origin=Debian,codename=${distro_codename}-security,label=Debian-Security";
        // Optional: point releases and regular updates:
        // "origin=Debian,codename=${distro_codename}-updates";
        // "origin=Debian,codename=${distro_codename}-proposed-updates";
};
Unattended-Upgrade::Automatic-Reboot "false";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
EOF
fi


log "Enabling services if systemd is available..."
if command -v systemctl >/dev/null 2>&1; then
  sudo systemctl enable --now unattended-upgrades || true
  sudo systemctl enable --now fail2ban || true
else
  log "systemd not detected; skipping systemctl enable/now steps."
fi

# Minimal hardening: enable sshd jail if SSH is present
if [ -f /etc/ssh/sshd_config ]; then
  sudo mkdir -p /etc/fail2ban/jail.d
  sudo tee /etc/fail2ban/jail.d/sshd.local >/dev/null <<'EOF'
[sshd]
enabled = true
# bantime, findtime, maxretry can be tuned; defaults are fine for home use
EOF
  if command -v systemctl >/dev/null 2>&1; then
    sudo systemctl restart fail2ban || true
  fi
fi

log "Security baseline configured."

# 0) Make sure we're NOT root
echo "Installing Ansible via pipx for user: $(whoami)"
log "Installing Ansible via pipx for user: $(whoami)"


pipx ensurepath >/dev/null 2>&1 || true
pipx uninstall ansible >/dev/null 2>&1 || true
pipx install --include-deps ansible --force

source ~/.bashrc
ansible --version

log "Installing VSCode Wsl extension"

code .

log "Cleaning up..."
sudo apt autoremove -y && sudo apt autoclean -y

log "Control node setup complete. Your system is updated and secured."
