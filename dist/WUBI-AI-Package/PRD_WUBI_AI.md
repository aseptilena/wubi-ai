# Product Requirement Document (PRD)
## WUBI-AI: Non-Destructive Windows-Based Ubuntu & Omarchy AI Workstation Installer

---

### 1. Executive Summary & Vision

**WUBI-AI** adalah installer sistem operasi AI modern untuk Windows yang mengadopsi filosofi Wubi (*Windows-based Ubuntu Installer*), namun didesain khusus untuk kebutuhan era GenAI / Deep Learning. Installer ini memungkinkan developer, data scientist, dan AI enthusiast memasang **Ubuntu 24.04 LTS native** beserta stack framework **Omarchy AI** langsung di dalam drive Windows yang ada **tanpa partisi ulang, tanpa shrink disk, dan tanpa risiko menghapus data Windows (Zero-Destruction Policy)**.

---

### 2. User Personas & Problem Statement

| Persona | Pain Points | Solusi WUBI-AI |
| :--- | :--- | :--- |
| **AI / ML Engineer** | WSL2 memiliki keterbatasan I/O, IPC latency, overhead virtualisasi GPU, dan keterbatasan low-level kernel driver. | Menjalankan Linux langsung di *bare-metal* (native kernel) memanfaatkan VHDX loopback boot dengan performa hardware 100%. |
| **Student / Hobbyist** | Takut partisi Windows terhapus (*accidental format*) atau bootloader Windows rusak saat install dual-boot tradisional. | Tidak ada manipulasi tabel partisi (MBR/GPT). OS tersimpan rapi dalam 1 file disk container (`root.vhdx`). |
| **Corporate / Enterprise Dev** | Laptop kerja Windows terkunci kebijakan IT, tidak boleh re-partition disk fisik. | Cukup taruh file VHD di partisi `D:\` atau `E:\` dan hapus kapan saja lewat menu uninstaller resmi. |

---

### 3. Visual UI Mockup (Best-Practice Fluent Design)

Desain UI mengadopsi standar **Windows 11 Fluent Design / Mica Material** dengan dark mode, tipografi modern, kartu deteksi hardware otomatis, dan kontrol partisi yang intuitif.

![WUBI-AI Installer Setup UI](C:\Users\ASUS\.gemini\antigravity\brain\82a1d865-0f23-4bc0-afc6-8017122fd90f\wubi_ai_installer_mockup_1789319453857.jpg)

---

### 4. System Architecture & Flow

```mermaid
flowchart TD
    A[Launch WUBI-AI Setup.exe / GUI] --> B[Hardware & Drive Pre-flight Check]
    B --> C{Detect Fixed NTFS Drives}
    C -->|Space >= 64GB| D[User Selects Target Drive e.g. D: & Allocates Size]
    C -->|Insufficient Space| E[Show Warning & Recommendations]
    D --> F[Auto-Detect GPU: NVIDIA / AMD / Intel / CPU]
    F --> G[Click 'Install AI OS (Zero Data Loss)']
    G --> H[Create Dynamic root.vhdx via diskpart]
    H --> I[Deploy Rootfs Base & Inject Lupin/VHD initramfs Hook]
    I --> J[Write Isolated Bootloader in X:\ubuntu-ai\boot]
    J --> K[Safely Register New BCD Entry with bcdedit]
    K --> L[Installation Complete: Prompt for Reboot]
    L --> M[Reboot -> Windows Boot Menu -> Ubuntu 24.04 Omarchy AI]
