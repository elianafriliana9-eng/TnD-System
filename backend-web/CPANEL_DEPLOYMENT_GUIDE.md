# 🚀 Panduan Deploy TnD System di cPanel/WHM Ubuntu 22

## 📋 Yang Anda Perlukan

- ✅ Akses cPanel
- ✅ Domain/Subdomain (contoh: api.tnd-system.com)
- ✅ PHP 8.0+
- ✅ MySQL Database
- ✅ File Manager atau FTP

---

## 🎯 LANGKAH 1: Persiapan Database di cPanel

### 1.1 Buat Database MySQL

1. **Login ke cPanel** → Cari **"MySQL Databases"**
2. **Create New Database:**
   - Database Name: `tnd_system` (atau nama lain)
   - Klik **"Create Database"**
   - Catat nama lengkapnya: `cpanelusername_tnd_system`

### 1.2 Buat User Database

1. Di halaman yang sama, scroll ke **"MySQL Users"**
2. **Create New User:**
   - Username: `tnd_user`
   - Password: **Generate password yang kuat** (klik Generate Password)
   - ✅ **PENTING: Salin dan simpan password ini!**
   - Klik **"Create User"**
   - Nama lengkap user: `cpanelusername_tnd_user`

### 1.3 Hubungkan User ke Database

1. Scroll ke **"Add User To Database"**
2. Pilih user: `cpanelusername_tnd_user`
3. Pilih database: `cpanelusername_tnd_system`
4. Klik **"Add"**
5. Di halaman privileges, centang **"ALL PRIVILEGES"**
6. Klik **"Make Changes"**

✅ **Database siap!** Catat informasi ini:
```
DB_HOST=localhost
DB_NAME=cpanelusername_tnd_system
DB_USERNAME=cpanelusername_tnd_user
DB_PASSWORD=password_yang_tadi_disimpan
```

---

## 🎯 LANGKAH 2: Setup Domain/Subdomain

### Option A: Gunakan Subdomain (Rekomendasi)

1. **cPanel** → **"Subdomains"**
2. **Create Subdomain:**
   - Subdomain: `api` (akan jadi: api.yourdomain.com)
   - Document Root: biarkan default atau ganti jadi `api_tnd`
   - Klik **"Create"**

### Option B: Gunakan Addon Domain

1. **cPanel** → **"Addon Domains"**
2. Masukkan domain baru dan document root

✅ **Catat Document Root Path** (contoh: `/home/cpaneluser/public_html/api_tnd`)

---

## 🎯 LANGKAH 3: Upload File Backend

### 3.1 Siapkan File di Komputer Lokal

1. **Buka PowerShell** di folder backend:
```powershell
cd C:\laragon\www\tnd_system\tnd_system\backend-web
```

2. **Export database lokal:**
```powershell
# Gunakan mysqldump dari Laragon
C:\laragon\bin\mysql\mysql-8.0.30-winx64\bin\mysqldump.exe -u root tnd_system > tnd_system_export.sql
```

3. **Buat arsip file yang akan diupload** (opsional, untuk mempercepat):
```powershell
# Buat folder sementara untuk file yang akan diupload
mkdir C:\temp\tnd_deploy
```

### 3.2 Upload via File Manager cPanel

1. **cPanel** → **"File Manager"**
2. Navigate ke **document root** subdomain Anda (contoh: `public_html/api_tnd`)
3. **Upload file-file ini:**
   - ✅ Semua folder: `api/`, `classes/`, `config/`, `utils/`, `database/`
   - ✅ File: `.htaccess`, `composer.json`, `composer.lock`
   - ✅ File SQL: `database_schema.sql`, `tnd_system_export.sql`
   - ✅ **JANGAN upload:** `.env`, `vendor/`, `uploads/`, `logs/`

4. **Cara upload:**
   - Klik **"Upload"** di toolbar
   - Drag & drop semua file/folder
   - Tunggu sampai selesai

### 3.3 Buat Folder yang Diperlukan

Di File Manager cPanel, buat folder-folder ini di document root:

1. Klik **"+ Folder"**
2. Buat folder:
   - `uploads/` 
   - `uploads/photos/`
   - `uploads/signatures/`
   - `uploads/reports/`
   - `logs/`
   - `vendor/` (akan diisi oleh Composer)

3. **Set Permissions:**
   - Klik kanan pada `uploads/` → **Permissions** → `755` atau `777`
   - Klik kanan pada `logs/` → **Permissions** → `755` atau `777`

---

## 🎯 LANGKAH 4: Setup PHP & Composer

### 4.1 Cek Versi PHP

