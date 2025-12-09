# Training Stats API - Type Error Fix

## Tanggal: 21 Oktober 2025

### Error:
```
Error getting statistics: type 'List<dynamic>' is not a subtype of type 'Map<dynamic, dynamic>'
```

---

## Root Cause:

### Problem:
API `/training/stats.php` mengembalikan `sessions_by_status` sebagai **array kosong** `[]` ketika tidak ada data, tapi model Flutter mengharapkan **object/map** `{}`.

### API Response (Before Fix):
```json
{
  "success": true,
  "data": {
    "sessions_by_status": [],  ← Array, bukan Object!
    "daily_trend": [],
    ...
  }
}
```

### Flutter Model Expectation:
```dart
sessionsByStatus: Map<String, int>.from(json['sessions_by_status'] ?? {})
```
Model mencoba convert `[]` (List) menjadi `Map` → **Type Error**

---

## Solution Implemented:

### 1. ✅ Backend API Fix (stats.php)

**Location 1:** Empty state response (Line 82)
```php
// Before
'sessions_by_status' => [],

// After
'sessions_by_status' => (object)[],
```

**Location 2:** Normal response (Line 376)
```php
// Before
'sessions_by_status' => $sessions_by_status,

// After
'sessions_by_status' => empty($sessions_by_status) ? (object)[] : $sessions_by_status,
```

**Result:**
- Ketika kosong: return `{}` (object) bukan `[]` (array)
- Ketika ada data: return `{"scheduled": 5, "ongoing": 2}` (object)

---

### 2. ✅ Flutter Model Fix (training_stats_model.dart)

**Location:** TrainingStatsModel.fromJson (Line 29)

**Before:**
```dart
sessionsByStatus: Map<String, int>.from(json['sessions_by_status'] ?? {}),
```
Akan crash jika `json['sessions_by_status']` adalah array

**After:**
```dart
sessionsByStatus: json['sessions_by_status'] != null && json['sessions_by_status'] is Map
    ? Map<String, int>.from(json['sessions_by_status'])
    : {},
```

**Logic:**
1. Check if not null
2. Check if is Map (bukan List)
3. Convert to Map<String, int>
4. Default to empty map `{}` jika bukan Map

---

## API Response Format (After Fix):

### Empty Data:
```json
{
  "success": true,
  "message": "Training statistics retrieved successfully",
  "data": {
    "period": {
      "from": "2025-09-21",
      "to": "2025-10-21",
      "days": 31
    },
    "summary": {
      "total_sessions": 0,
      "completed_sessions": 0,
      "in_progress_sessions": 0,
      "pending_sessions": 0,
      "total_participants": 0,
      "total_trainers": 0,
      "overall_average_score": 0,
      "total_photos": 0,
      "completion_rate": 0
    },
    "sessions_by_status": {},  ← Object kosong (correct!)
    "daily_trend": [],
    "top_trainers": [],
    "top_outlets": [],
    "top_checklists": [],
    "score_distribution": [],
    "recent_sessions": []
  }
}
```

### With Data:
```json
{
  "success": true,
  "data": {
    "sessions_by_status": {
      "scheduled": 5,
      "ongoing": 2,
      "completed": 10
    },
    ...
  }
}
```

---

## Testing:

### Test 1: Empty Stats (No Training Data)
```bash
GET /api/training/stats.php
```

**Expected:**
- ✅ No error
- ✅ Returns empty object `{}`
- ✅ Mobile app displays "0 sessions"

### Test 2: With Training Data
```bash
# Create training sessions first
POST /api/training/session-start.php
{
  "outlet_id": 1,
  "trainer_id": 5,
  "checklist_id": 1,
  "session_date": "2025-10-21"
}

# Then get stats
GET /api/training/stats.php
```

**Expected:**
- ✅ Returns sessions_by_status with counts
- ✅ Mobile app displays correct numbers

### Test 3: Mobile App Integration
```dart
// In TrainingMainScreen
Future<void> _loadQuickStats() async {
  final stats = await _trainingService.getCurrentMonthStats();
  // Should not throw error
}
```

**Expected:**
- ✅ No crash
- ✅ Stats load successfully
- ✅ UI displays numbers

---

## Files Modified:

1. **Backend API:**
   - `backend-web/api/training/stats.php`
   - Line 82: Changed `[]` to `(object)[]`
   - Line 376: Added check `empty() ? (object)[] : $sessions_by_status`

2. **Mobile Model:**
   - `tnd_mobile_flutter/lib/models/training/training_stats_model.dart`
   - Line 29: Added type check before converting to Map

---

## Why This Happens:

### PHP Behavior:
```php
$arr = [];        // Empty array
json_encode($arr) // Returns "[]" (JSON array)

$arr = (object)[]; // Empty object
json_encode($arr) // Returns "{}" (JSON object)
```

### Flutter/Dart Behavior:
```dart
// Type checking is strict
List != Map  // Will throw type error

// Solution: Check type before conversion
if (data is Map) {
  Map<String, int>.from(data)
} else {
  {}  // Default empty map
}
```

---

## Best Practice:

### PHP API (Consistent Data Types):
```php
// For map/object fields, always return object even when empty
'sessions_by_status' => empty($data) ? (object)[] : $data,

// For array/list fields, always return array
'daily_trend' => empty($data) ? [] : $data,
```

### Flutter/Dart (Defensive Parsing):
```dart
// Always check type before conversion
sessionsByStatus: json['field'] is Map 
    ? Map<String, int>.from(json['field'])
    : {},

// Or use try-catch
try {
  Map<String, int>.from(json['field'])
} catch (e) {
  {}
}
```

---

## Status: ✅ FIXED

**Error resolved:**
- ✅ API returns correct type (object not array)
- ✅ Model handles type mismatch gracefully
- ✅ Mobile app loads stats without error
- ✅ Both empty and filled data work correctly

**Ready to use!**

---

## Prevention:

To prevent similar issues in future:

1. **API Response Consistency:**
   - Document expected data types
   - Use TypeScript/JSON Schema for validation
   - Write API tests

2. **Model Type Safety:**
   - Always validate types before parsing
   - Use try-catch for JSON parsing
   - Provide sensible defaults

3. **Testing:**
   - Test with empty data
   - Test with partial data
   - Test with full data
   - Test error cases
