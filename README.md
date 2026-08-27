# BPS Oneliner-Script (BGEN Print Service)

BPS Oneliner-Script adalah solusi otomatisasi untuk menginstal dan menjalankan **BPS Print Service** (aplikasi .NET berbasis Windows) di lingkungan Linux menggunakan **Wine**. Script ini dirancang agar dapat mendeteksi distribusi Linux secara otomatis, menginstal dependensi yang diperlukan, melakukan konfigurasi otomatis, dan mengatur agar aplikasi berjalan secara otomatis saat sistem operasi dinyalakan (_autostart_).

---

## 🚀 Cara Instalasi (Oneliner Script)

User/IT Ops tidak perlu menginstal Git atau melakukan kloning manual. Mereka cukup menjalankan perintah satu baris (_oneliner_) berikut di terminal Linux mereka untuk mengunduh dan menjalankan proses instalasi secara instan:

```bash
curl -sSL https://raw.githubusercontent.com/andin1st/bps-print-service/main/install.sh | sudo bash
```

---

## 🛠️ Apa yang Dilakukan oleh `install.sh` Secara Otomatis?

1. **Deteksi Distribusi Linux**: Mendeteksi distro yang User gunakan secara otomatis (Arch Linux, Debian, Ubuntu, Fedora).
2. **Instalasi Dependensi**: Menginstal Wine beserta komponen pendukung utama yang kritis untuk menjalankan aplikasi .NET (`wine`, `wine-mono`, dan `wine-gecko` khusus distro).
3. **Pengunduhan Biner via Curl**: Mengunduh berkas biner `BPS.exe` (90 MB) secara aman langsung dari **GitHub Releases** dan file `appsettings.json` ke direktori home pengguna (`~/bps-print-service/`). Ini 100% aman dari risiko kerusakan file biner akibat Git LFS.
4. **Membuat Wrapper Global**: Menyediakan file eksekusi instan di `/usr/local/bin/bps-run`. Hal ini memungkinkan klien untuk **langsung menggunakan perintah `bps-run`** setelah instalasi selesai tanpa perlu memuat ulang terminal (_source ~/.bashrc_).
5. **Autostart Otomatis (Tanpa Terminal)**: Membuat file entri desktop XDG di `~/.config/autostart/bps-print-service.desktop` sehingga layanan BPS Print Service **otomatis berjalan di latar belakang saat komputer dinyalakan/masuk ke desktop**. Klien sama sekali tidak perlu berinteraksi dengan terminal lagi setelah proses instalasi selesai!
6. **Inisialisasi Prefix Wine**: Menyiapkan lingkungan Wine agar siap menjalankan aplikasi .NET.

---

## 📋 Struktur Direktori Target

Setelah instalasi selesai, berkas akan ditempatkan di:

```text
~/bps-print-service/
├── BPS.exe           # File eksekusi utama (aplikasi .NET ASP.NET Core Kestrel)
└── appsettings.json  # File konfigurasi printer & jaringan
```

---

## ⚙️ Cara Penggunaan & Perintah Dasar

Meskipun sistem akan otomatis berjalan saat komputer menyala, User tetap bisa mengelolanya secara manual:

### Menjalankan Aplikasi Secara Manual

```bash
bps-run
```

### Menghentikan Layanan

```bash
pkill -f BPS.exe
```

---

## 🔧 Konfigurasi Printer & Port

### 1. Mengatur Printer (CUPS)

BPS merupakan layanan cetak berbasis jaringan. Pastikan driver printer User sudah terpasang dan terkonfigurasi dengan baik di **CUPS** pada mesin target. Setelah itu, perbarui nama printer pada file konfigurasi:

- Lokasi konfigurasi setelah instalasi: `~/bps-print-service/appsettings.json`
- Ubah parameter `\"PrinterName\"` sesuai nama printer User di sistem Linux.

### 2. Port Jaringan

Aplikasi ini secara bawaan membuka Kestrel endpoint pada port:
`http://localhost:64209`
Pastikan port ini tidak diblokir oleh firewall dan tidak sedang digunakan oleh aplikasi lain.

### 3. Font (Opsional)

Jika teks atau karakter cetak pada printer muncul sebagai kotak-kotak (render error), pasang font Microsoft Core Fonts di sistem User:

- **Debian/Ubuntu**: `sudo apt install ttf-mscorefonts-installer`

---
