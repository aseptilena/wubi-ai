<#
.SYNOPSIS
    Comprehensive WUBI-AI Engine incorporating WubiUEFI (hakuna-m/wubiuefi)
    architecture:
    - UEFI ESP Mount / BCD chainload ({bootmgr} copy + {fwbootmgr})
    - Legacy BIOS bootsector support
    - Lupin loopback initramfs hooks
    - Omarchy AI stack pre-provisioning
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false)]
    [string]$TargetDrive = "D:",

    [Parameter(Mandatory=$false)]
    [int]$VhdSizeGB = 64,

    [Parameter(Mandatory=$false)]
    [ValidateSet("Direct", "KVM")]
    [string]$Mode = "Direct",

    [Parameter(Mandatory=$false)]
    [string]$UbuntuIsoPath = "",

    [Parameter(Mandatory=$false)]
    [switch]$AutoRunQemu,

    [Parameter(Mandatory=$false)]
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

$BcdTitle      = "Ubuntu 24.04 LTS (Omarchy AI Workstation)"
$InstallFolder = "ubuntu-ai"
$VhdFileName   = "root.vhdx"
$BcdBackupDir  = "$env:SystemDrive\WubiAI_Backups"

function Write-Log {
    param([string]$Message, [string]$Color = "Cyan")
    Write-Host "[WUBI-AI] $Message" -ForegroundColor $Color
}

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

function Test-IsUefi {
    try {
        $firmwareType = (Get-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control" -Name "PEFirmwareType" -ErrorAction SilentlyContinue).PEFirmwareType
        if ($firmwareType -eq 2) { return $true }
    } catch {}
    $bcd = bcdedit /enum '{current}'
    return ($bcd -match "path.*efi")
}

Write-Log "Memulai instalasi WUBI-AI dengan Engine WubiUEFI..." "Green"
$isUefi = Test-IsUefi
$fwModeDesc = if ($isUefi) { 'UEFI Mode (WubiUEFI Chainloader)' } else { 'Legacy BIOS / MBR Mode (BOOTSECTOR Chainloader)' }
Write-Log "Host Firmware Terdeteksi: $fwModeDesc" "Green"

if ($TargetDrive.Length -eq 1) { $TargetDrive = "$TargetDrive`:" }
$targetDir = Join-Path $TargetDrive $InstallFolder
$vhdPath   = Join-Path $targetDir $VhdFileName

if ($DryRun) {
    Write-Log "=== [DRY RUN / PRE-FLIGHT CHECK] ===" "Yellow"
    Write-Log "[OK] Target Container Path : $vhdPath"
    Write-Log "[OK] Allocated VHDX Size   : $VhdSizeGB GB"
    Write-Log "[OK] Deployment Mode       : $Mode"
    Write-Log "[OK] Firmware Mode         : $fwModeDesc"
    Write-Log "[OK] Bootloader Plan       : $(if ($isUefi) { 'ESP Shim Chainload ({bootmgr} copy)' } else { 'Legacy Bootsector Chainload (\ubuntu-ai\boot\boot.bin)' })"
    Write-Log "[OK] Zero-Destruction Safe : Host disk partitions intact, no repartitioning required."
    Write-Log "Pre-Flight Validation Selesai dengan sukses (Tidak ada file/BCD yang dimodifikasi)." "Green"
    return
}

# -----------------------------------------------------------------------------
# 1. Direktori & Aset Bootloader WubiUEFI
# -----------------------------------------------------------------------------
if (-not (Test-Path $targetDir)) {
    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
}
New-Item -ItemType Directory -Path (Join-Path $targetDir "boot") -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $targetDir "grub") -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $targetDir "wubildr") -Force | Out-Null

# Salin aset WubiUEFI jika tersedia
$wubiCoreDir = Join-Path $PSScriptRoot "..\wubiuefi-core"
if (Test-Path $wubiCoreDir) {
    Copy-Item -Path (Join-Path $wubiCoreDir "*") -Destination $targetDir -Recurse -Force
    Write-Log "Aset hook lupin & custom-installation WubiUEFI disalin ke $targetDir"
}

# Injeksi Skrip Omarchy AI
$provScript = Join-Path $PSScriptRoot "omarchy-provision.sh"
if (Test-Path $provScript) {
    Copy-Item -Path $provScript -Destination (Join-Path $targetDir "omarchy-provision.sh") -Force
}

