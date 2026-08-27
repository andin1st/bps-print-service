# BPS Oneliner-Script (BGEN Print Service)

BPS Oneliner-Script adalah solusi otomatisasi untuk menginstal dan menjalankan **BPS Print Service** (aplikasi .NET berbasis Windows) di lingkungan Linux menggunakan **Wine**. Script ini dirancang agar dapat mendeteksi distribusi Linux secara otomatis, menginstal dependensi yang diperlukan dengan aman, melakukan konfigurasi otomatis, dan mengatur agar aplikasi berjalan saat startup (autostart).

---

## 🚀 Cara Instalasi (Oneliner Script)

Anda hanya perlu menjalankan satu baris perintah berikut di terminal Linux Anda untuk mengkloning repositori dan menjalankan skrip instalasi secara otomatis:

```bash
git clone https://github.com/andin1st/bps-print-service.git && cd bps-print-service && sudo ./install.sh
```

---

## 🛠️ Apa yang Dilakukan oleh `install.sh` Secara Otomatis?

1. **Deteksi Distribusi Linux**: Mendeteksi distro yang Anda gunakan secara otomatis (Arch Linux, Debian, Ubuntu, Fedora).
2. **Instalasi Dependensi Cerdas**: Menginstal Wine beserta komponen pendukung utama yang kritis untuk menjalankan aplikasi .NET dengan penyesuaian otomatis per distro:
   - `wine` (Base Wine)
   - `wine-mono` (.NET runtime untuk Wine)
   - `wine-gecko` / `mingw-wine-gecko` (HTML engine untuk rendering yang disesuaikan secara khusus untuk Fedora maupun Ubuntu/Debian/Arch)
3. **Penyalinan Berkas Aman**: Memindahkan file aplikasi `BPS.exe` dan `appsettings.json` ke direktori lokal pengguna asli (`~/.local/share/bps/`) menggunakan hak akses pengguna biasa, mencegah masalah _permission denied_.
4. **Membuat Launcher**: Menyediakan file eksekusi instan di `~/.local/bin/bps-run`.
5. **Inisialisasi Prefix Wine**: Menyiapkan lingkungan Wine di bawah user non-root asli agar file konfigurasi aman dari kepemilikan root.
6. **Autostart**: Membuat entri desktop XDG sehingga BPS Print Service otomatis berjalan saat user melakukan login ke lingkungan grafis sistem.

---

## 📋 Struktur Repositori

```text
BPS/
├── BPS.exe           # File eksekusi utama (aplikasi .NET ASP.NET Core Kestrel)
├── appsettings.json  # File konfigurasi aplikasi (termasuk PrinterName)
├── install.sh        # Script instalasi otomatis (memerlukan sudo)
├── run.sh            # Script launcher utama
├── uninstall.sh      # Script untuk menghapus instalasi secara bersih
└── .gitignore        # Mengabaikan file log dan backup lokal
```

---

## ⚙️ Cara Penggunaan & Perintah Dasar

Setelah instalasi berhasil, Anda bisa mengelola layanan BPS menggunakan perintah-perintah berikut langsung dari terminal user biasa Anda:

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

- Lokasi konfigurasi setelah instalasi: `~/.local/share/bps/appsettings.json`
- Ubah parameter `"PrinterName"` sesuai nama printer Anda di sistem Linux (nama printer yang terdaftar di CUPS).

### 2. Port Jaringan

Aplikasi ini secara bawaan membuka Kestrel endpoint pada port:
`http://localhost:64209`
Pastikan port ini tidak diblokir oleh firewall dan tidak sedang digunakan oleh aplikasi lain.

### 3. Font (Opsional)

Jika teks atau karakter cetak pada printer muncul sebagai kotak-kotak (render error), pasang font Microsoft Core Fonts di sistem Anda:

- **Debian/Ubuntu**: `sudo apt install ttf-mscorefonts-installer`
- **Fedora/Arch**: Font ini akan diunduh secara otomatis atau bisa dipasang melalui paket distro masing-masing.

---

## 📦 Mengatasi Kendala Upload BPS.exe (Ukuran File Besar)

File `BPS.exe` memiliki ukuran sekitar **90 MB**. GitHub membatasi upload file tunggal maksimal **100 MB** untuk push biasa (dan memberikan peringatan jika file di atas **50 MB**).

Untuk menghindari masalah gagal push atau lambatnya proses upload, sangat direkomendasikan untuk menggunakan **Git LFS (Large File Storage)** di repositori Anda sebelum melakukan push pertama kali:

1. **Instal Git LFS di komputer Anda**:
   - **Debian/Ubuntu**: `sudo apt install git-lfs`
   - **Arch Linux**: `sudo pacman -S git-lfs`
   - **Fedora**: `sudo dnf install git-lfs`

2. **Inisialisasi Git LFS di folder repositori Anda**:

   ```bash
   git lfs install
   ```

3. **Atur Git LFS agar melacak file `.exe` (khususnya BPS.exe)**:

   ```bash
   git lfs track "BPS.exe"
   ```

4. **Tambahkan file `.gitattributes` yang baru terbuat dan lakukan commit**:

   ```bash
   git add .gitattributes
   git add -A
   git commit -m "Initial commit with Git LFS tracking for BPS.exe"
   ```

5. **Lakukan Push ke GitHub**:
   ```bash
   git push origin main
   ```
