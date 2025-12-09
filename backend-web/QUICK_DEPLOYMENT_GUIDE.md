# 🚀 Quick Deployment Guide

Panduan singkat untuk deployment TnD System ke shared hosting.

## 📦 Files yang Sudah Disiapkan

✅ **Dokumentasi:**
- `DEPLOYMENT.md` - Panduan lengkap deployment
- `PRODUCTION_CHECKLIST.md` - Checklist verifikasi sebelum go-live
- `README.md` - Dokumentasi project

✅ **Konfigurasi:**
- `.env.example` - Template environment variables
- `.gitignore` - File yang tidak di-commit ke git
- `.htaccess` - Konfigurasi keamanan Apache

✅ **Database:**
- `database/create_db_user.sql` - Script create user DB terbatas
- `database/backup_database.php` - Script backup otomatis
- `database/restore_database.php` - Script restore backup

✅ **Verifikasi:**
- `pre-deployment-check.php` - Script cek kesiapan deployment

---

## ⚡ Quick Start (5 Steps)

### Step 1: Verifikasi Lokal

```bash
cd c:\laragon\www\tnd_system\tnd_system\backend-web
php pre-deployment-check.php
```

Expected output: `✓ All checks passed!` atau `⚠ warnings` only

### Step 2: Generate JWT Secret

Windows PowerShell:
```powershell
[Convert]::ToBase64String((1..64 | ForEach-Object { Get-Random -Minimum 0 -Maximum 256 }))
```

**Save this secret!** Anda akan pakai di `.env` production.

### Step 3: Upload ke Hosting

**Via FTP (FileZilla/WinSCP):**
1. Connect ke hosting
2. Navigate ke `public_html` atau `www`
3. Upload semua files **KECUALI**:
   - `.env` (create manual di server)
   - `uploads/*` (biar kosong)
   - `logs/*` (biar kosong)

**Files yang WAJIB upload:**
- Semua folder: `api/`, `config/`, `utils/`, `classes/`, `database/`
- `.htaccess`
- `.env.example`
- Semua `.php` di root

### Step 4: Setup Database

**4.1. Create Database (cPanel → MySQL Databases):**
- Database name: `username_tnd` (contoh)
- Charset: `utf8mb4`

**4.2. Create User (MySQL → Users):**
- Username: `username_tnd` (contoh)
- Password: Strong password (save it!)
- Assign user to database
- Privileges: SELECT, INSERT, UPDATE, DELETE

**4.3. Import Database:**

Via phpMyAdmin:
1. Select your database
2. Import tab
3. Choose your SQL file
4. Execute

### Step 5: Configure .env

Create `.env` file di server (via File Manager atau FTP):

```env
# Application Environment
APP_ENV=production

# Database Configuration
DB_HOST=localhost
DB_NAME=username_tnd
DB_USERNAME=username_tnd
DB_PASSWORD=your_strong_password_here

# JWT Secret (paste generated secret from Step 2)
JWT_SECRET_KEY=paste_your_generated_secret_here

# CORS Configuration (your actual domain)
CORS_ALLOWED_ORIGINS=https://yourdomain.com,https://www.yourdomain.com
```

**Set permissions:** `chmod 600 .env` (via File Manager → Change Permissions → 600)

---

## ✅ Verification Checklist

Setelah upload, verify:

- [ ] Access `https://yourdomain.com/` → Should not list files
- [ ] Access `.env` via browser → Should be blocked (403/404)
- [ ] Test login API:
  ```bash
  curl -X POST https://yourdomain.com/api/login.php \
    -H "Content-Type: application/json" \
    -d '{"email":"admin@test.com","password":"admin123"}'
  ```
  Should return JWT token

- [ ] Test rate limiting → Login 6x with wrong password → 6th should be HTTP 429
- [ ] Upload test photo via mobile app → Should work
- [ ] Generate PDF → Should work
- [ ] Check `logs/error.log` → Should be empty or minimal errors

---

## 📱 Mobile App Update

**Before building production APK:**

1. Edit `tnd_mobile_flutter/lib/utils/api_config_manager.dart`:
   ```dart
   static const String _defaultBaseUrl = 'https://yourdomain.com';
   ```

2. Build APK:
   ```bash
   cd tnd_mobile_flutter
   flutter clean
   flutter pub get
   flutter build apk --release
   ```

3. Test APK before distributing

---

## 🆘 Troubleshooting

### "Database connection failed"
→ Check `.env` credentials, ensure database exists

### "CORS policy error"
→ Update `CORS_ALLOWED_ORIGINS` in `.env` with exact domain (including https://)

### "File upload failed"
→ Check permissions: `chmod 755 uploads` and subdirectories

### "500 Internal Server Error"
→ Check `logs/error.log` for details

### "Rate limiting not working"
→ Ensure `logs/ratelimit/` directory exists and writable (755)

---

## 📞 Need Help?

**Full Documentation:**
- `DEPLOYMENT.md` - Complete deployment guide
- `PRODUCTION_CHECKLIST.md` - Detailed checklist

**Support:**
- Developer: [Your Contact]
- Hosting Provider: [Support Contact]

---

## 🎯 What's Next?

After successful deployment:

1. ✅ Test all features thoroughly (UAT)
2. ✅ Monitor `logs/error.log` daily for first week
3. ✅ Setup automated backups (cron job)
4. ✅ Distribute production APK to users
5. ✅ Collect feedback and iterate

**Phase 2 (Training Module)** can be developed after QC System is stable in production.

---

**Ready to deploy?** Follow `DEPLOYMENT.md` for step-by-step instructions! 🚀
