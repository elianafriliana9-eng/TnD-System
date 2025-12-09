# 🚀 TND SYSTEM - PRODUCTION DEPLOYMENT GUIDE

## 📦 FILES YANG SUDAH DISIAPKAN:

```
C:\laragon\www\tnd_system\tnd_system\
├── backend-web-production.zip     ← Upload ini (tanpa vendor/)
├── frontend-web-production.zip    ← Upload ini
└── vendor.zip                     ← Upload ini (sudah ada dari sebelumnya)
```

---

## ✅ KONFIGURASI PRODUCTION:

### Database Credentials:
- **Host:** localhost
- **Database:** tnd_system
- **Username:** tnd
- **Password:** password2025

### Domain:
- **Primary:** tndsystem.online
- **Hostname:** server.tnd.system.com

### Struktur Folder di Server:
```
public_html/
├── backend-web/
└── frontend-web/
```

---

## 📋 LANGKAH DEPLOYMENT:

### **STEP 1: Upload Files ke cPanel**

1. Login cPanel → File Manager
2. Masuk ke `public_html/`
3. **Delete semua folder lama** (backend-web dan frontend-web jika ada)
4. Upload 3 file zip:
   - `backend-web-production.zip`
   - `frontend-web-production.zip`
   - `vendor.zip`

---

### **STEP 2: Extract Files**

**Extract Backend:**
1. Klik kanan `backend-web-production.zip`
2. Extract → Extract to `/public_html/backend-web/`
3. Delete file zip setelah extract

**Extract Frontend:**
1. Klik kanan `frontend-web-production.zip`
2. Extract → Extract to `/public_html/frontend-web/`
3. Delete file zip setelah extract

**Extract Vendor:**
1. Masuk ke folder `/public_html/backend-web/`
2. Upload `vendor.zip` di sini
3. Extract → Current directory
4. Pastikan folder `vendor/` muncul dengan isi lengkap
5. Delete `vendor.zip`

---

### **STEP 3: Buat Folder yang Diperlukan**

Di `/public_html/backend-web/`:

**1. Buat folder `logs/`:**
   - Klik "+ Folder"
   - Nama: `logs`
   - Permissions: 755 atau 777

**2. Buat folder `uploads/` dan subfolders:**
   - Buat folder: `uploads`
   - Masuk ke `uploads/`, buat subfolder:
     - `photos`
     - `reports`
     - `signatures`
   - Set permissions untuk `uploads/` dan semua subfolder: **755** atau **777**

---

### **STEP 4: Verify File Structure**

Pastikan struktur seperti ini:

```
public_html/
├── backend-web/
│   ├── api/
│   ├── classes/
│   ├── config/
│   │   ├── env.php
│   │   ├── database.php
│   │   └── storage.php
│   ├── database/
│   ├── logs/                    ← Buat manual, permission 755
│   ├── uploads/                 ← Buat manual, permission 755/777
│   │   ├── photos/
│   │   ├── reports/
│   │   └── signatures/
│   ├── utils/
│   ├── vendor/                  ← Extract dari vendor.zip
│   │   ├── composer/
│   │   ├── dompdf/
│   │   ├── masterminds/
│   │   └── autoload.php
│   ├── .env
│   ├── .htaccess
│   ├── index.php
│   └── test-environment.php
│
└── frontend-web/
    ├── assets/
    │   ├── css/
    │   ├── js/
    │   │   └── api.js          ← Sudah update URL production
    │   └── images/
    ├── .htaccess
    ├── index.html
    ├── login.html
    ├── training.html
    └── training-reports.html
```

---

### **STEP 5: Test Backend**

**Test 1 - Environment:**
```
http://tndsystem.online/backend-web/test-environment.php
```
✅ Harus tampil halaman test dengan:
- PHP Version
- Database Connection: ✅ Connected
- Loaded Extensions
- File Permissions

**Test 2 - API Endpoint:**
```
http://tndsystem.online/backend-web/api/
```
✅ Harus tampil JSON response atau API info

---

### **STEP 6: Test Frontend**

**Test Homepage:**
```
http://tndsystem.online/frontend-web/
```
✅ Harus tampil homepage tanpa error

**Test Login:**
```
http://tndsystem.online/frontend-web/login.html
```
✅ Harus tampil halaman login

**Test Login Credentials:**
- Email: `admin@example.com` atau `admin`
- Password: `admin123`

✅ Harus bisa login dan redirect ke dashboard

---

### **STEP 7: Install SSL Certificate**

1. Login cPanel
2. Cari **"SSL/TLS Status"**
3. Enable **AutoSSL** untuk domain `tndsystem.online`
4. Tunggu 5-10 menit

**Setelah SSL aktif:**
- Akses jadi `https://tndsystem.online`
- Update `.env`: `APP_URL=https://tndsystem.online/backend-web`
- Update CORS: `CORS_ALLOWED_ORIGINS=https://tndsystem.online`

---

## 🐛 TROUBLESHOOTING:

### Error 500 Internal Server Error:
✅ Cek error log di cPanel → "Errors" menu
✅ Cek file `.htaccess` - rename jadi `.htaccess.backup` untuk test
✅ Pastikan folder `vendor/` ada dan terisi lengkap
✅ Pastikan file `config/env.php` ada

### Login Error / JSON Parse Error:
✅ Cek database connection di `test-environment.php`
✅ Pastikan credentials database benar
✅ Cek browser console untuk detail error

### Upload Foto Gagal:
✅ Pastikan folder `uploads/` permission 755 atau 777
✅ Pastikan subfolder `photos/`, `signatures/` ada

### CORS Error:
✅ Pastikan domain benar di `.env`: `CORS_ALLOWED_ORIGINS`
✅ Pastikan frontend mengakses API dengan domain yang sama

---

## 📞 SUPPORT:

Jika ada error, kirim screenshot:
1. Error message dari browser
2. Hasil akses `test-environment.php`
3. Error log dari cPanel

---

## ✅ CHECKLIST FINAL:

- [ ] backend-web-production.zip uploaded & extracted
- [ ] frontend-web-production.zip uploaded & extracted
- [ ] vendor.zip uploaded & extracted
- [ ] Folder `logs/` created with permission 755
- [ ] Folder `uploads/` created with permission 755/777
- [ ] Subfolder `photos/`, `reports/`, `signatures/` created
- [ ] test-environment.php shows all green ✅
- [ ] Frontend login page accessible
- [ ] Login successful with admin/admin123
- [ ] SSL certificate installed (optional - untuk HTTPS)

---

🎉 **DEPLOYMENT COMPLETE!**

Access: http://tndsystem.online/frontend-web/login.html

---
Generated: November 2, 2025
