# 📋 TND SYSTEM - PRODUCTION TODO LIST
**Last Updated:** October 30, 2025 (02:46 AM)  
**Status:** Pre-Production Preparation  
**Priority:** High - Required before deployment

---

## 🎯 **QUICK OVERVIEW**

| Task | Priority | Time | Status |
|------|----------|------|--------|
| Backend Cleanup | 🔴 CRITICAL | 5 min | ⏳ TODO |
| Mobile App URL Fix | 🔴 CRITICAL | 15 min | ⏳ TODO |
| Create .env File | 🔴 CRITICAL | 30 min | ⏳ TODO |
| Database Setup | 🟡 HIGH | 1 hour | ⏳ TODO |
| Deploy Backend | 🟡 HIGH | 2 hours | ⏳ TODO |
| Test Everything | 🟡 HIGH | 2 hours | ⏳ TODO |

**Total Estimated Time:** 5-6 hours  
**Can be done in:** 1 day  

---

## 🔴 **CRITICAL TASKS (Must Complete First)**

### ☐ TASK 1: Backend Cleanup (5 minutes)
**Priority:** 🔴 CRITICAL  
**Blocks:** Deployment  
**Risk if skipped:** Security vulnerabilities

#### What to do:
1. Navigate to: `C:\laragon\www\tnd_system\tnd_system\backend-web\`
2. Double-click: `cleanup-test-files.bat`
3. Press any key to confirm
4. Wait for "CLEANUP COMPLETE!" message

#### Files being deleted:
- [ ] `api/test.php` - Exposes system info
- [ ] `api/debug.php` - Leaks server config
- [ ] `api/session-test.php` - Exposes session data
- [ ] `api/users-test.php` - **CRITICAL SECURITY HOLE!**

#### Verification:
```bash
# All should return 404:
http://localhost/tnd_system/tnd_system/backend-web/api/test.php
http://localhost/tnd_system/tnd_system/backend-web/api/users-test.php
```

#### Success Criteria:
- [ ] Script shows "[OK] removed" for all 4 files
- [ ] Test URLs return 404 Not Found
- [ ] Production APIs still respond

**Status:** ⏳ NOT STARTED  
**Owner:** Developer  
**Due:** Before any deployment

---

### ☐ TASK 2: Fix Mobile App URL (15 minutes)
**Priority:** 🔴 CRITICAL  
**Blocks:** Mobile app functionality  
**Risk if skipped:** App will stop working when ngrok expires

#### What to do:
1. Open: `tnd_mobile_flutter/lib/utils/api_config_manager.dart`
2. Find line 10-11:
   ```dart
   static const String _defaultBaseUrl = 'https://af032741f18c.ngrok-free.app/...';
   static const String _defaultApiUrl = 'https://af032741f18c.ngrok-free.app/.../api';
   ```
3. Change to production URL:
   ```dart
   static const String _defaultBaseUrl = 'https://yourdomain.com';
   static const String _defaultApiUrl = 'https://yourdomain.com/api';
   ```
4. Save file

#### Rebuild APK:
```bash
cd C:\laragon\www\tnd_system\tnd_system\tnd_mobile_flutter
flutter clean
flutter pub get
flutter build apk --release
```

#### Verification:
- [ ] APK created: `build/app/outputs/flutter-apk/app-release.apk`
- [ ] APK size: 20-50 MB (normal range)
- [ ] No build errors

**Status:** ⏳ NOT STARTED  
**Owner:** Developer  
**Due:** Before distributing app

---

### ☐ TASK 3: Create Production .env File (30 minutes)
**Priority:** 🔴 CRITICAL  
**Blocks:** Backend functionality  
**Risk if skipped:** System won't work at all

#### What to do:
1. Navigate to: `backend-web/`
2. Copy `.env.example` to `.env`
3. Edit `.env` with production values

#### Required settings:
```env
# Application
APP_ENV=production              # ✅ REQUIRED
APP_DEBUG=false                 # ✅ REQUIRED
APP_URL=https://yourdomain.com

# Database
DB_HOST=localhost
DB_NAME=tnd_production          # ✅ Change this
DB_USERNAME=tnd_user            # ✅ NOT root!
DB_PASSWORD=STRONG_PASSWORD     # ✅ Generate strong password

# Security
JWT_SECRET_KEY=GENERATE_64_CHAR_RANDOM_STRING  # ✅ REQUIRED