```

---

### 5. Functional Requirements (FR)

#### FR-1: Drive Discovery & User Selection
- Sistem **dilarang memaksakan** drive `C:\`.
- Sistem wajib memindai seluruh *fixed storage* (NTFS) yang tersedia, menampilkan:
  - Huruf drive (`C:`, `D:`, `E:`, dll.)
  - Label volume & Tipe Media (SSD NVMe / SATA)
  - Kapasitas total & Sisa *free space* yang valid.
- Memberikan slider dinamis untuk kapasitas disk container (`root.vhdx`), default: **64 GB**, rentang: **40 GB – 256 GB**.

#### FR-2: Zero-Destruction Guarantee (Safety Gates)
- **TIDAK** menjalankan perintah `format`, `clean`, atau `shrink` pada volume fisik Windows yang ada.
- Menghasilkan backup file BCD secara otomatis ke `$env:SystemDrive\BCD_Backup_<timestamp>.bcd` sebelum melakukan perubahan bootloader.
- Menjaga Windows Boot Manager sebagai bootloader utama (default), dengan menu timeout 5–10 detik.

#### FR-3: Automated Hardware & GPU Compute Profiling
- Mendeteksi Vendor ID & Model GPU pada host Windows sebelum instalasi (via WMI/DirectX API):
  - **NVIDIA**: Otomatis memilih driver Linux proprietary + CUDA 12.x + cuDNN + Container Toolkit.
  - **AMD**: Otomatis memilih ROCm + HIP runtime stack.
  - **Intel / CPU**: Mengaktifkan fallback ke AVX-512 / OpenVINO / oneAPI.

#### FR-4: Omarchy AI Stack Integration
- Menjaga integritas repositori `apt` resmi Ubuntu 24.04 LTS (Noble Numbat) beserta dukungan `snap`.
- Pre-konfigurasi *ready-to-use* saat first boot:
  - Environment Python 3.11/3.12 terisolasi di `/opt/omarchy/venv`.
  - PyTorch + FlashAttention + vLLM terpasang sesuai arsitektur GPU.
  - Runtime service **Ollama** diaktifkan otomatis di background (`port 11434`).
  - Web UI Dashboard Omarchy di port `7860` untuk memonitor utilitas VRAM dan manajemen model LLM.

#### FR-5: 1-Click Clean Uninstaller
- Menyediakan utilitas uninstaller yang:
  1. Menghapus entri GUID spesifik WUBI-AI dari Windows BCD store (`bcdedit /delete {GUID}`).
  2. Menghapus folder tunggal target (`X:\ubuntu-ai\`).
  3. Memastikan tidak ada jejak boot residual pada host Windows.

---

### 6. Non-Functional Requirements (NFR)

| Kategori | Spesifikasi |
| :--- | :--- |
| **Performance** | Menggunakan format VHDX *expandable* untuk menghemat ruang disk host (hanya memakan storage sesuai data aktual yang ditulis). Akses I/O bare-metal mendekati 97-99% native disk speed. |
| **Compatibility** | Mendukung firmware **UEFI Class 2/3 (Secure Boot enabled)** dan **Legacy BIOS / CSM**. |
| **Reliability** | *Fail-safe atomic operation*: Jika pembuatan VHD atau ekstraksi gagal di tengah jalan, script membatalkan proses dan menghapus file sementara secara otomatis. |
| **Security** | Payload EFI menggunakan stand-alone signed GRUB binary yang kompatibel dengan Microsoft Third-Party UEFI Certificate Authority. |

---

### 7. UX & UI Interaction Specifications

1. **State 1: Initial Launch (Pre-flight Inspection)**
   - Dialog memverifikasi hak akses Administrator. Jika belum elevasi, trigger UAC prompt.
   - Status bar menampilkan: *"Checking system firmware... UEFI Detected. Secure Boot: Supported."*
2. **State 2: Setup Configuration**
   - Dropdown pilihan partisi drive: Drive dengan kapasitas sisa terbesar otomatis dijadikan rekomendasi awal (default terpilih).
   - Chip info hardware: Badge hijau/cyan menampilkan GPU yang terdeteksi secara realtime.
   - Checkbox seleksi modul AI: PyTorch, vLLM, Ollama, Gradio WebUI.
3. **State 3: Progress & Extraction**
   - Progress bar multi-tahap:
     - [1/4] *Allocating disk image container...*
     - [2/4] *Unpacking Ubuntu 24.04 base rootfs...*
     - [3/4] *Injecting Omarchy AI bootstrap unit...*
     - [4/4] *Registering Windows Dual-Boot entry...*
4. **State 4: Complete Screen**
   - Kartu sukses dengan tombol: **"Reboot Now"** dan **"Finish Later"**.
