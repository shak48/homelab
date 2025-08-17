#!/bin/bash
set -euo pipefail

echo "📦 Updating system..."
sudo apt update && sudo apt install -y software-properties-common curl git

echo "🔧 Enabling Ansible PPA (official source)..."
sudo add-apt-repository --yes --update ppa:ansible/ansible

echo "🚀 Installing Ansible and dependencies..."
sudo apt install -y ansible python3-pip

echo "📚 Installing community modules..."
ansible-galaxy collection install community.general

echo "✅ Ansible installed!"
ansible --version
