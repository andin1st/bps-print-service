# BPS Oneliner-Script (BGEN Print Service) - Version 6

BPS Oneliner-Script adalah solusi otomatisasi untuk menginstal dan menjalankan **BPS Print Service** (aplikasi .NET berbasis Windows) di lingkungan Linux menggunakan **Wine**. Script ini dirancang agar dapat mendeteksi distribusi Linux secara otomatis, menginstal dependensi yang diperlukan, melakukan konfigurasi otomatis, dan mengatur agar aplikasi berjalan secara otomatis saat sistem operasi dinyalakan (*autostart*).

---

## 🚀 Cara Instalasi (Oneliner Script)

Klien Anda tidak perlu menginstal Git atau melakukan kloning manual. Mereka cukup menjalankan perintah satu baris (*oneliner*) berikut di terminal Linux mereka untuk mengunduh dan menjalankan proses instalasi secara instan:

```bash
curl -sSL https://raw.githubusercontent.com/andin1st/bps-print-service/main/install.sh | sudo bash
```

---

## 🛠️ Apa yang Dilakukan oleh `install.sh` Secara Otomatis?

1. **Deteksi Distribusi Linux**: Mendeteksi distro yang Anda gunakan secara otomatis (Arch Linux, Debian, Ubuntu, Fedora).
2. **Instalasi Dependensi**: Menginstal Wine beserta komponen pendukung utama yang kritis untuk menjalankan aplikasi .NET (`wine`, `wine-mono`, dan `wine-gecko` khusus distro).
3. **Pengunduhan Biner via Curl**: Mengunduh berkas biner `BPS.exe` (90 MB) secara aman langsung dari **GitHub Releases** dan file `appsettings.json` ke direktori home pengguna (`~/bps-print-service/`). Ini 100% aman dari risiko kerusakan file biner akibat Git LFS.
4. **Membuat Wrapper Global**: Menyediakan file eksekusi instan di `/usr/local/bin/bps-run`. Hal ini memungkinkan klien untuk **langsung menggunakan perintah `bps-run`** setelah instalasi selesai tanpa perlu memuat ulang terminal (*source ~/.bashrc*).
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

Meskipun sistem akan otomatis berjalan saat komputer menyala, Anda tetap bisa mengelolanya secara manual:

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
BPS merupakan layanan cetak berbasis jaringan. Pastikan driver printer Anda sudah terpasang dan terkonfigurasi dengan baik di **CUPS** pada mesin target. Setelah itu, perbarui nama printer pada file konfigurasi:
- Lokasi konfigurasi setelah instalasi: `~/bps-print-service/appsettings.json`
- Ubah parameter `\"PrinterName\"` sesuai nama printer Anda di sistem Linux.

### 2. Port Jaringan
Aplikasi ini secara bawaan membuka Kestrel endpoint pada port:
`http://localhost:64209`
Pastikan port ini tidak diblokir oleh firewall dan tidak sedang digunakan oleh aplikasi lain.

---

## 📦 Panduan untuk Developer (Mengunggah BPS.exe ke GitHub)

File `BPS.exe` memiliki ukuran sekitar **90 MB**. Agar skrip instalasi otomatis di atas berfungsi bagi klien Anda, Anda harus mengunggah berkas tersebut ke bagian **GitHub Releases**:

1. Masuk ke repositori GitHub Anda di browser: `https://github.com/andin1st/bps-print-service`
2. Klik **Releases** di sisi kanan, lalu pilih **Draft a new release**.
3. Beri tag versi baru (misalnya `v1.0.0`) dan buat rilis baru.
4. Pada kolom **Attach binaries by dropping them here**, seret dan unggah berkas **`BPS.exe`** Anda yang berukuran 90 MB tersebut.
5. Klik **Publish release**.
6. Dorong (*push*) berkas `install.sh` (dari berkas `install-v6.sh` yang Anda unduh) dan `appsettings.json` ke cabang utama (*main branch*) repositori Anda.
