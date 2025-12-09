# TND System - Privacy Policy Documentation

## 📄 Available Documents

### 1. **Full Privacy Policy**
- **English:** `PRIVACY_POLICY.md`
- **Bahasa Indonesia:** `PRIVACY_POLICY_ID.md`
- **Web Version:** `frontend-web/privacy-policy.html`

### 2. **Summary Version**
- `PRIVACY_POLICY_SUMMARY.md` - Quick overview for in-app display

---

## 🌐 Privacy Policy URLs

### Development (Local):
```
http://localhost/tnd_system/tnd_system/frontend-web/privacy-policy.html
```

### Production (After Hosting):
```
https://yourdomain.com/privacy-policy.html
```

---

## 📱 How to Use in Mobile App

### Option 1: Show Privacy Policy Link

Add link in registration screen:

```dart
// lib/screens/register_screen.dart

InkWell(
  onTap: () {
    // Open privacy policy URL
    launchUrl(Uri.parse('https://yourdomain.com/privacy-policy.html'));
  },
  child: Text(
    'Privacy Policy',
    style: TextStyle(
      color: Colors.blue,
      decoration: TextDecoration.underline,
    ),
  ),
)
```

### Option 2: Show In-App Dialog

Display summary in dialog:

```dart
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: Text('Privacy Policy'),
    content: SingleChildScrollView(
      child: Text('''
By using TND System, you agree that we collect:
- Personal Info (name, email, phone)
- Visit Data (location, photos, checklist)
- Device Info

Read full policy at: https://yourdomain.com/privacy-policy.html
      '''),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text('I Agree'),
      ),
    ],
  ),
);
```

### Option 3: WebView (Recommended)

Show full HTML version in WebView:

```dart
import 'package:webview_flutter/webview_flutter.dart';

// In build method:
WebView(
  initialUrl: 'https://yourdomain.com/privacy-policy.html',
  javascriptMode: JavascriptMode.unrestricted,
)
```

---

## ✅ Registration Flow with Privacy Policy

### Recommended Implementation:

1. **Registration Screen:**
   - Add checkbox: "I agree to the [Privacy Policy](link)"
   - Link opens WebView or browser
   - Register button disabled until checked

2. **Code Example:**

```dart
bool _agreedToPrivacy = false;

// In form:
CheckboxListTile(
  title: Row(
    children: [
      Text('I agree to the '),
      InkWell(
        onTap: _showPrivacyPolicy,
        child: Text(
          'Privacy Policy',
          style: TextStyle(
            color: Colors.blue,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    ],
  ),
  value: _agreedToPrivacy,
  onChanged: (value) {
    setState(() => _agreedToPrivacy = value ?? false);
  },
)

// Register button:
ElevatedButton(
  onPressed: _agreedToPrivacy ? _register : null,
  child: Text('Register'),
)
```

---

## 🔗 Links to Include in App

### 1. Registration Screen
- Privacy Policy link
- Terms of Service link (if applicable)

### 2. Profile/Settings Screen
- Privacy Policy
- About App
- Contact Support

### 3. About Screen
- Company info
- Privacy Policy
- Version info

---

## 📋 Checklist Before Publishing

### Google Play Store Requirements:
- ✅ Privacy Policy URL in app listing
- ✅ Privacy Policy accessible from app
- ✅ User consent before data collection
- ✅ Clear description of data usage
- ✅ Contact information provided

### Apple App Store Requirements:
- ✅ Privacy Policy in App Store Connect
- ✅ Privacy manifest (iOS 14+)
- ✅ App Tracking Transparency (if tracking)
- ✅ Privacy nutrition labels

---

## 📝 What's Covered

### Personal Data:
- ✅ Name, email, phone, employee ID
- ✅ Division/department
- ✅ Profile photo

### Visit Data:
- ✅ Visit date, time, location
- ✅ Checklist responses
- ✅ Photos and documentation

### Device Data:
- ✅ Device info, OS version
- ✅ App version
- ✅ IP address

### Location Data:
- ✅ GPS coordinates during visits
- ✅ Permission-based collection

### Usage Data:
- ✅ App usage patterns
- ✅ Feature access
- ✅ Error logs

---

## 🔒 Key Privacy Features

1. **No Third-Party Selling:** We don't sell user data
2. **Encryption:** HTTPS/SSL, password hashing
3. **User Control:** Delete account, export data
4. **Transparency:** Clear data usage disclosure
5. **Compliance:** Indonesian law (UU ITE, PDP)

---

## 🌍 Hosting Privacy Policy

### Static Hosting (Recommended):
Upload `privacy-policy.html` to:
- Your website
- GitHub Pages
- Netlify
- Vercel

### Backend Hosting:
Place in `frontend-web/` directory - accessible via your domain

### Content Delivery Network (CDN):
For faster global access

---

## 📱 Required App Permissions

Document these in app store listing:

### Android:
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

### iOS:
```xml
<key>NSCameraUsageDescription</key>
<string>We need camera access to take visit photos</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need location to verify visit check-in</string>
```

---

## 📞 Contact Information

Update these in all policy files before publishing:

- **Email:** support@tndsystem.com → [your-email]
- **Phone:** +62 XXX-XXXX-XXXX → [your-phone]
- **Address:** [Your Company Address] → [actual-address]
- **Website:** https://yourdomain.com → [your-domain]

---

## 🔄 Updating Privacy Policy

When you update the policy:

1. Update all versions (MD, HTML, ID, EN)
2. Change "Last Updated" date
3. Increment version number
4. Notify users via app notification
5. Re-upload to hosting

---

## ✅ Ready to Publish Checklist

- [ ] Privacy Policy uploaded to public URL
- [ ] URL added to Google Play Console
- [ ] URL added to App Store Connect
- [ ] Link in app registration screen
- [ ] Link in app settings
- [ ] Contact info updated
- [ ] Legal review completed (optional)
- [ ] User consent mechanism implemented
- [ ] Data deletion process documented

---

## 📚 Additional Resources

- Google Play Data Safety: https://support.google.com/googleplay/android-developer/answer/10787469
- Apple Privacy: https://developer.apple.com/app-store/user-privacy-and-data-use/
- GDPR Compliance: https://gdpr.eu/
- Indonesia PDP Law: [Link when available]

---

**Last Updated:** October 16, 2025
**Version:** 1.0
