<#
.SYNOPSIS
    Automated pre-flight, syntax validation, and virtualization profiling for WUBI-AI.
#>

$ErrorActionPreference = "Stop"
$ProjectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")

Write-Host "=================================================" -ForegroundColor Cyan
Write-Host " Running WUBI-AI Test Suite and Verification     " -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan

$passCount = 0
$failCount = 0

function Assert-Check {
    param(
        [string]$Title,
        [bool]$Condition,
        [string]$Detail = ""
    )
    if ($Condition) {
        $script:passCount++
        Write-Host " [PASS] $Title" -ForegroundColor Green
        if ($Detail) { Write-Host "        $Detail" -ForegroundColor Gray }
    } else {
        $script:failCount++
        Write-Host " [FAIL] $Title" -ForegroundColor Red
        if ($Detail) { Write-Host "        $Detail" -ForegroundColor Yellow }
    }
}

# 1. Firmware and Platform Assessment
try {
    $firmwareType = (Get-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control" -Name "PEFirmwareType" -ErrorAction SilentlyContinue).PEFirmwareType
    $fwName = if ($firmwareType -eq 2) { "UEFI Mode (GPT)" } else { "Legacy BIOS / MBR Mode" }
    Assert-Check "Firmware Detection" $true "Detected: $fwName"
} catch {
    Assert-Check "Firmware Detection" $false "Unable to read PEFirmwareType"
}

# 2. Storage and NTFS Partition Discovery
$volumes = Get-Volume | Where-Object { $_.DriveType -eq "Fixed" -and $_.FileSystem -eq "NTFS" -and $_.DriveLetter -ne $null }
$hasValidStorage = ($volumes -and $volumes.Count -gt 0)
Assert-Check "NTFS Fixed Storage Discovery" $hasValidStorage "$($volumes.Count) drive(s) eligible"
foreach ($v in $volumes) {
    $freeGB = [math]::Round($v.SizeRemaining / 1GB, 2)
    Write-Host "        - Drive $($v.DriveLetter): [Free: $freeGB GB | Label: '$($v.FileSystemLabel)']" -ForegroundColor Gray
}

# 3. GPU and Compute Acceleration Detection
$gpus = Get-CimInstance Win32_VideoController
Assert-Check "Compute Acceleration Discovery" ([bool]$gpus) "Found $($gpus.Count) GPU device(s)"
foreach ($gpu in $gpus) {
    Write-Host "        - GPU: $($gpu.Name) (Driver: $($gpu.DriverVersion))" -ForegroundColor Gray
}

# 4. QEMU Virtualization Engine Availability
$qemuCmd = Get-Command "qemu-system-x86_64.exe" -ErrorAction SilentlyContinue
$qemuStdPath = "C:\Program Files\qemu\qemu-system-x86_64.exe"
$hasQemu = [bool]$qemuCmd -or (Test-Path $qemuStdPath)
Assert-Check "QEMU Virtualization Engine" $hasQemu $(if ($hasQemu) { "Executable found" } else { "Not installed (Optional for V2P)" })

# 5. Core Asset Integrity and Syntax Validation
$scriptsToCheck = @(
    "src\gui\Launch-WubiAI-GUI.ps1",
    "src\scripts\Install-UbuntuOmarchy.ps1",
    "src\scripts\Install-ViaVirtualMachine.ps1",
    "src\scripts\Uninstall-UbuntuOmarchy.ps1",
    "src\scripts\Build-Distribution.ps1",
    "src\scripts\Create-DesktopShortcut.ps1"
)

foreach ($rel in $scriptsToCheck) {
    $fullPath = Join-Path $ProjectRoot $rel
    if (Test-Path $fullPath) {
        $tokens = $null
        $errors = $null
        [System.Management.Automation.Language.Parser]::ParseFile($fullPath, [ref]$tokens, [ref]$errors) | Out-Null
        $syntaxOk = ($errors.Count -eq 0)
        Assert-Check "Syntax Check: $rel" $syntaxOk $(if ($syntaxOk) { "AST Parse OK" } else { "$($errors.Count) syntax error(s)" })
    } else {
        Assert-Check "File Existence: $rel" $false "Missing file"
    }
}

Write-Host "`n-------------------------------------------------" -ForegroundColor Cyan
Write-Host " Test Summary: $passCount Passed, $failCount Failed" -ForegroundColor $(if ($failCount -eq 0) { "Green" } else { "Red" })
Write-Host "-------------------------------------------------" -ForegroundColor Cyan
if ($failCount -gt 0) { exit 1 }
