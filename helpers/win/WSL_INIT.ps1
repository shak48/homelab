<# Idempotent WSL bootstrap
		try: 	wsl --install
				wsl -u root
				    -l
				    --list --online 
				    --set-default-version <1|2>
				    --set-version <Distro> <1|2>
				     --set-version <distribution name> <versionNumber>
				     --set-default <Distribution Name>
				     ~ # Starts in user home
				     --user <Username>
				     --mount <DiskPath>
				     --unmount <DiskPath>
				     --terminate <Distribution Name>
				     --unregister <DistributionName>
				     --export <Distribution Name> <FileName>
				     --import <Distribution Name> <InstallLocation> <FileName>
             --import-in-place <Distribution Name> <FileName>
        wsl -d <debian> -- bash -lc '. code'  
				
   - Ensures WSL + VirtualMachinePlatform features
   - Ensures WSL2 is the default
   - Ensures latest WSL engine
   - Ensures target distro is installed (skips if present)
#>

param(
  [string]$DistroName = "debian"
)

$ErrorActionPreference = "Stop"

function Ensure-Feature {
  param([string]$Name)
  $f = Get-WindowsOptionalFeature -Online -FeatureName $Name
  if ($f.State -ne 'Enabled') {
    Write-Host "Enabling feature $Name..."
    Enable-WindowsOptionalFeature -Online -FeatureName $Name -NoRestart | Out-Null
    $script:rebootNeeded = $true
  } else {
    Write-Host "Feature $Name is already enabled."
  }
}

# 1) Make sure Windows features are on (no-op if already)
Ensure-Feature -Name "Microsoft-Windows-Subsystem-Linux"
Ensure-Feature -Name "VirtualMachinePlatform"

# 2) Update WSL engine (safe if already current)
try {
  wsl --update | Out-Null
  Write-Host "WSL engine updated (or already current)."
} catch {
  Write-Host "WSL engine update skipped/failed; continuing..." -ForegroundColor Yellow
}

# 3) Ensure default version is 2 (no-op if already)
try {
  $status = wsl --status 2>&1
  if ($status -match 'Default Version:\s*2') {
    Write-Host "WSL default version already set to 2."
  } else {
    Write-Host "Setting WSL default version to 2..."
    wsl --set-default-version 2
  }
} catch {
  Write-Host "Could not determine default version; forcing WSL2 default..."
  wsl --set-default-version 2
}

# 4) Optional: drop a sane .wslconfig (only if missing)
$wslcfg = Join-Path $env:USERPROFILE ".wslconfig"
if (-not (Test-Path $wslcfg)) {
@"
[wsl2]
memory=8GB
processors=4
swap=0
localhostForwarding=true
defaultVhdSize=33554432000
nestedVirtualization=true
guiApplications=false
debugConsole=false
"@ | Out-File -FilePath $wslcfg -Encoding ASCII
  Write-Host "Created $wslcfg"
} else {
  Write-Host "$wslcfg already exists; leaving as-is."
}

# 5) If we enabled features, ask for a reboot (idempotent safety)
if ($script:rebootNeeded) {
  Write-Host "`nA reboot is required to finalize Windows features."
  Write-Host "Please reboot, then run this script again. Exiting now."
  exit 3010
}

# 6) Install distro only if missing
$distroList = (wsl -l -v 2>$null) -join "`n"
if ($distroList -match "^\s*\*?\s*$([regex]::Escape($DistroName))\s" -or
    $distroList -match "^\s*$([regex]::Escape($DistroName))\s") {
  Write-Host "Distro '$DistroName' already installed."
} else {
  Write-Host "Installing distro '$DistroName'..."
  wsl --install -d $DistroName
  Write-Host "When the distro window appears the first time, create your Linux user/password."
}

# 7) Apply .wslconfig changes cleanly (safe even if not needed)
wsl --shutdown
Write-Host "WSL is ready. Launch with:  wsl -d $DistroName -- bash lc '.code'"


