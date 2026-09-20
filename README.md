# WUBI-AI: Non-Destructive Windows-Based Ubuntu Flavor & Omarchy AI Workstation Installer

[![GitHub License](https://img.shields.io/badge/license-GPLv2%20%2F%20MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Windows%2010%20%7C%2011-0078D6.svg)](https://www.microsoft.com/windows)
[![Architecture](https://img.shields.io/badge/architecture-x86__64-orange.svg)]()
[![Zero-Destruction Policy](https://img.shields.io/badge/Safety-Zero--Destruction%20Policy-10B981.svg)]()

**WUBI-AI** adalah installer sistem operasi modern untuk Windows yang mengadopsi filosofi Wubi (*Windows-based Ubuntu Installer*) dan WubiUEFI, namun didesain khusus untuk era Generative AI & Deep Learning. 

Installer ini memungkinkan developer, data scientist, pelajar, dan AI enthusiast memasang **Ubuntu 24.04 LTS (dan seluruh varian/flavor resmi)** beserta lingkungan **Omarchy AI Workstation** langsung di partisi Windows (C:, D:, dsb.) **tanpa memformat, tanpa mengecilkan (*shrink*) partisi, dan tanpa risiko kehilangan data (*Zero-Destruction Policy*)**.

---

## 🌟 Fitur Utama

### 1. Zero-Destruction Guarantee (Keamanan Mutlak)
- **100% Bebas Repartisi**: Seluruh sistem operasi Linux berjalan dari dalam 1 berkas kontainer virtual disk tunggal (oot.vhdx).
- **Pilihan Partisi Bebas**: Mendukung partisi NTFS mana pun (misal D:\ubuntu-ai\ atau E:\ubuntu-ai\), tidak memaksakan partisi sistem C:\.
- **Bootloader Aman**: 
  - Pada **UEFI**, menggunakan metode duplikasi bootloader WubiUEFI (cdedit /copy {bootmgr}) tanpa mengotori atau menghapus EFI bootloader bawaan Windows.
  - Pada **Legacy BIOS / MBR**, menggunakan chainload bootsector (oot.bin) tanpa menyentuh Master Boot Record fisik disk.
- **Clean Uninstallation**: Uninstaller 1-klik yang membersihkan entri BCD dan menghapus kontainer tanpa meninggalkan residu di sistem Windows.

### 2. Dual-Pipeline Deployment Engine
WUBI-AI menyediakan 2 mode instalasi sesuai kebutuhan:
1. **Direct VHDX Loopback (Bare-Metal)**:
   - Menyiapkan kontainer VHDX dan konfigurasi bootloader secara instan.
   - Booting langsung memanfaatkan hook lupin-vhd initramfs untuk performa hardware 100% (I/O, GPU, dan CPU native).
2. **Virtual-to-Physical (V2P via QEMU Installer)**:
   - Terintegrasi langsung dengan QEMU VM.
   - Mengunduh ISO dan langsung mem-boot installer grafis Linux di dalam VM QEMU untuk memformat dan menginstal OS ke dalam file oot.vhdx.
   - Begitu selesai, kontainer oot.vhdx tersebut dapat langsung di-booting secara fisik (*bare-metal*) dari Windows Boot Manager!

### 3. In-App Multi-Flavor Auto-Downloader
WUBI-AI memiliki modul download latar belakang berkecepatan tinggi dengan validasi integritas (TLS 1.2/1.3, progress tracking MB/s, auto-resume, dan proteksi partial download corrupt):
- **Ubuntu 24.04 LTS Desktop (Standard)** — GNOME Desktop resmi lengkap.
- **Ubuntu 24.04 Minimal / Server** — Headless, super hemat RAM/VRAM untuk inferensi AI maksimal (vLLM, Ollama).
- **Lubuntu 24.04 LTS** — Ultra-ringan berbasis LXQt, sangat responsif.
- **Xubuntu 24.04 LTS & Minimal** — Desktop XFCE yang stabil dan ringan.
- **Kubuntu 24.04 LTS** — Desktop modern berbasis KDE Plasma.
- **Ubuntu MATE, Budgie, Cinnamon, Studio, Unity, Edubuntu, & Kylin**.

### 4. Omarchy AI Workstation Stack Pre-Configuration
Dapat memilih stack AI yang otomatis disiapkan pada first-boot:
- **PyTorch (Hardware Accelerated)**: Dukungan otomatis deteksi NVIDIA CUDA 12.4, AMD ROCm 6.1, atau CPU AVX-512.
- **vLLM Inference Engine**: Engine inferensi LLM throughput tinggi dengan PagedAttention.
- **Ollama Daemon**: Manajemen dan eksekusi model open-source lokal (Port 11434).
- **Gradio WebUI**: Antarmuka interaktif siap pakai (Port 7860).

### 5. Kompatibilitas Hardware Modern (Termasuk Intel Generasi 13/14+)
- Skrip peluncur QEMU telah dioptimasi dengan arsitektur CPU -cpu Skylake-Client-v4,-svm -vga virtio untuk mencegah masalah *Kernel Panic* (exitcode=0x0000008b) pada prosesor hybrid (Intel P-Cores & E-Cores).

---

## 🖥️ Struktur Direktori Proyek

```text
WUBI-AI/
├── README.md                      # Dokumentasi publik utama repositori
├── AGENTS.md                      # Pedoman AI Agent & developer workflow (doc-c-p)
├── PRD_WUBI_AI.md                 # Product Requirement Document komprehensif
├── WALKTHROUGH.md                 # Dokumentasi alur pengujian & verifikasi
├── Launch-WubiAI.bat              # Entrypoint batch utama
├── .gitignore                     # Proteksi eksklusi file ISO & VHDX besar
├── config/
│   └── grub.cfg.template          # Template konfigurasi GRUB WUBI-AI
├── dist/
│   ├── WUBI-AI-Package/           # Paket aplikasi mandiri (portable)
│   └── WUBI-AI-v1.0.0-Setup.zip   # Arsip rilis siap distribusi
├── src/
│   ├── gui/
│   │   └── Launch-WubiAI-GUI.ps1  # Antarmuka WPF XAML Fluent Dark Mode
│   ├── scripts/
│   │   ├── Install-UbuntuOmarchy.ps1    # Core engine instalasi & konfigurasi BCD
│   │   ├── Install-ViaVirtualMachine.ps1# Pipeline integrasi QEMU V2P
│   │   ├── Uninstall-UbuntuOmarchy.ps1  # Script uninstaller bersih
│   │   ├── Build-Distribution.ps1       # Script pembuat paket rilis otomatis
│   │   ├── Create-DesktopShortcut.ps1   # Script pembuat pintasan desktop
│   │   └── omarchy-provision.sh         # Script otomatisasi stack AI Linux
│   └── wubiuefi-core/                   # Hook Lupin & kernel patch WubiUEFI
└── tests/
    └── Test-PreflightChecks.ps1         # Script pengujian otomatis (Dry-Run)
```

---

## 🚀 Panduan Penggunaan

### Prasyarat Sistem
- **Sistem Operasi**: Windows 10 (64-bit) atau Windows 11.
- **Storage**: Partisi NTFS dengan sisa ruang minimal **35 GB - 64 GB** (Disarankan Drive non-sistem seperti D: atau E:).
- **Hak Akses**: Administrator (WUBI-AI akan otomatis meminta elevasi saat mendaftarkan bootloader).
- **Virtualisasi (Opsional untuk Mode V2P)**: QEMU (winget install SoftwareFreedomConservancy.QEMU).

### Menjalankan WUBI-AI
1. Clone repositori ini atau download arsip rilis:
   `cmd
   git clone https://github.com/aseptilena/wubi-ai.git
   cd wubi-ai
   `
2. Jalankan launcher utama:
   - Dobel klik file Launch-WubiAI.bat, atau
   - Jalankan dari PowerShell:
     `powershell
     powershell.exe -ExecutionPolicy Bypass -STA -File src\gui\Launch-WubiAI-GUI.ps1
     `

### Alur Instalasi:
1. **Pilih Distro**: Tentukan edisi Ubuntu yang diinginkan (misal: *Lubuntu 24.04 LTS* atau *Ubuntu Minimal*).
2. **Pilih Target Drive**: Pilih huruf partisi (misal: D:).
3. **Alokasi Kapasitas**: Geser slider kapasitas oot.vhdx (default 64 GB).
4. **Pilih Mode Pipeline**:
   - Pilih **Virtual-to-Physical (V2P via QEMU / Hyper-V VM)** untuk instalasi interaktif via mesin virtual.
   - Klik **⚡ Auto-Download** jika belum memiliki berkas ISO.
5. **Klik Install AI OS (Safe)**:
   - Sistem akan menyiapkan berkas kontainer virtual disk dan mendaftarkan chainloader BCD secara aman.
   - QEMU VM akan langsung diluncurkan.
   - Pada layar QEMU, pilih **Try or Install**, lalu jalankan installer desktop dengan memilih disk virtual /dev/vda.
6. **Reboot ke Bare-Metal**:
   - Setelah instalasi di QEMU tuntas, tutup QEMU.
   - Restart PC Anda dan pilih **Ubuntu 24.04 LTS (Omarchy AI Workstation)** pada menu startup Windows!

---

## 🛠️ Uninstalasi (Pembersihan Bersih)
Jika Anda ingin menghapus sistem Ubuntu dan mengembalikan Windows Boot Manager ke kondisi default:
1. Buka WUBI-AI GUI.
2. Klik tombol **Clean Uninstall** di pojok kiri bawah.
3. Konfirmasi dialog:
   - Pilih apakah ingin melepas entri bootloader saja, atau
   - Menghapus folder kontainer (D:\ubuntu-ai\) beserta seluruh isinya secara permanen.
4. Sistem Windows Anda kembali 100% seperti semula tanpa sisa partisi.

---

## 📜 Lisensi & Penghargaan
- **Wubi & WubiUEFI**: Berdasarkan arsitektur open-source dari [hakuna-m/wubiuefi](https://github.com/hakuna-m/wubiuefi) dan tim Ubuntu Wubi.
- **Omarchy AI**: Dikembangkan untuk integrasi native stack AI Workstation.
- Didistribusikan di bawah lisensi GPLv2 / MIT.
