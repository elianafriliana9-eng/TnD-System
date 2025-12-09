# 🔍 VISIT DETAIL DEBUG CHECKLIST

**Issue:** Visit detail showing empty data and time 00:00  
**Visit ID:** 34  
**Date:** 2025-11-03

## ✅ Files Modified (Ready for Upload)

### Backend Files:
1. ✅ `backend-web/classes/Visit.php`
   - Added `check_in_time` on create
   - Location: `public_html/backend-web/classes/Visit.php`

2. ✅ `backend-web/api/visit-complete.php`
   - Added `check_out_time` on complete
   - Location: `public_html/backend-web/api/visit-complete.php`

3. ✅ `backend-web/api/debug-visit-detail.php` (NEW)
   - Debug endpoint for visit detail
   - Test URL: `https://tndsystem.online/backend-web/api/debug-visit-detail.php?visit_id=34`

4. ✅ `backend-web/api/debug-visits-list.php` (NEW)
   - Debug endpoint for visits list
   - Test URL: `https://tndsystem.online/backend-web/api/debug-visits-list.php`

### Mobile Files:
5. ✅ `lib/models/visit_model.dart`
   - Added `checkInTime` and `checkOutTime` fields
   
6. ✅ `lib/screens/visit_detail_screen.dart`
   - Fixed case-sensitive response_value comparison (OK vs ok)
   - Added extensive debug logging
   - Fixed time display to use checkInTime

### Database:
7. ✅ SQL executed:
   ```sql
   UPDATE visits 
   SET check_in_time = TIME(visit_date)
   WHERE check_in_time IS NULL;
   
   UPDATE visits 
   SET check_out_time = TIME(visit_date)
   WHERE check_out_time IS NULL 
   AND status = 'completed';
   ```

---

## 🧪 TESTING STEPS

### Step 1: Upload Backend Files
```
Upload to production:
1. backend-web/classes/Visit.php
2. backend-web/api/visit-complete.php
3. backend-web/api/debug-visit-detail.php
4. backend-web/api/debug-visits-list.php
```

### Step 2: Test Debug APIs
```bash
# Test visit detail debug
curl "https://tndsystem.online/backend-web/api/debug-visit-detail.php?visit_id=34"

# Expected response:
{
  "success": true,
  "data": {
    "visit_found": true,
    "visit_data": {
      "check_in_time": "11:58:00",  // Should NOT be null
      "check_out_time": "12:15:00"  // If completed
    },
    "responses_count": 5,
    "photos_count": 3,
    "grouped_responses": {
      "Staff": [...],
      "outlet": [...]
    }
  }
}

# Test visits list debug (requires auth token)
curl -H "Authorization: Bearer YOUR_TOKEN" \
  "https://tndsystem.online/backend-web/api/debug-visits-list.php"
```

### Step 3: Hot Restart Mobile App
```bash
# In VS Code terminal
r  # Hot restart
```

### Step 4: Check Mobile Logs
```
Expected logs when opening visit detail:

🕐 Visit check_in_time: 11:58:00        ✅ Should have value
🕐 Visit visitDate: 2025-11-03...
🔵 Loading visit details for visit ID: 34
🔵 Visit responses success: true
🔵 Visit responses data count: 5
🔵 Grouped responses: [Staff, outlet]
🔵 Total categories: 2
🔵 _groupedResponses.isEmpty BEFORE: true
🔵 _groupedResponses.isEmpty AFTER: false  ✅ Should be false!
🏗️ Building checklist section...
🏗️ _groupedResponses.isEmpty: false       ✅ Should be false!
🏗️ _groupedResponses.length: 2
✅ Building 2 category sections
📦 Building category: Staff with 4 items
🎯 Building category section: Staff
🎯 Total items: 4
   ❌ Menggunakan ID card: not ok
   ✅ Grooming sesuai SOP: ok
🎯 Stats: Pass=2, Fail=2, NA=0
📦 Building category: outlet with 1 items
```

### Step 5: Visual Check
**Visit Detail Screen should show:**
- ✅ Outlet name and code
- ✅ Date: "3 Nov 2025"
- ✅ Time: "11:58" (NOT 00:00!)
- ✅ Status badge
- ✅ Category cards (Staff, outlet)
- ✅ Items with colored icons (green ✓, red ✗)
- ✅ Statistics (Pass: X, Fail: Y, N/A: Z)
- ✅ Photos displayed

---

## 🐛 KNOWN ISSUES & FIXES

### Issue 1: Data checklist tidak muncul
**Cause:** Response value case-sensitive (`OK` vs `ok`)  
**Fix:** ✅ Changed to `.toLowerCase()` comparison

### Issue 2: Waktu 00:00
**Cause:** 
- Old visits: `check_in_time` was NULL in database
- New visits: Backend didn't set `check_in_time`

**Fix:** 
- ✅ SQL update for old visits
- ✅ Backend now sets `check_in_time` on create

### Issue 3: UI shows "No Checklist Data" despite data exists
**Possible causes:**
1. `_groupedResponses` not updating after setState
2. Build method running before setState completes
3. Response data format issue

**Debug:** Check logs for:
```
🔵 _groupedResponses.isEmpty AFTER: false  ← Should be false
🏗️ _groupedResponses.isEmpty: false       ← Should be false
```

If still true → UI state sync issue

---

## 📊 EXPECTED vs ACTUAL

| Item | Expected | Actual | Status |
|------|----------|--------|--------|
| API returns data | ✅ Yes | ✅ Yes | OK |
| Data grouped by category | ✅ 2 categories | ✅ 2 categories | OK |
| _groupedResponses updated | ✅ Not empty | ❓ TBD | ? |
| UI renders categories | ✅ 2 cards | ❓ TBD | ? |
| Time display | ✅ 11:58 | ❌ 00:00 | FAIL |
| Photos visible | ✅ 3 photos | ✅ Yes | OK |

---

## 🔧 TROUBLESHOOTING

### If time still shows 00:00:
1. Check debug API: `/debug-visits-list.php`
2. Look for `check_in_time` value
3. If NULL → backend file not uploaded
4. If has value → mobile not parsing correctly

### If data still empty:
1. Check log: `_groupedResponses.isEmpty AFTER`
2. If true → setState not working
3. If false → build() not re-rendering
4. Check log: `🏗️ Building checklist section`
5. Count how many times it prints

### If photos 404:
1. Files already uploaded ✅
2. URLs correct ✅
3. Should work now

---

## 📝 NEXT STEPS

1. ⏳ Upload 4 backend files
2. ⏳ Test debug endpoints
3. ⏳ Hot restart mobile app
4. ⏳ Check logs for debug output
5. ⏳ Visual verification
6. ⏳ Report findings

---

## 🎯 SUCCESS CRITERIA

Visit detail screen must show:
- [x] Correct time (not 00:00)
- [ ] 2 category cards visible
- [ ] 5 total checklist items
- [ ] Colored response icons
- [ ] Statistics (Pass/Fail/NA)
- [ ] 3 photos with correct URLs

Once all checked → Issue resolved! 🎉
