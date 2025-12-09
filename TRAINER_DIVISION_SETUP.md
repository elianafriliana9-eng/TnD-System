# Training Module - Trainer Division Setup Guide

## Overview

Trainer Division telah ditambahkan sebagai divisi baru terpisah dari QC dan unit lainnya. Trainer memiliki role khusus `trainer` yang memungkinkan akses eksklusif ke Training Module di mobile app.

---

## Architecture & Data Separation

### User Roles & Access Control
```
┌─────────────────────────────────────────────────────┐
│                    System Roles                      │
├─────────────────────────────────────────────────────┤
│ super_admin   → Full system access                   │
│ admin         → General administration               │
│ supervisor    → Department supervision               │
│ trainer       → Training module (NEW)                │
│ staff         → Basic user access                    │
│ visitor       → Guest access                         │
└─────────────────────────────────────────────────────┘

Role: trainer is separate and dedicated to Training Module
```

### Database Schema

#### Users Table - Role Column
```sql
ALTER TABLE users 
MODIFY COLUMN role ENUM('super_admin', 'admin', 'visitor', 'trainer') NOT NULL DEFAULT 'visitor';
```

#### Additional Trainer Fields (Optional)
```sql
-- Already added in migrations
ALTER TABLE users ADD COLUMN specialization VARCHAR(255) NULL;
ALTER TABLE users ADD COLUMN trainer_bio TEXT NULL;
```

---

## How to Create a Trainer Account

### Method 1: Via Web Super Admin Interface

#### Steps:
1. **Login to Web Super Admin**
   - URL: `http://localhost/tnd_system/frontend-web`
   - Email: super_admin account
   - Password: ****

2. **Navigate to Users Management**
   - Click on "Users Management" in the sidebar
   - Click "Add User" button

3. **Fill Trainer Account Form**
   ```
   Full Name:     [Nama Trainer Lengkap]
   Email:         [trainer@company.com]
   Password:      [Generated Password - min 6 chars]
   Phone:         [+62XXXXXXX]
   Division:      [Pilih division - contoh: QC, Operations, etc]
   Role:          [Trainer] ← NEW OPTION
   Status:        [Active]
   ```

4. **Submit Form**
   - Click "Add User" button
   - Trainer account will be created with role 'trainer'
   - Email will receive welcome message with credentials

#### Screenshot Field Reference:
| Field | Notes |
|-------|-------|
| Full Name | Required - min 2 chars |
| Email | Required - unique, used for login |
| Password | Required - min 6 chars |
| Phone | Optional - for contact |
| Division | Required - trainer's home division |
| **Role** | **NEW - Select 'Trainer' option** |

---

### Method 2: Via Direct Database Insert (Dev/Testing)

```sql
-- Insert trainer user directly
INSERT INTO users (
    username,
    full_name,
    email,
    password,
    phone,
    role,
    division_id,
    is_active,
    created_at,
    updated_at
) VALUES (
    'trainer_username',
    'Trainer Name',
    'trainer@company.com',
    SHA2('password123', 256),  -- or password_hash()
    '+62812345678',
    'trainer',  -- Role set to trainer
    1,          -- division_id (adjust as needed)
    1,          -- is_active (1 = active)
    NOW(),
    NOW()
);
```

---

## Training Module - Trainer Access

### Mobile App Login

#### Login Credentials
- **URL**: Training Mobile App
- **Email**: trainer@company.com (from super admin)
- **Password**: [Password set during creation]

#### After Login
1. **SharedPreferences** will store:
   ```
   user_id: [auto_id]
   user_name: [Trainer Name]
   user_email: trainer@company.com
   user_role: trainer
   user_division_id: 1
   user_division_name: [Division Name]
   is_logged_in: true
   ```

