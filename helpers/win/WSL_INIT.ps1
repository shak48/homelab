<# Idempotent WSL bootstrap 
	https://learn.microsoft.com/en-us/windows/wsl/basic-commands
		try: 	wsl --install <distor_name>
				wsl -u root
				wsl -l
				wsl	--list --online 
				wsl	--set-default-version <1|2>
				wsl --set-version <Distro> <1|2>
				wsl --set-version <distribution name> <versionNumber>
				wsl --set-default <Distribution Name>
				wsl ~ # Starts in user home
				wsl --user <Username>
				wsl --mount <DiskPath>
				wsl --unmount <DiskPath>
				wsl --terminate <Distribution Name>
				wsl --unregister <DistributionName>
				wsl --export <Distribution Name> <FileName>
				wsl --import <Distribution Name> <InstallLocation> <FileName>
				wsl --import-in-place <Distribution Name> <FileName>
				. code # initiate VS CODE
				
   - Ensures WSL + VirtualMachinePlatform features
   - Ensures WSL2 is the default
   - Ensures latest WSL engine
   - Ensures target distro is installed (skips if present)
#>

param(
  [string]$DistroName   = "Debian",
  [string]$BootstrapUri = "https://raw.githubusercontent.com/shak48/homelab/main/helpers/linux-wsl/install-ansible.sh"
)

# 1. Download script in Windows TEMP
$WinTmp = Join-Path $env:TEMP 'install-ansible.sh'
Invoke-WebRequest -Uri $BootstrapUri -OutFile $WinTmp -UseBasicParsing

# 2. Copy into distro home (~/.tmp)
$payload = @"
set -euo pipefail
cp /mnt/c/Users/$env:USERNAME/AppData/Local/Temp/install-ansible.sh \/tmp/
cd "\/tmp"
chmod +x ./install-ansible.sh
bash ./install-ansible.sh
"@

& wsl.exe -d $DistroName -- bash -lc $payload

Write-Host "Done. Verify: wsl -d $DistroName -- bash -lc 'ansible --version'"
