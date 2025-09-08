# Run from windows 10/11 to get starteted

# Download the RAW script and save it locally
Invoke-WebRequest `
  -Uri "https://raw.githubusercontent.com/shak48/homelab/main/helpers/win/WSL_INIT.ps1" `
  -OutFile "$env:TEMP\WSL_INIT.ps1"

# Run it (ExecutionPolicy Bypass avoids the block on unsigned scripts)
powershell.exe -ExecutionPolicy Bypass -File "$env:TEMP\WSL_INIT.ps1"

# Run it to initiate the git and install ansible 
Invoke-WebRequest `
  -Uri "https://raw.githubusercontent.com/shak48/homelab/main/helpers/linux-wsl/install-ansible.sh" `
  -OutFile "$env:TEMP\bootstrap.sh"

wsl -d debian -- bash -lc "chmod +x /mnt/c/Users/$env:USERNAME/AppData/Local/Temp/bootstrap.sh && sudo /mnt/c/Users/$env:USERNAME/AppData/Local/Temp/bootstrap.sh"

