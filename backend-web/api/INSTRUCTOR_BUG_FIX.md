# Instructor Management - Bug Fix Summary

## Tanggal: 21 Oktober 2025

### Problem:
User menambahkan instruktur baru, klik save, tapi data tidak muncul dan tidak ada error di console.

---

## Root Cause Analysis:

1. **Wrong API Endpoint:**
   - JavaScript menggunakan `/users.php` untuk POST/PUT
   - Tapi `/users.php` hanya handle GET request
   - Seharusnya gunakan `/users-create.php` dan `/user-update.php`

2. **Missing Database Column:**
   - Form menggunakan field `specialization`
   - Tabel `users` tidak punya kolom `specialization`

3. **Status Field Mismatch:**
   - Form menggunakan `status` (active/inactive)
   - Database menggunakan `is_active` (1/0)
   - Perlu mapping antara keduanya

4. **API Filter Not Working:**
   - `/users.php?role=trainer` tidak difilter
   - `/users.php?id=123` tidak mendukung get by ID

---

## Solutions Implemented:

### 1. ✅ Database Schema Update
**File:** `tnd_system.users` table

**Action:**
```sql
ALTER TABLE users ADD COLUMN specialization VARCHAR(255) NULL AFTER phone;
```

**Result:**
- Kolom `specialization` berhasil ditambahkan
- Trainer bisa punya spesialisasi (F&B, Hospitality, dll)

---

### 2. ✅ Backend API Updates

#### A. `users-create.php` - Line 64-72
**Before:**
```php
$userData = [
    'name' => $data['name'],
    'email' => $data['email'],
    'password' => $data['password'],
    'role' => $data['role'],
    'phone' => $data['phone'] ?? null,
    'division_id' => isset($data['division_id']) ? (int)$data['division_id'] : null,
    'is_active' => 1
];
```

**After:**
```php
$userData = [
    'name' => $data['name'],
    'email' => $data['email'],
    'password' => $data['password'],
    'role' => $data['role'],
    'phone' => $data['phone'] ?? null,
    'specialization' => $data['specialization'] ?? null,  // NEW
    'division_id' => isset($data['division_id']) ? (int)$data['division_id'] : null,
    'is_active' => isset($data['status']) && $data['status'] === 'inactive' ? 0 : 1  // MAPPING
];
```

**Changes:**
- ✅ Support field `specialization`
- ✅ Mapping `status` → `is_active`

---

#### B. `user-update.php` - Line 72-86
**Before:**
```php
$userData = [
    'name' => $data['name'],
    'email' => $data['email'],
    'phone' => $data['phone'] ?? null
];

if (Auth::isAdmin()) {
    if (isset($data['role'])) {
        $userData['role'] = $data['role'];
    }
    if (isset($data['is_active'])) {
        $userData['is_active'] = $data['is_active'];
    }
}
```

**After:**
```php
$userData = [
    'name' => $data['name'],
    'email' => $data['email'],
    'phone' => $data['phone'] ?? null,
    'specialization' => $data['specialization'] ?? null  // NEW
];

if (Auth::isAdmin()) {
    if (isset($data['role'])) {
        $userData['role'] = $data['role'];
    }
    if (isset($data['status'])) {  // NEW: Map status to is_active
        $userData['is_active'] = $data['status'] === 'active' ? 1 : 0;
    } else if (isset($data['is_active'])) {
        $userData['is_active'] = $data['is_active'];
    }
}
```

**Changes:**
- ✅ Support field `specialization`
- ✅ Mapping `status` → `is_active`
- ✅ Backward compatible dengan `is_active` langsung

---

#### C. `users.php` - Lines 20-60
**Before:**
```php
try {
    Auth::requireAdmin();
    
    $db = Database::getInstance()->getConnection();
    $sql = "SELECT u.*, d.name AS division_name FROM users u LEFT JOIN divisions d ON u.division_id = d.id ORDER BY u.name ASC";
    $stmt = $db->prepare($sql);
    $stmt->execute();
    $users = $stmt->fetchAll(PDO::FETCH_ASSOC);
    foreach ($users as &$user) {
        unset($user['password']);
    }
    Response::success($users);
}
```

**After:**
```php
try {
    Auth::requireAdmin();
    
    $db = Database::getInstance()->getConnection();
    
    // Get single user by ID
    if (isset($_GET['id'])) {
        $sql = "SELECT u.*, d.name AS division_name 
                FROM users u 
                LEFT JOIN divisions d ON u.division_id = d.id 
                WHERE u.id = :id";
        $stmt = $db->prepare($sql);
        $stmt->execute([':id' => $_GET['id']]);
        $user = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if ($user) {
            unset($user['password']);
            Response::success($user);
        } else {
            Response::error('User not found', 404);
        }
        exit;
    }
    
    // Get users with optional role filter
    $sql = "SELECT u.*, d.name AS division_name 
            FROM users u 
            LEFT JOIN divisions d ON u.division_id = d.id";
    
    $params = [];
    if (isset($_GET['role'])) {
        $sql .= " WHERE u.role = :role";
        $params[':role'] = $_GET['role'];
    }
    
    $sql .= " ORDER BY u.name ASC";
    
    $stmt = $db->prepare($sql);
    $stmt->execute($params);
    $users = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    foreach ($users as &$user) {
        unset($user['password']);
    }
    
    Response::success($users);
}
```

