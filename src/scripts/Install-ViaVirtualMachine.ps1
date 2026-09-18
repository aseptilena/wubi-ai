<#
.SYNOPSIS
    Installs Ubuntu and Omarchy AI into a VHDX using Virtualization (QEMU/Hyper-V),
    injects the V2P loopback initramfs hook, and prepares for Bare-Metal Native Boot.
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false)]
    [string]$TargetDrive = "D:",

    [Parameter(Mandatory=$false)]
    [int]$VhdSizeGB = 64,

    [Parameter(Mandatory=$false)]
    [string]$UbuntuIsoPath = "",

    [Parameter(Mandatory=$false)]
    [switch]$AutoRunQemu
)

$ErrorActionPreference = "Stop"

$InstallDir = Join-Path $TargetDrive "ubuntu-ai"
$VhdPath    = Join-Path $InstallDir "root.vhdx"

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host " WUBI-AI: Virtual-to-Physical (V2P) Installation Pipeline       " -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

# 0. Helper Functions for QEMU Detection & Provisioning
function Get-QemuExecutablePath {
    $candidates = @(
        "qemu-system-x86_64.exe",
        "C:\Program Files\qemu\qemu-system-x86_64.exe",
        "C:\Program Files (x86)\qemu\qemu-system-x86_64.exe",
        "$env:LOCALAPPDATA\Programs\qemu\qemu-system-x86_64.exe"
    )
    foreach ($c in $candidates) {
        if ($c -eq "qemu-system-x86_64.exe") {
            $cmd = Get-Command "qemu-system-x86_64.exe" -ErrorAction SilentlyContinue
            if ($cmd) { return $cmd.Source }
        } else {
            if (Test-Path $c) { return $c }
        }
    }
    return $null
}

function Install-QemuEngine {
    Write-Host "[*] QEMU tidak ditemukan. Memeriksa winget..." -ForegroundColor Yellow
    $winget = Get-Command "winget.exe" -ErrorAction SilentlyContinue
    if ($winget) {
        Write-Host "[*] Memasang QEMU via Windows Package Manager (winget)..." -ForegroundColor Cyan
        & winget install SoftwareFreedomConservancy.QEMU --accept-source-agreements --accept-package-agreements
        return (Get-QemuExecutablePath)
    } else {
        Write-Host "[!] Winget tidak tersedia. Silakan unduh QEMU dari: https://qemu.weilnetz.de/w64/" -ForegroundColor Red
        return $null
    }
}

# 1. Ensure Target Directory
if (-not (Test-Path $InstallDir)) {
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $InstallDir "boot") -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $InstallDir "grub") -Force | Out-Null
}

# 2. Check Virtualization Engines
$hasHyperV = $false
try {
    $hvService = Get-Service -Name "vmms" -ErrorAction SilentlyContinue
    if ($hvService -and $hvService.Status -eq "Running") { $hasHyperV = $true }
} catch {}

$qemuExe = Get-QemuExecutablePath
$hasQemu = [bool]$qemuExe

Write-Host "[*] Virtualization Engine Assessment:" -ForegroundColor Gray
Write-Host "    - Microsoft Hyper-V : $(if ($hasHyperV) { 'Available' } else { 'Not Detected / Inactive' })"
Write-Host "    - QEMU / KVM Engine : $(if ($hasQemu) { "Found ($qemuExe)" } else { 'Not Detected' })"

# 3. Write V2P Initramfs Hook Script (to be placed in /etc/initramfs-tools/scripts/local-top/vhdboot)
$hookContent = @'
#!/bin/sh
PREREQ=""
prereqs() { echo "$PREREQ"; }
case $1 in prereqs) prereqs; exit 0;; esac
. /scripts/functions

modprobe ntfs3 2>/dev/null || modprobe ntfs 2>/dev/null
modprobe loop

mkdir -p /host
for dev in $(blkid -t TYPE=ntfs -o device); do
    if mount -t ntfs3 -o ro "$dev" /host 2>/dev/null || mount -t ntfs -o ro "$dev" /host 2>/dev/null; then
        if [ -f /host/ubuntu-ai/root.vhdx ]; then
            HOST_DEV="$dev"
            break
        fi
        umount /host 2>/dev/null
    fi
done

if [ -n "$HOST_DEV" ]; then
    losetup -P /dev/loop0 /host/ubuntu-ai/root.vhdx
    mount /dev/loop0p1 ${rootmnt} 2>/dev/null || mount /dev/loop0 ${rootmnt}
fi
'@
Set-Content -Path (Join-Path $InstallDir "v2p-initramfs-hook.sh") -Value $hookContent -Encoding ASCII

# 4. Generate QEMU Launcher Script
$qemuLaunchBat = Join-Path $InstallDir "Launch-Qemu-Installer.bat"
$exeToRun = if ($qemuExe) { "`"$qemuExe`"" } else { "qemu-system-x86_64.exe" }
$qemuCmd = @"
@echo off
title WUBI-AI QEMU Virtual Installer
echo =========================================================
echo  WUBI-AI: Finalisasi Instalasi OS ke Virtual Drive
echo =========================================================
echo Target Container : $VhdPath
echo ISO Image        : $UbuntuIsoPath
echo.
$exeToRun -m 4096 -smp 4 -accel whpx -accel tcg -drive file="$VhdPath",format=vhdx,if=virtio -cdrom "$UbuntuIsoPath" -boot d -net nic,model=virtio -net user
exit /b
"@
Set-Content -Path $qemuLaunchBat -Value $qemuCmd -Encoding ASCII

Write-Host "`n[+] V2P Pipeline Assets Generated Successfully in $InstallDir :" -ForegroundColor Green
Write-Host "    - V2P Hook Script    : $(Join-Path $InstallDir 'v2p-initramfs-hook.sh')" -ForegroundColor Cyan
Write-Host "    - QEMU Launcher      : $qemuLaunchBat" -ForegroundColor Cyan

# 5. Automatically Run QEMU if requested
if ($AutoRunQemu) {
    if (-not $qemuExe) {
        $qemuExe = Install-QemuEngine
    }
    if ($qemuExe -and (Test-Path $UbuntuIsoPath)) {
        Write-Host "[*] Meluncurkan QEMU Virtual Machine Installer..." -ForegroundColor Green
        Start-Process -FilePath $qemuLaunchBat
    } elseif (-not (Test-Path $UbuntuIsoPath)) {
        Write-Host "[!] Berkas ISO belum tersedia di: $UbuntuIsoPath" -ForegroundColor Yellow
    }
}
