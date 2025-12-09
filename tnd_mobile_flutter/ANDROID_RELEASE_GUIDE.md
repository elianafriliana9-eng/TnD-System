# 🤖 Android Production Release Guide - TND Mobile

**Quick reference for deploying TND Mobile to Google Play Store**

---

## 📋 Prerequisites

- [ ] Android Studio installed (optional but recommended)
- [ ] Flutter SDK 3.9.2+ installed
- [ ] Java JDK installed (for keytool)
- [ ] Google Play Console account ($25 one-time fee)

---

## Step 1: Generate Release Keystore (One-time setup)

### Create Keystore
```bash
keytool -genkey -v -keystore C:\keys\tnd-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias tnd-key
```

**You will be asked for:**
- Keystore password (create a strong password)
- Key password (create a strong password, can be same as keystore)
- Name, Organization, City, State, Country

**⚠️ CRITICAL: Save these credentials securely!**
```
Keystore Path: C:\keys\tnd-release-key.jks
Keystore Password: [YOUR_PASSWORD]
Key Alias: tnd-key
Key Password: [YOUR_PASSWORD]
```

**Backup your keystore file! If you lose it, you cannot update your app!**

---

## Step 2: Configure Signing in Android Project

### Create `android/key.properties`
```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=tnd-key
storeFile=C:/keys/tnd-release-key.jks
```

**⚠️ Never commit this file to Git!** (Already added to .gitignore)

### Update `android/app/build.gradle.kts`

Add at the top (before `plugins` block):
```kotlin
import java.util.Properties
import java.io.FileInputStream

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
```

Update `signingConfigs` section:
```kotlin
signingConfigs {
    create("release") {
        keyAlias = keystoreProperties["keyAlias"] as String
        keyPassword = keystoreProperties["keyPassword"] as String
        storeFile = file(keystoreProperties["storeFile"] as String)
        storePassword = keystoreProperties["storePassword"] as String
    }
}

buildTypes {
    release {
        isMinifyEnabled = true
        isShrinkResources = true
        proguardFiles(
            getDefaultProguardFile("proguard-android-optimize.txt"),
            "proguard-rules.pro"
        )
        signingConfig = signingConfigs.getByName("release")
    }
}
```

---

## Step 3: Update Version Number

Edit `pubspec.yaml`:
```yaml
version: 1.0.0+1  # Format: major.minor.patch+buildNumber
```

For updates, increment:
- Build number (+1, +2, +3...) for every Play Store upload
- Version number (1.0.1, 1.1.0, 2.0.0) for user-visible updates

---

## Step 4: Production Checklist

### Code Quality
- [ ] Remove all `print()` statements or replace with logging
- [ ] Run `flutter analyze` and fix critical issues
- [ ] Test all features in release mode: `flutter run --release`

### API Configuration
- [ ] Verify production API URL is set
- [ ] Test API connectivity
- [ ] Ensure using HTTPS endpoints

### Security
- [ ] Remove debug features
- [ ] Disable cleartext traffic if using HTTPS only
- [ ] Verify ProGuard rules don't break functionality

---

## Step 5: Build Release APK/AAB

### For Testing (APK)
```bash
cd C:\laragon\www\tnd_system\tnd_system\tnd_mobile_flutter
flutter clean
flutter pub get
flutter build apk --release
```

**Output:** `build\app\outputs\flutter-apk\app-release.apk`

### For Play Store (App Bundle - Required)
```bash
flutter build appbundle --release
```

**Output:** `build\app\outputs\bundle\release\app-release.aab`

---

## Step 6: Test Release Build

### Install APK on Physical Device
```bash
adb install build\app\outputs\flutter-apk\app-release.apk
```

### Test Everything:
- [ ] App launches correctly
- [ ] Login works
- [ ] API calls succeed
- [ ] Camera and photo permissions work
- [ ] PDF generation works
- [ ] Signature capture works
- [ ] Share functionality works
- [ ] No crashes or errors

---

## Step 7: Prepare Play Store Assets

### Required Assets:

#### 1. App Icon (Already configured)
- 512x512 PNG icon for Play Store listing

#### 2. Feature Graphic
- 1024x500 pixels
- Showcases your app

#### 3. Screenshots (Required)
- **Minimum:** 2 screenshots
- **Recommended:** 4-8 screenshots
- Phone: 1080x1920 to 3840x2160 pixels
- Show key features: Login, Dashboard, Checklist, Reports, etc.

#### 4. App Description
**Short Description (80 chars max):**
```
Training & Development management for field operations and reporting
```

