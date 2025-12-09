# TND Mobile - Production Setup Guide

## ✅ Current Status: Production-Ready Configurations Applied

### Changes Made:

#### 1. **Android Configuration**
- ✅ Changed package name from `com.example.tnd_mobile_flutter` to `com.tnd.mobile`
- ✅ Set minimum SDK to 21 (Android 5.0)
- ✅ Enabled MultiDex support
- ✅ Configured ProGuard for code obfuscation and optimization
- ✅ Added release build type with minification
- ✅ Created ProGuard rules file

#### 2. **iOS Configuration**
- ✅ Updated app display name to "TND Mobile"
- ✅ Added camera permission descriptions (NSCameraUsageDescription)
- ✅ Added photo library permission descriptions (NSPhotoLibraryUsageDescription)
- ✅ Added photo library add permission (NSPhotoLibraryAddUsageDescription)

#### 3. **Security**
- ✅ Network security config already in place
- ✅ Permissions properly configured (Internet, Storage, Camera)

---

## 🚀 Next Steps for Production Deployment

### Step 1: Generate Android Signing Key

```bash
keytool -genkey -v -keystore C:\path\to\tnd-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias tnd-key
```

**Save these credentials securely:**
- Keystore password
- Key alias: tnd-key
- Key password

### Step 2: Configure Android Signing

Create `android/key.properties`:
```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=tnd-key
storeFile=C:/path/to/tnd-release-key.jks
```

Add to `.gitignore`:
```
**/android/key.properties
**/android/*.jks
```

Update `android/app/build.gradle.kts` signingConfigs section:
```kotlin
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

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
        signingConfig = signingConfigs.getByName("release")
        // ... rest of config
    }
}
```

### Step 3: iOS Code Signing

1. Enroll in Apple Developer Program ($99/year)
2. Create App ID in Apple Developer Console: `com.tnd.mobile`
3. Create provisioning profiles (Development & Distribution)
4. Configure in Xcode:
   - Open `ios/Runner.xcworkspace`
   - Select Runner target
   - Go to Signing & Capabilities
   - Select your team
   - Ensure bundle identifier is `com.tnd.mobile`

### Step 4: Update API Configuration

**Important:** Ensure production API URL is configured:

1. Remove or disable `usesCleartextTraffic="true"` in AndroidManifest.xml for production
2. Use HTTPS endpoints only
3. Update API URLs in the app settings

### Step 5: Test Production Build

**Android:**
```bash
flutter build apk --release
# or for App Bundle (recommended for Play Store)
flutter build appbundle --release
```

**iOS:**
```bash
flutter build ios --release
```

### Step 6: App Store Preparation

#### Android - Google Play Store
- [ ] Create Google Play Console account
- [ ] Prepare store listing (screenshots, description)
- [ ] Set up app content rating
- [ ] Configure pricing & distribution
- [ ] Upload app bundle (`.aab` file recommended)

#### iOS - Apple App Store
- [ ] Create App Store Connect account
- [ ] Create app record in App Store Connect
- [ ] Prepare App Store screenshots & metadata
- [ ] Submit for review via Xcode or Transporter

---

## 📋 Pre-Launch Checklist

### Security
- [ ] All API calls use HTTPS
- [ ] Sensitive data encrypted in storage
- [ ] Authentication tokens properly secured
- [ ] No hardcoded credentials in code
- [ ] ProGuard rules tested

### Testing
- [ ] Test on physical Android devices (various versions)
- [ ] Test on physical iOS devices
- [ ] Test all features in release mode
- [ ] Test offline functionality
- [ ] Test camera and photo permissions
- [ ] Test PDF generation and sharing
- [ ] Test signature capture
- [ ] Performance testing (loading times, memory usage)

### Configuration
- [ ] Production API endpoint configured
- [ ] Remove debug logging
- [ ] Disable debug mode features
- [ ] Analytics properly configured
- [ ] Crash reporting enabled (consider Firebase Crashlytics)
- [ ] App version number updated

### Legal & Compliance
- [ ] Privacy Policy URL added
- [ ] Terms of Service prepared
- [ ] GDPR compliance checked (if applicable)
- [ ] Data retention policies implemented

---

## 🔧 Build Commands Reference

### Development
```bash
flutter run --debug
```

### Production Testing
```bash
flutter run --release
```

### Android Production Build
```bash
# APK (for testing/direct distribution)
flutter build apk --release

# App Bundle (for Play Store)
flutter build appbundle --release
```

### iOS Production Build
```bash
flutter build ios --release
```

### Analyze Code
```bash
flutter analyze
```

### Run Tests
```bash
flutter test
```

---

## 📱 Version Management

Current version: `1.0.0+1`

Update in `pubspec.yaml`:
```yaml
version: 1.0.0+1  # format: major.minor.patch+build
```

- First number (1.0.0): Version name shown to users
- Second number (+1): Build number (increment for each release)

---

## 🔐 Environment Variables (Recommended)

Consider using environment-specific configurations:

1. Install `flutter_dotenv` package
2. Create `.env.production` and `.env.development`
3. Store API URLs, keys separately
4. Add `.env*` to `.gitignore`

---

## 📊 Monitoring & Analytics

**Recommended Tools:**
- Firebase Crashlytics (crash reporting)
- Firebase Analytics (user behavior)
- Sentry (error tracking)

---

## 🆘 Troubleshooting

### Common Issues:

**Build fails with signing error:**
- Check keystore path in key.properties
- Verify passwords are correct

**ProGuard issues:**
- Check proguard-rules.pro
- Add missing keep rules for libraries

**iOS provisioning issues:**
- Clean build: `flutter clean`
- Delete derived data in Xcode
- Regenerate provisioning profiles

---

## 📞 Support

For issues or questions, contact the development team.

---

**Last Updated:** October 2024
**Status:** ✅ Ready for production builds (pending signing configuration)