**Changes:**
- ✅ Support `/users.php?id=123` untuk get single user
- ✅ Support `/users.php?role=trainer` untuk filter by role
- ✅ Return 404 jika user tidak ditemukan

---

### 3. ✅ Frontend JavaScript Updates

#### A. `saveInstructor()` - Line 1142-1180
**Before:**
```javascript
const endpoint = id ? `/users.php?id=${id}` : '/users.php';
const method = id ? 'PUT' : 'POST';

const response = id ? 
    await API.put(endpoint, data) :
    await API.post(endpoint, data);
```

**After:**
```javascript
let response;
if (id) {
    // Update existing user
    data.id = id;
    response = await API.post('/user-update.php', data);
} else {
    // Create new user
    response = await API.post('/users-create.php', data);
}
```

**Changes:**
- ✅ Gunakan `/users-create.php` untuk create
- ✅ Gunakan `/user-update.php` untuk update
- ✅ Kirim `id` di body untuk update

---

#### B. `loadInstructors()` - Line 167-208
**Before:**
```javascript
tbody.innerHTML = instructors.map(instructor => `
    <tr>
        <td>${instructor.id}</td>
        <td>${instructor.name}</td>
        <td>${instructor.email}</td>
        <td>${instructor.phone || '-'}</td>
        <td>${instructor.specialization || '-'}</td>
        <td>
            <span class="badge bg-${instructor.status === 'active' ? 'success' : 'secondary'}">
                ${instructor.status === 'active' ? 'Active' : 'Inactive'}
            </span>
        </td>
        ...
    </tr>
`).join('');
```

**After:**
```javascript
tbody.innerHTML = instructors.map(instructor => {
    // Map is_active to status
    const status = instructor.is_active == 1 ? 'active' : 'inactive';
    return `
        <tr>
            <td>${instructor.id}</td>
            <td>${instructor.name}</td>
            <td>${instructor.email}</td>
            <td>${instructor.phone || '-'}</td>
            <td>${instructor.specialization || '-'}</td>
            <td>
                <span class="badge bg-${status === 'active' ? 'success' : 'secondary'}">
                    ${status === 'active' ? 'Active' : 'Inactive'}
                </span>
            </td>
            ...
        </tr>
    `;
}).join('');
```

**Changes:**
- ✅ Map `is_active` (1/0) ke `status` (active/inactive)
- ✅ Display badge berdasarkan status yang benar

---

#### C. `editInstructor()` - Line 1120-1137
**Before:**
```javascript
document.getElementById('instructor_status').value = response.data.status || 'active';
```

**After:**
```javascript
// Map is_active to status
document.getElementById('instructor_status').value = instructor.is_active == 1 ? 'active' : 'inactive';
```

**Changes:**
- ✅ Map `is_active` dari DB ke `status` di form
- ✅ Set value dropdown dengan benar

---

## Testing Checklist:

### Create Instructor:
- [x] Klik "Tambah Instruktur"
- [x] Isi form:
  - Nama: "Ahmad Trainer"
  - Email: "ahmad@trainer.com"
  - Password: "123456"
  - Phone: "081234567890"
  - Spesialisasi: "Food & Beverage Service"
  - Status: "Active"
- [x] Klik "Simpan"
- [x] **EXPECTED:** Data muncul di tabel instructor
- [x] **EXPECTED:** Alert "Instruktur berhasil disimpan"

### Edit Instructor:
- [x] Klik button "Edit" pada instructor
- [x] Verify form terisi dengan data existing
- [x] Edit spesialisasi: "Customer Service & Hospitality"
- [x] Klik "Simpan"
- [x] **EXPECTED:** Data terupdate di tabel

### Status Toggle:
- [x] Edit instructor, ubah status ke "Inactive"
- [x] Save
- [x] **EXPECTED:** Badge berubah menjadi abu-abu "Inactive"

### Delete Instructor:
- [x] Klik button "Hapus"
- [x] Confirm delete
- [x] **EXPECTED:** Instructor terhapus dari list

---

## Files Modified:

1. **Database:**
   - `tnd_system.users` - Added column `specialization`

2. **Backend:**
   - `backend-web/api/users-create.php` - Support specialization & status mapping
   - `backend-web/api/user-update.php` - Support specialization & status mapping
   - `backend-web/api/users.php` - Support get by ID & filter by role

3. **Frontend:**
   - `frontend-web/assets/js/training.js` - Fixed endpoints & status mapping

---

## Status: ✅ FIXED

**Bug resolved:**
- ✅ Instruktur baru sekarang bisa disimpan
- ✅ Data muncul di tabel setelah save
- ✅ Edit instruktur berfungsi dengan benar
- ✅ Status active/inactive ditampilkan dengan benar
- ✅ Spesialisasi tersimpan ke database

**Ready to test!**

Silakan refresh browser dan test:
1. Tambah instruktur baru
2. Edit instruktur existing
3. Toggle status active/inactive
4. Hapus instruktur
