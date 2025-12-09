# 📋 Production Deployment Checklist

## 🎯 Pre-Deployment (Local Environment)

### Code & Configuration
- [ ] All code committed to git repository
- [ ] `.gitignore` configured (excludes .env, uploads/, logs/)
- [ ] `.env.example` updated with all required variables
- [ ] All test/debug files deleted (verify with `ls test-*.php debug-*.php`)
- [ ] Error logging configured for production (APP_ENV=production)
- [ ] CORS origins set to production domain only

### Database
- [ ] Database schema finalized
- [ ] All migrations applied
- [ ] Indexes created for frequently queried columns
- [ ] Database exported (`mysqldump -u root tnd_system > tnd_export.sql`)
- [ ] Sample/test data cleaned (or use fresh schema)

### Security Review
- [ ] No hardcoded credentials in code
- [ ] Strong JWT secret generated (64+ characters)
- [ ] File upload validation in place (5MB, MIME check)
- [ ] Rate limiting configured (login: 5/min)
- [ ] Security headers implemented (CSP, HSTS, X-Frame-Options)
- [ ] SQL injection prevention (PDO prepared statements)
- [ ] XSS prevention (proper output escaping)

### Testing
- [ ] All QC features tested locally
- [ ] Login/logout working
- [ ] Visit creation working
- [ ] Checklist responses saving
- [ ] Photo upload working
- [ ] PDF generation working
- [ ] Report viewing working
- [ ] Mobile app tested with local backend

---

## 🏗️ Hosting Setup

