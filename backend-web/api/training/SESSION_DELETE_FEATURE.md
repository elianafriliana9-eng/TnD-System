# Training Schedule Delete Feature - Implementation

## Tanggal: 21 Oktober 2025

### Problem:
User klik tombol "Hapus" di jadwal training tapi tidak berfungsi (masih alert "Delete functionality will be implemented").

---

## Solution Implemented:

### 1. ✅ Backend API - session-delete.php

**File:** `backend-web/api/training/session-delete.php`

**Endpoint:** `/api/training/session-delete.php?id={sessionId}`

**Method:** DELETE

**Features:**

#### A. Smart Delete Logic:
```
┌─────────────────────────────────────────────┐
│  Check Session Status & Data                │
└─────────────────┬───────────────────────────┘
                  │
        ┌─────────┴──────────┐
        │                    │
        ▼                    ▼
   COMPLETED          HAS DATA?
   ❌ Don't delete    (participants/responses/photos)
                      │
              ┌───────┴────────┐
              │                │
              ▼                ▼
           YES              NO
     SOFT DELETE      HARD DELETE
     (Cancel)         (Remove)
```

#### B. Protection Rules:

**1. Completed Sessions:**
```php
if ($session['status'] === 'completed') {
    Response::error('Cannot delete completed sessions');
}
```
❌ **TIDAK BISA DIHAPUS** - Data training penting

**2. Sessions with Data:**
```php
if ($hasParticipants || $hasResponses || $hasPhotos) {
    // SOFT DELETE - Change status to 'cancelled'
    UPDATE training_sessions SET status = 'cancelled' WHERE id = ?
}
```
✅ **SOFT DELETE** - Status berubah jadi "Cancelled"

**3. Empty Sessions:**
```php
else {
    // HARD DELETE - Remove completely
    DELETE FROM training_sessions WHERE id = ?
}
```
✅ **HARD DELETE** - Dihapus permanen

---

### 2. ✅ Frontend JavaScript Update

**File:** `frontend-web/assets/js/training.js`

**Function:** `deleteSchedule(id)` - Line 354-370

**Before:**
```javascript
async function deleteSchedule(id) {
    if (!confirm('Apakah Anda yakin ingin menghapus jadwal ini?')) {
        return;
    }
    
    try {
        // TODO: Implement delete API
        alert('Delete functionality will be implemented');
    } catch (error) {
        console.error('Error deleting schedule:', error);
    }
}
```

**After:**
```javascript
async function deleteSchedule(id) {
    if (!confirm('Apakah Anda yakin ingin menghapus jadwal training ini?')) {
        return;
    }
    
    try {
        const response = await API.delete(`/training/session-delete.php?id=${id}`);
        
        if (response.success) {
            alert(response.message || 'Jadwal training berhasil dihapus');
            await loadSchedules();
        } else {
            alert('Error: ' + (response.message || 'Gagal menghapus jadwal'));
        }
    } catch (error) {
        console.error('Error deleting schedule:', error);
        alert('Error: ' + error.message);
    }
}
```

**Changes:**
- ✅ Call DELETE API endpoint
- ✅ Show success/error message from API
- ✅ Reload schedules after successful delete
- ✅ Handle errors gracefully

---

## Delete Scenarios:

### Scenario 1: Empty Schedule (Just Created)
```
Status: scheduled
Participants: 0
Responses: 0
Photos: 0

ACTION: HARD DELETE ✅
RESULT: Session dihapus permanen dari database
MESSAGE: "Training session deleted successfully"
```

### Scenario 2: Schedule with Participants
```
Status: scheduled
Participants: 5
Responses: 0
Photos: 0

ACTION: SOFT DELETE (Cancel) ✅
RESULT: Status berubah menjadi 'cancelled'
MESSAGE: "Training session has been cancelled because it contains training data"
```

### Scenario 3: Ongoing Training
```
Status: ongoing
Participants: 5
Responses: 10
Photos: 3

ACTION: SOFT DELETE (Cancel) ✅
RESULT: Status berubah menjadi 'cancelled'
MESSAGE: "Training session has been cancelled because it contains training data"
```

