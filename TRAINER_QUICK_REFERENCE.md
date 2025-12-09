# Quick Reference - Trainer Account Management

## For Web Super Admin Users

### Creating a Trainer Account - Step by Step

#### Step 1: Login to Web Super Admin
```
URL: http://localhost/tnd_system/frontend-web
Role: Super Admin or Admin
```

#### Step 2: Navigate to Users Management
```
Sidebar → Users Management
OR
Main Menu → Administration → Users
```

#### Step 3: Click "Add User" Button
```
Location: Top right of Users table
Button: "+ Add User"
```

#### Step 4: Fill the Form
| Field | Value | Notes |
|-------|-------|-------|
| **Full Name** | Trainer Name | Required - min 2 characters |
| **Email** | trainer@company.com | Required - unique email |
| **Phone** | +62812345678 | Optional - for contact |
| **Password** | Auto-generated | Required - min 6 chars |
| **Division** | Select from dropdown | Required - trainer's department |
| **Role** | **Trainer** ⭐ | **NEW OPTION - Select this** |

#### Step 5: Submit and Confirm
```
Click: "Add User" button
Wait: Form processes
Result: Success message "User added successfully"
```

---

## Field Details Explained

### Email (Required)
- Must be unique in system
- Used for login to mobile app
- Example: `trainer.name@company.com`

### Password (Required)
- Minimum 6 characters
- Can contain numbers, special chars
- Example: `Training@123`
- **IMPORTANT**: Share this password securely with trainer

### Division (Required)
- Trainer's home/primary division
- Examples: QC, Operations, HR, Production
- Can assign to same or different division than other roles

### Role Dropdown - NEW OPTIONS
Previously only had:
- Admin
- Supervisor  
- Staff

**Now includes:**
- ✨ **Trainer** ← SELECT THIS FOR TRAINERS

### Status (Active)
- ✅ Active: User can login immediately
- ❌ Inactive: User cannot login

---

## After Creating Trainer Account

### Communicate with Trainer
Send trainer the following credentials:
```
Email:    trainer@company.com
Password: [password you set]
App:      Training Mobile App
URL:      [app download link]
```

### Trainer's First Login
```
1. Open Training Mobile App
2. Login with email & password
3. Dashboard will load
4. Can start creating training sessions
```

### Verify Trainer Access
Trainer should see:
- ✅ Training Dashboard
- ✅ Training Schedule (Create Sessions)
- ✅ Daily Training View
- ✅ Session Checklist
- ✅ Session Completion

---

## Editing Existing Trainer

### To Change Trainer Role (if needed)
1. Go to Users Management
2. Find trainer in list
3. Click "Edit" button
4. Change Role from "Trainer" to other role or vice versa
5. Click "Update User"

### To Deactivate Trainer
1. Go to Users Management
2. Find trainer in list
3. Click "Edit"
4. Uncheck "Active User" checkbox
5. Click "Update User"
6. Trainer cannot login anymore

### To Change Trainer Password
Currently: Direct password reset not supported in UI
Workaround: Edit user and they can reset via app

---

## Common Questions

**Q: Can a trainer also be a QC auditor?**
A: No - Role must be ONE of: trainer, admin, supervisor, staff
   Each user has one primary role. To switch, use Edit User.

**Q: Can trainer see all training sessions?**
A: Mobile App: No - only their own sessions
   Web Dashboard: Yes - super admin can see all

**Q: What if trainer forgets password?**
A: Edit trainer account in super admin and set new password
   Trainer logs back in with new credentials

**Q: Can trainer create accounts?**
A: No - only super admin/admin can create users

**Q: Where do trainers login?**
A: Mobile app only - use Training Mobile App with their email/password

---

## Bulk Import (Advanced)

If you need to create many trainers at once:

### Via Database (for developers)
```sql
INSERT INTO users (username, full_name, email, password, phone, role, division_id, is_active)
VALUES 
('trainer_1', 'Trainer One', 'trainer1@company.com', SHA2('pass123', 256), '+6281234567', 'trainer', 1, 1),
('trainer_2', 'Trainer Two', 'trainer2@company.com', SHA2('pass123', 256), '+6281234568', 'trainer', 2, 1),
('trainer_3', 'Trainer Three', 'trainer3@company.com', SHA2('pass123', 256), '+6281234569', 'trainer', 3, 1);
```

### Via Web UI (recommended)
Use the Add User form multiple times - safer and auditable

---

## Trainer Role Features

### What Trainers Can Do
- ✅ View own training sessions
- ✅ Create new training sessions
- ✅ Conduct training with checklist
- ✅ Save training notes and ratings
- ✅ Mark training as completed
- ✅ View personal statistics

### What Trainers CANNOT Do
- ❌ Edit other trainer's sessions
- ❌ Access QC audit module
- ❌ Manage user accounts
- ❌ Change system settings
- ❌ View financial data

---

## Useful Database Queries

### List All Trainers
```sql
SELECT id, full_name, email, phone, division_id, created_at
FROM users 
WHERE role = 'trainer' 
ORDER BY full_name;
```

### Count Sessions by Trainer
```sql
SELECT 
    u.full_name,
    COUNT(ts.id) as total_sessions,
    SUM(ts.status = 'completed') as completed
FROM users u
LEFT JOIN training_sessions ts ON u.id = ts.trainer_id
WHERE u.role = 'trainer'
GROUP BY u.id, u.full_name;
```

### Deactivate All Trainers (if needed)
```sql
UPDATE users SET is_active = 0 WHERE role = 'trainer';
```

---

## Support & Troubleshooting

### "Trainer role not showing in dropdown"
- ✅ Ensure browser cache is cleared (Ctrl+F5)
- ✅ Check users.js file has trainer option
- ✅ Refresh page

### "Cannot login with trainer account"
- ✅ Verify email/password correct
- ✅ Check user is_active = 1
- ✅ Verify role = 'trainer'
- ✅ Check app version is latest

### "Trainer can see all sessions"
- ✅ Check backend filtering by trainer_id
- ✅ Verify session-list.php WHERE clause

---

*Quick Reference v1.0*  
*Training Module - Trainer Division Setup*  
*Last Updated: November 18, 2025*
