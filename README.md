# Run from windows 10/11 to get starteted

# Download the RAW script and save it locally
Invoke-WebRequest `
  -Uri "https://raw.githubusercontent.com/shak48/homelab/main/helpers/win/WSL_INIT.ps1" `
  -OutFile "$env:USERPROFILE\Downloads\WSL_INIT.ps1"

# Run it (ExecutionPolicy Bypass avoids the block on unsigned scripts)
powershell.exe -ExecutionPolicy Bypass -File "$env:USERPROFILE\Downloads\WSL_INIT.ps1"