### Scenario 4: Completed Training
```
Status: completed
Participants: 5
Responses: 25
Photos: 8

ACTION: BLOCK ❌
RESULT: Error - tidak bisa dihapus
MESSAGE: "Cannot delete completed sessions. Completed sessions contain important training data."
```

---

## API Request & Response:

### Request:
```http
DELETE /api/training/session-delete.php?id=123
```

### Response - Hard Delete:
```json
{
  "success": true,
  "message": "Training session deleted successfully",
  "data": null
}
```

### Response - Soft Delete:
```json
{
  "success": true,
  "message": "Training session has been cancelled because it contains training data (participants, responses, or photos)",
  "data": null
}
```

### Response - Completed Session:
```json
{
  "success": false,
  "message": "Cannot delete completed sessions. Completed sessions contain important training data.",
  "code": 400
}
```

### Response - Not Found:
```json
{
  "success": false,
  "message": "Training session not found",
  "code": 404
}
```

---

## Database Impact:

### Hard Delete:
```sql
-- Before
SELECT * FROM training_sessions WHERE id = 123;
-- Result: 1 row

-- After DELETE
SELECT * FROM training_sessions WHERE id = 123;
-- Result: 0 rows (deleted permanently)
```

### Soft Delete (Cancel):
```sql
-- Before
SELECT id, status FROM training_sessions WHERE id = 123;
-- Result: 123, 'scheduled'

-- After DELETE
SELECT id, status FROM training_sessions WHERE id = 123;
-- Result: 123, 'cancelled'
```

---

## UI Flow:

### Web Admin Interface:

**1. View Schedule:**
```
┌────────────────────────────────────────────┐
│ Jadwal Training                            │
├────────────────────────────────────────────┤
│ ID | Date       | Outlet | Trainer | Aksi │
├────────────────────────────────────────────┤
│ 1  | 2025-10-21 | Outlet | Ahmad   | 🗑️  │
└────────────────────────────────────────────┘
```

**2. Click Delete Button:**
```
┌────────────────────────────────────────────┐
│ ⚠️  Confirm                                │
├────────────────────────────────────────────┤
│ Apakah Anda yakin ingin menghapus jadwal   │
│ training ini?                              │
│                                            │
│           [Cancel]  [OK]                   │
└────────────────────────────────────────────┘
```

**3. Success:**
```
┌────────────────────────────────────────────┐
│ ✅ Success                                 │
├────────────────────────────────────────────┤
│ Training session deleted successfully      │
│                                            │
│              [OK]                          │
└────────────────────────────────────────────┘
```

**4. List Refreshed:**
```
┌────────────────────────────────────────────┐
│ Jadwal Training                            │
├────────────────────────────────────────────┤
│ Belum ada jadwal training                  │
└────────────────────────────────────────────┘
```

---

## Testing Checklist:

