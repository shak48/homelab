# Ensure WSL + Virtual Machine Platform are enabled, and set WSL2 as default
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

# Get the latest WSL engine (recommended)
wsl --update

# Make sure new distros use WSL2
wsl --set-default-version 2

# Install Ubuntu 24.04 LTS (change the name if you prefer another image)
wsl --install -d Ubuntu-24.04
# wsl --install -d Debian

# ----------------------------------------------------------------------
# Write a default .wslconfig to the current user's profile
# Adjust memory/CPU/disk/etc. as you like
# ----------------------------------------------------------------------
@"
[wsl2]
memory=8GB
processors=4
swap=0
localhostForwarding=true
defaultVhdSize=33554432000   # 16 GB
nestedVirtualization=true
guiApplications=false
debugConsole=false
"@ | Out-File -Encoding ASCII -FilePath "$env:USERPROFILE\.wslconfig" -Force