1. **cPanel** → **"Select PHP Version"** atau **"MultiPHP Manager"**
2. Pastikan **PHP 8.0** atau lebih tinggi
3. Aktifkan ekstensi yang diperlukan:
   - ✅ `mysqli`
   - ✅ `pdo_mysql`
   - ✅ `mbstring`
   - ✅ `json`
   - ✅ `curl`
   - ✅ `fileinfo`
   - ✅ `gd` (untuk manipulasi gambar)

### 4.2 Install Dependencies dengan Composer

**Pilihan 1: Via SSH (jika tersedia)**

```bash
# Login SSH ke server
ssh cpaneluser@your-server-ip

# Navigate ke folder backend
cd ~/public_html/api_tnd

# Install Composer dependencies
composer install --no-dev --optimize-autoloader
```

**Pilihan 2: Via Terminal di cPanel**

1. **cPanel** → **"Terminal"**
2. Jalankan:
```bash
cd ~/public_html/api_tnd
composer install --no-dev --optimize-autoloader
```

**Pilihan 3: Upload vendor/ dari lokal (jika tidak ada Composer di server)**

1. Di lokal, jalankan:
```powershell
cd C:\laragon\www\tnd_system\tnd_system\backend-web
composer install --no-dev
```

2. Upload folder `vendor/` ke cPanel (ini akan besar, ~30-50MB)

---

## 🎯 LANGKAH 5: Konfigurasi .env Production

### 5.1 Generate JWT Secret

Di komputer lokal, buka PowerShell:

```powershell
# Generate JWT Secret
$bytes = New-Object byte[] 64
(New-Object Random).NextBytes($bytes)
[Convert]::ToBase64String($bytes)
```

✅ **Salin hasilnya** (contoh: `x7k9m2n5p8r1t4w6y9z2b5d8f1h4j7l0n3q6s9v2x5z8c1e4g7j0m3p6r9u2w5y8`)

### 5.2 Buat File .env di cPanel

1. **File Manager** → Navigate ke document root
2. Klik **"+ File"** → Nama: `.env`
3. **Edit file** `.env`, isi dengan:

```env
# Application Environment
APP_ENV=production

# Database Configuration
DB_HOST=localhost
DB_NAME=cpanelusername_tnd_system
DB_USERNAME=cpanelusername_tnd_user
DB_PASSWORD=your_database_password_here

# JWT Configuration
JWT_SECRET=paste_jwt_secret_dari_generate_tadi
JWT_EXPIRY=86400

# CORS Configuration  
CORS_ORIGIN=*
# Untuk production, ganti * dengan domain frontend:
# CORS_ORIGIN=https://your-frontend-domain.com

# Upload Configuration
UPLOAD_MAX_SIZE=5242880
ALLOWED_PHOTO_TYPES=jpg,jpeg,png
ALLOWED_SIGNATURE_TYPES=png

# Timezone
TIMEZONE=Asia/Jakarta

# Error Reporting (production)
ERROR_REPORTING=0
DISPLAY_ERRORS=0
LOG_ERRORS=1
```

4. **Ganti nilai-nilai:**
   - `DB_NAME`, `DB_USERNAME`, `DB_PASSWORD` → sesuai database yang dibuat di Langkah 1
   - `JWT_SECRET` → hasil generate tadi
   - `CORS_ORIGIN` → domain frontend (jika sudah ada)

5. **Save file**

---

## 🎯 LANGKAH 6: Import Database

### 6.1 Via phpMyAdmin

1. **cPanel** → **"phpMyAdmin"**
2. Pilih database: `cpanelusername_tnd_system` di sidebar kiri
3. Tab **"Import"**
4. **Choose File** → Upload `tnd_system_export.sql`
5. Scroll ke bawah → Klik **"Go"**
6. Tunggu hingga selesai (akan muncul pesan sukses)

### 6.2 Via SSH/Terminal (Alternatif, lebih cepat untuk database besar)

```bash
cd ~/public_html/api_tnd
mysql -u cpanelusername_tnd_user -p cpanelusername_tnd_system < tnd_system_export.sql
# Masukkan password database saat diminta
```

✅ **Database berhasil diimport!**

---

## 🎯 LANGKAH 7: Test Backend API

### 7.1 Test Koneksi Database

1. Buka browser, akses:
```
https://api.yourdomain.com/test-environment.php
```

2. **Cek outputnya:**
   - ✅ PHP Version: 8.0+
   - ✅ Database Connected: Yes
   - ✅ Required Extensions: All enabled
   - ✅ Uploads folder: Writable
   - ✅ Logs folder: Writable

### 7.2 Test API Endpoints

