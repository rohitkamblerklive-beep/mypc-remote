# ============================================================
#  MyPC Remote — 1-Command Auto Installer
#  Run: irm https://rohitkamblerklive-beep.github.io/mypc-remote/install.ps1 | iex
# ============================================================

$ErrorActionPreference = 'Stop'

# Config
$AppName    = "MyPC Remote"
$AppFolder  = "$env:ProgramFiles\MyPC Remote"
$ExeName    = "MyPC_Remote_Server.exe"
$ExePath    = "$AppFolder\$ExeName"
$ShortcutD  = "$env:USERPROFILE\Desktop\MyPC Remote.lnk"
$ShortcutS  = "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\MyPC Remote.lnk"
$ZipUrl     = "https://github.com/rohitkamblerklive-beep/mypc-remote/releases/latest/download/MyPC_Remote_Server.zip"
$TempZip    = "$env:TEMP\MyPC_Remote_Server.zip"
$TempFolder = "$env:TEMP\MyPC_Remote_Extract"
$FirewallRuleName = "MyPC Remote Server"
$Port       = 9999

Write-Host ""
Write-Host "  =====================================================" -ForegroundColor Cyan
Write-Host "        MyPC Remote - Auto Installer" -ForegroundColor Cyan
Write-Host "    Control Your PC From Your Android Phone" -ForegroundColor Cyan
Write-Host "  =====================================================" -ForegroundColor Cyan
Write-Host ""

# Admin Check
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "  [!] Restarting with Administrator privileges..." -ForegroundColor Yellow
    $script = [System.IO.Path]::GetTempFileName() + ".ps1"
    (Invoke-WebRequest -UseBasicParsing "https://rohitkamblerklive-beep.github.io/mypc-remote/install.ps1").Content | Set-Content $script
    Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$script`"" -Wait
    exit
}

# Step 1: Create Install Folder
Write-Host "  [1/5] Creating install folder..." -ForegroundColor Green
if (Test-Path $TempFolder) { Remove-Item $TempFolder -Recurse -Force }
New-Item -ItemType Directory -Force -Path $AppFolder | Out-Null
New-Item -ItemType Directory -Force -Path $TempFolder | Out-Null

# Step 2: Download
Write-Host "  [2/5] Downloading MyPC Remote Server..." -ForegroundColor Green
$ProgressPreference = 'SilentlyContinue'
try {
    Invoke-WebRequest -Uri $ZipUrl -OutFile $TempZip -UseBasicParsing
} catch {
    Write-Host "  [!] Download failed. Check your internet connection." -ForegroundColor Red
    exit 1
}
Write-Host "        Download complete" -ForegroundColor DarkGray

# Step 3: Extract and Install
Write-Host "  [3/5] Installing to Program Files..." -ForegroundColor Green
Expand-Archive -Path $TempZip -DestinationPath $TempFolder -Force
$FoundExe = Get-ChildItem -Path $TempFolder -Recurse -Filter "*.exe" | Select-Object -First 1
if (-not $FoundExe) {
    Write-Host "  [!] EXE not found in package." -ForegroundColor Red
    exit 1
}
Copy-Item -Path $FoundExe.FullName -Destination $ExePath -Force
Remove-Item $TempZip -Force -ErrorAction SilentlyContinue
Remove-Item $TempFolder -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "        Installed to: $AppFolder" -ForegroundColor DarkGray

# Step 4: Firewall Rules
Write-Host "  [4/5] Configuring Windows Firewall (Port $Port)..." -ForegroundColor Green
Remove-NetFirewallRule -DisplayName $FirewallRuleName -ErrorAction SilentlyContinue
New-NetFirewallRule -DisplayName $FirewallRuleName -Direction Inbound -Protocol TCP -LocalPort $Port -Action Allow -Profile Any -Description "MyPC Remote Server" | Out-Null
New-NetFirewallRule -DisplayName "$FirewallRuleName UDP" -Direction Inbound -Protocol UDP -LocalPort $Port -Action Allow -Profile Any | Out-Null
New-NetFirewallRule -DisplayName "$FirewallRuleName App" -Direction Inbound -Program $ExePath -Action Allow -Profile Any | Out-Null
Write-Host "        Firewall Port 9999 TCP+UDP allowed" -ForegroundColor DarkGray

# Step 5: Shortcuts
Write-Host "  [5/5] Creating shortcuts..." -ForegroundColor Green
$WshShell = New-Object -ComObject WScript.Shell
$sc = $WshShell.CreateShortcut($ShortcutD)
$sc.TargetPath = $ExePath; $sc.WorkingDirectory = $AppFolder; $sc.WindowStyle = 1; $sc.Save()
$sm = $WshShell.CreateShortcut($ShortcutS)
$sm.TargetPath = $ExePath; $sm.WorkingDirectory = $AppFolder; $sm.WindowStyle = 1; $sm.Save()
Write-Host "        Desktop and Start Menu shortcuts created" -ForegroundColor DarkGray

Write-Host ""
Write-Host "  =====================================================" -ForegroundColor Green
Write-Host "       MyPC Remote installed successfully!" -ForegroundColor Green
Write-Host "  =====================================================" -ForegroundColor Green
Write-Host ""
Write-Host "  1. Launch 'MyPC Remote' from your Desktop" -ForegroundColor White
Write-Host "  2. Open MyPC Remote app on your Android phone" -ForegroundColor White
Write-Host "  3. Scan the QR code on screen to connect!" -ForegroundColor White
Write-Host ""

$launch = Read-Host "  Launch MyPC Remote Server now? (Y/N)"
if ($launch -match '^[Yy]$') {
    Start-Process -FilePath $ExePath -WorkingDirectory $AppFolder
}
Write-Host ""
Write-Host "  Thank you for using MyPC Remote!" -ForegroundColor Cyan
