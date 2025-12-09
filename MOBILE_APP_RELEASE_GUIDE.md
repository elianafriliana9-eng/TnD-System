# TND Mobile App - Release Guide

## 🎉 Release Information

**Version:** 1.0.0  
**Release Date:** 2025  
**Build Date:** January 2025  

---

## 📱 APK Location

After successful build, the APK can be found at:
```
tnd_mobile_flutter/build/app/outputs/flutter-apk/app-release.apk
```

---

## 🔑 Keystore Information

**Location:** `android/app/tnd-release-key.jks`  
**Alias:** tnd  
**Password:** tnd2025  
**Validity:** 10,000 days  

**Certificate Details:**
- CN: TND System
- OU: Development
- O: TND
- L: Jakarta
- ST: Jakarta
- C: ID

---

## 🎨 New Features in This Release

### 1. Modern Login Screen
- **Purple gradient background** (#6B4CE6 to #9D7CE8)
- **Clean white card design** with rounded corners
- **Three input fields:**
  - Username (with person icon)
  - Email (with email icon)
  - Password (with lock icon & visibility toggle)
- **Social media login section** with colored icons
- **"Get Started" button** for new users
- **"Forgot password?" link**

### 2. Complete Features
✅ User authentication (login/logout)  
✅ Outlet management (view, search, filter)  
✅ Daily visit tracking with:
   - Photos upload
   - Checklist items
   - Visit history
   - Times recording
✅ Recommendations feature:
   - View recommendations list
   - See details
   - Save recommendations
   - Export to PDF
   - Lock mechanism
✅ Comprehensive reports:
   - Daily reports
   - Visit history reports
   - Performance analytics
✅ Profile management  
✅ Privacy policy page  

---

## 🔐 Test Credentials

### Super Admin (Web)
- **URL:** https://tndsystem.online/backend-web/
- **Username:** superadmin
- **Password:** Srttnd2025!
- **Email:** tndsrt@gmail.com
- **Role:** admin

### Test Mobile Users
Use existing sales/supervisor accounts from database.

---

## 📋 Pre-Deployment Checklist

Before distributing the APK:

- [ ] APK successfully built
- [ ] Tested on physical Android device
- [ ] Login functionality verified
- [ ] All core features tested:
  - [ ] Outlets list loads
  - [ ] Visit creation works
  - [ ] Photo upload successful
  - [ ] Recommendations feature works
  - [ ] Reports generate correctly
  - [ ] Profile displays correctly
- [ ] Backend API responding (https://tndsystem.online/backend-web/)
- [ ] Database connection stable
- [ ] No critical errors in logs

---

## 📥 Distribution Steps

### Step 1: Locate the APK
```powershell
cd c:\laragon\www\tnd_system\tnd_system\tnd_mobile_flutter
cd build\app\outputs\flutter-apk
```

### Step 2: Verify APK Size
The APK should be approximately 40-60 MB.

### Step 3: Test Installation
1. Copy APK to Android device
2. Enable "Install from Unknown Sources" in device settings
3. Install the APK
4. Test login and core features

### Step 4: Distribution Methods

**Option A: Email Distribution**
- Attach `app-release.apk` to email
- Send to sales team members
- Include installation instructions

**Option B: Cloud Storage**
- Upload to Google Drive/Dropbox
- Share link with team
- Set appropriate permissions

**Option C: Direct Transfer**
- Use USB cable
- Copy APK to device
- Install directly

---

## 📱 Installation Instructions for Users

### For Android Users:

1. **Download the APK**
   - Receive the `app-release.apk` file via email or download link
   - Save to your device

2. **Enable Installation from Unknown Sources**
   - Go to Settings → Security
   - Enable "Install apps from unknown sources" or "Install unknown apps"
   - Allow installation for your file manager/browser

3. **Install the App**
   - Open File Manager
   - Navigate to Downloads folder
   - Tap on `app-release.apk`
   - Tap "Install"
   - Wait for installation to complete

4. **Launch the App**
   - Tap "Open" after installation
   - Or find "TND Mobile" in your app drawer

5. **Login**
   - Enter your username
   - Enter your email
   - Enter your password
   - Tap "Sign In"

---

## 🔧 Build Commands Reference

### Clean Build
```bash
flutter clean
flutter pub get
flutter build apk --release
```

### Debug Build (for testing)
```bash
flutter build apk --debug
```

### Split APK by ABI (smaller files)
```bash
flutter build apk --split-per-abi
```

### Build App Bundle (for Play Store)
```bash
flutter build appbundle --release
```

---

## 🐛 Troubleshooting

### Issue: "App not installed"
**Solution:**
- Uninstall any previous version
- Clear installation cache
- Retry installation

### Issue: Login fails
**Solution:**
- Check internet connection
- Verify backend server is running
- Check credentials with admin

### Issue: Photos won't upload
**Solution:**
- Grant camera and storage permissions
- Check internet connection
- Verify file size (max 5MB recommended)

### Issue: App crashes on startup
**Solution:**
- Clear app data and cache
- Reinstall the app
- Check Android version (minimum: Android 5.0)

---

## 📊 App Specifications

### Minimum Requirements
- **Android:** 5.0 (Lollipop) or higher
- **RAM:** 2GB minimum
- **Storage:** 100MB free space
- **Internet:** Required for all features

### Recommended
- **Android:** 8.0 (Oreo) or higher
- **RAM:** 4GB or more
- **Storage:** 500MB free space
- **Internet:** Stable 4G/WiFi connection

### Permissions Required
- **Camera:** For taking visit photos
- **Storage:** For saving photos and PDFs
- **Internet:** For syncing with server
- **Location:** For visit tracking (optional)

---

## 📞 Support Information

### For Technical Issues:
- **Email:** support@tndsystem.com (update with actual email)
- **Phone:** +62 xxx xxxx xxxx (update with actual phone)

### For Training:
- Refer to **USER_GUIDE.md** (876 lines comprehensive guide)
- Section: "Mobile Apps User Guide"
- Available in: English and Bahasa Indonesia

---

## 🔄 Update Process

### For Future Updates:

1. **Build new APK** with updated version number
2. **Test thoroughly** on test devices
3. **Distribute** to users via same channels
4. **Users install** over existing app (data preserved)
5. **Notify users** of new features/fixes

### Version Numbering
Follow semantic versioning: MAJOR.MINOR.PATCH
- **MAJOR:** Breaking changes
- **MINOR:** New features
- **PATCH:** Bug fixes

Current: 1.0.0

---

## 📝 Release Notes - Version 1.0.0

### New Features
✨ Modern purple gradient login screen  
✨ Complete outlet management system  
✨ Daily visit tracking with photos  
✨ Recommendations feature with PDF export  
✨ Comprehensive reporting system  
✨ User profile management  
✨ Privacy policy page  

### Improvements
🔧 Optimized image upload (max 5MB)  
🔧 Better error handling and messages  
🔧 Improved UI/UX consistency  
🔧 Database schema compatibility with production  

### Bug Fixes
🐛 Fixed visit detail display issues  
🐛 Fixed photo upload errors  
🐛 Fixed recommendation save functionality  
🐛 Fixed report generation  
🐛 Removed dark mode (stability)  

### Known Issues
⚠️ Social media login buttons are UI only (not functional)  
⚠️ "Get Started" button shows info dialog (no signup feature)  
⚠️ "Forgot Password" shows info dialog (contact admin required)  

---

## 🎯 Success Metrics

Track these metrics post-deployment:

- Number of successful installations
- Daily active users
- Login success rate
- Visit submissions per day
- Photo upload success rate
- Report generation frequency
- App crashes (should be near 0%)
- User feedback and ratings

---

## 📄 Related Documentation

1. **USER_GUIDE.md** - Complete user manual (876 lines)
   - Super Admin Web Guide
   - Mobile Apps Guide
   - FAQ & Troubleshooting

2. **SETUP_SUPER_ADMIN.md** - Admin account setup
   - Database access guide
   - phpMyAdmin instructions

3. **PRODUCTION_DEPLOYMENT_GUIDE.md** - Backend deployment
   - cPanel setup
   - Database configuration
   - API endpoints

---

## ✅ Post-Release Checklist

After distributing the app:

- [ ] Collect user feedback
- [ ] Monitor error logs
- [ ] Track active users
- [ ] Note feature requests
- [ ] Plan next update
- [ ] Update documentation as needed
- [ ] Train new users
- [ ] Provide ongoing support

---

## 🏆 Deployment Success

Once APK is distributed and tested:

### Celebrate! 🎉
Your TND Mobile App is now live and ready to help your sales team manage outlets, track visits, and generate reports efficiently!

### Next Steps:
1. Monitor usage patterns
2. Gather user feedback
3. Plan feature enhancements
4. Schedule regular updates
5. Maintain backend infrastructure

---

**Last Updated:** January 2025  
**Document Version:** 1.0  
**Maintained By:** TND Development Team
