<#
.SYNOPSIS
    Builds the distribution package, standalone executable/launcher, 
    and creates desktop and start menu shortcuts for WUBI-AI.
#>

[CmdletBinding()]
param (
    [switch]$CreateDesktopShortcut,
    [switch]$BuildDistZip
)

$ErrorActionPreference = "Stop"

$ProjectRoot = "d:\Project\WUBI-AI"
$DistDir     = Join-Path $ProjectRoot "dist"
$BinDir      = Join-Path $DistDir "WUBI-AI-Package"
$LauncherVbs = Join-Path $BinDir "Launch-WubiAI.vbs"
$LauncherBat = Join-Path $BinDir "Launch-WubiAI.bat"

Write-Host "=================================================" -ForegroundColor Cyan
Write-Host " Building WUBI-AI Distribution Package           " -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan

# 1. Clean & Prepare Dist Directories
if (Test-Path $DistDir) {
    Remove-Item -Path $DistDir -Recurse -Force
}
New-Item -ItemType Directory -Path $BinDir -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $BinDir "src") -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $BinDir "config") -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $BinDir "tests") -Force | Out-Null

# 2. Copy Distribution Assets
Write-Host "[*] Packaging core engine and scripts..." -ForegroundColor Gray
Copy-Item -Path (Join-Path $ProjectRoot "src\*") -Destination (Join-Path $BinDir "src") -Recurse -Force
Copy-Item -Path (Join-Path $ProjectRoot "config\*") -Destination (Join-Path $BinDir "config") -Recurse -Force
Copy-Item -Path (Join-Path $ProjectRoot "tests\*") -Destination (Join-Path $BinDir "tests") -Recurse -Force
Copy-Item -Path (Join-Path $ProjectRoot "PRD_WUBI_AI.md") -Destination $BinDir -Force
Copy-Item -Path (Join-Path $ProjectRoot "WALKTHROUGH.md") -Destination $BinDir -Force

# 3. Create Silent/Elevated Batch & VBS Launchers
Write-Host "[*] Creating entrypoint launchers..." -ForegroundColor Gray

# Batch launcher with elevation trigger
$batContent = @"
@echo off
:: Batch Entrypoint for WUBI-AI
setlocal
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File ".\src\gui\Launch-WubiAI-GUI.ps1"
exit /b
"@
Set-Content -Path $LauncherBat -Value $batContent -Encoding ASCII

# VBScript launcher to avoid flashing a black command prompt window
$vbsContent = @"
Set WshShell = CreateObject("WScript.Shell")
strPath = CreateObject("Scripting.FileSystemObject").GetParentFolderName(WScript.ScriptFullName)
WshShell.CurrentDirectory = strPath
WshShell.Run "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & strPath & "\src\gui\Launch-WubiAI-GUI.ps1""", 0, False
"@
Set-Content -Path $LauncherVbs -Value $vbsContent -Encoding ASCII

# 4. Helper Function: Create Desktop & Start Menu Shortcuts
function New-AppShortcut {
    param (
        [string]$Target,
        [string]$ShortcutPath,
        [string]$Description,
        [string]$WorkingDir,
        [string]$IconLocation
    )
    $WshShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut($ShortcutPath)
    $Shortcut.TargetPath = $Target
    $Shortcut.WorkingDirectory = $WorkingDir
    $Shortcut.WindowStyle = 1
    $Shortcut.Description = $Description
    if ($IconLocation -and (Test-Path $IconLocation)) {
        $Shortcut.IconLocation = $IconLocation
    } else {
        # Fallback to shell32 modern screen/disk icon
        $Shortcut.IconLocation = "$env:SystemRoot\System32\shell32.dll, 13"
    }
    $Shortcut.Save()
    Write-Host "[+] Shortcut created: $ShortcutPath" -ForegroundColor Green
}

# Create Shortcuts
$desktopPath = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::Desktop)
$desktopShortcut = Join-Path $desktopPath "WUBI-AI Installer.lnk"
New-AppShortcut -Target $LauncherBat -ShortcutPath $desktopShortcut -Description "Ubuntu & Omarchy AI Installer (Zero-Destruction)" -WorkingDir $BinDir

# 5. Standalone Self-Extractor / Setup Script (Setup.ps1 inside package)
$setupPkgScript = @"
<#
.SYNOPSIS
    Self-Installer for WUBI-AI Tools into Program Files or Local AppData
#>
`$installTarget = "`$env:LOCALAPPDATA\WUBI-AI"
Write-Host "Installing WUBI-AI to `$installTarget..." -ForegroundColor Cyan
if (-not (Test-Path `$installTarget)) {
    New-Item -ItemType Directory -Path `$installTarget -Force | Out-Null
}
Copy-Item -Path "`$PSScriptRoot\*" -Destination `$installTarget -Recurse -Force

# Create Desktop Shortcut
`$WshShell = New-Object -ComObject WScript.Shell
`$desktop = [System.Environment]::GetFolderPath('Desktop')
`$shortcut = `$WshShell.CreateShortcut("`$desktop\WUBI-AI Installer.lnk")
`$shortcut.TargetPath = "`$installTarget\Launch-WubiAI.bat"
`$shortcut.WorkingDirectory = `$installTarget
`$shortcut.IconLocation = "`$env:SystemRoot\System32\shell32.dll, 13"
`$shortcut.Save()
Write-Host "Installation Complete! Launch WUBI-AI from your Desktop shortcut." -ForegroundColor Green
"@
Set-Content -Path (Join-Path $BinDir "Setup.ps1") -Value $setupPkgScript -Encoding UTF8

# 6. Compress Distribution into .ZIP
Write-Host "[*] Compressing distribution package into ZIP archive..." -ForegroundColor Gray
$zipOutput = Join-Path $DistDir "WUBI-AI-v1.0.0-Setup.zip"
Compress-Archive -Path "$BinDir\*" -DestinationPath $zipOutput -Force
Write-Host "[+] Distribution archive generated: $zipOutput" -ForegroundColor Green

Write-Host "`n=================================================" -ForegroundColor Green
Write-Host " Package Distribution Successfully Generated!    " -ForegroundColor Green
Write-Host " Distribution Folder : $DistDir                  " -ForegroundColor Green
Write-Host " Release Archive     : $zipOutput                " -ForegroundColor Green
Write-Host " Desktop Shortcut    : $desktopShortcut          " -ForegroundColor Green
Write-Host "=================================================" -ForegroundColor Green
