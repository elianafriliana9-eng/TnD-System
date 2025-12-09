# 📤 DEPLOYMENT GUIDE: Photo Bug Fix

## 🎯 OVERVIEW

**Bug Fixed:** Item NOK dengan foto muncul juga sebagai OK dengan foto yang sama

**Files Modified:**
1. ✅ `backend-web/classes/Visit.php` - Auto-delete photos logic
2. ⏳ `tnd_mobile_flutter/lib/screens/category_checklist_screen.dart` - Confirmation dialog

**Files Created:**
1. ✅ `backend-web/cleanup-orphaned-photos.sql` - Data cleanup script
2. ✅ `backend-web/PHOTO_ON_OK_RESPONSE_BUG_FIX.md` - Documentation

---

## 📂 FILE STRUCTURE & LOCATIONS

### Production Server (tndsystem.online)

```
public_html/
├── backend-web/
│   ├── api/
│   │   ├── visit-checklist-response.php    ← NO CHANGE (hanya routing)
│   │   └── visit-photo-upload.php          ← NO CHANGE
│   ├── classes/
│   │   └── Visit.php                       ← ✅ UPLOAD INI (modified)
│   ├── cleanup-orphaned-photos.sql         ← ✅ UPLOAD INI (new file)
│   └── PHOTO_ON_OK_RESPONSE_BUG_FIX.md    ← ✅ UPLOAD INI (documentation)
```

### Local Development

```
c:\laragon\www\tnd_system\tnd_system\
├── backend-web/
│   ├── classes/
│   │   └── Visit.php                       ← ✅ MODIFIED
│   ├── cleanup-orphaned-photos.sql         ← ✅ NEW
│   └── PHOTO_ON_OK_RESPONSE_BUG_FIX.md    ← ✅ NEW
└── tnd_mobile_flutter/
    └── lib/screens/
        └── category_checklist_screen.dart  ← ⏳ TO BE MODIFIED
```

---

## 🚀 DEPLOYMENT STEPS

### STEP 1: Backup Current Files

**Login to cPanel:**
- URL: https://tndsystem.online/cpanel
- Navigate to File Manager

**Backup files:**
```
1. public_html/backend-web/classes/Visit.php
   → Download and save as: Visit.php.backup.2025-11-04
```

**Backup database:**
```
1. Open phpMyAdmin
2. Select database: u211765246_tnd_db
3. Export → Custom → Select tables:
   - visit_checklist_responses
   - photos
4. Save as: tnd_db_backup_2025-11-04.sql
```

---

### STEP 2: Upload Backend Files

**Method: cPanel File Manager**

1. **Login** to cPanel File Manager
2. Navigate to: `public_html/backend-web/classes/`
3. **Upload** `Visit.php`:
   - Click "Upload" button
   - Select: `c:\laragon\www\tnd_system\tnd_system\backend-web\classes\Visit.php`
   - **Overwrite** when prompted: YES
   - Verify upload success

4. Navigate to: `public_html/backend-web/`
5. **Upload** new files:
   - `cleanup-orphaned-photos.sql`
   - `PHOTO_ON_OK_RESPONSE_BUG_FIX.md`

6. **Verify file permissions:**
   - Visit.php → 644
   - cleanup-orphaned-photos.sql → 644
   - PHOTO_ON_OK_RESPONSE_BUG_FIX.md → 644

---

### STEP 3: Run Database Cleanup

**Open phpMyAdmin:**

**Query 1: Identify Orphaned Photos (DRY RUN)**
```sql
SELECT 
    p.id as photo_id,
    p.visit_id,
    p.item_id as checklist_point_id,
    vcr.response,
    cp.question as item_text,
    p.file_name,
    p.file_path,
    v.id as visit_number,
    o.name as outlet_name
FROM photos p
INNER JOIN visit_checklist_responses vcr 
    ON p.visit_id = vcr.visit_id 
    AND p.item_id = vcr.checklist_point_id
INNER JOIN checklist_points cp ON p.item_id = cp.id
INNER JOIN visits v ON p.visit_id = v.id
INNER JOIN outlets o ON v.outlet_id = o.id
WHERE vcr.response IN ('OK', 'N/A')
ORDER BY p.visit_id DESC, p.item_id;
```

**Expected:**
- If result is **empty** → No cleanup needed, skip to STEP 4
- If result has **rows** → Continue to Query 2

**Query 2: Delete Orphaned Photos (EXECUTE)**
```sql
DELETE p 
FROM photos p
INNER JOIN visit_checklist_responses vcr 
    ON p.visit_id = vcr.visit_id 
    AND p.item_id = vcr.checklist_point_id
WHERE vcr.response IN ('OK', 'N/A');
```

