<#
.SYNOPSIS
    Completely removes WSL2 from Windows 10.
.DESCRIPTION
    Unregisters distributions, disables required Windows features, removes WSL files and registry entries.
.NOTES
    Do Not Run this script as Administrator. Run below command to bypass security.
    Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

#>

# Enable strict error handling
$ErrorActionPreference = "Stop"

# Function to display logs
function Write-Log {
    param ([string]$message, [string]$color="Cyan")
    Write-Host "[INFO] $message" -ForegroundColor $color
}

# Function to handle failures
function Write-Failure {
    param (
        [string]$errorMessage,
        [string]$solution = "Try running the script as Administrator and ensure no active WSL sessions exist."
    )
    Write-Error "[ERROR] $errorMessage"
    Write-Host "[DEBUG] Suggested Fix: $solution" -ForegroundColor Yellow
    exit 1
}

Write-Log "Starting WSL2 uninstallation process..."

# Step 1: Unregister All Installed WSL Distributions
try {
    $wslDistros = wsl --list --verbose | Select-String "Running|Stopped" | ForEach-Object { ($_ -split '\s{2,}')[0] }
    foreach ($distro in $wslDistros) {
        Write-Log "Unregistering $distro..."
        wsl --unregister $distro
    }
} catch {
    Write-Failure "Failed to unregister some WSL distributions." "Manually run 'wsl --list --verbose' and 'wsl --unregister <DistroName>'."
}

# Step 2: Disable Windows Features for WSL2
try {
    Write-Log "Disabling WSL and Virtual Machine Platform..."
    dism.exe /online /disable-feature /featurename:Microsoft-Windows-Subsystem-Linux /norestart
    dism.exe /online /disable-feature /featurename:VirtualMachinePlatform /norestart
} catch {
    Write-Failure "Failed to disable WSL-related Windows features." "Try running 'dism.exe /online /get-features' to verify feature status."
}

# Step 3: Uninstall WSL Kernel Update (If Installed)
try {
    Write-Log "Removing WSL Kernel Update..."
    Get-AppxPackage | Where-Object { $_.Name -like "*WindowsSubsystemForLinux*" } | Remove-AppxPackage
} catch {
    Write-Failure "Failed to remove WSL Kernel Update." "Manually uninstall 'Windows Subsystem for Linux Update' via Control Panel."
}

# Step 4: Delete WSL File Directories
try {
    Write-Log "Deleting WSL user files..."
    Remove-Item -Path "$env:USERPROFILE\AppData\Local\Packages\CanonicalGroupLimited*" -Recurse -Force -ErrorAction SilentlyContinue
} catch {
    Write-Failure "Failed to delete WSL directories." "Check file permissions and manually remove '$env:USERPROFILE\AppData\Local\Packages\CanonicalGroupLimited*'."
}

# Step 5: Remove WSL Registry Entries
try {
    Write-Log "Removing WSL registry keys..."
    Remove-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LxssManager" -Recurse -Force -ErrorAction SilentlyContinue
} catch {
    Write-Failure "Failed to remove WSL registry keys." "Manually delete 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\LxssManager' in Registry Editor."
}

Write-Log "WSL2 has been completely removed. Restart your computer to apply all changes."
