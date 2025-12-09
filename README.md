# TND System - Web Super Admin

Sistem manajemen audit TND (Visit System) yang dibangun menggunakan PHP Native tanpa framework, dengan Laragon sebagai database client.

## Fitur Utama

- **Manajemen User**: Sistem autentikasi dan otorisasi berbasis role
- **Manajemen Outlet**: Kelola data outlet/toko
- **Checklist Management**: Buat dan kelola kategori serta poin checklist
- **Audit System**: Lakukan audit dengan checklist yang sudah dibuat
- **Reporting**: Laporan dan analisis hasil audit
- **Web Admin Panel**: Interface web untuk super admin

## Struktur Folder

```
tnd_system/
├── backend-web/
│   ├── api/                    # REST API endpoints
│   │   ├── index.php          # Main API router
│   │   ├── Router.php         # API router class
│   │   ├── AuthController.php # Authentication endpoints
│   │   └── UserController.php # User management endpoints
│   ├── classes/               # Model classes
│   │   ├── Database.php       # Database connection
│   │   ├── BaseModel.php      # Base model class
│   │   ├── User.php           # User model
│   │   ├── Outlet.php         # Outlet model
│   │   ├── Audit.php          # Audit model
│   │   ├── AuditResult.php    # Audit result model
│   │   ├── ChecklistCategory.php
│   │   └── ChecklistPoint.php
│   ├── config/                # Konfigurasi
│   │   └── database.php       # Database config
│   ├── utils/                 # Utility classes
│   │   ├── Response.php       # API response helper
│   │   ├── Request.php        # Request helper
│   │   └── Auth.php           # Authentication helper
│   └── database_schema.sql    # Database schema
├── frontend-web/              # Web admin interface
│   ├── index.html            # Main admin page
│   ├── login.html            # Login page
│   └── assets/
│       ├── css/
│       │   └── admin.css     # Admin styles
│       └── js/
│           ├── api.js        # API helper functions
│           ├── auth.js       # Authentication functions
│           ├── login.js      # Login functionality
│           ├── dashboard.js  # Dashboard functions
│           ├── users.js      # User management
│           └── admin.js      # Main admin functions
└── tnd_mobile/               # Flutter mobile app (future)
```

## Setup dan Instalasi

### Prasyarat
- **Laragon** (Latest version) dengan:
  - PHP 7.4+ atau PHP 8.x
  - MySQL 5.7+ atau MySQL 8.0
  - Apache Web Server
- Web browser modern (Chrome, Firefox, Edge, Safari)

### Langkah Instalasi untuk Laragon

1. **Pastikan Laragon berjalan**
   - Start Laragon
   - Pastikan Apache dan MySQL services running (hijau)

2. **Copy project ke folder Laragon**
   ```
   C:\laragon\www\tnd_system\
   ```

3. **Setup Database Otomatis**
   - Jalankan file: `setup-database.bat`
   - Script akan membuka phpMyAdmin dan memberikan instruksi
   - Import file `backend-web/database_schema.sql`
   - Database `tnd_system` akan dibuat dengan data sample

4. **Verifikasi Konfigurasi**
   - File `backend-web/config/database.php` sudah dikonfigurasi untuk Laragon
   - Host: 127.0.0.1, Port: 3306, User: root, Password: (kosong)

5. **Akses aplikasi**
   - Web Admin: `http://localhost/tnd_system/tnd_system/frontend-web/login.html`
   - API: `http://localhost/tnd_system/tnd_system/backend-web/api/`
   - phpMyAdmin: `http://localhost/phpmyadmin` (via Laragon)

### Login Default
- **Email**: admin@tnd-system.com
- **Password**: password

## API Endpoints

### Authentication
- `POST /api/auth/login` - User login
- `POST /api/auth/logout` - User logout
- `GET /api/auth/me` - Get current user info
- `POST /api/auth/change-password` - Change password

### Users
- `GET /api/users` - Get all users
- `GET /api/users/{id}` - Get user by ID
- `POST /api/users` - Create new user
- `PUT /api/users/{id}` - Update user
- `DELETE /api/users/{id}` - Delete user
- `GET /api/users/role/{role}` - Get users by role

### Health Check
- `GET /api/health` - API health check

## Database Schema

### Tables
1. **users** - Sistem user dengan role-based access
2. **outlets** - Data outlet/toko
3. **checklist_categories** - Kategori checklist
4. **checklist_points** - Poin-poin checklist
5. **audits** - Data audit
6. **audit_results** - Hasil detail audit per poin

### User Roles
- **super_admin**: Akses penuh ke sistem
- **admin**: Manajemen user dan outlet
- **supervisor**: Monitoring audit
- **auditor**: Melakukan audit

## Fitur Web Admin

### Dashboard
- Statistik sistem
- Recent activities
- Quick actions

### User Management
- Tambah/edit/hapus user
- Manajemen role
- Status user (active/inactive)

### Outlet Management
- Data outlet lengkap
- Lokasi dan kontak
- Status outlet

### Checklist Setup
- Kategori checklist
- Poin-poin checklist
- Scoring system

### Audit System
- Schedule audit
- Conduct audit
- Review results

### Reports
- Performance charts
- Score distribution
- Export functionality

## Security Features

- Password hashing dengan bcrypt
- Session management
- Role-based access control
- CSRF protection (headers)
- Input validation
- SQL injection prevention (PDO)

## Development Notes

### API Response Format
```json
{
  "success": true,
  "message": "Success message",
  "data": {...}
}
```

### Error Response Format
```json
{
  "success": false,
  "message": "Error message",
  "errors": {...}
}
```

### Adding New Features
1. Buat model class di `backend-web/classes/`
2. Tambah API controller di `backend-web/api/`
3. Update router di `backend-web/api/index.php`
4. Buat frontend JavaScript di `frontend-web/assets/js/`

## Browser Support
- Chrome 80+
- Firefox 75+
- Safari 13+
- Edge 80+

## License
Proprietary - TND System

## Contact
Developer: TND System Team# TnD-System
