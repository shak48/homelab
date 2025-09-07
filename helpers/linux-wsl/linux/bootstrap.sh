#!/bin/bash
set -euo pipefail
trap 'echo "Script failed at line $LINENO"; exit 1' ERR

# Allow overrides via env vars
KEY_NAME="${KEY_NAME:-id_ansible_ed25519}"
KEY_COMMENT="${KEY_COMMENT:-ansible@$(hostname -s)}"
KEY_PATH="$HOME/.ssh/$KEY_NAME"
ARCHIVE_DIR="${ARCHIVE_DIR:-$HOME/.ssh/old-keys}"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"

echo "Generating SSH key at $KEY_PATH"
mkdir -p "$ARCHIVE_DIR"

# Archive existing keys if present
if [[ -f "$KEY_PATH" ]]; then
  mv "$KEY_PATH" "$ARCHIVE_DIR/$(basename "$KEY_PATH").bak$TIMESTAMP"
fi

if [[ -f "$KEY_PATH.pub" ]]; then
  mv "$KEY_PATH.pub" "$ARCHIVE_DIR/$(basename "$KEY_PATH.pub").bak$TIMESTAMP"
fi

# Generate new keypair
ssh-keygen -t ed25519 -f "$KEY_PATH" -C "$KEY_COMMENT" -N ""

echo "SSH key generated:"
echo "  Private: $KEY_PATH"
echo "  Public : ${KEY_PATH}.pub"
echo "  Archived keys stored in: $ARCHIVE_DIR"

#For wake-on-LAN functionality
echo "Install wakeonlan package if not already installed"
sudo apt install wakeonlan

