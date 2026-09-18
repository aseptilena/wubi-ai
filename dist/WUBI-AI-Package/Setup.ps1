<#
.SYNOPSIS
    Self-Installer for WUBI-AI Tools into Program Files or Local AppData
#>
$installTarget = "$env:LOCALAPPDATA\WUBI-AI"
Write-Host "Installing WUBI-AI to $installTarget..." -ForegroundColor Cyan
if (-not (Test-Path $installTarget)) {
    New-Item -ItemType Directory -Path $installTarget -Force | Out-Null
}
Copy-Item -Path "$PSScriptRoot\*" -Destination $installTarget -Recurse -Force

# Create Desktop Shortcut
$WshShell = New-Object -ComObject WScript.Shell
$desktop = [System.Environment]::GetFolderPath('Desktop')
$shortcut = $WshShell.CreateShortcut("$desktop\WUBI-AI Installer.lnk")
$shortcut.TargetPath = "$installTarget\Launch-WubiAI.bat"
$shortcut.WorkingDirectory = $installTarget
$shortcut.IconLocation = "$env:SystemRoot\System32\shell32.dll, 13"
$shortcut.Save()
Write-Host "Installation Complete! Launch WUBI-AI from your Desktop shortcut." -ForegroundColor Green
