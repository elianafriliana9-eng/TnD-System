# PANDUAN RILIS MOBILE APK - TND SYSTEM

## 📱 PERSIAPAN BUILD RELEASE APK

### STEP 1: Update Version Number
Sebelum build, update version di `pubspec.yaml`:

```yaml
version: 1.0.0+1
```

Format: `version: <major>.<minor>.<patch>+<build_number>`
- 1.0.0 = Version name (yang terlihat user)
- +1 = Build number (increment setiap build baru)

---

## 🔐 STEP 2: Generate Signing Key (Jika Belum Ada)

### Untuk Windows (PowerShell):
```powershell
cd c:\laragon\www\tnd_system\tnd_system\tnd_mobile_flutter\android

keytool -genkey -v -keystore tnd-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias tnd-key
```

### Informasi yang akan ditanyakan:
- **Keystore password**: (buat password, contoh: `Tnd2025!Release`)
- **Re-enter password**: (ulangi password)
- **First and last name**: `TND System`
- **Organizational unit**: `Development`
- **Organization**: `TND`
- **City**: (isi kota Anda)
- **State**: (isi provinsi)
- **Country code**: `ID`
- **Is correct?**: `yes`

**PENTING**: Simpan password ini dengan aman! Tanpa password ini, Anda tidak bisa update app di masa depan.

---

## 📝 STEP 3: Konfigurasi Signing (key.properties)

Buat file `android/key.properties`:

```
```

**CATATAN**: Ganti password dengan password yang Anda buat di Step 2

---

## 🛠️ STEP 4: Build Release APK

### Build APK (Universal):
```powershell
flutter build apk --release
```

### Build APK per ABI (Ukuran lebih kecil):
```powershell
flutter build apk --split-per-abi --release
```

Output APK akan ada di:
- Universal: `build/app/outputs/flutter-apk/app-release.apk`
- Split ABI:
  * `build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk` (ARM 32-bit)
  * `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk` (ARM 64-bit)
  * `build/app/outputs/flutter-apk/app-x86_64-release.apk` (Intel 64-bit)

**REKOMENDASI**: Upload `app-release.apk` (universal) untuk distribusi umum.

---

## 📦 STEP 5: Build App Bundle (Untuk Google Play Store)

Jika ingin upload ke Play Store:
```powershell
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

---

## ✅ CHECKLIST SEBELUM BUILD

Pastikan semua sudah benar:

- [ ] Version di `pubspec.yaml` sudah diupdate
- [ ] API URL production sudah benar di `lib/utils/constants.dart`
- [ ] Semua fitur sudah ditest dengan baik
- [ ] Dark mode sudah dihapus (sudah done)
- [ ] Privacy Policy sudah pindah ke Profile (sudah done)
- [ ] Tidak ada debug code/console.log
- [ ] Icon dan splash screen sudah sesuai
- [ ] Package name sudah benar di `android/app/build.gradle`

---

## 🎯 SETELAH BUILD SELESAI

### 1. Test APK
- Install APK di device test
- Test semua fitur critical:
  * Login
  * Start Visit
  * Upload Photo
  * Complete Visit
  * Recommendations
  * Reports
  * Profile

### 2. Distribusi APK

**Option A: Upload ke Server**
Upload ke folder: `https://tndsystem.online/downloads/TND-Mobile-v1.0.0.apk`

**Option B: Google Drive**
1. Upload ke Google Drive
2. Set permission: "Anyone with link can view"
3. Share link ke user

**Option C: Direct Install**
Transfer APK via USB/WhatsApp ke device user

### 3. Instalasi di Device User

**Instruksi untuk User:**
1. Download APK ke smartphone
2. Buka file APK
3. Jika muncul "Install Blocked": 
   - Buka Settings > Security
   - Enable "Unknown Sources" atau "Install Unknown Apps"
4. Tap "Install"
5. Tunggu instalasi selesai
6. Buka aplikasi "TND Mobile"
7. Login dengan username & password yang diberikan admin

---

## 📋 USER CREDENTIALS (Contoh)

Setelah Super Admin login ke web dashboard, buat user untuk mobile:

### Role: Sales
- Username: `sales1`
- Password: `Sales123!`
- Email: `sales1@tndsystem.com`
- Role: `sales`

### Role: Supervisor
- Username: `supervisor1`
- Password: `Supervisor123!`
- Email: `supervisor1@tndsystem.com`
- Role: `supervisor`

---

## 🔄 UPDATE APK (Untuk Versi Berikutnya)

Jika ada update/bug fix:

1. **Update version di pubspec.yaml**:
   ```yaml
   version: 1.0.1+2  # Increment version
   ```

2. **Build ulang**:
   ```powershell
   flutter clean
   flutter pub get
   flutter build apk --release
   ```

3. **Distribusi APK baru**

4. **User install ulang** (akan replace app lama)

---

## 🛡️ KEAMANAN

### Key File Security:
- ❌ **JANGAN** commit `tnd-release-key.jks` ke Git
- ❌ **JANGAN** share key file ke orang lain
- ❌ **JANGAN** share password di public
- ✅ **SIMPAN** backup key file di tempat aman (cloud storage private)
- ✅ **CATAT** password di password manager

### .gitignore:
Pastikan file ini sudah ada di `.gitignore`:
```
android/key.properties
android/*.jks
android/*.keystore
```

---

## 📊 APP INFO

**App Name**: TND Mobile
**Package Name**: com.tnd.mobile (atau sesuai di build.gradle)
**Version**: 1.0.0
**Build**: 1
**Min SDK**: Android 5.0 (API 21)
**Target SDK**: Android 13 (API 33)

---

## 🆘 TROUBLESHOOTING

### Build Failed: "Keystore not found"
- Pastikan file `tnd-release-key.jks` ada di folder `android/`
- Cek path di `key.properties` sudah benar

### Build Failed: "Password incorrect"
- Cek password di `key.properties` sesuai dengan yang dibuat saat generate key

### APK tidak bisa install: "App not installed"
- Uninstall versi debug dulu
- Enable "Unknown Sources"
- Pastikan device Android 5.0+

### APK crash saat dibuka
- Cek logs dengan: `adb logcat`
- Pastikan semua dependencies sudah benar
- Test di debug mode dulu

---

## 📞 SUPPORT

Jika ada masalah saat build atau instalasi:
- Developer: Elian Afriliana
- Email: (isi email support)
- Phone/WA: (isi nomor support)

---

**SELAMAT! Aplikasi siap untuk dirilis! 🎉**