2. **App Screens Accessible**:
   - ✅ Training Dashboard - View overall statistics
   - ✅ Training Schedule - Create new training sessions
   - ✅ Training Daily - View scheduled training
   - ✅ Session Checklist - Conduct training with checklist
   - ✅ Session Complete - Mark training as completed

3. **Data Isolation**:
   - Trainers can **only see/create** their own training sessions
   - Trainer ID auto-populated from logged-in user
   - Dashboard shows aggregated statistics across all trainers

---

## API Endpoints - Trainer Access

### Authentication
```
POST /api/login.php
Body: {
    "email": "trainer@company.com",
    "password": "password123"
}
Response: {
    "success": true,
    "data": {
        "id": 5,
        "full_name": "Trainer Name",
        "email": "trainer@company.com",
        "role": "trainer",
        "division_id": 1,
        "division_name": "Training Division"
    }
}
```

### Training Endpoints (Trainer Access)
All endpoints below require valid trainer login:

| Endpoint | Method | Purpose | Role |
|----------|--------|---------|------|
| `/api/training/session-start` | POST | Create training session | trainer |
| `/api/training/sessions-list` | GET | List trainer's sessions | trainer |
| `/api/training/stats` | GET | View dashboard stats | trainer |
| `/api/training/session-complete` | POST | Complete session | trainer |
| `/api/training/outlets` | GET | Get available outlets | trainer |

#### Example: Create Training Session
```php
POST /api/training/session-start.php
{
    "outlet_id": 1,
    "trainer_id": 5,           // Current logged-in trainer
    "session_date": "2025-11-18",
    "start_time": "08:00:00",
    "checklist_id": 3,
    "notes": "Training session notes"
}

Response (201):
{
    "success": true,
    "data": {
        "message": "Training session started successfully",
        "session": {
            "id": 6,
            "trainer_id": 5,
            "trainer_name": "Trainer Name",
            "status": "ongoing",
            "session_date": "2025-11-18",
            "start_time": "08:00:00"
        }
    }
}
```

---

## Key Features & Separation

### What Trainers Can Do
- ✅ View their training schedule
- ✅ Start new training sessions
- ✅ Conduct training with checklist verification
- ✅ Record responses and notes
- ✅ Complete training sessions
- ✅ View personal dashboard statistics

### What Trainers CANNOT Do
- ❌ Edit QC audit data
- ❌ Access management features
- ❌ Modify system settings
- ❌ Create/edit other users
- ❌ Delete audit records
- ❌ Access financial data

### Data Isolation
```
Trainer Login (user_id = 5)
    ↓
Mobile App Loads
    ↓
Training Service checks user_id
    ↓
All API calls include trainer_id = 5
    ↓
Database queries filtered by trainer_id = 5
    ↓
Only sessions created by trainer_id = 5 returned
```

---

## Security Considerations

### 1. Role-Based Access Control
```php
// Backend validation (all training endpoints)
if (!isset($_SESSION['user_id']) || $_SESSION['role'] !== 'trainer') {
    Response::unauthorized('Trainer access required');
}
```

### 2. Data Ownership Validation
```php
// Trainer can only access own sessions
$session = $db->query("SELECT * FROM training_sessions 
                       WHERE id = ? AND trainer_id = ?", 
                       [$sessionId, $_SESSION['user_id']]);
```

### 3. Password Security
- Passwords hashed with PHP's `password_hash()` using PASSWORD_DEFAULT
- Minimum 6 characters enforced
- Unique email addresses required

---

## Testing Trainer Account

### Test Case 1: Create Trainer in Super Admin
**Steps:**
1. Login to super admin
2. Go to Users Management
3. Add New User with Role = "Trainer"
4. Fill all required fields
5. Submit

**Expected:**
- User created successfully
- Email appears in user list
- Role shows as "Trainer" with green badge

---

### Test Case 2: Login with Trainer Account
**Steps:**
1. Open Training Mobile App
2. Login with trainer email & password
3. Check Dashboard loads

