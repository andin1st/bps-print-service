# BPS Oneliner-Script (BGEN Print Service) - Version 11

BPS Oneliner-Script adalah solusi otomatisasi untuk menginstal dan menjalankan **BPS Print Service** (aplikasi .NET berbasis Windows) di lingkungan Linux menggunakan **Wine**. 

Versi terbaru ini menggunakan arsitektur **Systemd User Service** untuk memastikan kestabilan tinggi, otomatis menyala saat komputer dinyalakan, dan yang paling penting **mengatasi masalah sistem Linux gantung (stuck) saat shutdown** yang disebabkan oleh proses emulasi Wine di latar belakang.

---

## 🚀 Cara Instalasi (Oneliner Script)

Anda hanya perlu menjalankan satu baris perintah berikut di terminal Linux Anda untuk menginstal dan mengonfigurasi segalanya secara otomatis:

```bash
curl -sSL https://raw.githubusercontent.com/andin1st/BPS/main/install.sh | sudo bash
```

*Catatan: Jika Anda menggunakan repositori dengan nama lain, cukup sesuaikan nama repositorinya pada URL raw di atas.*

---

## 🛠️ Apa yang Diperbaiki pada Versi Ini?

1. **Resolusi Error 404 pada Linux Mint 21**:
   Mengoreksi logika deteksi sistem operasi. Pada versi sebelumnya, Linux Mint 21 (yang memiliki basis Ubuntu Jammy) salah terdeteksi sebagai Debian murni. Hal ini menyebabkan skrip mencari repositori WineHQ di:
   `https://dl.winehq.org/wine-builds/debian/dists/jammy/...` (yang menghasilkan error 404).
   Skrip terbaru secara cerdas mendeteksi Linux Mint dan mengarahkannya dengan benar ke repositori resmi Ubuntu:
   `https://dl.winehq.org/wine-builds/ubuntu/dists/jammy/...` (100% Valid & Sukses).

2. **Dukungan WineHQ Stable (Wine 9.0+) Otomatis**:
   Mengupgrade secara otomatis versi Wine bawaan distro yang terlalu usang (seperti `wine-6.0.3` bawaan Mint/Ubuntu lama) ke versi stabil terbaru untuk mencegah crash `page fault` (null pointer crash) saat mengeksekusi aplikasi .NET Core.

3. **Autostart & Pencegahan Shutdown Gantung**:
   Mendaftarkan `BPS.exe` sebagai **Systemd User Service** (`bps.service`). Ini memastikan:
   - Aplikasi otomatis menyala di latar belakang setiap kali komputer dinyalakan/login.
   - **Shutdown Aman**: Systemd menjamin penutupan proses secara bersih tanpa menahan atau membuat sistem operasi gantung (stuck) saat shutdown.

4. **Instalasi Mandiri Bebas Corrupt**:
   Mengunduh `BPS.exe` (90 MB) secara aman langsung dari **GitHub Releases** dan file konfigurasi `appsettings.json` langsung ke folder `~/bps-print-service/`. Langkah ini 100% aman dari risiko kerusakan berkas biner akibat kesalahan pembacaan pointer Git LFS.

5. **Pengecualian Paket Font (Bebas dari Masalah Stuck)**:
   Seluruh baris kode penginstalan paket `ttf-mscorefonts-installer` telah dihapus sepenuhnya dari skrip otomatis untuk mencegah dialog persetujuan lisensi (EULA) Microsoft yang kerap membuat instalasi otomatis terhenti (*stuck*). Klien dapat memasangnya sendiri secara manual jika diperlukan.

---

## 📋 Struktur Repositori Terinstal (`~/bps-print-service`)

```text
~/bps-print-service/
├── BPS.exe           # File eksekusi utama (.NET Core)
└── appsettings.json  # File konfigurasi printer (PrinterName)
```

---

## ⚙️ Cara Penggunaan & Perintah Dasar

Setelah instalasi berhasil, Anda dapat mengelola layanan BPS menggunakan perintah mudah di terminal:

### 1. Menjalankan Layanan Sekarang
```bash
bps-run start
```

### 2. Menghentikan Layanan
```bash
bps-run stop
```

### 3. Memeriksa Status Layanan
```bash
bps-run status
```

### 4. Memantau Log Aktivitas Cetak
```bash
bps-run log
```

### 5. Menghapus Instalasi (Uninstall)
Jika Anda ingin menghapus BPS dari sistem secara bersih, jalankan script uninstall berikut dari folder repositori:
```bash
sudo ./uninstall.sh
```

---

## 🔧 Konfigurasi Printer & Font Mandiri

### 1. Mengatur Printer (CUPS)
Pastikan driver printer Anda sudah terpasang dan terkonfigurasi dengan baik di **CUPS** pada mesin target. Setelah itu, perbarui nama printer pada file konfigurasi:
- Lokasi konfigurasi setelah instalasi: `~/bps-print-service/appsettings.json`
- Ubah parameter `"PrinterName"` sesuai nama printer Anda di sistem Linux.

### 2. Memperbaiki Font Kotak-kotak (Manual)
Jika kertas print mengeluarkan karakter kotak-kotak atau rendering font rusak, Anda dapat memasang paket font Microsoft secara manual menggunakan perintah:
* **Debian/Ubuntu/Linux Mint**: `sudo apt install ttf-mscorefonts-installer` (setujui lisensi yang muncul di layar).
* **Fedora**: `sudo dnf install mscorefonts2`
