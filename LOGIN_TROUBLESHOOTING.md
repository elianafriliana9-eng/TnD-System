# TND System Mobile - Login Troubleshooting Guide

## Problem: Login Failed pada Mobile Apps

### Quick Checklist:

1. **✓ API URL Configuration**
   - Android Emulator: `http://10.0.2.2/tnd_system/tnd_system/backend-web/api`
   - iOS Simulator: `http://localhost/tnd_system/tnd_system/backend-web/api`
   - Physical Device: `http://[YOUR_IP]/tnd_system/tnd_system/backend-web/api`

2. **✓ Laragon Running**
   - Pastikan Laragon sudah start
   - Apache dan MySQL harus running
   - Test di browser: `http://localhost/tnd_system/tnd_system/backend-web/api/test.php`

3. **✓ CORS Headers**
   - Sudah ditambahkan di semua API files
   - `Access-Control-Allow-Origin: *`
   - `Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS`

### Testing Steps:

#### Step 1: Test API di Browser
```
http://localhost/tnd_system/tnd_system/backend-web/api/test.php
```
Harus return JSON dengan `"success": true`

#### Step 2: Test API dari Mobile (Connection Test)
1. Run aplikasi mobile
2. Di login screen, klik "Test API Connection"
3. Harus muncul ✅ Connection successful

#### Step 3: Test Login di Browser
POST ke: `http://localhost/tnd_system/tnd_system/backend-web/api/login.php`
Body:
```json
{
  "email": "admin@tnd-system.com",
  "password": "admin123"
}
```

#### Step 4: Check Debug Logs
Di Flutter console, akan muncul logs:
```
=== LOGIN ATTEMPT ===
Email: admin@tnd-system.com
API URL: http://10.0.2.2/tnd_system/tnd_system/backend-web/api/login.php
API Request URL: http://10.0.2.2/tnd_system/tnd_system/backend-web/api/login.php
POST Request: ...
Response Status: 200
Response Body: ...
Login Response: success=true, message=...
```

### Common Issues & Solutions:

#### Issue 1: Connection Timeout
**Cause:** Wrong URL or Laragon not running
**Solution:** 
- Check Laragon is running
- Verify URL in `lib/utils/constants.dart`
- For Android Emulator, use `10.0.2.2` not `localhost`

#### Issue 2: CORS Error
**Cause:** Browser/app blocking cross-origin requests
**Solution:**
- Already fixed in backend with CORS headers
- Restart Laragon after adding CORS headers

#### Issue 3: 401 Unauthorized
**Cause:** Wrong credentials
**Solution:**
- Use default: `admin@tnd-system.com` / `admin123`
- Or check database: `SELECT * FROM users;`

#### Issue 4: Invalid JSON Response
**Cause:** PHP error or wrong response format
**Solution:**
- Check PHP error logs in Laragon
- Verify Response.php class exists and works

### Default Test Credentials:

```
Email: admin@tnd-system.com
Password: admin123
```

Or:

```
Email: elianjhon100@gmail.com
Password: 123456
```

### URLs to Update:

**File:** `lib/utils/constants.dart`

Choose based on your testing device:

```dart
// Android Emulator (DEFAULT)
static const String apiBaseUrl = 'http://10.0.2.2/tnd_system/tnd_system/backend-web/api';

// iOS Simulator
// static const String apiBaseUrl = 'http://localhost/tnd_system/tnd_system/backend-web/api';

// Physical Device (Replace with your PC IP)
// static const String apiBaseUrl = 'http://192.168.1.100/tnd_system/tnd_system/backend-web/api';
```

### How to Find Your PC IP (for Physical Device):

**Windows:**
```powershell
ipconfig
```
Look for "IPv4 Address" under your active network adapter.

**Example:** `192.168.1.100`

Then update constants.dart:
```dart
static const String apiBaseUrl = 'http://192.168.1.100/tnd_system/tnd_system/backend-web/api';
```

### Debug Mode Enabled:

All API calls now print debug info to console:
- Request URL
- Request body
- Response status
- Response body

Check Flutter console for detailed logs.