**Expected:**
- Login successful
- User role stored as 'trainer'
- Dashboard displays stats
- Can create training sessions

---

### Test Case 3: Create Training Session
**Steps:**
1. Logged in as trainer
2. Go to Training Schedule
3. Select outlet from dropdown
4. Click "Create Session"
5. Session saves to database

**Expected:**
- Session created with trainer_id = logged-in user
- Session visible in daily schedule
- Dashboard stats updated

---

## Troubleshooting

### Issue: "Trainer role not appearing in dropdown"
**Solution:** Ensure users.js was updated with trainer option:
```javascript
<option value="trainer">Trainer</option>
```

### Issue: "Trainer cannot login to mobile app"
**Solution:** Check:
1. User created with role = 'trainer'
2. User email/password correct
3. User is_active = 1
4. Mobile app uses correct API endpoint

### Issue: "Trainer sees all sessions, not just own"
**Solution:** Verify stats.php filters by trainer_id:
```php
WHERE ts.trainer_id = :trainer_id
```

---

## Database Verification Queries

### Check Trainer Users Created
```sql
SELECT id, full_name, email, role, division_id, is_active, created_at
FROM users 
WHERE role = 'trainer'
ORDER BY created_at DESC;
```

### Check Trainer Sessions
```sql
SELECT ts.id, ts.session_date, ts.status, u.full_name as trainer_name, o.name as outlet_name
FROM training_sessions ts
JOIN users u ON ts.trainer_id = u.id
JOIN outlets o ON ts.outlet_id = o.id
WHERE u.role = 'trainer'
ORDER BY ts.session_date DESC;
```

### Count Sessions by Trainer
```sql
SELECT 
    u.id,
    u.full_name,
    COUNT(ts.id) as total_sessions,
    SUM(CASE WHEN ts.status = 'completed' THEN 1 ELSE 0 END) as completed,
    SUM(CASE WHEN ts.status = 'ongoing' THEN 1 ELSE 0 END) as ongoing
FROM users u
LEFT JOIN training_sessions ts ON u.id = ts.trainer_id
WHERE u.role = 'trainer'
GROUP BY u.id, u.full_name;
```

---

## Configuration Summary

### Web Super Admin Changes
- ✅ Added "Trainer" option to Role dropdown in users.js
- ✅ Added badge color for trainer role (green/success)
- ✅ Both Add User and Edit User modals support trainer role

### Mobile App Changes
- ✅ Added `roleTrainer = 'trainer'` constant in constants.dart
- ✅ Training endpoints already support trainer role
- ✅ No hard-coded role restrictions blocking trainer access

### Database Changes
- ✅ Users table role enum includes 'trainer'
- ✅ Users table has optional specialization & trainer_bio columns
- ✅ Training tables use trainer_id for proper referencing

---

## Summary

| Component | Status | Details |
|-----------|--------|---------|
| Database Schema | ✅ Complete | Users table supports trainer role |
| Web Super Admin UI | ✅ Complete | Trainer option in user management |
| API Endpoints | ✅ Compatible | Training endpoints work with trainer role |
| Mobile App | ✅ Ready | Can login and access training features |
| Data Isolation | ✅ Implemented | Trainers see only their own sessions |
| Documentation | ✅ Complete | This guide covers all aspects |

---

## Next Steps

1. **Create Test Trainer Account**
   - Use Web Super Admin to create a test trainer
   - Note the email and auto-generated password

2. **Test Login in Mobile App**
   - Login with trainer credentials
   - Verify dashboard loads correctly

3. **Test Training Session Creation**
   - Create a training session
   - Verify it's assigned to the correct trainer
   - Conduct training with checklist

4. **Verify Data Isolation**
   - Login with another trainer account
   - Verify they cannot see other trainer's sessions
   - Check dashboard only shows their data

---

*Document Version: 1.0*  
*Last Updated: November 18, 2025*  
*System: TnD System - Training Module*