**Test 1: Health Check**
```
GET https://api.yourdomain.com/api/health.php
```

**Test 2: Login API**
```
POST https://api.yourdomain.com/api/auth/login.php
Body (JSON):
{
  "username": "admin",
  "password": "admin123"
}
```

### 7.3 Test dengan Postman atau cURL

```bash
# cURL test
curl -X POST https://api.yourdomain.com/api/auth/login.php \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}'
```

✅ **Jika berhasil**, Anda akan mendapat response dengan `token`

---

## 🎯 LANGKAH 8: Setup SSL Certificate (HTTPS)

### 8.1 Install SSL via cPanel

1. **cPanel** → **"SSL/TLS Status"**
2. Centang domain/subdomain Anda
3. Klik **"Run AutoSSL"**
4. Tunggu beberapa menit (Let's Encrypt akan auto-install)

### 8.2 Force HTTPS

Edit `.htaccess` di document root, pastikan ada:

```apache
# Force HTTPS
RewriteEngine On
RewriteCond %{HTTPS} off
RewriteRule ^(.*)$ https://%{HTTP_HOST}%{REQUEST_URI} [L,R=301]

# API Routes
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule ^api/(.*)$ api/$1 [L]
```

---

## 🎯 LANGKAH 9: Update Mobile App

### 9.1 Update API URL di Flutter App

Edit file: `lib/utils/constants.dart`

```dart
class ApiConstants {
  // Ganti dengan URL production Anda
  static const String baseUrl = 'https://api.yourdomain.com';
  
  // Endpoints
  static const String loginEndpoint = '/api/auth/login.php';
  static const String usersEndpoint = '/api/users.php';
  // ... dst
}
```

### 9.2 Build Ulang APK

```powershell
cd C:\laragon\www\tnd_system\tnd_system\tnd_mobile_flutter

# Build release APK
flutter build apk --release

# APK ada di: build/app/outputs/flutter-apk/app-release.apk
```

---

## ✅ CHECKLIST DEPLOYMENT

### Pre-Deployment
- [ ] Database diekspor dari lokal
- [ ] JWT Secret di-generate
- [ ] Semua file backend siap

### cPanel Setup
- [ ] Database MySQL dibuat
- [ ] User database dibuat dan dihubungkan
- [ ] Subdomain/domain dikonfigurasi
- [ ] PHP 8.0+ aktif dengan ekstensi yang diperlukan

### File Upload
- [ ] Folder api/, classes/, config/, utils/ uploaded
- [ ] File .htaccess uploaded
- [ ] Folder uploads/, logs/ dibuat dengan permission 755/777
- [ ] Composer dependencies terinstall (vendor/)

### Configuration
- [ ] File .env dibuat dengan konfigurasi production
- [ ] Database diimport via phpMyAdmin
- [ ] SSL certificate terinstall

### Testing
- [ ] test-environment.php menunjukkan semua OK
- [ ] API login berfungsi
- [ ] Upload foto/signature berfungsi
- [ ] Mobile app terhubung ke API production

---

## 🔧 Troubleshooting

### Error: "500 Internal Server Error"

**Cek error log:**
1. cPanel → **"Errors"** → **"Error Log"**
2. Lihat pesan error terakhir

**Solusi umum:**
- Cek file `.htaccess` syntax
- Cek permission folder (uploads/, logs/ harus writable)
- Cek `.env` konfigurasi database

### Error: "Database connection failed"

**Cek:**
1. Nama database, username, password di `.env` benar?
2. User database sudah dihubungkan ke database?
3. DB_HOST = `localhost` (bukan 127.0.0.1)

### Error: "Class not found" atau Composer error

**Solusi:**
```bash
# Re-install composer dependencies
cd ~/public_html/api_tnd
rm -rf vendor/
composer install --no-dev --optimize-autoloader
```

### Upload foto gagal

**Cek:**
1. Permission folder `uploads/` = 755 atau 777
2. Cek `.env`: `UPLOAD_MAX_SIZE`, `ALLOWED_PHOTO_TYPES`
3. cPanel → **"Select PHP Version"** → Cek `upload_max_filesize` dan `post_max_size`

---

## 📞 Bantuan Lebih Lanjut

Jika ada masalah:

1. **Cek error log** di cPanel
2. **Test API** dengan Postman
3. **Cek dokumentasi:**
   - `DEPLOYMENT.md` - Panduan deployment umum
   - `PRODUCTION_CHECKLIST.md` - Checklist lengkap
   - `QUICK_DEPLOYMENT_GUIDE.md` - Panduan cepat

---

**🎉 Selamat! TnD System Anda sekarang sudah live di production!**