# CORS
CORS_ALLOWED_ORIGINS=https://yourdomain.com    # ✅ Production domain only
```

#### Generate JWT Secret:
**Option 1 - PowerShell:**
```powershell
-join ((48..57) + (65..90) + (97..122) | Get-Random -Count 64 | % {[char]$_})
```

**Option 2 - Online:**
- Visit: https://www.random.org/strings/
- Generate 64-character alphanumeric string

#### Checklist:
- [ ] .env file created
- [ ] APP_ENV=production
- [ ] APP_DEBUG=false
- [ ] Database credentials configured
- [ ] JWT secret generated (64+ chars)
- [ ] CORS set to production domain only
- [ ] File permissions set (not readable by web)
- [ ] File NOT committed to git

**Status:** ⏳ NOT STARTED  
**Owner:** Developer  
**Due:** Before deployment

---

## 🟡 **HIGH PRIORITY TASKS (Before Going Live)**

### ☐ TASK 4: Additional Backend Cleanup (10 minutes)
**Priority:** 🟡 HIGH  
**Optional but recommended**

#### Additional test files to delete:
- [ ] `backend-web/test_outlet.php`
- [ ] `backend-web/test_session.php`
- [ ] `backend-web/test_structure.php`
- [ ] `backend-web/simple_debug.php`
- [ ] `backend-web/debug_outlets.php`
- [ ] `backend-web/check-uploads.php`

#### How to delete:
```cmd
cd C:\laragon\www\tnd_system\tnd_system\backend-web
del test_outlet.php test_session.php test_structure.php
del simple_debug.php debug_outlets.php check-uploads.php
```

**Status:** ⏳ NOT STARTED  
**Owner:** Developer

---

### ☐ TASK 5: Database Setup (1 hour)
**Priority:** 🟡 HIGH  
**Blocks:** Backend functionality

#### Production Database:
- [ ] Create production database
- [ ] Character set: utf8mb4
- [ ] Collation: utf8mb4_unicode_ci
- [ ] Database name matches .env

#### Database User:
- [ ] Create dedicated user (NOT root)
- [ ] Grant limited privileges only:
  - SELECT
  - INSERT
  - UPDATE
  - DELETE
- [ ] Set strong password
- [ ] Test connection

#### Import Schema:
- [ ] Upload `database/schema.sql` to server
- [ ] Import via phpMyAdmin or CLI
- [ ] Verify all tables created
- [ ] Check foreign keys

#### Verification:
```sql
-- Should list all tables:
SHOW TABLES;

