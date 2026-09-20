# AGENTS.md: Developer & AI Agent Guidelines for WUBI-AI

Dokumen ini merupakan panduan arsitektur, standar kode, tata kelola repositori, dan protokol eksekusi bagi AI agent (Claude, Antigravity, Gemini, Copilot) maupun human developer yang memelihara codebase **WUBI-AI**.

---

## 1. Project Philosophy & Core Invariants

1. **Zero-Destruction Policy (Absolute Safety Gate)**:
   - **DILARANG KERAS** menjalankan operasi repartisi disk fisik (`clean`, `delete partition`, `format` pada partisi Windows host, atau shrink volume paksa).
   - Seluruh instalasi OS Linux wajib diisolasi di dalam file disk container (`root.vhdx`).
   - Setiap operasi BCD wajib menyertakan backup sebelum modifikasi (`bcdedit /export`).
2. **Non-Invasive Bootloader**:
   - Pada UEFI: Gunakan duplikasi BCD WubiUEFI (`bcdedit /copy {bootmgr}`) dan salin payload shim ke EFI (`\EFI\ubuntu-ai\shimx64.efi`). Jangan timpa Windows Boot Manager default.
   - Pada Legacy BIOS: Gunakan application type `BOOTSECTOR` (`boot.bin`) tanpa memodifikasi MBR fisik host.
3. **Hardware & Architecture Adaptive**:
   - Skrip harus selalu mendukung hardware hybrid modern (contoh: Intel Core 12th/13th/14th Gen P-Core + E-Core).
   - Jalankan QEMU dengan instruksi CPU terisolasi `-cpu Skylake-Client-v4,-svm -vga virtio` untuk mencegah kernel panic (`exitcode=0x0000008b`).
4. **Auto-Synchronization Mandate**:
   - Setiap kali ada pembaruan pada modul di `src/`, WAJIB jalankan `Build-Distribution.ps1` dan `Create-DesktopShortcut.ps1` agar paket portable di `dist/` dan shortcut desktop selalu sinkron dengan versi master.

---

## 2. Directory Structure & Key Responsibilities

```text
D:\Project\WUBI-AI/
├── README.md                      # Dokumentasi publik utama repositori
├── AGENTS.md                      # Pedoman AI agent & developer workflow (file ini)
├── PRD_WUBI_AI.md                 # Product Requirement Document & Mockup UI
├── WALKTHROUGH.md                 # Dokumentasi pengujian, arsitektur teknis & log
├── Launch-WubiAI.bat              # Entrypoint batch utama
├── .gitignore                     # Proteksi ISO (>500MB), VHD, dan file rilis zip
├── config/
│   └── grub.cfg.template          # Template konfigurasi GRUB WUBI-AI loopback
├── dist/
│   ├── WUBI-AI-Package/           # Bundle aplikasi portable siap pakai
│   └── WUBI-AI-v1.0.0-Setup.zip   # Arsip zip release
├── src/
│   ├── gui/
│   │   └── Launch-WubiAI-GUI.ps1  # WPF XAML Fluent Dark Mode GUI + Downloader
│   ├── scripts/
│   │   ├── Install-UbuntuOmarchy.ps1    # Core engine installer VHDX & BCD setup
│   │   ├── Install-ViaVirtualMachine.ps1# QEMU V2P pipeline launcher & hook injector
│   │   ├── Uninstall-UbuntuOmarchy.ps1  # Uninstaller bersih
│   │   ├── Build-Distribution.ps1       # Generator bundle rilis & zip builder
│   │   ├── Create-DesktopShortcut.ps1   # Pembuat shortcut desktop (-STA mode)
│   │   └── omarchy-provision.sh         # Skrip provision stack AI Linux (CUDA/ROCm)
│   └── wubiuefi-core/                   # Lupin loopback hook & kernel patches
└── tests/
    └── Test-PreflightChecks.ps1         # Test suite otomatis (Firmware, GPU, AST Parse)
```

---

## 3. Automation Protocol: The `doc-c-p` Workflow

Shortcut `doc-c-p` adalah akronim untuk:
> **Document, Clean Tests, Commit, and Push**

Saat perintah ini dipanggil atau disinggung, agent wajib menjalankan urutan berikut secara otomatis:
1. **Tests Hygiene**:
   - Pastikan `tests/Test-PreflightChecks.ps1` valid dan semua uji AST parser lolos (`10 Passed, 0 Failed`).
2. **Documentation Sync**:
   - Pastikan dokumentasi sinkron antara `README.md`, `WALKTHROUGH.md`, dan `AGENTS.md`.
3. **Build & Package**:
   - Jalankan `src/scripts/Build-Distribution.ps1` dan `src/scripts/Create-DesktopShortcut.ps1`.
4. **Git Commit & Push**:
   - Lakukan staging `git add .`.
   - Buat commit yang deskriptif dan terstruktur sesuai konvensi Conventional Commits (`feat:`, `fix:`, `docs:`).
   - Push ke branch aktif saat ini (`origin <current-branch>`).

---

## 4. Coding & PowerShell Guidelines

- **Encoding**: Selalu simpan file skrip PowerShell dalam format UTF-8 (atau ASCII yang kompatibel) tanpa BOM yang merusak parsing XAML.
- **WPF Execution**: Selalu jalankan GUI PowerShell dengan flag `-STA` (*Single-Threaded Apartment*).
- **Background Operations**: Selalu gunakan `Dispatcher.BeginInvoke` untuk memperbarui elemen WPF UI dari background thread/WebClient events.
- **Cache Integrity**: Selalu verifikasi ukuran file sebelum menggunakan berkas ISO di disk (`Length -gt 500MB`).
- **Syntax Verification**: Sebelum melakukan commit, selalu jalankan pengecekan AST:
  ```powershell
  [System.Management.Automation.Language.Parser]::ParseFile($filePath, [ref]$tokens, [ref]$errors)
  ```
