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

## Uncomment if cleanup needed
# wsl --unregister $DistroName

# --- tiny helpers ---
function Write-Step($msg) { Write-Host "[*] $msg" -ForegroundColor Cyan }

function Set-WSL2Default {
  Write-Step "Ensuring WSL2 is default…"
      $current = wsl --status 2>$null | Select-String "Default Version" | ForEach-Object { $_.ToString().Split(':')[1].Trim() }
    if ($current -ne "2") {
        wsl --set-default-version 2 | Out-Null
  wsl --set-default-version 2 | Out-Null
}

function Test-Installed {
  (wsl -l -q 2>$null | ForEach-Object { $_.Trim() }) -contains $DistroName
}


function Test-Initialized {
  # returns $true only after user has completed first-run
  $out = & wsl.exe -d $DistroName -- bash -lc "id -un" 2>$null
  ($LASTEXITCODE -eq 0) -and ($out) -and ($out.Trim().Length -gt 0)
}

function Install-DistroIfMissing {
  if (-not (Test-Installed)) {
    Write-Step "Installing $DistroName (this will launch first-run in a separate window)…"
    Start-Process -FilePath "wsl.exe" -ArgumentList "--install","-d",$DistroName -Wait
  }

  # If the distro isn’t initialized yet, open its first-run shell for user creation and wait for it to close.
  if (-not (Test-Initialized)) {
    Write-Step "Opening $DistroName to complete first-run (create user, then type 'exit')…"
    Start-Process -FilePath "wsl.exe" -ArgumentList "-d",$DistroName -Wait
  }

  # Double-check init (user might have closed without completing)
  if (-not (Test-Initialized)) {
    throw "WSL distro '$DistroName' is not initialized. Re-run this script after completing first-run."
  }
}

function Invoke-BootstrapInWSL {
  Write-Step "Bootstrapping inside $DistroName…"
  $payload = @"
set -euo pipefail
sudo apt-get update -y >/dev/null
sudo apt-get install -y wget >/dev/null
wget -qO /tmp/install-ansible.sh '$BootstrapUri'
chmod +x /tmp/install-ansible.sh
bash /tmp/install-ansible.sh
"@
  & wsl.exe -d $DistroName -- bash -lc $payload

  Write-Step "Done. Verify:"
  Write-Host "wsl -d $DistroName -- bash -lc 'ansible --version'"
}

function Set-DefaultDistro {
  Write-Step "Setting default distro: $DistroName"
  wsl --set-default $DistroName
}

function Show-WSLStatus {
  Write-Step "WSL status:"
  wsl --status
}

# -------- main flow --------



Set-WSL2Default
Install-DistroIfMissing
Set-DefaultDistro
Show-WSLStatus
Invoke-BootstrapInWSL