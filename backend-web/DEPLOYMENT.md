# 🚀 TnD System - Deployment Guide

## 📋 Prerequisites

- [ ] Shared hosting account (cPanel recommended)
- [ ] Domain/subdomain configured
- [ ] SSL certificate installed (Let's Encrypt)
- [ ] PHP 8.0 or higher
- [ ] MySQL 5.7 or higher
- [ ] SSH/FTP access to hosting

---

## 🔧 Pre-Deployment Preparation

### 1. Local Verification

Before deploying, verify everything works locally:

```bash
# Test database connection
php test-db-connection.php

# Verify .env is loaded correctly
php -r "require 'config/database.php'; echo 'APP_ENV: ' . (defined('APP_ENV') ? APP_ENV : 'Not loaded');"

# Check if all required directories exist
php create-upload-dirs.php
```

### 2. Generate Strong JWT Secret

Generate a strong JWT secret for production:

```bash
# Linux/Mac
openssl rand -base64 64

# Windows PowerShell
[Convert]::ToBase64String((1..64 | ForEach-Object { Get-Random -Minimum 0 -Maximum 256 }))
```

Save this secret - you'll need it for the production `.env` file.

### 3. Database Export

Export your current database (structure + data):

```bash
# From Laragon MySQL
mysqldump -u root tnd_system > database/tnd_system_export.sql

# Or export only structure
mysqldump -u root --no-data tnd_system > database/schema.sql
```

---

## 📤 Deployment Steps

### Step 1: Upload Files to Hosting

**Via FTP/SFTP** (FileZilla, WinSCP, etc.):

1. Connect to your hosting server
2. Navigate to your domain's root directory (usually `public_html` or `www`)
3. Upload all files EXCEPT:
   - `.env` (will be created manually)
   - `uploads/` directory contents (user data)
   - `logs/` directory
   - `test-db-connection.php` (for temporary testing only)

**Via SSH** (if available):

```bash
# Compress locally
tar -czf tnd_backend.tar.gz --exclude=.env --exclude=uploads/* --exclude=logs/* .

# Upload to server
scp tnd_backend.tar.gz user@yourserver.com:/path/to/public_html/

# Extract on server
ssh user@yourserver.com
cd /path/to/public_html/
tar -xzf tnd_backend.tar.gz
rm tnd_backend.tar.gz
```

### Step 2: Create Production .env File

Create `.env` file on the server with production values:

```env
# Application Environment
APP_ENV=production

# Database Configuration
DB_HOST=localhost
DB_NAME=your_production_db_name
DB_USERNAME=your_db_username
DB_PASSWORD=your_strong_db_password

# JWT Secret (use the generated strong secret)
JWT_SECRET_KEY=your_generated_strong_secret_here

# CORS Configuration (use your actual domain)
CORS_ALLOWED_ORIGINS=https://yourdomain.com,https://www.yourdomain.com
```

**Important Security Notes:**
- Use `APP_ENV=production` for live environment
- Use strong database password (min 16 characters, mixed case, numbers, symbols)
- Use the JWT secret generated in pre-deployment step
- Only allow your actual domain(s) in CORS
- Set file permissions: `chmod 600 .env` (only owner can read/write)

### Step 3: Setup Database

**3.1. Create Database** (via cPanel or phpMyAdmin):

- Database name: `your_production_db_name`
- Charset: `utf8mb4`
- Collation: `utf8mb4_unicode_ci`

**3.2. Create Dedicated Database User**:

```sql
-- Replace placeholders with actual values
CREATE USER 'tnd_user'@'localhost' IDENTIFIED BY 'StrongPassword123!@#';

GRANT SELECT, INSERT, UPDATE, DELETE 
ON your_production_db_name.* 
TO 'tnd_user'@'localhost';

FLUSH PRIVILEGES;
```

**3.3. Import Database**:

Via phpMyAdmin:
1. Select your database
2. Click "Import" tab
3. Choose your `tnd_system_export.sql` file
4. Click "Go"

Via MySQL command line (if SSH available):
```bash
mysql -u your_db_username -p your_production_db_name < database/tnd_system_export.sql
```

**3.4. Verify Database Connection**:

Upload `test-db-connection.php` temporarily and access via browser:
```
https://yourdomain.com/test-db-connection.php
```

Expected output:
```
✓ Database connection successful!
✓ Loaded from .env file
Database: your_production_db_name
```

**⚠️ DELETE `test-db-connection.php` immediately after testing!**

### Step 4: Configure Directory Permissions

Set proper permissions for upload and log directories:

```bash
# Create required directories if not exist
mkdir -p uploads uploads/visit_photos uploads/training/photos uploads/profile_photos logs logs/ratelimit

# Set permissions (via SSH)
chmod 755 uploads uploads/visit_photos uploads/training uploads/training/photos uploads/profile_photos
chmod 755 logs logs/ratelimit
chmod 644 .env

# Or via cPanel File Manager: Right-click → Change Permissions
# Directories: 755
# .env file: 600 or 644
```

### Step 5: Test Backend Endpoints

Test critical endpoints to ensure everything works:

**5.1. Test Login**:
```bash
curl -X POST https://yourdomain.com/api/login.php \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@test.com","password":"admin123"}'
```

Expected: JWT token in response

**5.2. Test Rate Limiting**:

Try logging in 6 times with wrong password - should get HTTP 429 on 6th attempt

**5.3. Test File Upload**:

Upload a test photo via mobile app or Postman to verify upload directories are writable

**5.4. Test CORS**:

Access API from browser console:
```javascript
fetch('https://yourdomain.com/api/outlets-list.php', {
  headers: { 'Authorization': 'Bearer YOUR_TOKEN' }
})
```

Should work from allowed domains, fail from others

### Step 6: Configure SSL (if not done)

Most hosting providers offer free Let's Encrypt SSL via cPanel:

1. cPanel → SSL/TLS Status
2. Select your domain
3. Click "Run AutoSSL"

Verify HTTPS works: `https://yourdomain.com`

### Step 7: Update Mobile App Base URL

**7.1. Update Default Base URL**:

Edit `tnd_mobile_flutter/lib/utils/api_config_manager.dart`:

```dart
static const String _defaultBaseUrl = 'https://yourdomain.com';
```

**7.2. Build Production APK**:

```bash
cd tnd_mobile_flutter
flutter clean
flutter pub get
flutter build apk --release
```

APK location: `build/app/outputs/flutter-apk/app-release.apk`

**7.3. Test APK**:

1. Install on test device
2. Login with production credentials
3. Test all QC features:
   - Create visit
   - Fill checklist
   - Upload photos
   - Generate PDF
   - View reports

---

## ✅ Post-Deployment Checklist

- [ ] `.env` file exists with production values
- [ ] `APP_ENV=production` in .env
- [ ] Strong JWT secret configured
- [ ] Database connection working
- [ ] Dedicated database user created (limited privileges)
- [ ] Upload directories writable (755 permissions)
- [ ] Logs directory writable (755 permissions)
- [ ] `.env` file protected (600/644 permissions)
- [ ] `test-db-connection.php` deleted
- [ ] SSL certificate active (HTTPS working)
- [ ] CORS restricted to production domain only
- [ ] Rate limiting working (test login attempts)
- [ ] File upload validation working (test with oversized/invalid files)
- [ ] Login endpoint working
- [ ] Outlets list endpoint working
- [ ] Visit creation working
- [ ] Photo upload working
- [ ] PDF generation working
- [ ] Mobile app connected to production
- [ ] Error logging working (check logs/error.log)
- [ ] Security headers present (check browser DevTools → Network → Response Headers)

---

## 🔒 Security Best Practices

### 1. File Permissions

```
.env → 600 (only owner read/write)
*.php → 644 (owner write, all read)
directories → 755 (owner full, others read+execute)
uploads/ → 755 (web server needs write access)
logs/ → 755 (web server needs write access)
```

### 2. Hide Sensitive Files

Create `.htaccess` in root directory:

```apache
# Deny access to sensitive files
<FilesMatch "\.(env|log|sql|md)$">
    Order allow,deny
    Deny from all
</FilesMatch>

# Deny access to specific directories
RedirectMatch 403 ^/logs/
RedirectMatch 403 ^/database/
```

### 3. Disable Directory Listing

Add to `.htaccess`:
```apache
Options -Indexes
```

### 4. Regular Backups

Schedule daily database backups via cPanel → Backup Wizard or cron job:

```bash
# Daily backup at 2 AM
0 2 * * * mysqldump -u user -ppassword database > /backups/db_$(date +\%Y\%m\%d).sql
```

### 5. Monitor Error Logs

Regularly check `logs/error.log` for issues:

```bash
tail -f logs/error.log
```

### 6. Update Dependencies

Keep PHP and MySQL updated via hosting control panel

---

## 🐛 Troubleshooting

### Issue: "Database connection failed"

**Solutions:**
1. Verify `.env` values match database credentials
2. Check if database user has proper privileges
3. Ensure database exists
4. Test with `test-db-connection.php`

### Issue: "CORS policy error"

**Solutions:**
1. Verify `CORS_ALLOWED_ORIGINS` in `.env` includes your domain
2. Check if domain uses `https://` (not `http://`)
3. Clear browser cache
4. Check `cors_headers.php` is loaded

### Issue: "File upload failed"

**Solutions:**
1. Check directory permissions (755 for uploads/)
2. Verify PHP `upload_max_filesize` setting (should be ≥5MB)
3. Check PHP `post_max_size` setting
4. Verify web server has write access

### Issue: "Rate limiting too strict"

**Solutions:**
1. Clear rate limit files: `rm -rf logs/ratelimit/*`
2. Adjust limits in `RateLimiter.php` if needed
3. Check system time is correct

### Issue: "JWT token invalid"

**Solutions:**
1. Ensure `JWT_SECRET_KEY` in .env matches what was used to generate tokens
2. Check token expiration (current: 30 days)
3. Clear app data and login again

### Issue: "500 Internal Server Error"

**Solutions:**
1. Check `logs/error.log` for details
2. Verify PHP version ≥8.0
3. Check all required PHP extensions are installed
4. Verify file permissions

---

## 📞 Support Information

**Developer Contact:**
- Name: [Your Name]
- Email: [your-email@example.com]

**Hosting Information:**
- Provider: [Hosting Provider Name]
- Support: [Hosting Support Contact]

**Application Version:** 1.0.0 (QC System - Phase 1)

---

## 📝 Change Log

### Version 1.0.0 (Phase 1 - QC System)
- ✅ Complete QC visit and checklist functionality
- ✅ Photo upload and management
- ✅ PDF report generation
- ✅ Security hardening (.env, rate limiting, validation)
- ✅ Web admin interface
- ⏸️ Training module (deferred to Phase 2)

---

**Last Updated:** October 28, 2025
