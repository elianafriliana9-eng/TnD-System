# TND System - Context & Recent Changes

**Last Updated:** December 8, 2025

## Recent Major Changes

### 1. Training Dashboard - DISABLED (Dec 8, 2025)
**Status:** 🔄 DISABLED - Focus on Daily Training

- **Training Dashboard** di-disable sementara dari home screen
- Keputusan untuk fokus pengembangan di **Daily Training** untuk InHouse Training
- Dashboard code tetap ada dan bisa di-enable kembali kapan saja
- Issue pending sessions (troubleshooting sudah dilakukan, siap untuk fix nanti)

**What Was Done:**
- Fixed backend query: `pending_sessions` include both 'pending' and 'scheduled' status
- Extended default date range: 30 days back + 30 days forward
- Added debug logging (frontend & backend)
- Improved type parsing with `int.tryParse()`

**Files Modified:**
- `lib/screens/home_screen.dart` - Commented out Training Dashboard card
- `backend-web/api/training/stats.php` - Fixed query (ready for when enabled)
- `lib/services/training/training_service.dart` - Extended date range (ready for when enabled)
- `lib/screens/training/training_dashboard_screen.dart` - Added debug logs (ready for when enabled)

---

### 2. Color Palette Unification (Blue Theme)
**Status:** ✅ COMPLETED

Semua modul training sekarang menggunakan tema **BIRU** yang konsisten dengan home screen.

#### Home Screen
- Feature cards: Glass morphism dengan gradient biru
- Training Dashboard card: `#5B9BD5` → `#2E75B5`

#### Training Dashboard Screen
- **Header gradient**: `#4A90E2` → `#357ABD` (Blue)
- **Avatar icon**: Blue `#4A90E2`
- **Greeting card**: Blue theme
- **Touch app icon background**: Light blue `#E3F2FD`
- **Generate PDF button**: Blue `#4A90E2`
- **Date picker theme**: Blue
- **Success snackbar**: Blue

#### Training Main Screen
- **Header gradient**: `#4A90E2` → `#357ABD` (Blue)
- **Avatar icon**: Blue `#4A90E2`
- **Jadwal Training card**: Blue `#4A90E2`
- **Manajemen Checklist card**: Teal `#26A69A`
- **Daily Training card**: Indigo `#5C6BC0`

#### Checklist Management Screen
- **AppBar**: Teal `#26A69A`
- **Badge item count**: Teal light `#B2DFDB`
- **Expanded section background**: Teal lightest `#E0F2F1`
- **Item number badge**: Teal
- **Button Tambah Item**: Teal `#26A69A`

#### Daily Training Screen
- **AppBar**: Indigo `#5C6BC0`
- **Card status colors**:
  - Completed: Indigo lightest `#E8EAF6`
  - Ongoing: Indigo light `#C5CAE9`
  - Scheduled: Indigo medium `#9FA8DA`
- **Button Lihat Detail**: Indigo `#5C6BC0`
- **Button Lanjutkan**: Indigo `#5C6BC0`
- **Button Mulai**: Purple `#7E57C2`

**Files Modified:**
- `lib/screens/training/training_dashboard_screen.dart`
- `lib/screens/training/training_main_screen.dart`
- `lib/screens/training/training_checklist_management_screen.dart`
- `lib/screens/training/training_daily_screen.dart`

---

### 3. UI Improvements (Previous)
**Status:** ✅ COMPLETED

- Glass morphism effects di home screen (cards, icons, banner)
- Search box dihapus dari home screen
- Welcome banner dengan glass blur effect
- Modern gradient designs untuk training screens

---

## Color Palette Reference

### Primary Colors
- **Main Blue**: `#4A90E2` - Primary actions, headers
- **Dark Blue**: `#357ABD` - Gradients, hover states
- **Light Blue**: `#E3F2FD` - Backgrounds, highlights

### Secondary Colors
- **Teal**: `#26A69A` - Checklist management
- **Indigo**: `#5C6BC0` - Daily training
- **Purple**: `#7E57C2` - Action buttons

### Status Colors
- **Success/Completed**: Indigo lightest `#E8EAF6`
- **Ongoing**: Indigo light `#C5CAE9`
- **Scheduled**: Indigo medium `#9FA8DA`
- **Error/Cancelled**: Red shades (unchanged)

---

## Architecture Notes

### Training Module Structure
```
Home Screen (Main)
├── InHouse Training (Menu)
│   ├── Jadwal Training (Schedule management)
│   ├── Manajemen Checklist (Checklist categories & points)
│   └── Daily Training (Today's sessions - MAIN FOCUS)
│       ├── Scheduled sessions
│       ├── Start/Continue training
│       └── Complete with digital signature
└── Training Dashboard ← DISABLED (Dec 8, 2025)
    [Temporarily disabled - focus on Daily Training]
```