**Query 3: Verify Cleanup (VERIFICATION)**
```sql
SELECT 
    vcr.visit_id,
    vcr.checklist_point_id,
    vcr.response,
    cp.question,
    COUNT(p.id) as photo_count
FROM visit_checklist_responses vcr
INNER JOIN checklist_points cp ON vcr.checklist_point_id = cp.id
LEFT JOIN photos p ON vcr.visit_id = p.visit_id AND vcr.checklist_point_id = p.item_id
WHERE vcr.response IN ('OK', 'N/A')
GROUP BY vcr.visit_id, vcr.checklist_point_id, vcr.response, cp.question
HAVING COUNT(p.id) > 0;
```

**Expected:** 0 rows (no OK/NA with photos)

---

### STEP 4: Test Backend Fix

**Test dengan Postman atau Browser:**

**Test Case 1: Change response from NOK to OK (should delete photos)**

```
1. Login ke mobile app
2. Create new visit
3. Select item, choose NOK
4. Upload photo
5. Change response to OK
6. Check database:
   - visit_checklist_responses: response = 'OK'
   - photos: no record for that item
7. Check filesystem: photo file deleted
```

**Test Case 2: Normal flow (NOK with photo)**

```
1. Create visit
2. Select item, choose NOK
3. Upload photo
4. Don't change response
5. Complete visit
6. Check Visit Detail: NOK item shows with photo ✅
```

---

### STEP 5: Mobile App Update (OPTIONAL - For Enhanced UX)

**File to modify:** `tnd_mobile_flutter/lib/screens/category_checklist_screen.dart`

**Purpose:** Add confirmation dialog before changing response

**Status:** ⏳ Not yet implemented (backend fix already handles deletion)

**If you want to add this:**
1. Modify `_saveResponse()` method
2. Add confirmation dialog
3. Rebuild APK
4. Distribute to users

**For now:** Backend fix is sufficient. Mobile dialog is optional enhancement.

---

## ✅ VERIFICATION CHECKLIST

**After deployment, verify:**

- [ ] Visit.php uploaded successfully (check file size/timestamp)
- [ ] File permissions: 644
- [ ] Database cleanup executed (Query 1-3)
- [ ] No orphaned photos remain (Query 3 returns 0 rows)
- [ ] Test: Change NOK → OK deletes photos
- [ ] Test: Visit Detail shows correct data
- [ ] Test: Web admin reports accurate
- [ ] Check error logs: no PHP errors

**Verification Commands:**

```bash
# Check file exists on server
ls -la public_html/backend-web/classes/Visit.php

# Check file permissions
stat -c %a public_html/backend-web/classes/Visit.php
# Should output: 644

# Check PHP syntax
php -l public_html/backend-web/classes/Visit.php
# Should output: No syntax errors detected
```

---

## 🔍 TROUBLESHOOTING

**Issue:** Upload fails / File not found

**Solution:**
- Check cPanel File Manager path
- Verify you're in correct directory: `public_html/backend-web/classes/`
- Try uploading with FTP client (FileZilla) instead

**Issue:** Photos not deleted after response change

**Solution:**
- Check error logs in cPanel: `public_html/backend-web/error_log`
- Verify file paths in database match filesystem
- Check file permissions (photos directory needs write permission)

**Issue:** Database cleanup fails

**Solution:**
- Check foreign key constraints
- Verify table names: `photos`, `visit_checklist_responses`
- Check column names: `item_id`, `checklist_point_id`

---

## 📊 DEPLOYMENT SUMMARY

**Files to Upload:**
1. ✅ `backend-web/classes/Visit.php` (modified, ~300 lines)
2. ✅ `backend-web/cleanup-orphaned-photos.sql` (new, ~120 lines)
3. ✅ `backend-web/PHOTO_ON_OK_RESPONSE_BUG_FIX.md` (documentation)

**Database Changes:**
- DELETE orphaned photos (photos table)
- No schema changes required

**Testing Required:**
- Response change from NOK → OK
- Photo deletion verification
- Visit Detail display
- Web admin reports

**Rollback Plan:**
- Restore `Visit.php.backup.2025-11-04`
- Restore database from backup if needed
- No permanent changes to database schema

---

## 🎯 SUCCESS CRITERIA

After deployment, verify:

✅ **Functional:**
- Changing response from NOK → OK deletes photos automatically
- Visit Detail shows correct data (OK without photos)
- Web admin reports accurate

✅ **Technical:**
- No PHP errors in logs
- Database cleanup successful
- File permissions correct

✅ **Data Integrity:**
- No orphaned photos (OK/NA with photos)
- No duplicate responses
- Photos only on NOT OK items

---

**Deployment by:** Administrator  
**Date:** November 4, 2025  
**Version:** 1.0  
**Status:** ✅ READY FOR PRODUCTION
