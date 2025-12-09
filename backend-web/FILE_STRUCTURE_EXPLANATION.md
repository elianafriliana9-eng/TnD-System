# 📂 STRUKTUR FILE & PENJELASAN

## 🎯 PENJELASAN ARSITEKTUR

```
backend-web/
├── api/                                    ← ENDPOINT (dipanggil mobile)
│   ├── visit-checklist-response.php       ← Routing & validation
│   └── visit-photo-upload.php             ← Upload foto handler
│
├── classes/                                ← BUSINESS LOGIC
│   └── Visit.php                          ← ✅ FILE INI YANG DIUBAH!
│
├── cleanup-orphaned-photos.sql            ← ✅ NEW FILE
├── PHOTO_ON_OK_RESPONSE_BUG_FIX.md       ← ✅ NEW FILE
└── DEPLOYMENT_GUIDE_PHOTO_FIX.md         ← ✅ NEW FILE
```

---

## 🔄 ALUR KERJA (Flow)

### Mobile App → Backend

```
┌─────────────────┐
│  Mobile App     │
│ (Flutter)       │
└────────┬────────┘
         │
         │ POST request
         │ /api/visit-checklist-response.php
         │ {visit_id, checklist_item_id, response}
         ▼
┌─────────────────────────────────┐
│ api/visit-checklist-response.php│  ← Endpoint (API layer)
│                                 │
│ 1. Validate input               │
│ 2. Check authentication         │
│ 3. Map response format          │
│    (ok → OK, not_ok → NOT OK)   │
│                                 │
└────────┬────────────────────────┘
         │
         │ $visitModel->saveChecklistResponse($data)
         ▼
┌─────────────────────────────────┐
│ classes/Visit.php               │  ← Business Logic
│                                 │
│ ✅ MODIFIED:                    │
│ 1. Check if changing NOK → OK   │
│ 2. Query existing photos        │
│ 3. DELETE from database         │
│ 4. DELETE from filesystem       │
│ 5. Save new response            │
│                                 │
└────────┬────────────────────────┘
         │
         │ Query database
         ▼
┌─────────────────────────────────┐
│ MySQL Database                  │
│                                 │
│ Tables:                         │
│ - visit_checklist_responses     │
│ - photos                        │
└─────────────────────────────────┘
```

---

## ❓ KENAPA Visit.php DI classes/, BUKAN di api/?

### Konsep MVC (Model-View-Controller):

```
api/           → Controller (routing, validation, response)
classes/       → Model (business logic, database operations)
frontend-web/  → View (UI, display)
```

### Contoh:

**SALAH ❌:**
```
api/visit-checklist-response.php:
    // Logic langsung di API file
    $sql = "INSERT INTO visit_checklist_responses...";
    $stmt = $db->prepare($sql);
    // Delete photos langsung di sini
    // ❌ Tidak reusable, sulit di-maintain
```

**BENAR ✅:**
```
api/visit-checklist-response.php:
    // Hanya routing & validation
    $visitModel = new Visit();
    $result = $visitModel->saveChecklistResponse($data);
    // ✅ Clean, reusable, easy to test

classes/Visit.php:
    public function saveChecklistResponse($data) {
        // Business logic ada di sini
        // ✅ Bisa dipanggil dari berbagai endpoint
    }
```

---

## 📤 STRUKTUR UPLOAD YANG BENAR

### Production Server Directory:

```
public_html/
└── backend-web/
    ├── api/
    │   ├── visit-checklist-response.php    ← NO CHANGE
    │   ├── visit-photo-upload.php          ← NO CHANGE
    │   └── (other API files...)
    │
    ├── classes/
    │   ├── Visit.php                       ← ✅ UPLOAD INI (MODIFIED)
    │   ├── User.php                        ← NO CHANGE
    │   ├── Outlet.php                      ← NO CHANGE
    │   └── (other class files...)
    │
    ├── config/
    │   └── database.php                    ← NO CHANGE
    │
    ├── utils/
    │   ├── Response.php                    ← NO CHANGE
    │   └── Auth.php                        ← NO CHANGE
    │
    └── (other directories...)
```

### Files Modified/Created:

```
✅ MODIFIED:
   classes/Visit.php
   
✅ NEW FILES:
   cleanup-orphaned-photos.sql
   PHOTO_ON_OK_RESPONSE_BUG_FIX.md
   DEPLOYMENT_GUIDE_PHOTO_FIX.md
   UPLOAD_CHECKLIST.txt
```

---

## 🔍 CARA VERIFIKASI FILE YANG BENAR

### 1. Check File Size

**Visit.php (after modification):**
- Before: ~8-9 KB
- After: ~11-12 KB (added photo deletion logic ~50 lines)

### 2. Check Content

Open `classes/Visit.php` dan cari:

```php
// CRITICAL FIX: Delete photos when response changes from NOT OK to OK or N/A
```

Jika ada line ini pada line ~166, berarti file **SUDAH BENAR** ✅

### 3. Check Function

Function `saveChecklistResponse()` harus punya logic:

```php
public function saveChecklistResponse($data) {
    // 1. Map checklist_item_id
    $checklistPointId = $data['checklist_item_id'];
    
    // 2. Check if changing to OK/NA
    if ($data['response'] === 'OK' || $data['response'] === 'N/A') {
        // 3. Query existing response
        // 4. If was NOT OK, delete photos
        // 5. Delete from database
        // 6. Delete from filesystem
    }
    
    // 7. Save response (INSERT ... ON DUPLICATE KEY UPDATE)
}
```

---

## ⚠️ COMMON MISTAKES TO AVOID

### ❌ SALAH:

**Mistake 1:** Edit file di `api/` folder
```
❌ api/visit-checklist-response.php (JANGAN EDIT INI!)
```

**Mistake 2:** Upload ke path yang salah
```
❌ public_html/backend-web/Visit.php (SALAH PATH!)
✅ public_html/backend-web/classes/Visit.php (BENAR!)
```

**Mistake 3:** Tidak backup file lama
```
❌ Langsung overwrite tanpa backup
✅ Download Visit.php dulu, save as Visit.php.backup
```

### ✅ BENAR:

1. Edit file: `classes/Visit.php` ✅
2. Upload ke: `public_html/backend-web/classes/` ✅
3. Backup dulu sebelum upload ✅
4. Verify file permissions: 644 ✅
5. Test setelah upload ✅

---

## 🎯 SUMMARY

**File yang dimodifikasi:**
- `backend-web/classes/Visit.php` ← Business logic layer

**File yang TIDAK diubah:**
- `backend-web/api/visit-checklist-response.php` ← API layer (sudah benar)
- `backend-web/api/visit-photo-upload.php` ← Upload handler (sudah benar)

**Kenapa?**
- Separation of concerns (MVC pattern)
- Business logic harus di Model (classes/)
- API hanya routing & validation

**Upload path:**
```
Local: c:\laragon\www\tnd_system\tnd_system\backend-web\classes\Visit.php
Server: public_html/backend-web/classes/Visit.php
```

**Verification:**
```bash
# After upload, check file exists:
ls -la public_html/backend-web/classes/Visit.php

# Check content has the fix:
grep -n "CRITICAL FIX" public_html/backend-web/classes/Visit.php
# Should show line number ~166
```

---

✅ **READY FOR UPLOAD!**
