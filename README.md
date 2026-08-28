# BPS Oneliner-Script (BGEN Print Service) - Version 7 (Mint/Ubuntu Fixed)

BPS Oneliner-Script adalah solusi otomatisasi untuk menginstal dan menjalankan **BPS Print Service** (aplikasi .NET berbasis Windows) di lingkungan Linux menggunakan **Wine**. Script ini dirancang agar dapat mendeteksi distribusi Linux secara otomatis, menginstal dependensi yang diperlukan, melakukan konfigurasi otomatis, dan mengatur agar aplikasi berjalan saat startup (autostart).

---

## 🚀 Cara Instalasi (Oneliner Script)

Anda hanya perlu menjalankan satu baris perintah berikut di terminal Linux Anda. Tidak perlu mengunduh repositori menggunakan Git clone lagi, skrip ini akan mengurus pengunduhan berkas yang aman menggunakan **curl** langsung dari repositori publik Anda:

```bash
curl -sSL https://raw.githubusercontent.com/andin1st/bps-print-service/main/install.sh | sudo bash
```

---

## 🛠️ Apa yang Dilakukan oleh `install.sh` Secara Otomatis?

1. **Deteksi Distribusi Linux**: Mendeteksi distro yang Anda gunakan secara otomatis (Arch Linux, Debian, Ubuntu, Fedora, Linux Mint, dll.).
2. **Instalasi Dependensi Cerdas**: Menginstal Wine beserta komponen pendukung utama yang kritis:
   - Di **Fedora**: menginstal `wine`, `wine-mono`, `mingw32-wine-gecko`, `mingw64-wine-gecko`, dan `curl`.
   - Di **Debian/Ubuntu/Linux Mint**: menginstal `wine` dan `curl` (menghindari error pencarian paket `wine-mono` atau `wine-gecko` di APT karena Debian/Ubuntu tidak menyediakan paket tersebut secara terpisah di repositori standar). Wine akan otomatis menanganinya secara aman.
   - Di **Arch Linux**: menginstal `wine`, `wine-mono`, `wine-gecko`, dan `curl`.
3. **Penyelesaian Masalah EULA Microsoft**: Menyuntikkan persetujuan lisensi EULA Microsoft (`ttf-mscorefonts-installer`) secara otomatis di latar belakang sebelum pemasangan, sehingga proses instalasi **tidak akan pernah stuck/gantung** menunggu konfirmasi interaktif pengguna.
4. **Penyalinan Berkas via Curl**: Memindahkan file aplikasi `BPS.exe` (90 MB) langsung dari **GitHub Releases** dan `appsettings.json` ke direktori lokal pengguna (`~/bps-print-service/`), menjamin file biner tidak rusak (*corrupt*) oleh penunjuk Git LFS.
5. **Membuat Wrapper Global Executable**: Menyediakan file eksekusi instan di `/usr/local/bin/bps-run` sehingga aplikasi **langsung bisa dipanggil seketika itu juga setelah instalasi selesai** tanpa perlu mengetikkan `source ~/.bashrc` atau membuka terminal baru.
6. **Inisialisasi Prefix Wine**: Menyiapkan lingkungan Wine agar siap menjalankan aplikasi .NET.
7. **Autostart saat Komputer Menyala**: Membuat entri desktop XDG sehingga BPS Print Service otomatis berjalan di latar belakang setiap kali pengguna masuk (*login*) ke sistem.

---

## 📋 Struktur Repositori

```text
bps-print-service/
├── BPS.exe           # File eksekusi utama (aplikasi .NET ASP.NET Core Kestrel)
├── appsettings.json  # File konfigurasi aplikasi (termasuk PrinterName)
├── install.sh        # Script instalasi otomatis (memerlukan sudo)
├── uninstall.sh      # Script untuk menghapus instalasi secara bersih
└── .gitignore        # Mengabaikan file log dan backup lokal
```

---

## ⚙️ Cara Penggunaan & Perintah Dasar

Setelah instalasi berhasil, Anda bisa mengelola layanan BPS menggunakan perintah-perintah berikut:

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

---

## 📦 Mengatasi Kendala Upload BPS.exe ke GitHub Releases

Karena ukuran file `BPS.exe` sebesar **90 MB**, dan skrip installer sekarang mengunduhnya langsung dari GitHub Releases agar biner tidak rusak/corrupt, developer harus memastikan file tersebut diunggah di bagian rilis:

1. Masuk ke halaman repositori Anda di browser.
2. Di panel kanan, klik **Releases** -> **Create a new release**.
3. Beri tag rilis (misal `v1.0.0`) dan unggah file `BPS.exe` asli Anda ke dalam kolom **Assets** di bagian bawah.
4. Klik **Publish release**.
