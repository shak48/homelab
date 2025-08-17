#Run Allow Executon Temporarily
#Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned


# --- CONFIG ---
$ServerIP   = "192.168.10.120"
$Shares     = @("Common", "Shahriar", "Tahia")
$User       = "Guest"
$Password   = ""

# --- Enable Guest logons persistently ---
Write-Host "Enabling guest logons..." -ForegroundColor Yellow
Set-SmbClientConfiguration -EnableInsecureGuestLogons $true -Force

# --- Test connectivity on TCP 445 ---
Write-Host "Testing TCP 445 connectivity to $ServerIP..." -ForegroundColor Yellow
$test = Test-NetConnection -ComputerName $ServerIP -Port 445
if (-not $test.TcpTestSucceeded) {
    Write-Host "ERROR: Cannot reach $ServerIP on port 445. Check network/firewall." -ForegroundColor Red
    Read-Host "Press ENTER to exit"
    exit 1
}

# --- Disconnect existing mappings to this server ---
Write-Host "Disconnecting any existing mappings to $ServerIP..." -ForegroundColor Yellow
Get-SmbMapping | Where-Object { $_.RemotePath -like "\\$ServerIP\*" } | ForEach-Object {
    net use $_.LocalPath /delete /y
}

# --- Map shares ---
foreach ($Share in $Shares) {
    $RemotePath = "\\$ServerIP\$Share"
    Write-Host "Mapping $RemotePath as $User..." -ForegroundColor Green
    net use $RemotePath $Password /user:$User /persistent:yes
}

# --- List available shares ---
Write-Host "`nShares available on $ServerIP:" -ForegroundColor Cyan
net view \\$ServerIP

# --- Wait for key before exiting ---
Write-Host ""
Read-Host "Press ENTER to exit"
