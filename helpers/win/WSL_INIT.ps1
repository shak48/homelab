param(
  [string]$DistroName = "Debian",   # default to proper-cased display name
  [string]$WslUser    = "rumie"
)

$ErrorActionPreference = "Stop"
$script:rebootNeeded = $false

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

# 1) Windows features
Ensure-Feature -Name "Microsoft-Windows-Subsystem-Linux"
Ensure-Feature -Name "VirtualMachinePlatform"

# 2) Update WSL engine (best effort)
try { wsl --update | Out-Null; Write-Host "WSL engine updated (or already current)." }
catch { Write-Host "WSL engine update skipped/failed; continuing..." -ForegroundColor Yellow }

# 3) Ensure WSL2 default
try {
  $status = wsl --status 2>&1
  if ($status -match 'Default Version:\s*2') { Write-Host "WSL default version already set to 2." }
  else { Write-Host "Setting WSL default version to 2..."; wsl --set-default-version 2 }
} catch {
  Write-Host "Could not determine default version; forcing WSL2 default..."; wsl --set-default-version 2
}

# 4) .wslconfig (only if missing)
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

# 5) Reboot if features changed
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
  Write-Host "Re-run this script after initial user setup so file copy can succeed."
  return
}

# 7) Apply .wslconfig and ensure distro session is initialized
wsl --shutdown
# Start the distro once so \\wsl$ path is available
wsl -d $DistroName -- bash -lc 'echo WSL session initialized' | Out-Null
Write-Host "WSL is ready. Launch with:  wsl -d $DistroName -- bash -lc ""code ."""

# 8) Copy keys (audit only; overwrites if present)
$Src = "\\192.168.10.120\Shahriar\.ssh.bak\"
$Dst = "\\wsl$\$DistroName\home\$WslUser\.ssh\"

# Ensure destination exists (create .ssh if user home exists)
try {
  New-Item -ItemType Directory -Path $Dst -Force | Out-Null
} catch {
  Write-Host "Could not create $Dst. Does the user '$WslUser' exist in $DistroName and has it been launched at least once?" -ForegroundColor Yellow
  throw
}

Copy-Item -Path (Join-Path $Src '*') -Destination $Dst -Recurse -Force
Write-Host "Copied SSH files from $Src to $Dst."