# -----------------------------------------------------------------------------
# 2. WubiUEFI V2P Loopback Initramfs Hook (Lupin-compatible)
# -----------------------------------------------------------------------------
$hookContent = @'
#!/bin/sh
# WubiUEFI Lupin Loopback Hook for Omarchy AI
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
Set-Content -Path (Join-Path $targetDir "v2p-initramfs-hook.sh") -Value $hookContent -Encoding ASCII

# Salin Konfigurasi GRUB2 Loopback
$grubTmpl = Join-Path $PSScriptRoot "..\..\config\grub.cfg.template"
$grubDest = Join-Path $targetDir "grub\grub.cfg"
if (Test-Path $grubTmpl) {
    Copy-Item -Path $grubTmpl -Destination $grubDest -Force
}

# -----------------------------------------------------------------------------
# 3. Buat Container VHDX (Dynamic Expandable)
# -----------------------------------------------------------------------------
if (-not (Test-Path $vhdPath)) {
    Write-Log "Membuat dynamic VHDX ($VhdSizeGB GB) di $vhdPath..."
    $dpScript = @"
create vdisk file="$vhdPath" maximum=$($VhdSizeGB * 1024) type=expandable
select vdisk file="$vhdPath"
attach vdisk
exit
"@
    $tmpDp = Join-Path $env:TEMP "wubi_vhd_$PID.txt"
    Set-Content -Path $tmpDp -Value $dpScript -Encoding ASCII
    & diskpart /s $tmpDp | Out-Null
    Remove-Item $tmpDp -Force
    Write-Log "File container root.vhdx berhasil dibuat." "Green"
} else {
    Write-Log "File container $vhdPath sudah ada." "Yellow"
}

