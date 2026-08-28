# BPS Oneliner-Script (BGEN Print Service) - Version 9

BPS Oneliner-Script adalah solusi otomatisasi untuk menginstal dan menjalankan **BPS Print Service** (aplikasi .NET berbasis Windows) di lingkungan Linux menggunakan **Wine**. 

Versi 9 ini menghadirkan peningkatan besar pada aspek kompatibilitas dengan **secara otomatis memasang WineHQ Stable (Wine 9.0+)** pada distribusi berbasis Debian, Ubuntu, dan Linux Mint. Langkah ini terbukti sukses **mengatasi error `page fault` (crash instan)** yang kerap ditemui pada Wine versi lama (seperti bawaan Ubuntu/Mint versi 6.0.3).

Selain itu, versi ini menggunakan arsitektur **Systemd User Service** untuk memastikan kestabilan tinggi, otomatis menyala saat komputer dinyalakan, dan mencegah masalah sistem Linux gantung (stuck) saat shutdown.

---

## 🚀 Cara Instalasi (Oneliner Script)

Anda hanya perlu menjalankan satu baris perintah berikut di terminal Linux Anda untuk menginstal dan mengonfigurasi segalanya secara otomatis:

```bash
curl -sSL https://raw.githubusercontent.com/andin1st/bps-print-service/main/install.sh | sudo bash
```

*Catatan: Metode instalasi berbasis `curl` ini menghilangkan ketergantungan terhadap Git pada sisi klien dan mencegah kerusakan file biner `BPS.exe` akibat masalah pembacaan pointer Git LFS.*

---

## 🛠️ Apa yang Dilakukan oleh `install.sh` Secara Otomatis?

1. **Deteksi Distribusi Linux**: Mendeteksi distribusi OS secara otomatis (Arch Linux, Debian, Ubuntu, Fedora, Linux Mint 21).
2. **Pemasangan WineHQ Stable (Wine 9.0+) secara Otomatis**: 
   - Pada **Debian/Ubuntu/Mint**, skrip akan mengaktifkan arsitektur 32-bit, mengimpor kunci GPG WineHQ, mendeteksi codename OS secara dinamis, menambahkan repositori resmi WineHQ, dan memasang paket `winehq-stable` (Wine 9.0+). Ini menjamin fungsionalitas .NET modern berjalan stabil tanpa crash.
   - Pada **Fedora dan Arch Linux**, skrip akan memasang Wine terbaru langsung dari repositori resmi distro yang sudah diperbarui.
3. **Download Mandiri Bebas Corrupt**: Mengunduh `BPS.exe` (90 MB) secara aman langsung dari **GitHub Releases** dan file konfigurasi `appsettings.json` langsung ke folder `~/bps-print-service/`.
4. **Integrasi Systemd User Service**: Mendaftarkan `BPS.exe` sebagai layanan Systemd pengguna (`bps.service`). Ini memastikan:
   - Aplikasi otomatis menyala di latar belakang saat komputer menyala/login.
   - **Shutdown Aman**: Systemd menjamin penutupan proses secara bersih tanpa menahan atau membuat sistem gantung saat shutdown.
   - **Auto-restart**: Jika aplikasi mengalami crash tak terduga, Systemd akan langsung menghidupkannya kembali dalam waktu 5 s.
5. **Membuat Executable Global Manager**: Menyediakan file `/usr/local/bin/bps-run` yang bertindak sebagai manager service interaktif. Anda bisa langsung memakainya seketika setelah instalasi selesai **tanpa perlu memanggil `source ~/.bashrc`** atau membuka terminal baru!

---

## 📋 Struktur Repositori Terinstal (`~/bps-print-service`)

```text
~/bps-print-service/
├── BPS.exe           # File eksekusi utama (.NET Core)
└── appsettings.json  # File konfigurasi printer (PrinterName)
```

---\n\n## ⚙️ Cara Penggunaan & Perintah Dasar

Setelah instalasi berhasil, Anda dapat mengelola layanan BPS menggunakan perintah mudah di terminal:

### 1. Menjalankan Layanan Sekarang
```bash
bps-run start
```

### 2. Menghentikan Layanan
```bash
bps-run stop
```

### 3. Memuat Ulang Layanan (Restart)
```bash
bps-run restart
```

### 4. Memeriksa Status Layanan
```bash
bps-run status
```

### 5. Memantau Log Aktivitas Cetak
```bash
bps-run log
```

### 6. Menghapus Instalasi (Uninstall)
Jika Anda ingin menghapus BPS dari sistem secara bersih, jalankan script uninstall berikut dari folder repositori:
```bash
sudo ./uninstall.sh
```

---

## 🔧 Konfigurasi Printer & Font Mandiri

### 1. Mengatur Printer (CUPS)
Pastikan driver printer Anda sudah terpasang dan terkonfigurasi dengan baik di **CUPS** pada mesin target. Setelah itu, perbarui nama printer pada file konfigurasi:
- Lokasi konfigurasi setelah instalasi: `~/bps-print-service/appsettings.json`
- Ubah parameter `\"PrinterName\"` sesuai nama printer Anda di sistem Linux.

### 2. Memperbaiki Font Kotak-kotak (Manual)
Untuk menghindari dialog persetujuan lisensi (EULA) Microsoft yang kerap membuat instalasi otomatis terhenti (*stuck*), instalasi font Microsoft ditiadakan dari skrip otomatis. 

Jika kertas print mengeluarkan karakter kotak-kotak atau rendering font rusak, Anda dapat memasang paket font Microsoft secara manual menggunakan perintah:
* **Debian/Ubuntu/Linux Mint**: `sudo apt install ttf-mscorefonts-installer` (setujui lisensi yang muncul di layar).
* **Fedora**: `sudo dnf install mscorefonts2`

---

## 📦 Mengunggah Berkas BPS.exe ke GitHub Releases (Developer Only)

Agar tautan pengunduhan biner `BPS.exe` bekerja sempurna bagi seluruh klien Anda, Anda **harus** mengunggah berkas `BPS.exe` biner asli Anda ke halaman Rilis:

1. Buka halaman repositori Anda di browser.
2. Klik menu **Releases** di sisi kanan, lalu pilih **Create a new release**.
3. Beri nama tag versi (misal: `v1.0.0`) dan jadikan sebagai rilis terbaru (*Latest Release*).
4. Di bagian pengunggahan berkas, seret dan taruh file **`BPS.exe` (90 MB)** Anda sebagai **Assets**, lalu klik **Publish release**.
