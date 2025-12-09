# 📋 DEPLOYMENT FILES LIST - TND System Mobile Fix

## 🎯 Upload File-File Berikut ke Server Production

### 1️⃣ **Backend PHP Files (12 files)**

#### Root Configuration (1 file)
```
backend-web/.htaccess
```
**Path Server:** `~/public_html/backend-web/.htaccess`
**Changes:** Added Authorization header forwarding

---

#### API Endpoints (7 files)
```
backend-web/api/outlets.php
backend-web/api/report-overview.php
backend-web/api/report-by-outlet.php
backend-web/api/improvement-recommendations.php
backend-web/api/visits-create.php
backend-web/api/visit-complete.php
backend-web/api/visit-photo-upload.php
```
**Path Server:** `~/public_html/backend-web/api/`
**Changes:** 
- Added Auth::checkAuth() with bearer token support
- Fixed database column references (started_at, completed_at, u.name)
- Better error handling

---

#### Utilities (1 file)
```
backend-web/utils/Auth.php
```
**Path Server:** `~/public_html/backend-web/utils/Auth.php`
**Changes:** Enhanced header detection for Apache/Nginx, added logging

---

#### Model Classes (3 files)
```
backend-web/classes/Visit.php
backend-web/classes/Audit.php
backend-web/classes/Outlet.php
```
**Path Server:** `~/public_html/backend-web/classes/`
**Changes:** Changed `u.name` to `u.full_name`, removed `started_at` column

---

### 2️⃣ **Setup Scripts (2 files)**
```
backend-web/create-upload-dirs.php
backend-web/migrate-visit-photos.php
```
**Path Server:** `~/public_html/backend-web/`
**Purpose:** 
- `create-upload-dirs.php`: Create upload directories (755 permissions)
- `migrate-visit-photos.php`: Add checklist_item_id column to visit_photos table
**⚠️ DELETE both files after running!**

---

## 📱 Flutter Mobile App - Rebuild Required

### Files Modified (4 files)
```
tnd_mobile_flutter/lib/screens/start_visit_screen.dart
tnd_mobile_flutter/lib/screens/profile_screen.dart
tnd_mobile_flutter/lib/screens/checklist_screen.dart
tnd_mobile_flutter/lib/screens/category_checklist_screen.dart
```

**Changes:**
- Division-based outlet filtering
- Profile screen null safety
- Image compression: quality 85→70, dimensions 1920x1080→1280x720

**Action Required:** 
```powershell
cd tnd_mobile_flutter
flutter clean
flutter pub get
flutter build apk --release
```

---

## 🚀 DEPLOYMENT STEPS

### Step 1: Upload Backend Files to cPanel
1. Login ke cPanel: https://tndsystem.online:2083
2. Buka **File Manager**
3. Navigate to `public_html/backend-web/`
4. Upload 13 files sesuai path di atas
5. **Pastikan overwrite file yang sudah ada**

### Step 2: Run Setup Scripts
1. **Create Upload Directories**
   - Buka browser: `https://tndsystem.online/backend-web/create-upload-dirs.php`
   - Verify semua directory created dengan status ✅
   - DELETE file setelah success

2. **Run Database Migration**
   - Buka browser: `https://tndsystem.online/backend-web/migrate-visit-photos.php`
   - Verify migration completed successfully ✅
   - Check table structure shows `checklist_item_id` column
   - **DELETE file setelah success**

### Step 3: Rebuild Mobile App
```powershell
cd c:\laragon\www\tnd_system\tnd_system\tnd_mobile_flutter
flutter clean
flutter pub get
flutter build apk --release
```
APK location: `build/app/outputs/flutter-apk/app-release.apk`

### Step 4: Test All Features
Install APK baru dan test:

- [ ] **Login** - Already working ✅
- [ ] **Start Visit** - Outlet list filtered by division
- [ ] **Report** - Data terisi (not empty)
- [ ] **Recommendations** - No 401 error
- [ ] **Profile** - Screen tampil normal (not blank)
- [ ] **Photo Upload** - No 500 error, file size ~50-100KB

---

## 📊 Expected Results

### Before Fix:
- ❌ Outlet list kosong
- ❌ Report kosong
- ❌ Recommendations: HTTP 401
- ❌ Profile: blank screen
- ❌ Photo upload: HTTP 500 (196KB file)

### After Fix:
- ✅ Outlet list filtered by user division
- ✅ Report data loaded
- ✅ Recommendations: HTTP 200
- ✅ Profile: full_name, email, division displayed
- ✅ Photo upload: HTTP 200 (50-100KB file)

---

## 🔍 Verification Commands

### Check Upload Directories on Server
Via cPanel Terminal atau SSH:
```bash
cd ~/public_html/backend-web
ls -la uploads/
ls -la uploads/visit_photos/
ls -la uploads/profile_photos/
ls -la uploads/training_photos/
```

Expected output:
```
drwxr-xr-x 2 username username 4096 ... visit_photos
drwxr-xr-x 2 username username 4096 ... profile_photos
drwxr-xr-x 2 username username 4096 ... training_photos
```

### Check Authorization Header
Test dengan curl:
```bash
curl -H "Authorization: Bearer YOUR_TOKEN" https://tndsystem.online/backend-web/api/outlets.php
```

Should return JSON, not 401.

---

## ⚠️ IMPORTANT NOTES

1. **Backup First:** Sebelum upload, backup file lama di cPanel
2. **Check Permissions:** Pastikan upload directories 755 (rwxr-xr-x)
3. **Delete Setup Script:** Hapus `create-upload-dirs.php` setelah dijalankan
4. **Test Incrementally:** Test satu-satu fitur setelah deployment
5. **Monitor Logs:** Check `backend-web/logs/` jika ada error

---

## 📝 Checklist

- [ ] Upload 12 backend PHP files to cPanel
- [ ] Upload 2 setup scripts (create-upload-dirs.php, migrate-visit-photos.php)
- [ ] Run `create-upload-dirs.php` via browser
- [ ] Verify all directories created (4 directories)
- [ ] Delete `create-upload-dirs.php`
- [ ] Run `migrate-visit-photos.php` via browser
- [ ] Verify checklist_item_id column added
- [ ] Delete `migrate-visit-photos.php`
- [ ] Rebuild Flutter app (`flutter build apk`)
- [ ] Install new APK on device
- [ ] Test Login ✅
- [ ] Test Start Visit (outlet list)
- [ ] Test Report (data)
- [ ] Test Recommendations (no 401)
- [ ] Test Profile (display)
- [ ] Test Photo Upload (no 500, column error fixed)

---

## 🆘 Troubleshooting

### If outlet list still empty:
- Check `backend-web/api/outlets.php` line 24: `Auth::checkAuth()`
- Check user's `division_id` in database
- Check API response: `/api/outlets.php?division_id=X`

### If still getting 401:
- Check `.htaccess` rules uploaded correctly
- Test Authorization header with curl
- Check `backend-web/logs/app.log`

### If photo upload still 500:
- Verify upload directories exist and writable
- Check file size < 2MB
- Check `backend-web/logs/app.log` for errors
- Check cPanel error_log

---

**Last Updated:** 2024
**Version:** Mobile Fix v1.0
**Status:** Ready for deployment 🚀
