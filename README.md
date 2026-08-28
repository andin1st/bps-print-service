# BPS Oneliner-Script (BGEN Print Service) - Version 7

BPS Oneliner-Script adalah solusi otomatisasi untuk menginstal dan menjalankan **BPS Print Service** (aplikasi .NET berbasis Windows) di lingkungan Linux menggunakan **Wine**. Script ini dirancang agar dapat mendeteksi distribusi Linux secara otomatis, menginstal dependensi yang diperlukan, melakukan konfigurasi otomatis, dan mengatur agar aplikasi berjalan saat startup (autostart).

---

## 🚀 Cara Instalasi (Oneliner Script)

Anda hanya perlu menjalankan satu baris perintah berikut di terminal Linux Anda untuk mengunduh dan menjalankan instalasi secara otomatis tanpa memerlukan instalasi Git:

```bash
curl -sSL https://raw.githubusercontent.com/andin1st/bps-print-service/main/install.sh | sudo bash
```

---

## 🛠️ Apa yang Dilakukan oleh `install.sh` Secara Otomatis?

1. **Deteksi Distribusi Linux**: Mendeteksi distro yang Anda gunakan secara otomatis (**Debian, Ubuntu, Linux Mint, Fedora, Arch Linux**).
2. **Instalasi Dependensi Khusus Distro (Safe APT-Get)**:
   - Di **Debian/Ubuntu/Linux Mint**: Menginstal `wine` dan `curl`. Paket `wine-mono` dan `wine-gecko` sengaja dikecualikan karena tidak tersedia di APT dan akan otomatis diunduh oleh Wine ke dalam prefix saat inisialisasi. Hal ini memperbaiki error `Unable to locate package` pada Linux Mint 21.
   - Di **Fedora**: Menginstal `wine`, `wine-mono`, `mingw32-wine-gecko`, dan `mingw64-wine-gecko`.
   - Di **Arch Linux**: Menginstal `wine`, `wine-mono`, dan `wine-gecko`.
3. **Penyalinan & Pengunduhan Berkas Bebas Masalah Izin**: Membuat folder aplikasi di `~/bps-print-service/` menggunakan identitas pengguna asli untuk menghindari kesalahan izin (*permission denied*).
4. **Instalasi Launcher Global**: Membuat script eksekusi di `/usr/local/bin/bps-run` sehingga dapat dipanggil secara langsung tanpa perlu melakukan `source` manual pada shell profil.
5. **Autostart**: Membuat entri desktop XDG sehingga BPS Print Service otomatis berjalan saat komputer menyala/login ke lingkungan desktop.

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