### Key Services
- `TrainingService` - API calls untuk training sessions
- `DivisionService` - Division data
- `TrainingPDFService` - PDF generation dengan foto attachments

### Backend APIs
- `api/training/stats.php` - Dashboard statistics
- `api/training/sessions-list.php` - Training sessions list
- `api/training/session-detail.php` - Session detail
- `api/divisions.php` - Division list

---

## Known Issues / Notes

### Device Detection
- ADB mendeteksi device fisik (`79d272af`)
- Flutter devices mungkin perlu restart VSCode atau `flutter doctor`
- USB Debugging harus enabled di device Android

### Push Notification
- Feature push notification **DITUNDA** untuk tahun depan
- Dependencies FCM sudah di-revert dari pubspec.yaml

---

## Next Steps / TODO

### High Priority - Daily Training Focus
- [ ] Test Daily Training workflow end-to-end di device fisik
- [ ] Verify crew name & crew leader display di checklist dan PDF
- [ ] Test 4-level rating system (BS/B/C/K) functionality
- [ ] Verify digital signature flow dengan crew leader input
- [ ] Upload modified files ke production

### Medium Priority
- [ ] Test jadwal training creation dengan crew name input
- [ ] Verify glass morphism effects di berbagai device
- [ ] Test PDF generation (single page, crew name/leader separation)

### Low Priority / Future
- [ ] Re-enable Training Dashboard (sudah siap, tinggal uncomment)
- [ ] Push notification feature (2026)
- [ ] Additional color theme options
- [ ] Dark mode support

---

## Development Setup

### Prerequisites
- Flutter SDK
- Android Studio / VS Code
- Device fisik dengan USB Debugging enabled
- ADB installed

### Commands
```bash
# Check devices
adb devices
flutter devices

# Run app
flutter run

# Format code
dart format lib/

# Check errors
flutter analyze
```

---

## Recent File Changes (Dec 5-8, 2025)

### Mobile App (Flutter)
```
tnd_mobile_flutter/
├── lib/
│   ├── screens/
│   │   ├── home_screen.dart ← MODIFIED (Dashboard disabled Dec 8)
│   │   ├── digital_signature_screen.dart ← MODIFIED (Reordered form Dec 5)
│   │   └── training/
│   │       ├── training_main_screen.dart ← Blue theme
│   │       ├── training_dashboard_screen.dart ← Debug logs (disabled)
│   │       ├── training_checklist_management_screen.dart ← Teal theme
│   │       ├── training_daily_screen.dart ← Indigo theme, crew name fix
│   │       ├── training_schedule_form_screen.dart ← Crew name input
│   │       └── training_session_checklist_screen.dart ← 4-level rating
│   ├── services/
│   │   └── training/
│   │       ├── training_service.dart ← Crew name mapping, date range fix
│   │       └── training_pdf_service.dart ← Crew name/leader separation
│   └── models/
│       └── training/
│           ├── training_schedule_model.dart ← Added crewName field
│           └── training_session_model.dart ← Added crewName field
```

### Backend (PHP)
```
backend-web/
├── api/
│   ├── training/
│   │   ├── session-start.php ← Crew name handling
│   │   ├── session-actual-start.php ← Crew name SELECT
│   │   ├── signatures-save.php ← Crew name UPDATE
│   │   ├── sessions-list.php ← Crew name in response
│   │   └── stats.php ← Pending fix, debug logs
│   ├── user-change-password.php ← NEW (Dec 5)
│   └── ...
```

### Web Admin (Frontend)
```
frontend-web/
├── assets/
│   └── js/
│       ├── users.js ← Change password modal & functions
│       └── api.js ← UsersAPI.changePassword() method
```

---

## Summary of Current State (Dec 8, 2025)

### Training System Status
- ✅ **Daily Training**: Fully functional, main focus
  - Per-crew training system (crew name input di schedule)
  - Crew leader input di digital signature
  - 4-level rating (BS/B/C/K)
  - Single page PDF with proper crew name/leader separation
  - Glass morphism UI dengan indigo theme
  
- 🔄 **Training Dashboard**: Temporarily disabled
  - Code ready, fixes applied (pending query, date range)
  - Can be re-enabled anytime by uncommenting in home_screen.dart
  - Decision: Focus on Daily Training development first

- ✅ **Checklist Management**: Operational (teal theme)
- ✅ **Schedule Management**: Operational (blue theme)

### Web Admin Status
- ✅ User management with change password feature
- ✅ Outlet management
- ✅ Training reports access

### Key Recent Changes
1. **Dec 5**: Crew name/leader separation, PDF fix, TTD form reorder, change password user
2. **Dec 8**: Training Dashboard disabled, extended debugging for future re-enable
