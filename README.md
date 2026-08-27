# BPS Oneliner-Script (BGEN Print Service)

BPS Oneliner-Script adalah solusi otomatisasi untuk menginstal dan menjalankan **BPS Print Service** (aplikasi .NET berbasis Windows) di lingkungan Linux menggunakan **Wine**. Script ini dirancang agar dapat mendeteksi distribusi Linux secara otomatis, menginstal dependensi yang diperlukan, melakukan konfigurasi otomatis, dan mengatur agar aplikasi berjalan saat startup (autostart).

---

## 🚀 Cara Instalasi (Oneliner Script)

Anda hanya perlu menjalankan satu baris perintah berikut di terminal Linux Anda untuk mengkloning repositori dan menjalankan skrip instalasi secara otomatis:

```bash
git clone https://github.com/andin1st/bps-print-service.git && cd bps-print-service && sudo ./install.sh
```

---

## 🛠️ Apa yang Dilakukan oleh `install.sh` Secara Otomatis?

1. **Deteksi Distribusi Linux**: Mendeteksi distro yang Anda gunakan secara otomatis (Arch Linux, Debian, Ubuntu, Fedora, openSUSE).
2. **Instalasi Dependensi**: Menginstal Wine beserta komponen pendukung utama yang kritis untuk menjalankan aplikasi .NET:
   - `wine` (Base Wine)
   - `wine-mono` (.NET runtime untuk Wine)
   - `wine-gecko` (HTML engine untuk rendering)
3. **Penyalinan Berkas**: Memindahkan file aplikasi `BPS.exe` dan `appsettings.json` ke direktori lokal pengguna (`~/.local/share/bps/`).
4. **Membuat Launcher**: Menyediakan file eksekusi instan di `~/.local/bin/bps-run`.
5. **Inisialisasi Prefix Wine**: Menyiapkan lingkungan Wine agar siap menjalankan aplikasi .NET.
6. **Autostart**: Membuat entri desktop XDG sehingga BPS Print Service otomatis berjalan saat user melakukan login ke sistem.

---

## 📋 Struktur Repositori

```text
bps-print-service/
├── BPS.exe           # File eksekusi utama (aplikasi .NET ASP.NET Core Kestrel)
├── appsettings.json  # File konfigurasi aplikasi (termasuk PrinterName)
├── install.sh        # Script instalasi otomatis (memerlukan sudo)
├── run.sh            # Script launcher utama
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
  ```
