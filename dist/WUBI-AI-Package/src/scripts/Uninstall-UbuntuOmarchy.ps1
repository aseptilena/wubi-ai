<#
.SYNOPSIS
    Clean 1-Click Uninstaller for WUBI-AI.
#>

[CmdletBinding()]
param (
    [switch]$Force
)

$ErrorActionPreference = "Stop"
$BcdTitle      = "Ubuntu 24.04 LTS (Omarchy AI Workstation)"
$InstallFolder = "ubuntu-ai"

Write-Host "`n[WUBI-AI] Initiating Clean Uninstallation..." -ForegroundColor Yellow

# 1. Locate and remove BCD entry
$bcdEnum = bcdedit /enum all
$match = $bcdEnum | Select-String -Pattern "description\s+$([regex]::Escape($BcdTitle))" -Context 3,0

if ($match) {
    $idLine = $match.Context.PreContext | Select-String -Pattern "\{[a-f0-9\-]+\}"
    if ($idLine -match "(\{[a-f0-9\-]+\})") {
        $guid = $matches[1]
        Write-Host "[WUBI-AI] Removing BCD entry: $guid" -ForegroundColor Cyan
        & bcdedit /delete $guid /cleanup | Out-Null
        Write-Host "[WUBI-AI] BCD entry removed successfully." -ForegroundColor Green
    }
} else {
    Write-Host "[WUBI-AI] No BCD entry found matching '$BcdTitle'." -ForegroundColor Gray
}

# 2. Search and remove installation directory
$drives = Get-PSDrive -PSProvider FileSystem | Where-Object { Test-Path "$($_.Root)$InstallFolder" }
foreach ($d in $drives) {
    $targetPath = Join-Path $d.Root $InstallFolder
    $doDelete = $Force
    if (-not $doDelete) {
        $ans = Read-Host "Delete container folder '$targetPath'? (y/N)"
        if ($ans -match '^[yY]$') { $doDelete = $true }
    }
    if ($doDelete) {
        Remove-Item -Path $targetPath -Recurse -Force
        Write-Host "[WUBI-AI] Container folder deleted: $targetPath" -ForegroundColor Green
    }
}

Write-Host "[WUBI-AI] System cleanly restored to default Windows Boot Manager." -ForegroundColor Green
