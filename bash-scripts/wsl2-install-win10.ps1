<#
.SYNOPSIS
    Installs WSL2 and Debian on Windows 10.
.DESCRIPTION
    Enables WSL2, installs necessary Windows features, and sets up Debian.
.NOTES
    Run this script as Administrator.
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
        [string]$solution = "Try running the script as Administrator and ensure Windows is up to date."
    )
    Write-Error "[ERROR] $errorMessage"
    Write-Host "[DEBUG] Suggested Fix: $solution" -ForegroundColor Yellow
    exit 1
}

Write-Log "Starting WSL2 installation process..."

# Step 1: Enable WSL
try {
    Write-Log "Enabling WSL..."
    wsl --install
    Start-Sleep -Seconds 5  # Allow time for installation to start
} catch {
    Write-Failure "WSL installation failed. Possible reasons: User canceled installation, system incompatibility." `
                  "Ensure your Windows version supports WSL2 (Windows 10 version 1903+)."
}

# Step 2: Verify WSL Installation
if (-not (Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux).State -eq "Enabled") {
    Write-Failure "WSL was not installed correctly. The installation may have been canceled." `
                  "Run 'wsl --install' manually in PowerShell and check for errors."
}
Write-Log "WSL installation verified successfully."

# Step 3: Enable Required Windows Features
try {
    Write-Log "Enabling Windows features for WSL2..."
    dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
    dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
} catch {
    Write-Failure "Failed to enable Windows features. These are required for WSL2." `
                  "Try running: 'dism.exe /online /get-features' to check if WSL features are available."
}

# Step 4: Verify Features Are Enabled
if (-not (Get-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform).State -eq "Enabled") {
    Write-Failure "Virtual Machine Platform was not enabled correctly." `
                  "Ensure virtualization is enabled in your BIOS and restart your computer."
}
Write-Log "Windows features verified successfully."

# Step 5: Set WSL2 as Default
try {
    Write-Log "Setting WSL2 as the default version..."
    wsl --set-default-version 2
} catch {
    Write-Failure "Failed to set WSL2 as default." `
                  "Run 'wsl --set-default-version 2' manually and check if it works."
}

# Step 6: Install Debian
try {
    Write-Log "Installing Debian..."
    wsl --install -d Debian
} catch {
    Write-Failure "Debian installation failed. Possible reasons: User cancellation, internet issues." `
                  "Try installing Debian manually from the Microsoft Store."
}

# Step 7: Verify Debian Installation
$wslList = wsl --list --verbose
if ($wslList -notmatch "Debian") {
    Write-Failure "Debian installation was not completed. It may have been canceled." `
                  "Run 'wsl --list --verbose' to check installed distributions."
}
Write-Log "WSL2 and Debian installation completed successfully!"
