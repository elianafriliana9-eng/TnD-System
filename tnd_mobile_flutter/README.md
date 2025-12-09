# TND Mobile - Training & Development Mobile Application

A Flutter mobile application for managing training and development activities, visit schedules, checklists, and reporting.

## 📱 About

TND Mobile is a comprehensive mobile solution for training and development management, featuring:

- User authentication and role-based access
- Visit schedule management
- Checklist creation and completion
- Digital signature capture
- PDF report generation and export
- Outlet and division management
- Real-time data synchronization with backend API

## 🚀 Features

- ✅ Secure login with token-based authentication
- ✅ Dynamic API configuration
- ✅ Visit scheduling and tracking
- ✅ Interactive checklists with photo capture
- ✅ Digital signature support
- ✅ PDF report generation with charts
- ✅ Offline data handling
- ✅ Share reports via multiple channels
- ✅ Material Design 3 UI

## 📋 Requirements

- Flutter SDK: 3.9.2 or higher
- Dart SDK: 3.9.2 or higher
- Android SDK: Min API 21 (Android 5.0+)
- iOS: iOS 12.0+

## 🛠️ Installation

### 1. Clone the repository
```bash
git clone <repository-url>
cd tnd_mobile_flutter
```

### 2. Install dependencies
```bash
flutter pub get
```

### 3. Generate app icons
```bash
flutter pub run flutter_launcher_icons
```

### 4. Generate splash screen
```bash
flutter pub run flutter_native_splash:create
```

### 5. Run the app
```bash
# Development mode
flutter run

# Release mode
flutter run --release
```

## 🏗️ Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
├── screens/                  # UI screens
├── services/                 # API and business logic services
├── utils/                    # Utilities and constants
└── widgets/                  # Reusable UI components

android/                      # Android platform code
ios/                         # iOS platform code
assets/                      # Images, fonts, etc.
```

## 🔧 Configuration

### API Configuration
The app uses dynamic API configuration. Set the API URL in the app settings:
- Default: Can be changed in Settings screen
- Stored in SharedPreferences

### Network Security
- Android: Uses network security config for HTTP/HTTPS
- iOS: Info.plist configured for required permissions

## 📦 Dependencies

Main dependencies:
- `provider: ^6.1.1` - State management
- `http: ^1.1.0` - HTTP client
- `shared_preferences: ^2.2.2` - Local storage
- `image_picker: ^1.0.7` - Camera/gallery access
- `pdf: ^3.11.3` - PDF generation
- `signature: ^6.3.0` - Digital signature
- `fl_chart: ^0.68.0` - Charts and graphs
- `share_plus: ^7.2.2` - Share functionality

See `pubspec.yaml` for complete list.

## 🚀 Production Deployment

For production deployment instructions, see [PRODUCTION_SETUP.md](PRODUCTION_SETUP.md)

### Quick Build Commands

**Android:**
```bash
flutter build appbundle --release
```

**iOS:**
```bash
flutter build ios --release
```

## 🧪 Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage
```

## 📊 Code Quality

```bash
# Analyze code
flutter analyze

# Format code
dart format .
```

## 🔐 Security Notes

- Never commit API keys or credentials
- Use environment variables for sensitive data
- Production builds use code obfuscation
- HTTPS required for production API endpoints

## 📄 License

Proprietary - TND System

## 👥 Team

Development team for TND System

## 📞 Support

For issues or questions, contact the development team.

---

**Version:** 1.0.0+1  
**Last Updated:** October 2024
