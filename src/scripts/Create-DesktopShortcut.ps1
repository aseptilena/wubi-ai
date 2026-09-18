<#
.SYNOPSIS
    Create or Refresh Desktop and Start Menu Shortcuts for WUBI-AI.
#>

[CmdletBinding()]
param (
    [switch]$AllUsers
)

$AppPath = "D:\Project\WUBI-AI\Launch-WubiAI.bat"

$WshShell = New-Object -ComObject WScript.Shell

# Resolve Desktop Directory
$desktopDir = if ($AllUsers) {
    [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::CommonDesktopDirectory)
} else {
    [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::Desktop)
}

$shortcutPath = Join-Path $desktopDir "WUBI-AI Installer.lnk"
$shortcut = $WshShell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = "powershell.exe"
$shortcut.Arguments = "-NoProfile -ExecutionPolicy Bypass -STA -File `"D:\Project\WUBI-AI\src\gui\Launch-WubiAI-GUI.ps1`""
$shortcut.WorkingDirectory = "D:\Project\WUBI-AI"

$shortcut.Description = "WUBI-AI: Ubuntu & Omarchy AI Workstation Installer (Zero-Destruction)"
$shortcut.IconLocation = "$env:SystemRoot\System32\shell32.dll, 13" # Modern Screen/Disk Icon
$shortcut.Save()

Write-Host "[+] Desktop Shortcut Created Successfully:" -ForegroundColor Green
Write-Host "    Path: $shortcutPath" -ForegroundColor Cyan
