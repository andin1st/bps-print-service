# BPS Oneliner-Script (BGEN Print Service) - Curl-Based Setup

BPS Oneliner-Script adalah solusi otomatisasi untuk menginstal dan menjalankan **BPS Print Service** (aplikasi .NET berbasis Windows) di lingkungan Linux menggunakan **Wine**.

Versi terbaru ini menggunakan **`curl`** alih-alih `git clone` untuk proses instalasi yang lebih lancar, bebas dari ketergantungan Git LFS yang rawan membuat file biner `.exe` menjadi rusak (*corrupt*), serta memudahkan klien yang tidak memasang Git di komputer mereka.

---

## 🚀 Cara Instalasi Klien (Oneliner Script via Curl)

Klien hanya perlu menyalin dan menjalankan perintah satu baris berikut di terminal Linux mereka. Perintah ini akan mengunduh skrip instalasi secara otomatis dan mengonfigurasi seluruh sistem:

```bash
curl -sSL https://raw.githubusercontent.com/andin1st/bps-print-service/main/install.sh | sudo bash
```

*Catatan: Setelah proses instalasi selesai, muat ulang konfigurasi terminal Anda dengan perintah `source ~/.bashrc` atau `source ~/.zshrc` agar perintah instan `bps-run` aktif.*

---

## 🛠️ Cara Kerja Skrip Pemasangan Baru

1. **Deteksi & Pemasangan Dependensi Otomatis**: 
   Skrip mendeteksi sistem operasi (Fedora, Debian, Ubuntu, Arch) dan memasang paket Wine, Wine-Mono, Wine-Gecko, serta Curl yang kompatibel.
2. **Unduhan Bersih Langsung dari GitHub Releases**:
   Menggunakan `curl` untuk mengunduh berkas biner asli `BPS.exe` (90 MB) langsung dari **GitHub Releases** dan berkas konfigurasi `appsettings.json` langsung dari repositori utama. Langkah ini mengeliminasi masalah *corrupt file* yang sering terjadi akibat pengunduhan parser pointer Git LFS.
3. **Konfigurasi Alias `bps-run` Otomatis**:
   Skrip mendaftarkan perintah alias yang aman di bagian bawah berkas `.bashrc` atau `.zshrc` milik pengguna asli:
   ```bash
   alias bps-run="cd \$HOME/bps-print-service && DISPLAY=:0 nohup wine BPS.exe > /tmp/bps.log 2>&1 &"
   ```
   *Keunggulan:* Alias ini otomatis berpindah direktori (*cd*) ke folder aplikasi sebelum memanggil Wine sehingga ASP.NET Core Kestrel dapat membaca file `appsettings.json` yang berada tepat di sebelahnya secara tepat.

---

## ⚙️ Cara Penggunaan & Perintah Dasar

### Menjalankan Layanan Printer
Cukup jalankan perintah alias berikut dari direktori mana pun:
```bash
bps-run
```

### Menghentikan Layanan Printer
```bash
pkill -f BPS.exe
```

### Memantau Aktivitas Server Kestrel / Wine
```bash
tail -f /tmp/bps.log
```

---

## ⚠️ Panduan Kritis untuk Pengembang (Developer Setup)

Karena skrip ini mengunduh `BPS.exe` langsung dari fungsionalitas GitHub Releases, Anda sebagai pengembang wajib mempersiapkan hal-hal berikut agar tautan unduhan klien bekerja dengan sempurna:

1. **Unggah `install.sh`**:
   Unggah berkas `install.sh` (unduhan dari panel Studio) dan `appsettings.json` ke cabang utama (*main branch*) repositori GitHub Anda di `https://github.com/andin1st/bps-print-service`.
2. **Buat Release Baru**:
   Buka halaman repositori Anda di browser, klik tab **Releases** -> **Create a new release**.
3. **Unggah Berkas BPS.exe**:
   Tulis tag versi (misal: `v1.0.0` atau langsung publikasikan sebagai rilis terbaru) dan unggah berkas asli **`BPS.exe`** Anda (90 MB) sebagai bagian dari **Assets** rilis tersebut.
   *Skrip instalasi akan otomatis membaca rilis terbaru Anda lewat tautan pengarah `.../releases/latest/download/BPS.exe`*.
