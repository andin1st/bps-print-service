# BPS Oneliner-Script (BGEN Print Service) - Version 6

BPS Oneliner-Script adalah solusi otomatisasi untuk menginstal dan menjalankan **BPS Print Service** (aplikasi .NET berbasis Windows) di lingkungan Linux menggunakan **Wine**. Script ini dirancang agar dapat mendeteksi distribusi Linux secara otomatis, menginstal dependensi yang diperlukan, melakukan konfigurasi otomatis, dan mengatur agar aplikasi berjalan secara instan.

---

## 🚀 Cara Instalasi Instan (Oneliner Script)

Klien Anda **tidak perlu menginstal Git** atau menjalankan perintah `source` setelah instalasi. Mereka cukup menyalin dan menjalankan perintah satu baris (oneliner) berikut di terminal Linux mereka:

```bash
curl -sSL https://raw.githubusercontent.com/andin1st/bps-print-service/main/install.sh | sudo bash
```

---

## 🛠️ Apa yang Dilakukan oleh `install.sh` Secara Otomatis?

1. **Deteksi Distribusi Linux**: Mendeteksi distro yang Anda gunakan secara otomatis (Arch Linux, Debian, Ubuntu, Fedora).
2. **Instalasi Dependensi Khusus Distro**: Menginstal Wine beserta komponen pendukung utama yang kritis untuk menjalankan aplikasi .NET:
   - `wine` (Base Wine)
   - `wine-mono` (.NET runtime untuk Wine)
   - Di **Fedora**: menginstal paket `mingw32-wine-gecko` dan `mingw64-wine-gecko` secara otomatis.
   - Di **Debian/Ubuntu**: menginstal `wine-gecko` standar.
3. **Instalasi Command Global Tanpa Perlu `source`**: 
   - Skrip membuat berkas pembungkus (*wrapper binary*) secara otomatis di direktori sistem **`/usr/local/bin/bps-run`**.
   - Karena `/usr/local/bin` secara bawaan sudah ada di dalam jalur pencarian aplikasi sistem (`$PATH`), klien Anda bisa **langsung memanggil perintah `bps-run` saat itu juga di terminal aktif mereka setelah instalasi selesai** tanpa perlu mengetikkan `source ~/.bashrc`!
4. **Registrasi Alias Cadangan**: Skrip tetap mendaftarkan alias cadangan di dalam file `.bashrc` dan `.zshrc` untuk memastikan kompatibilitas jangka panjang.

---

## 📋 Struktur Repositori

```text
bps-print-service/
├── BPS.exe           # File eksekusi utama (diunggah melalui GitHub Releases)
├── appsettings.json  # File konfigurasi aplikasi (termasuk PrinterName)
├── install.sh        # Script instalasi otomatis (diunduh lewat curl)
└── .gitignore        # Mengabaikan file log dan backup lokal
```

---

## ⚙️ Cara Penggunaan & Perintah Dasar

Setelah instalasi selesai, Anda bisa langsung mengelola layanan BPS menggunakan perintah-perintah berikut dari direktori mana saja:

### Menjalankan Aplikasi Sekarang (Instan!)
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
