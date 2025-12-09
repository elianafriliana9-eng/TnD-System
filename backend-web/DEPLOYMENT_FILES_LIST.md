==========================================
DEPLOYMENT PACKAGE - Photo Upload Fix
==========================================

Date: November 3, 2025
Issue: Photo upload error 500 (empty body)
Status: Debug test ✅ WORKS | Real endpoint ❌ FAILS

ROOT CAUSE:
Production files masih code lama dengan:
- Table name: visit_photos (should be: photos)
- Column: checklist_point_id (should be: item_id)
- Column: photo_path (should be: file_path)

==========================================
UPLOAD THESE 7 FILES TO PRODUCTION
==========================================

Location: public_html/backend-web/

FILE 1: classes/Visit.php
- Size: 9.32 KB
- Hash: 639883C4
- Changes: Fixed getVisitDetails() and savePhoto() to use correct table/columns

FILE 2: api/visit-photo-upload.php
- Size: 9.27 KB
- Hash: 8E61EA49
- Changes: Added detailed logging, uses correct table name

FILE 3: api/visit-detail.php
- Size: 2.95 KB
- Hash: 9BE301FF
- Changes: Query uses item_id AS checklist_item_id

FILE 4: api/visit-responses.php
- Size: 3 KB
- Hash: E7F7F80A
- Changes: JOIN photos ON p.item_id

FILE 5: api/improvement-recommendations.php
- Size: 8.69 KB
- Hash: 33D511A8
- Changes: Query uses p.item_id, p.file_path

FILE 6: api/generate-recommendation-pdf.php
- Size: 5.29 KB
- Hash: 01873665
- Changes: FROM photos, p.item_id, p.file_path

FILE 7: api/finding-photos.php
- Size: 2.67 KB
- Hash: 28C1702C
- Changes: FROM photos, JOIN ON p.item_id

==========================================
VERIFICATION AFTER UPLOAD
==========================================

Method 1: Check file modification time
- cPanel File Manager → Right-click file → Properties
- Verify: "Last Modified" is recent (today)

Method 2: Check file size
- Compare with sizes above
- If different → wrong file or not uploaded

Method 3: Download & compare hash
- Download from production
- Get MD5 hash
- Compare with hash above

==========================================
KNOWN WORKING SETUP
==========================================

✅ PHP Settings:
- upload_max_filesize: 10M
- post_max_size: 10M
- max_execution_time: 300
- memory_limit: 128M

✅ Folder Structure:
- uploads/ (755)
- uploads/photos/ (755)

✅ Debug Test Result:
- POST data: ✓ Received
- FILES: ✓ Received
- PHP: ✓ Working
- Permissions: ✓ OK

==========================================
CURRENT ERROR ANALYSIS
==========================================

Error: HTTP 500 with empty body
Location: visit-photo-upload.php
Cause: PHP fatal error before output

Most Likely:
1. File not uploaded (still old code)
2. Syntax error in uploaded file (encoding issue?)
3. Missing dependency (Auth.php, Visit.php, etc.)
4. Database connection error
5. SQL error (table/column doesn't exist)

NEED: Production error log to confirm

==========================================
HOW TO CHECK PRODUCTION ERROR LOG
==========================================

cPanel Method 1:
1. Login cPanel
2. Go to "Metrics" section
3. Click "Errors"
4. Look for recent errors (last 5 minutes)
5. Copy error message

cPanel Method 2:
1. Login cPanel
2. File Manager
3. Navigate: public_html/backend-web/
4. Look for file: error_log
5. Download & open
6. Look at bottom (newest errors)

What to look for:
- "Fatal error:"
- "Parse error:"
- "Table 'xxx' doesn't exist"
- "Column 'xxx' unknown"
- "Call to undefined function"

==========================================
IMMEDIATE ACTION
==========================================

OPTION A (if you can access error log):
1. Check production error_log
2. Send error message to me
3. I'll provide exact fix

OPTION B (if error log not accessible):
1. Upload all 7 files
2. Verify upload by checking file sizes
3. Test again
4. If still error, try debug-upload.php again to confirm PHP still works

==========================================
DEPLOYMENT VERIFICATION SCRIPT
==========================================

After uploading files, access this URL:
https://tndsystem.online/backend-web/check-php-config.php

Should show:
- All green checkmarks
- No errors

If shows errors → PHP config issue
If shows 404 → File not uploaded

==========================================
ROLLBACK PLAN
==========================================

If everything breaks after upload:

1. Restore backup files (if you made backups)
2. Or delete uploaded files
3. Or rename: file.php → file.php.broken
4. Contact me with error details

==========================================
NEXT STEPS
==========================================

□ Upload all 7 files via cPanel File Manager
□ Verify files uploaded (check sizes/dates)
□ Test upload from mobile
□ If error: Check error_log
□ If success: Test all photo features
□ Delete debug files (debug-upload.php, check-php-config.php)

==========================================
SUPPORT NEEDED FROM YOU
==========================================

Please send:
1. Screenshot: cPanel error log (Metrics → Errors)
   OR
2. Content of: backend-web/error_log file (bottom 50 lines)
   OR
3. Confirm: "All 7 files uploaded successfully"

With error log, I can tell you EXACTLY what's wrong!

==========================================
