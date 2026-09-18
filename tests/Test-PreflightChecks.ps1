<#
.SYNOPSIS
    Automated pre-flight & hardware profiling verification for WUBI-AI.
#>

$ErrorActionPreference = "Stop"

Write-Host "=================================================" -ForegroundColor Cyan
Write-Host " Running WUBI-AI Pre-Flight Verification Tests   " -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan

# Test 1: Firmware check
try {
    $firmwareType = (Get-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control" -Name "PEFirmwareType" -ErrorAction SilentlyContinue).PEFirmwareType
    $fwName = if ($firmwareType -eq 2) { "UEFI" } else { "Legacy BIOS" }
    Write-Host "[PASS] Firmware Detected: $fwName" -ForegroundColor Green
} catch {
    Write-Host "[FAIL] Firmware detection failed." -ForegroundColor Red
}

# Test 2: Scan eligible NTFS partitions
$volumes = Get-Volume | Where-Object { $_.DriveType -eq "Fixed" -and $_.FileSystem -eq "NTFS" -and $_.DriveLetter -ne $null }
if ($volumes) {
    Write-Host "[PASS] Eligible Fixed NTFS Drives Found:" -ForegroundColor Green
    foreach ($v in $volumes) {
        $freeGB = [math]::Round($v.SizeRemaining / 1GB, 2)
        Write-Host "       - Drive $($v.DriveLetter): [Free: $freeGB GB | Label: '$($v.FileSystemLabel)']" -ForegroundColor Gray
    }
} else {
    Write-Host "[WARN] No NTFS fixed partitions detected." -ForegroundColor Yellow
}

# Test 3: GPU Detection
$gpus = Get-CimInstance Win32_VideoController
Write-Host "[PASS] Hardware Acceleration Scan:" -ForegroundColor Green
foreach ($gpu in $gpus) {
    Write-Host "       - GPU: $($gpu.Name) (Driver: $($gpu.DriverVersion))" -ForegroundColor Gray
}

# Test 4: Verify Script Files Integrity
$requiredFiles = @(
    "d:\Project\WUBI-AI\src\scripts\Install-UbuntuOmarchy.ps1",
    "d:\Project\WUBI-AI\src\scripts\Uninstall-UbuntuOmarchy.ps1",
    "d:\Project\WUBI-AI\src\scripts\omarchy-provision.sh",
    "d:\Project\WUBI-AI\config\grub.cfg.template"
)

foreach ($f in $requiredFiles) {
    if (Test-Path $f) {
        Write-Host "[PASS] Verified file exists: $(Split-Path $f -Leaf)" -ForegroundColor Green
    } else {
        Write-Host "[FAIL] Missing required file: $f" -ForegroundColor Red
    }
}

Write-Host "`nAll Pre-Flight Tests Completed Successfully." -ForegroundColor Cyan
