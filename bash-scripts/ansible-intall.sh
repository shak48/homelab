#!/bin/bash

# Define colors for output
GREEN='\e[32m'
RED='\e[31m'
RESET='\e[0m'

# Function to log messages
log() {
    echo -e "$1"
}

# Check for internet connection
log "${GREEN}Checking internet connection...${RESET}"
if ! ping -c 3 8.8.8.8 &>/dev/null; then
    log "${RED}No internet connection. Please check your network and try again.${RESET}"
    exit 1
fi

# Configure Ansible logging
ANSIBLE_CONFIG="/etc/ansible/ansible.cfg"
ANSIBLE_LOG="/var/log/ansible.log"

log "${GREEN}Configuring Ansible logging...${RESET}"
sudo mkdir -p /etc/ansible /var/log
echo -e "[defaults]\nlog_path = $ANSIBLE_LOG" | sudo tee "$ANSIBLE_CONFIG" > /dev/null
sudo touch "$ANSIBLE_LOG" && sudo chmod 666 "$ANSIBLE_LOG"

# Update system & install Ansible
log "${GREEN}Updating system and installing Ansible...${RESET}"
sudo apt update -y && sudo apt upgrade -y
sudo apt install -y ansible python3-proxmoxer python3-requests

# Cleanup
log "${GREEN}Cleaning up installation files...${RESET}"
sudo apt clean

# Verify installation
log "${GREEN}Verifying Ansible installation...${RESET}"
ansible --version || { log "${RED}Ansible installation failed!${RESET}"; exit 1; }

log "${GREEN}Ansible installation complete!${RESET}"
