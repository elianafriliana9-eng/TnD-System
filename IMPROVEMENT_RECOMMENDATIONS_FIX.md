# 🔧 IMPROVEMENT RECOMMENDATIONS FIX

## Problem
Rekomendasi perbaikan tidak menampilkan data NOK (NOT OK) meskipun sudah ada input.

## Root Cause
1. ❌ Query mencari `response = 'not_ok'` tapi database menyimpan `'NOT OK'` (uppercase)
2. ❌ Query JOIN ke wrong column: `checklist_item_id` instead of `checklist_point_id`
3. ❌ Photo URL baseUrl double path: `/tnd_system/tnd_system/backend-web/`

## Fixes Applied

### 1. Case-Insensitive NOT OK Query
**File:** `backend-web/api/improvement-recommendations.php`

**Changed:**
```sql
-- OLD (strict match)
AND vcr.response = 'not_ok'

-- NEW (flexible matching)
AND (LOWER(REPLACE(vcr.response, ' ', '_')) = 'not_ok' 
     OR LOWER(vcr.response) = 'not ok'
     OR vcr.response = 'NOT OK')
```

**Locations:**
- Line 93: Detail findings query
- Line 206: NOK count subquery
- Line 219: EXISTS check for visits with NOK

### 2. Fixed JOIN Column
**Changed:**
```sql
-- OLD
vcr.checklist_item_id
INNER JOIN checklist_points cp ON vcr.checklist_item_id = cp.id

-- NEW
vcr.checklist_point_id as checklist_item_id
INNER JOIN checklist_points cp ON vcr.checklist_point_id = cp.id
```

### 3. Fixed Photo URL
**Changed:**
```php
// OLD
$baseUrl = $protocol . '://' . $host . '/tnd_system/tnd_system/backend-web/';

// NEW
$baseUrl = $protocol . '://' . $host . '/backend-web/';
```

## Files Modified
- ✅ `backend-web/api/improvement-recommendations.php`

## Upload Required
1. Upload `improvement-recommendations.php` to production:
   - Path: `public_html/backend-web/api/improvement-recommendations.php`

## Testing Steps

### 1. Test Recommendation List
```bash
# Mobile app: Buka halaman Rekomendasi
# Should show list of completed visits with NOK findings
```

**Expected:**
- ✅ List visits dengan NOK count > 0
- ✅ Show outlet name, region, division
- ✅ Display NOK count dan photo count

### 2. Test Recommendation Detail
```bash
# Tap on a visit in the list
# Should show detail findings grouped by category
```

**Expected:**
- ✅ Show visit info (outlet, date, auditor)
- ✅ Group findings by category (Staff, outlet, etc.)
- ✅ Each finding shows:
  - Question text
  - Notes (if any)
  - Photos (if any) with correct URL

### 3. Verify Photos
**Expected URL format:**
```
https://tndsystem.online/backend-web/uploads/photos/visit_34_xxx.jpg
```

**NOT:**
```
https://tndsystem.online/tnd_system/tnd_system/backend-web/uploads/photos/...
```

## Data Verification

Check if data exists:
```sql
-- Check NOK responses
SELECT 
    v.id as visit_id,
    o.name as outlet,
    COUNT(*) as nok_count
FROM visit_checklist_responses vcr
JOIN visits v ON vcr.visit_id = v.id
JOIN outlets o ON v.outlet_id = o.id
WHERE LOWER(vcr.response) = 'not ok'
   OR vcr.response = 'NOT OK'
   OR LOWER(REPLACE(vcr.response, ' ', '_')) = 'not_ok'
GROUP BY v.id, o.name
ORDER BY v.id DESC;
```

**Expected result:**
- Visit 34 should have NOK count > 0

## Success Criteria
- [ ] Recommendation list shows visits with NOK
- [ ] NOK count accurate
- [ ] Tap visit shows detail findings
- [ ] Findings grouped by category
- [ ] Photos display with correct URL
- [ ] No 404 errors on photos

## Notes
- Database stores `response` as `'NOT OK'` (uppercase with space)
- Mobile app sends `'not_ok'` (lowercase with underscore)
- Query now handles both formats