### Account & Domain
- [ ] Shared hosting account purchased
- [ ] Domain/subdomain configured (e.g., api.yourdomain.com)
- [ ] DNS records propagated (check with `nslookup yourdomain.com`)
- [ ] SSL certificate installed (Let's Encrypt via cPanel)
- [ ] HTTPS working (verify in browser)

### Server Environment
- [ ] PHP version ≥ 8.0 (check in cPanel → Select PHP Version)
- [ ] MySQL version ≥ 5.7 (check in phpMyAdmin)
- [ ] Required PHP extensions enabled:
  - [ ] PDO
  - [ ] pdo_mysql
  - [ ] json
  - [ ] mbstring
  - [ ] fileinfo
  - [ ] gd or imagick (for image processing)
- [ ] `upload_max_filesize` ≥ 5MB (php.ini)
- [ ] `post_max_size` ≥ 6MB (php.ini)
- [ ] `max_execution_time` ≥ 60 seconds

### File Upload
- [ ] All backend files uploaded (FTP/SSH)
- [ ] Directory structure intact
- [ ] File permissions set correctly:
  - [ ] `.env` → 600 or 644
  - [ ] `*.php` → 644
  - [ ] `uploads/` → 755
  - [ ] `logs/` → 755
  - [ ] `config/` → 755
  - [ ] `api/` → 755

---

## 🗄️ Database Configuration

### Database Creation
- [ ] Database created (via cPanel → MySQL Databases)
- [ ] Database name recorded: `________________`
- [ ] Charset: utf8mb4
- [ ] Collation: utf8mb4_unicode_ci

### Database User
- [ ] Dedicated user created (not root)
- [ ] Username: `________________`
- [ ] Strong password generated
- [ ] User privileges granted (SELECT, INSERT, UPDATE, DELETE only)
- [ ] User assigned to database
- [ ] Privileges flushed

### Database Import
- [ ] SQL file uploaded to server
- [ ] Database imported via phpMyAdmin or CLI
- [ ] Import successful (no errors)
- [ ] All tables present (verify count)
- [ ] Sample data imported (if needed)

---

## ⚙️ Environment Configuration

### .env File
- [ ] `.env` file created on server (not uploaded from local)
- [ ] `APP_ENV=production` (CRITICAL!)
- [ ] `DB_HOST=localhost` (or provided by hosting)
- [ ] `DB_NAME` = your production database name
- [ ] `DB_USERNAME` = dedicated database user
- [ ] `DB_PASSWORD` = strong password
- [ ] `JWT_SECRET_KEY` = generated strong secret (64+ chars)
- [ ] `CORS_ALLOWED_ORIGINS` = production domain(s) only
- [ ] File permissions: 600 or 644
- [ ] File ownership: correct user/group

### Connection Test
- [ ] Upload `test-db-connection.php` temporarily
- [ ] Access via browser: `https://yourdomain.com/test-db-connection.php`
- [ ] Expected output: "✓ Database connection successful!"
- [ ] Verify database name displayed
- [ ] **DELETE `test-db-connection.php`** immediately

---

## 🔒 Security Configuration

### File & Directory Protection
- [ ] `.htaccess` created to block sensitive files
- [ ] Directory listing disabled (`Options -Indexes`)
- [ ] `.env` file not accessible via web
- [ ] `logs/` directory not accessible via web
- [ ] `database/` directory not accessible via web

### CORS Configuration
- [ ] `CORS_ALLOWED_ORIGINS` set to production domain only
- [ ] Remove ngrok URLs from allowed origins
- [ ] Test CORS from browser console
- [ ] Verify blocked from unauthorized domains

### Rate Limiting
- [ ] Rate limit files directory exists: `logs/ratelimit/`
- [ ] Test rate limiting: try 6 failed logins
- [ ] Verify HTTP 429 response on 6th attempt
- [ ] Rate limit files being created in `logs/ratelimit/`

### Upload Validation
- [ ] Test uploading oversized file (>5MB) - should fail
- [ ] Test uploading non-image file (.txt, .exe) - should fail
- [ ] Test uploading valid image (JPG/PNG <5MB) - should succeed
- [ ] Uploaded files have sanitized names

---

## 🧪 API Endpoint Testing

### Authentication
- [ ] **POST /api/login.php**
  - [ ] Valid credentials → returns JWT token
  - [ ] Invalid credentials → returns error
  - [ ] Rate limiting works (6th attempt blocked)
  - [ ] Token format correct (3 parts separated by dots)

### Outlets
- [ ] **GET /api/outlets-list.php**
  - [ ] Returns outlet list
  - [ ] Requires valid JWT token
  - [ ] Returns 401 without token

### Visits
- [ ] **GET /api/visits-list.php**
  - [ ] Returns visit list for authenticated user
  - [ ] Filtered by user_id correctly
- [ ] **POST /api/visit-save.php**
  - [ ] Creates new visit
  - [ ] Returns visit_id
  - [ ] Validates required fields

### Checklist
- [ ] **GET /api/checklist-points-list.php**
  - [ ] Returns all checklist points
  - [ ] Grouped by categories
- [ ] **POST /api/checklist-responses-save.php**
  - [ ] Saves responses for a visit
  - [ ] Handles OK/NOT_OK responses

### Photos
- [ ] **POST /api/visit-photo-upload.php**
  - [ ] Accepts valid image upload
  - [ ] Returns uploaded file path
  - [ ] Validates file size (5MB max)
  - [ ] Validates MIME type (image only)
- [ ] **POST /api/profile-photo-upload.php**
  - [ ] Profile photo upload works
  - [ ] Same validation as visit photos

### Reports
- [ ] **GET /api/visit-detail.php**
  - [ ] Returns complete visit details
  - [ ] Includes checklist responses
  - [ ] Includes findings with photos
- [ ] **GET /api/visits-report.php**
  - [ ] Returns visits for web admin
  - [ ] Filters work (date range, outlet, user)

---

## 📱 Mobile App Configuration

### APK Build
- [ ] Base URL updated to production domain
  - File: `lib/utils/api_config_manager.dart`
  - `_defaultBaseUrl = 'https://yourdomain.com'`
- [ ] Flutter dependencies updated (`flutter pub get`)
- [ ] Clean build performed (`flutter clean`)
- [ ] Release APK built (`flutter build apk --release`)
- [ ] APK size reasonable (<50MB)
- [ ] APK location: `build/app/outputs/flutter-apk/app-release.apk`

### APK Testing
- [ ] Install APK on test device
- [ ] App launches without errors
- [ ] Login with production credentials works
- [ ] Create new visit works
- [ ] Fill checklist works
- [ ] Upload finding photos works
- [ ] Generate PDF works
- [ ] View reports works
- [ ] Logout and re-login works

---

## 🌐 Web Admin Testing

### Access & Authentication
- [ ] Web admin accessible: `https://yourdomain.com/frontend-web/`
- [ ] Login page loads
- [ ] Login with valid credentials works
- [ ] Invalid credentials rejected
- [ ] Logout works

### Features
- [ ] Dashboard displays correctly
- [ ] Outlets list loads
- [ ] Users list loads
- [ ] Checklists page works
- [ ] Reports page loads
- [ ] Date filters work
- [ ] Export functionality works (if implemented)
- [ ] Training menu items hidden (Phase 2)

---

## 🔍 Monitoring & Logging

### Error Logging
- [ ] `logs/` directory exists and writable
- [ ] `logs/error.log` created after first error
- [ ] Errors logged correctly (check file content)
- [ ] No sensitive data in logs (passwords, tokens)

### Performance
- [ ] API response times acceptable (<2 seconds)
- [ ] Database queries optimized (no N+1 queries)
- [ ] Image upload/download speed acceptable
- [ ] PDF generation completes in reasonable time

### Backup
- [ ] Backup strategy defined
- [ ] Database backup scheduled (daily/weekly)
- [ ] File backup scheduled (weekly)
- [ ] Backup restoration tested
- [ ] Backup storage location secured

---

## 📊 User Acceptance Testing (UAT)

### Test Users
- [ ] Create test users with different roles
- [ ] Provide test credentials to users
- [ ] Users can login successfully

### QC Workflow (End-to-End)
- [ ] Create new visit from mobile app
- [ ] Select outlet and fill details
- [ ] Answer all checklist items
- [ ] Add findings with photos for NOT_OK items
- [ ] Generate PDF rekomendasi
- [ ] View PDF on mobile (correct layout, photos visible)
- [ ] View visit in web admin reports
- [ ] Verify data accuracy in reports

### Edge Cases
- [ ] No internet connection handling
- [ ] Slow connection handling
- [ ] Large photo upload (4-5MB)
- [ ] Many findings in single visit (10+)
- [ ] PDF with many photos (layout correct)
- [ ] Concurrent users (multiple people using app)

---

## ✅ Go-Live Approval

### Sign-off Required From:
- [ ] **Project Manager** - Business requirements met
- [ ] **Developer** - Technical implementation complete
- [ ] **QA Tester** - All tests passed
- [ ] **End Users** - UAT successful
- [ ] **Stakeholder** - Ready for production

### Final Verification
- [ ] All checklist items above completed
- [ ] No critical bugs remaining
- [ ] Performance acceptable
- [ ] Security measures in place
- [ ] Backup and recovery plan ready
- [ ] Support plan in place
- [ ] Documentation complete

### Deployment Timing
- [ ] Deployment scheduled: **Date:** __________ **Time:** __________
- [ ] Users notified of go-live date
- [ ] Support team ready for launch day
- [ ] Rollback plan prepared (if needed)

---

## 🚀 Post Go-Live

### Immediate Actions (Day 1)
- [ ] Monitor error logs for issues
- [ ] Monitor user feedback
- [ ] Verify all users can access system
- [ ] Quick response to critical issues

### Week 1 Actions
- [ ] Daily error log review
- [ ] Performance monitoring
- [ ] User feedback collection
- [ ] Minor bug fixes if needed

### Ongoing Maintenance
- [ ] Weekly database backups verified
- [ ] Monthly security review
- [ ] Regular dependency updates
- [ ] User training and support

---

## 📝 Notes & Issues

**Deployment Date:** __________

**Deployed By:** __________

**Production URL:** __________

**Issues Encountered:**
```
(Document any issues during deployment here)
```

**Resolutions:**
```
(Document how issues were resolved)
```

---

**Checklist Completed:** ☐ YES ☐ NO

**Ready for Production:** ☐ YES ☐ NO

**Approved By:** __________________ **Date:** __________

**Signature:** __________________
