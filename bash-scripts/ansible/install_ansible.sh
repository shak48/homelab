#!/bin/bash

# Define colors for output
GREEN='\e[32m'
RED='\e[31m'
RESET='\e[0m'

# Grant write permissions to all users
chmod a+w "$0"

# Check for internet connection
echo -e "${GREEN}Checking internet connection...${RESET}"
ping -c 3 8.8.8.8 > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo -e "${RED}No internet connection. Please check your network and try again.${RESET}"
    exit 1
fi

# Define user temp directory
USER_TEMP_DIR="/var/tmp/ansible_install"
echo -e "${GREEN}Creating temporary directory at $USER_TEMP_DIR...${RESET}"
sudo mkdir -p "$USER_TEMP_DIR"
sudo chmod 777 "$USER_TEMP_DIR"

# Define user installation log file
INSTALL_LOG="/var/log/usr/ansible_install.log"
sudo mkdir -p "/var/log/usr"
sudo touch "$INSTALL_LOG"
sudo chmod 666 "$INSTALL_LOG"

# Update and upgrade system
echo -e "${GREEN}Updating system packages...${RESET}"
sudo apt update && sudo apt upgrade -y 2>&1 | tee -a "$INSTALL_LOG"

# Install Ansible
echo -e "${GREEN}Installing Ansible...${RESET}"
sudo apt install -y ansible 2>&1 | tee -a "$INSTALL_LOG"

# Install additional dependencies
echo -e "${GREEN}Installing Python dependencies...${RESET}"
sudo apt install -y python3-proxmoxer python3-requests 2>&1 | tee -a "$INSTALL_LOG"

# Cleanup installation files
echo -e "${GREEN}Cleaning up installation files...${RESET}"
sudo apt clean
sudo rm -rf "$USER_TEMP_DIR"

# Verify installation
echo -e "${GREEN}Verifying Ansible installation...${RESET}"
ansible --version 2>&1 | tee -a "$INSTALL_LOG"

# Completion message
echo -e "${GREEN}Ansible installation complete!${RESET}"