**Full Description (4000 chars max):**
```
TND Mobile - Training & Development Management System

Streamline your training and development operations with TND Mobile. 
This comprehensive mobile solution enables field teams to:

✓ Manage visit schedules efficiently
✓ Complete interactive checklists with photo documentation
✓ Capture digital signatures
✓ Generate professional PDF reports
✓ Track training progress and recommendations
✓ Access outlet and division information
✓ Work offline with data synchronization

Perfect for organizations managing field training operations, quality 
assurance, and compliance tracking.

KEY FEATURES:
• Secure authentication and role-based access
• Dynamic visit scheduling
• Customizable checklists with photo capture
• Digital signature support
• PDF report generation with charts
• Offline data handling
• Multi-channel report sharing
• Real-time data synchronization

Built for training coordinators, field supervisors, and management 
teams to improve operational efficiency and ensure compliance.
```

#### 5. Privacy Policy URL (Required)
Create a privacy policy webpage and provide the URL.

#### 6. Content Rating
Complete the questionnaire in Play Console (covers violence, mature content, etc.)

---

## Step 8: Google Play Console Setup

### Initial Setup (One-time)
1. Go to https://play.google.com/console
2. Pay $25 one-time registration fee
3. Complete account verification

### Create App
1. Click "Create App"
2. App name: **TND Mobile**
3. Language: English (or your primary language)
4. App/Game: App
5. Free/Paid: Free (or as needed)

### App Setup
1. **Store Listing:**
   - Upload icon, feature graphic, screenshots
   - Add descriptions
   - Set category: Business
   - Add contact email
   - Privacy policy URL

2. **Content Rating:**
   - Complete questionnaire
   - Submit for rating

3. **App Content:**
   - Privacy policy
   - Ads declaration (if any)
   - Target audience
   - News apps declaration

4. **Store Settings:**
   - App category: Business
   - Tags: Training, Business, Management

### Production Release
1. **Create Release:**
   - Go to "Production"
   - Click "Create new release"
   - Upload `app-release.aab`
   - Add release notes

2. **Release Notes Example:**
```
Version 1.0.0 - Initial Release

• Secure user authentication
• Visit schedule management
• Interactive checklists with photos
• Digital signature capture
• PDF report generation
• Offline support
• Real-time synchronization
```

3. **Review and Rollout:**
   - Review all sections
   - Submit for review
   - Google typically reviews in 24-48 hours

---

## Step 9: Beta Testing (Recommended)

Before production release, test with real users:

1. **Internal Testing** (up to 100 testers)
   - Instant publishing (no review)
   - Share test link with team

2. **Closed Testing** (Open/Closed tracks)
   - Invite specific testers
   - Get feedback before public release

3. **Open Testing**
   - Anyone can join
   - Wider testing before production

---

## 🔧 Common Issues & Solutions

### Build Fails with Signing Error
**Problem:** Can't find keystore or wrong password
**Solution:**
- Check `key.properties` path is correct
- Verify passwords are correct
- Use absolute paths for `storeFile`

### ProGuard Causes Crashes
**Problem:** App crashes in release but not debug
**Solution:**
- Check `proguard-rules.pro` for missing keep rules
- Test thoroughly in release mode
- Add keep rules for problematic classes

### App Size Too Large
**Problem:** APK/AAB is very large
**Solution:**
- Already configured: minification and resource shrinking
- Consider removing unused dependencies
- Compress images in assets folder

### Upload Rejected
**Problem:** Play Store rejects upload
**Solution:**
- Increment version code in `pubspec.yaml`
- Check for policy violations
- Ensure all required assets are uploaded

---

## 📊 Version Management

### Semantic Versioning
```
version: MAJOR.MINOR.PATCH+BUILD

1.0.0+1   - Initial release
1.0.1+2   - Bug fix (patch)
1.1.0+3   - New feature (minor)
2.0.0+4   - Breaking change (major)
```

### For Every Update:
1. Increment build number (+1)
2. Update version if needed
3. Build new AAB
4. Upload to Play Console
5. Add release notes

---

## 🚀 Quick Command Reference

```bash
# Clean and rebuild
flutter clean && flutter pub get

# Test release mode
flutter run --release

# Build APK for testing
flutter build apk --release

# Build AAB for Play Store
flutter build appbundle --release

# Check APK size
flutter build apk --release --analyze-size

# Check code issues
flutter analyze

# Run tests
flutter test
```

---

## 📞 Support Resources

- **Flutter Docs:** https://docs.flutter.dev/deployment/android
- **Play Console:** https://play.google.com/console
- **Play Console Help:** https://support.google.com/googleplay/android-developer

---

## ✅ Pre-Upload Checklist

Final checks before uploading to Play Store:

- [ ] Version number incremented
- [ ] Keystore properly configured
- [ ] App tested in release mode on physical devices
- [ ] All features working (login, camera, PDF, etc.)
- [ ] Debug code removed
- [ ] Production API configured
- [ ] App Bundle (.aab) built successfully
- [ ] Screenshots captured
- [ ] Store listing complete
- [ ] Privacy policy published
- [ ] Content rating completed
- [ ] Release notes written

**When all checked: Upload to Play Console and submit for review!**

---

**Last Updated:** October 2024  
**Status:** Ready for Android deployment