### Test 1: Delete Empty Schedule
- [ ] Create new schedule (don't start)
- [ ] Click delete button
- [ ] Confirm deletion
- [ ] **VERIFY:** Session deleted permanently
- [ ] **VERIFY:** Message: "Training session deleted successfully"
- [ ] **VERIFY:** Schedule list refreshed

### Test 2: Delete Schedule with Participants
- [ ] Create schedule and add participants
- [ ] Click delete button
- [ ] Confirm deletion
- [ ] **VERIFY:** Status changed to "Cancelled"
- [ ] **VERIFY:** Message mentions "contains training data"
- [ ] **VERIFY:** Schedule still visible with "Cancelled" badge

### Test 3: Try Delete Completed Session
- [ ] Find completed training session
- [ ] Click delete button
- [ ] Confirm deletion
- [ ] **VERIFY:** Error message appears
- [ ] **VERIFY:** Session NOT deleted
- [ ] **VERIFY:** Message: "Cannot delete completed sessions"

### Test 4: Delete Ongoing Training
- [ ] Start a training session (ongoing)
- [ ] Try to delete from web
- [ ] **VERIFY:** Changed to "Cancelled"
- [ ] **VERIFY:** Trainer can't continue in mobile app

### Test 5: Cancel Confirmation
- [ ] Click delete button
- [ ] Click "Cancel" in confirm dialog
- [ ] **VERIFY:** Nothing happens
- [ ] **VERIFY:** Schedule still exists

---

## Security Features:

### 1. Authentication (TODO: Enable in Production)
```php
// Currently disabled for testing
// if (!Auth::checkAuth()) {
//     Response::unauthorized('Authentication required');
// }
```

### 2. Method Validation
```php
if ($_SERVER['REQUEST_METHOD'] !== 'DELETE') {
    Response::error('Method not allowed', 405);
}
```

### 3. Input Validation
```php
if (!$sessionId) {
    Response::error('Session ID is required', 400);
}
```

### 4. Existence Check
```php
if (!$session) {
    Response::error('Training session not found', 404);
}
```

### 5. Business Logic Protection
```php
if ($session['status'] === 'completed') {
    Response::error('Cannot delete completed sessions', 400);
}
```

---

## Related Files:

### Backend:
1. ✅ **NEW:** `backend-web/api/training/session-delete.php`
2. **USES:** `config/database.php`
3. **USES:** `utils/Response.php`
4. **USES:** `utils/Auth.php`
5. **USES:** `utils/Headers.php`

### Frontend:
1. ✅ **MODIFIED:** `frontend-web/assets/js/training.js`
   - Function: `deleteSchedule(id)` - Line 354-370

### Database:
1. **TABLE:** `training_sessions`
   - Status: scheduled/ongoing/completed/cancelled
2. **TABLE:** `training_participants`
3. **TABLE:** `training_responses`
4. **TABLE:** `training_photos`

---

## Status Lifecycle:

```
┌──────────┐     ┌─────────┐     ┌───────────┐
│scheduled │────>│ ongoing │────>│ completed │
└────┬─────┘     └────┬────┘     └─────┬─────┘
     │                │                 │
     │ delete         │ delete          │ delete
     │                │                 │
     ▼                ▼                 ▼
┌────────────────────────────────────────────┐
│            ❌ Cannot Delete               │
│   (soft delete → cancelled)                │
└────────────────────────────────────────────┘
```

**EXCEPTION:**
- Empty scheduled sessions (no data) → CAN be hard deleted

---

## Best Practices Applied:

### 1. Data Integrity:
- ✅ Don't delete completed sessions
- ✅ Preserve data by soft delete
- ✅ Check for related data before hard delete

### 2. User Experience:
- ✅ Confirmation dialog
- ✅ Clear success/error messages
- ✅ Auto refresh list after delete

### 3. Error Handling:
- ✅ Validate input
- ✅ Check existence
- ✅ Handle exceptions
- ✅ Rollback on error

### 4. Transaction Safety:
- ✅ Use database transactions
- ✅ Rollback on failure
- ✅ Atomic operations

---

## Status: ✅ IMPLEMENTED & READY

**Features:**
- ✅ Delete API endpoint created
- ✅ Frontend function implemented
- ✅ Smart delete logic (hard/soft)
- ✅ Protection for completed sessions
- ✅ Confirmation dialog
- ✅ Success/error messages
- ✅ Auto refresh after delete

**Ready to test!**

Silakan refresh browser dan test:
1. Buat jadwal training baru
2. Klik tombol "Hapus" (trash icon)
3. Confirm deletion
4. Verify jadwal terhapus

---

## Future Enhancements (Optional):

### 1. Bulk Delete:
- Select multiple schedules
- Delete in one action

### 2. Restore Cancelled:
- Restore cancelled sessions back to scheduled

### 3. Delete with Reason:
- Add deletion reason field
- Track who deleted and why

### 4. Archive Instead of Delete:
- Move to archive table
- Keep full history