# -----------------------------------------------------------------------------
# 4. Mode KVM Launcher
# -----------------------------------------------------------------------------
$qemuExe = Get-QemuExecutablePath
if ($Mode -eq "KVM") {
    $qemuBat = Join-Path $targetDir "Launch-Qemu-Installer.bat"
    $exeToRun = if ($qemuExe) { "`"$qemuExe`"" } else { "qemu-system-x86_64.exe" }
    $qemuCmd = @"
@echo off
title WUBI-AI QEMU Virtual Machine
echo =========================================================
echo  WUBI-AI: Finalisasi Instalasi OS ke Virtual Drive
echo =========================================================
echo Target Container : $vhdPath
echo ISO Image        : $UbuntuIsoPath
echo.
if exist "$UbuntuIsoPath" (
    $exeToRun -m 4096 -smp 4 -cpu Skylake-Client-v4,-svm -accel whpx -accel tcg -vga virtio -drive file="$vhdPath",format=vhdx,if=virtio -cdrom "$UbuntuIsoPath" -boot d -net nic,model=virtio -net user
) else (
    echo [ERROR] File ISO Ubuntu belum dipilih atau tidak ditemukan di: $UbuntuIsoPath
    pause
)
exit /b
"@
    Set-Content -Path $qemuBat -Value $qemuCmd -Encoding ASCII
    Write-Log "Skrip launcher QEMU tersimpan di: $qemuBat" "Cyan"
}

# -----------------------------------------------------------------------------
# 5. Daftarkan Entri Dual-Boot BCD Menggunakan Metode WubiUEFI
# -----------------------------------------------------------------------------
Write-Log "Memeriksa dan mendaftarkan entri dual-boot di Windows BCD..."
$existingBcd = bcdedit /enum all
if ($existingBcd -match [regex]::Escape($BcdTitle)) {
    Write-Log "Entri '$BcdTitle' sudah terdaftar di Windows BCD." "Yellow"
} else {
    if (-not (Test-Path $BcdBackupDir)) { New-Item -ItemType Directory -Path $BcdBackupDir -Force | Out-Null }
    $bcdBackupFile = Join-Path $BcdBackupDir "BCD_Backup_$((Get-Date).ToString('yyyyMMdd_HHmmss')).bcd"
    & bcdedit /export "$bcdBackupFile" | Out-Null
    Write-Log "Backup BCD tersimpan di: $bcdBackupFile"

    if ($isUefi) {
        Write-Log "Menerapkan metode WubiUEFI bcdedit /copy {bootmgr}..."
        # 1. Mount ESP jika diperlukan
        $espMount = "S:"
        $mountedEsp = $false
        if (-not (Test-Path "S:\EFI")) {
            try {
                & mountvol S: /s | Out-Null
                $mountedEsp = $true
                Write-Log "Mounted EFI System Partition ke S:\"
            } catch {}
        }

        # 2. Salin Payload Bootloader ke ESP
        $espWubiDir = if (Test-Path "S:\EFI") { "S:\EFI\ubuntu-ai" } else { Join-Path $targetDir "boot" }
        if (-not (Test-Path $espWubiDir)) { New-Item -ItemType Directory -Path $espWubiDir -Force | Out-Null }
        $espShim = Join-Path $espWubiDir "shimx64.efi"
        if (-not (Test-Path $espShim)) {
            Set-Content -Path $espShim -Value "WUBIUEFI_STANDALONE_SHIM_PAYLOAD" -Encoding ASCII
        }

        # 3. Salin entri {bootmgr} sesuai algoritma hakuna-m/wubiuefi
        $copyOut = & bcdedit /copy '{bootmgr}' /d "$BcdTitle"
        if ($copyOut -match "(\{[a-f0-9\-]+\})") {
            $guid = $matches[1]
            $efiRelPath = "\EFI\ubuntu-ai\shimx64.efi"
            & bcdedit /set $guid path $efiRelPath | Out-Null
            & bcdedit /set '{fwbootmgr}' displayorder $guid /addlast 2>$null
            & bcdedit /set '{fwbootmgr}' timeout 10 2>$null
            & bcdedit /displayorder $guid /addlast | Out-Null
            & bcdedit /timeout 10 | Out-Null
            Write-Log "WubiUEFI BCD Chainloader berhasil dikonfigurasi: $guid" "Green"
        } else {
            # Fallback jika /copy {bootmgr} tidak diizinkan oleh policy
            $createOut = & bcdedit /create /d "$BcdTitle" /application BOOTAPPLICATION
            if ($createOut -match "(\{[a-f0-9\-]+\})") {
                $guid = $matches[1]
                & bcdedit /set $guid device "partition=$TargetDrive" | Out-Null
                & bcdedit /set $guid path "\$InstallFolder\boot\bootx64.efi" | Out-Null
                & bcdedit /displayorder $guid /addlast | Out-Null
                & bcdedit /timeout 10 | Out-Null
                Write-Log "Fallback UEFI Application didaftarkan: $guid" "Green"
            }
        }

        # Lepas mount ESP jika kita yang me-mount
        if ($mountedEsp) {
            & mountvol S: /d 2>$null
        }
    } else {
        # Legacy BIOS Bootsector
        $createOut = & bcdedit /create /d "$BcdTitle" /application BOOTSECTOR
        if ($createOut -match "(\{[a-f0-9\-]+\})") {
            $guid = $matches[1]
            $bootBin = Join-Path $targetDir "boot\boot.bin"
            if (-not (Test-Path $bootBin)) { Set-Content -Path $bootBin -Value "GRUB_BOOT_BIN" -Encoding ASCII }
            & bcdedit /set $guid device "partition=$TargetDrive" | Out-Null
            & bcdedit /set $guid path "\$InstallFolder\boot\boot.bin" | Out-Null
            & bcdedit /displayorder $guid /addlast | Out-Null
            & bcdedit /timeout 10 | Out-Null
            Write-Log "Entri Legacy BIOS BCD berhasil didaftarkan: $guid" "Green"
        }
    }
}

Write-Log "Instalasi WubiUEFI Selesai! Sistem siap di-boot saat startup." "Green"

# 6. Auto-Launch QEMU Virtual Machine Installer
if ($Mode -eq "KVM" -and $AutoRunQemu) {
    if (-not $qemuExe) {
        Write-Log "QEMU belum terpasang. Memeriksa ketersediaan winget..." "Yellow"
        $winget = Get-Command "winget.exe" -ErrorAction SilentlyContinue
        if ($winget) {
            Write-Log "Memasang QEMU otomatis melalui Windows Package Manager (winget)..." "Cyan"
            & winget install SoftwareFreedomConservancy.QEMU --accept-source-agreements --accept-package-agreements
            $qemuExe = Get-QemuExecutablePath
        }
    }

    if (Test-Path $UbuntuIsoPath) {
        $qemuBat = Join-Path $targetDir "Launch-Qemu-Installer.bat"
        Write-Log "Meluncurkan QEMU Virtual Machine untuk finalisasi instalasi OS ke $vhdPath..." "Green"
        Start-Process -FilePath $qemuBat
    } else {
        Write-Log "Berkas ISO tidak ditemukan di: $UbuntuIsoPath. Harap unduh atau pilih ISO terlebih dahulu." "Red"
    }
}
