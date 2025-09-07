#!/bin/bash

set -e
set -o pipefail

USERNAME="$1"

if [[ -z "$USERNAME" ]]; then
  echo "Usage: $0 <username>"
  exit 1
fi

echo "=== Installing sudo & OpenSSH Server ==="
apt update
apt install -y sudo openssh-server

if id "$USERNAME" &>/dev/null; then
  echo "=== User $USERNAME already exists — skipping user creation ==="
else
  echo "=== Creating user: $USERNAME ==="
  adduser "$USERNAME"
fi

echo "=== Ensuring $USERNAME is in sudo group ==="
usermod -aG sudo "$USERNAME"

echo "=== Setting up SSH directory for $USERNAME ==="
mkdir -p /home/"$USERNAME"/.ssh
chown "$USERNAME":"$USERNAME" /home/"$USERNAME"/.ssh
chmod 700 /home/"$USERNAME"/.ssh

echo "=== Hardening SSH config ==="
sed -i 's/^#\?PermitRootLogin .*/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/^#\?PasswordAuthentication .*/PasswordAuthentication no/' /etc/ssh/sshd_config

echo "=== Restarting SSH service ==="
systemctl enable ssh
systemctl restart ssh

echo "=== Hardened SSH and sudo setup complete ==="
echo "User $USERNAME has sudo privileges."
echo "SSH root login disabled."
echo "Add SSH key to: /home/$USERNAME/.ssh/authorized_keys"