-- Should show correct charset:
SHOW TABLE STATUS;
```

**Status:** ⏳ NOT STARTED  
**Owner:** Developer/DBA  
**Due:** Before backend deployment

---

### ☐ TASK 6: Deploy Backend to Hosting (2 hours)
**Priority:** 🟡 HIGH  

#### Pre-deployment:
- [ ] Hosting account ready
- [ ] Domain/subdomain configured
- [ ] SSL certificate installed (HTTPS)
- [ ] PHP version ≥ 8.0
- [ ] Required PHP extensions enabled

#### Upload Files:
- [ ] Upload all backend files via FTP/SFTP
- [ ] EXCLUDE: .env (create manually on server)
- [ ] EXCLUDE: uploads/ contents
- [ ] EXCLUDE: logs/ contents
- [ ] EXCLUDE: vendor/ (run composer on server)

#### Server Configuration:
- [ ] Create .env on server with production values
- [ ] Set directory permissions:
  - uploads/ → 755
  - logs/ → 755
  - .env → 600
  - *.php → 644
- [ ] Run composer install (if needed)
- [ ] Create required directories

#### Verification:
```bash
# Test health endpoint:
curl https://yourdomain.com/api/health.php
# Should return: {"status":"ok"}
```

**Status:** ⏳ NOT STARTED  
**Owner:** Developer/DevOps  
**Due:** Deployment day

---

### ☐ TASK 7: Complete Testing (2 hours)
**Priority:** 🟡 HIGH  

#### Backend API Testing:
- [ ] Test login endpoint
- [ ] Test rate limiting (6 failed attempts)
- [ ] Test authenticated endpoints
- [ ] Test file uploads (5MB limit)
- [ ] Test CORS from browser
- [ ] Test all QC endpoints
- [ ] Test all Training endpoints
- [ ] Check error logs

#### Mobile App Testing:
- [ ] Install APK on test device
- [ ] Test login/logout
- [ ] Create QC visit
- [ ] Fill checklist
- [ ] Upload photos
- [ ] Generate PDF
- [ ] View reports
- [ ] Create training session
- [ ] Add participants
- [ ] Complete evaluation

#### Web Admin Testing:
- [ ] Access admin panel
- [ ] Login as admin
- [ ] View dashboard
- [ ] Check reports
- [ ] Manage users
- [ ] View analytics

#### Security Testing:
- [ ] Verify test endpoints return 404
- [ ] Test unauthorized access (should fail)
- [ ] Test SQL injection attempts (should fail)
- [ ] Test file upload validation
- [ ] Check security headers

**Status:** ⏳ NOT STARTED  
**Owner:** QA Team/Developer  
**Due:** Before go-live

---

## 🟢 **OPTIONAL BUT RECOMMENDED**

### ☐ TASK 8: Setup Monitoring (1 hour)
**Priority:** 🟢 MEDIUM  

- [ ] Configure error logging
- [ ] Setup log rotation
- [ ] Configure backup schedule
- [ ] Setup uptime monitoring
- [ ] Configure email alerts

**Status:** ⏳ NOT STARTED  

---

### ☐ TASK 9: Documentation Review (30 minutes)
**Priority:** 🟢 MEDIUM  

- [ ] Review API documentation
- [ ] Update team wiki
- [ ] Create user manual
- [ ] Document deployment process
- [ ] Create troubleshooting guide

**Status:** ⏳ NOT STARTED  

---

### ☐ TASK 10: Backup Strategy (30 minutes)
**Priority:** 🟢 MEDIUM  

- [ ] Setup automated database backups
- [ ] Configure file backups (uploads/)
- [ ] Test backup restoration
- [ ] Document backup procedures
- [ ] Store backups in safe location

**Status:** ⏳ NOT STARTED  

---

## 📅 **TIMELINE ESTIMATE**

### **Day 1: Preparation (1 hour)**
- Morning: Tasks 1-3 (Critical fixes)
- Afternoon: Task 4 (Additional cleanup)
- **Deliverable:** Code ready for deployment

### **Day 2: Deployment (4 hours)**
- Morning: Tasks 5-6 (Database + Deploy)
- Afternoon: Task 7 (Testing)
- **Deliverable:** System live in production

### **Day 3: Post-deployment (2 hours)**
- Optional: Tasks 8-10 (Monitoring + Docs)
- **Deliverable:** Stable production system

---

## ✅ **COMPLETION CHECKLIST**

### Critical Tasks (Must Complete):
- [ ] Task 1: Backend Cleanup ✓
- [ ] Task 2: Mobile App URL ✓
- [ ] Task 3: Production .env ✓
- [ ] Task 5: Database Setup ✓
- [ ] Task 6: Backend Deployment ✓
- [ ] Task 7: Testing ✓

### Optional Tasks:
- [ ] Task 4: Additional Cleanup
- [ ] Task 8: Monitoring
- [ ] Task 9: Documentation
- [ ] Task 10: Backups

### Final Sign-off:
- [ ] Project Manager approval
- [ ] Developer sign-off
- [ ] QA sign-off
- [ ] Stakeholder approval

---

## 📊 **PROGRESS TRACKING**

```
Tasks Completed: 0/10 (0%)
Critical Tasks: 0/6 (0%)
Time Spent: 0 hours
Time Remaining: ~6 hours
```

### Status Legend:
- ⏳ NOT STARTED - Task not begun
- 🔄 IN PROGRESS - Currently working
- ✅ COMPLETE - Task finished
- ⏸️ BLOCKED - Waiting on dependency
- ⚠️ ISSUE - Problem encountered

---

## 🚨 **BLOCKERS & RISKS**

### Current Blockers:
- None (ready to start Task 1)

### Potential Risks:
1. **Ngrok URL expires** → Mobile app won't work
   - Mitigation: Complete Task 2 ASAP
   
2. **Missing .env on server** → Backend won't start
   - Mitigation: Complete Task 3 before deploy
   
3. **Test files exposed** → Security vulnerability
   - Mitigation: Complete Task 1 immediately

---

## 📞 **CONTACTS & RESOURCES**

### Key Documents:
- `PRODUCTION_READY_STEPS.md` - Step-by-step guide
- `CLEANUP_SUMMARY.md` - Cleanup details
- `DEPLOYMENT.md` - Deployment instructions
- `PRODUCTION_CHECKLIST.md` - 370-point checklist

### Tools Created:
- `cleanup-test-files.bat` - Automated cleanup script

### Support:
- Developer: [Your Name]
- Project Manager: [PM Name]
- Hosting Support: [Provider Support]

---

## 📝 **NOTES & UPDATES**

### October 30, 2025 - 02:46 AM
- ✅ Created automated cleanup script
- ✅ Identified all security issues
- ✅ Created comprehensive documentation
- ⏳ Ready to begin Task 1

### [Add your updates here as you progress]
- 

---

## 🎯 **SUCCESS CRITERIA**

### System is production-ready when:
1. ✅ All critical tasks (1-3, 5-7) completed
2. ✅ No test/debug files in production code
3. ✅ Mobile app uses production URL
4. ✅ Production .env configured correctly
5. ✅ Database setup and tested
6. ✅ All APIs responding correctly
7. ✅ Mobile app tested on devices
8. ✅ Security score ≥ 95/100
9. ✅ All stakeholders signed off

---

## 🚀 **READY TO START?**

**Next Action:** Run Task 1 (Backend Cleanup)
- Takes: 5 minutes
- Location: `backend-web/cleanup-test-files.bat`
- Just: Double-click and press any key

**After Task 1:** Mark it complete and move to Task 2!

---

**Last Updated:** October 30, 2025 at 02:46 AM  
**Document Version:** 1.0  
**Status:** Active TODO List  
**Next Review:** After each task completion

---

💡 **TIP:** Check off tasks as you complete them and update the Progress Tracking section!
