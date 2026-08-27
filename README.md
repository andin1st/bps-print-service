# BPS Oneliner-Script (BGEN Print Service) - Version 5 (Ultimate)

BPS Oneliner-Script adalah solusi otomatisasi untuk menginstal dan menjalankan **BPS Print Service** (aplikasi .NET berbasis Windows) di lingkungan Linux menggunakan **Wine**. Script ini dirancang agar dapat mengunduh berkas biner secara aman via `curl` tanpa bergantung pada sistem Git LFS yang rawan merusak berkas biner besar.

Script ini juga secara otomatis mengonfigurasi wrapper global `/usr/local/bin/bps-run` sehingga aplikasi dapat langsung dijalankan seketika setelah instalasi selesai **tanpa perlu melakukan reload shell atau mengetik `source`**.

---

## 🚀 Cara Instalasi (Oneliner Script)

Klien Anda tidak perlu lagi menginstal Git. Mereka cukup menjalankan perintah satu baris berikut di terminal Linux mereka:

```bash
curl -sSL https://raw.githubusercontent.com/andin1st/bps-print-service/main/install.sh | sudo bash
```

---

## 🛠️ Apa yang Dilakukan oleh `install.sh` Secara Otomatis?

1. **Deteksi Distribusi Linux**: Mendeteksi distro yang digunakan secara otomatis (Arch Linux, Debian, Ubuntu, Fedora).
2. **Instalasi Dependensi Khusus Distro**: Menginstal Wine beserta komponen pendukung utama yang kritis untuk menjalankan aplikasi .NET (`wine`, `wine-mono`, `wine-gecko`, dan `curl`).
3. **Pengunduhan Berkas via Curl**: Mengunduh berkas biner `BPS.exe` langsung dari GitHub Releases dan `appsettings.json` dari repositori utama Anda ke folder `~/bps-print-service/`. Langkah ini 100% aman dari masalah kerusakan berkas akibat transfer biner Git LFS.
4. **Membuat Wrapper Global Instant**: Menyediakan executable launcher di `/usr/local/bin/bps-run`. Karena direktori ini default di dalam `$PATH` Linux, klien bisa langsung mengetik `bps-run` secara instan setelah instalasi selesai.
5. **Inisialisasi Prefix Wine**: Menyiapkan lingkungan Wine agar siap menjalankan aplikasi .NET.

---

## 📋 Struktur Folder Aplikasi

```text
~/bps-print-service/
├── BPS.exe           # File eksekusi utama (aplikasi .NET ASP.NET Core Kestrel)
└── appsettings.json  # File konfigurasi aplikasi (termasuk PrinterName)
```

---

## ⚙️ Cara Penggunaan & Perintah Dasar

Setelah instalasi berhasil, Anda bisa mengelola layanan BPS menggunakan perintah-perintah berikut langsung dari direktori mana saja:

### Menjalankan Aplikasi Sekarang
```bash
bps-run
```

### Menghentikan Layanan
```bash
pkill -f BPS.exe
```

### Menghapus Instalasi (Uninstall)
Jika Anda ingin menghapus BPS dari sistem secara bersih, jalankan script uninstall dengan akses root:
```bash
sudo ./uninstall.sh
```

---

## 🔧 Konfigurasi Printer & Port

### 1. Mengatur Printer (CUPS)
BPS merupakan layanan cetak berbasis jaringan. Pastikan driver printer Anda sudah terpasang dan terkonfigurasi dengan baik di **CUPS** pada mesin target. Setelah itu, perbarui nama printer pada file konfigurasi:
- Lokasi konfigurasi setelah instalasi: `~/bps-print-service/appsettings.json`
- Ubah parameter `"PrinterName"` sesuai nama printer Anda di sistem Linux.

### 2. Port Jaringan
Aplikasi ini secara bawaan membuka Kestrel endpoint pada port:
`http://localhost:64209`
Pastikan port ini tidak diblokir oleh firewall dan tidak sedang digunakan oleh aplikasi lain.

### 3. Font (Opsional)
Jika teks atau karakter cetak pada printer muncul sebagai kotak-kotak (render error), pasang font Microsoft Core Fonts di sistem Anda:
- **Debian/Ubuntu**: `sudo apt install ttf-mscorefonts-installer`
