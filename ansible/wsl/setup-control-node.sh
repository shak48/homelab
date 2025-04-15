#!/bin/bash

set -euo pipefail

# Colors for readability
GREEN="\033[0;32m"
NC="\033[0m" # No Color

log() {
    echo -e "${GREEN}[INFO] $1${NC}"
}

log "🔄 Updating package list and upgrading system..."
sudo apt update -y && sudo apt upgrade -y

log "🔒 Installing basic security tools..."
sudo apt install -y unattended-upgrades apt-listchanges fail2ban

log "⚙️ Enabling unattended security updates..."
sudo dpkg-reconfigure -plow unattended-upgrades

# Optional: customize automatic update schedule (non-interactive)
log "🛠️ Configuring unattended-upgrades preferences..."
sudo tee /etc/apt/apt.conf.d/20auto-upgrades > /dev/null <<EOF
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
EOF

sudo tee /etc/apt/apt.conf.d/50unattended-upgrades > /dev/null <<EOF
Unattended-Upgrade::Origins-Pattern {
        "origin=Ubuntu,codename=\${distro_codename},label=Ubuntu-Security";
};
Unattended-Upgrade::Automatic-Reboot "false";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
EOF

log "📦 Installing Ansible and common tools (if missing)..."
sudo apt install -y ansible curl git sshpass python3-pip python3-venv

log "🧹 Cleaning up..."
sudo apt autoremove -y && sudo apt autoclean -y

log "✅ Control node setup complete. Your system is updated and secured."
