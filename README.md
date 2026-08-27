# BPS Oneliner-Script (BGEN Print Service) - Clean Edition

BPS Oneliner-Script adalah skrip otomatisasi bersih dan minimalis untuk mendeteksi distribusi Linux, menginstal dependensi Wine yang diperlukan, serta menambahkan alias sistem agar aplikasi **BPS Print Service** dapat dijalankan dengan mudah menggunakan perintah `bps-run`.

---

## 🚀 Cara Instalasi (Oneliner Script)

Jalankan perintah satu baris berikut di terminal Linux Anda dari direktori home (`~`):

```bash
git clone https://github.com/andin1st/bps-print-service.git && cd bps-print-service && sudo ./install.sh
```

---

## 🛠️ Apa yang Dilakukan oleh `install.sh`?

1. **Deteksi Distribusi & Pasang Dependensi**:
   - Skrip mendeteksi sistem operasi (Debian/Ubuntu, Fedora, Arch Linux) secara otomatis.
   - Memasang paket `wine`, `wine-mono`, dan versi `wine-gecko` yang tepat secara otomatis sesuai distro target (termasuk paket khusus `mingw` di Fedora).
2. **Konfigurasi Alias Otomatis**:
   - Menambahkan alias `bps-run` ke berkas konfigurasi shell Anda (`.bashrc` dan/atau `.zshrc`) milik pengguna non-root.
   - Alias tersebut terdaftar dengan perintah:
     `alias bps-run="DISPLAY=:0 nohup wine ~/bps-print-service/BPS.exe > /tmp/bps.log 2>&1 &"`

---

## ⚙️ Cara Penggunaan & Perintah Dasar

Setelah instalasi selesai, silakan **muat ulang** sesi terminal Anda atau jalankan:
```bash
source ~/.bashrc  # Jika Anda menggunakan Bash
source ~/.zshrc   # Jika Anda menggunakan Zsh
```

### Menjalankan Layanan
```bash
bps-run
```

### Menghentikan Layanan
```bash
pkill -f BPS.exe
```

### Memantau Log Aktivitas
```bash
tail -f /tmp/bps.log
```

---

## 📦 Penggunaan Git LFS (Rekomendasi Developer)
Karena `BPS.exe` memiliki ukuran berkas yang cukup besar (~90 MB), pastikan Anda telah mengaktifkan **Git LFS** di repositori Anda sebelum melakukan push agar menghindari kegagalan upload:
```bash
git lfs install
git lfs track "BPS.exe"
git add .gitattributes
git add -A
git commit -m "init: setup git lfs"
git push origin main
```
