# 🚀 TND System - Training & Development Management System

> **Modern Training & Development Management Platform** - Sistem manajemen pelatihan dan pengembangan karyawan yang komprehensif dengan interface modern dan mobile app support.

![Version](https://img.shields.io/badge/version-2.0.0-blue.svg)
![PHP](https://img.shields.io/badge/PHP-7.4%2B-777BB4.svg)
![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B.svg)
![License](https://img.shields.io/badge/license-Proprietary-red.svg)

## 📋 Overview

TND System adalah platform komprehensif untuk manajemen Training & Development yang terdiri dari:
- 🌐 **Web Admin Panel** - Interface modern untuk super admin dengan dashboard analytics
- 📱 **Mobile App (Flutter)** - Aplikasi mobile untuk trainer dan crew melakukan daily training
- 🔌 **REST API Backend** - Backend API dengan PHP native untuk komunikasi antar platform
- 📊 **PDF Generation** - Generate training reports dengan digital signature

## ✨ Fitur Utama

### Web Admin Panel
- **Dashboard Analytics** - Real-time statistics dengan modern card design
- **User Management** - Kelola user dengan role-based access control
- **Outlet Management** - Manajemen data outlet/toko
- **Checklist Management** - Setup kategori dan item checklist dengan drag & drop
- **Training Reports** - View dan export laporan training
- **Session Timeout** - Auto logout setelah 30 menit inactivity
- **Modern UI/UX** - Clean design dengan gradient colors dan smooth animations

### Mobile App (Flutter)
- **Daily Training** - Catat training harian per crew dengan rating system (BS/B/C/K)
- **Digital Signature** - Tanda tangan digital untuk trainer dan crew leader
- **Photo Upload** - Upload foto training dengan compression
- **PDF Generation** - Generate training report dalam format PDF
- **Offline Support** - Bekerja offline dan sync saat online
- **Training History** - Riwayat training lengkap dengan filter

### Backend API
- **RESTful API** - Clean API architecture
- **JWT Authentication** - Secure authentication dengan token
- **Rate Limiting** - Prevent brute force attacks (5 req/min)
- **File Upload** - Support untuk foto dan dokumen
- **Database Migration** - Easy database setup dan updates

## 📁 Struktur Project

```
tnd_system/
├── 📂 backend-web/                 # PHP Backend API
│   ├── 📂 api/                     # REST API Endpoints
│   │   ├── login.php               # Authentication
│   │   ├── training/               # Training endpoints
│   │   ├── users.php               # User management
│   │   ├── outlets.php             # Outlet management
│   │   ├── checklist-*.php         # Checklist management
│   │   └── dashboard-stats.php     # Dashboard statistics
│   ├── 📂 classes/                 # Model Classes
│   │   ├── Database.php            # Database connection
│   │   ├── User.php                # User model
│   │   ├── Outlet.php              # Outlet model
│   │   └── Training.php            # Training model
│   ├── 📂 config/                  # Configuration
│   │   └── database.php            # Database config
│   ├── 📂 utils/                   # Utility Classes
│   │   ├── Response.php            # API response helper
│   │   ├── Security.php            # Security utilities
│   │   └── RateLimiter.php         # Rate limiting
│   └── 📂 uploads/                 # Upload directory
│       └── training_photos/        # Training photos
│
├── 📂 frontend-web/                # Web Admin Interface
│   ├── index.html                  # Main dashboard
│   ├── login.html                  # Login page (modern design)
│   └── 📂 assets/
│       ├── 📂 css/
│       │   └── admin.css           # Modern admin styles
│       ├── 📂 js/
│       │   ├── api.js              # API configuration
│       │   ├── auth.js             # Session & auth management
│       │   ├── dashboard.js        # Dashboard functions
│       │   ├── users.js            # User CRUD
│       │   ├── admin.js            # Main admin functions
│       │   └── outlets.js          # Outlet management
│       └── 📂 img/
│           └── logo T&D 2-02.png   # Company logo
│
└── 📂 tnd_mobile_flutter/          # Flutter Mobile App
    ├── 📂 lib/
    │   ├── 📂 models/              # Data models
    │   ├── 📂 services/            # API services
    │   │   ├── api_service.dart
    │   │   ├── training_service.dart
    │   │   └── training_pdf_service.dart
    │   ├── 📂 screens/             # App screens
    │   │   ├── 📂 training/        # Training module
    │   │   │   ├── daily_training_form.dart
    │   │   │   ├── training_history.dart
    │   │   │   └── digital_signature_screen.dart
    │   │   └── home_screen.dart
    │   └── main.dart
    ├── pubspec.yaml                # Flutter dependencies
    └── 📂 android/                 # Android config
```

## 🚀 Setup dan Instalasi

### 🔧 Prasyarat

**Local Development (Laragon):**
- Laragon Full (Latest version)
  - PHP 7.4+ atau PHP 8.x
  - MySQL 5.7+ atau MySQL 8.0
  - Apache Web Server
- Web browser modern (Chrome, Firefox, Edge)

**Production Server:**
- PHP 7.4+ dengan extensions: PDO, GD, JSON
- MySQL 5.7+ atau MySQL 8.0
- Apache/Nginx Web Server
- SSL Certificate (HTTPS)
- Min 512MB RAM

### 📦 Instalasi Local (Laragon)

#### 1️⃣ Setup Project
```bash
# Clone repository
git clone https://github.com/elianafriliana9-eng/TnD-System.git

# Copy ke folder Laragon
C:\laragon\www\tnd_system\
```

#### 2️⃣ Setup Database
```bash
# Jalankan Laragon
# Start All Services (Apache + MySQL)

# Import database
1. Buka http://localhost/phpmyadmin
2. Create database: tnd_system
3. Import file: backend-web/database_schema.sql
```

#### 3️⃣ Konfigurasi
File `backend-web/config/database.php` sudah dikonfigurasi untuk Laragon:
```php
$host = '127.0.0.1';
$port = '3306';
$dbname = 'tnd_system';
$username = 'root';
$password = '';  // Kosong untuk Laragon
```

#### 4️⃣ Akses Aplikasi
- 🌐 Web Admin: `http://localhost/tnd_system/frontend-web/login.html`
- 🔌 API Endpoint: `http://localhost/tnd_system/backend-web/api/`
- 📊 phpMyAdmin: `http://localhost/phpmyadmin`

### 🌍 Instalasi Production Server

#### 1️⃣ Upload Files
```bash
# Upload via FTP/SFTP ke hosting
/public_html/
├── backend-web/
└── frontend-web/
```

#### 2️⃣ Update API Configuration
Edit `frontend-web/assets/js/api.js`:
```javascript
const API_BASE_URL = 'https://yourdomain.com/backend-web/api';
```

#### 3️⃣ Setup Database
```sql
CREATE DATABASE tnd_system;
-- Import database_schema.sql via phpMyAdmin
```

#### 4️⃣ Update Database Config
Edit `backend-web/config/database.php`:
```php
$host = 'localhost';
$dbname = 'your_db_name';
$username = 'your_db_user';
$password = 'your_db_password';
```

#### 5️⃣ Set Permissions
```bash
chmod 755 backend-web/uploads/
chmod 755 backend-web/uploads/training_photos/
```

### 🔐 Login Default

**Super Admin:**
- Email: `admin@tnd-system.com`
- Password: `password`

**Test User:**
- Email: `user@tnd-system.com`
- Password: `password`

> ⚠️ **Penting**: Ganti password default setelah login pertama!

## 🔌 API Documentation

### Base URL
- **Local**: `http://localhost/tnd_system/backend-web/api`
- **Production**: `https://tndsystem.online/backend-web/api`

### Authentication
| Method | Endpoint | Description | Rate Limit |
|--------|----------|-------------|------------|
| POST | `/login.php` | User login | 5 req/min |
| POST | `/logout.php` | User logout | - |
| GET | `/me.php` | Get current user | - |

### User Management
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/users.php` | Get all users |
| GET | `/users.php?id={id}` | Get user by ID |
| POST | `/users-create.php` | Create new user |
| PUT | `/user-update.php?id={id}` | Update user |
| DELETE | `/user-delete.php?id={id}` | Delete user |
| POST | `/user-change-password.php` | Change user password (5 req/min) |

### Training Management
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/training/list.php` | Get training sessions |
| GET | `/training/detail.php?id={id}` | Get training detail |
| POST | `/training/create.php` | Create training session |
| POST | `/training/upload-photo.php` | Upload training photo |
| GET | `/training/stats.php` | Get training statistics |

### Outlet Management
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/outlets.php` | Get all outlets |
| GET | `/outlets.php?id={id}` | Get outlet by ID |
| POST | `/outlets.php` | Create outlet |
| PUT | `/outlets.php?id={id}` | Update outlet |
| DELETE | `/outlets.php?id={id}` | Delete outlet |

### Checklist Management
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/divisions.php` | Get divisions with categories |
| POST | `/checklist-categories.php` | Create category |
| PUT | `/checklist-categories.php?id={id}` | Update category |
| DELETE | `/checklist-categories.php?id={id}` | Delete category |
| POST | `/checklist-points.php` | Create checklist point |
| PUT | `/checklist-points.php?id={id}` | Update point |
| DELETE | `/checklist-points.php?id={id}` | Delete point |

### Response Format
**Success:**
```json
{
  "success": true,
  "message": "Operation successful",
  "data": {...}
}
```

**Error:**
```json
{
  "success": false,
  "message": "Error description",
  "errors": {...}
}
```

## 🗄️ Database Schema

### Core Tables

| Table | Description | Key Fields |
|-------|-------------|------------|
| `users` | User accounts & authentication | id, email, name, role, password_hash |
| `outlets` | Store/outlet data | id, name, address, latitude, longitude |
| `divisions` | Training divisions | id, name, description |
| `checklist_categories` | Checklist categories | id, division_id, name, description |
| `checklist_points` | Checklist items | id, category_id, question |
| `training_sessions` | Training records | id, trainer_id, outlet_id, date, status |
| `training_participants` | Training crew data | id, session_id, crew_name, rating |
| `training_photos` | Training photos | id, session_id, photo_path |

### User Roles & Permissions

| Role | Web Access | Mobile Access | Permissions |
|------|------------|---------------|-------------|
| `super_admin` | ✅ Full | ✅ Full | All operations |
| `admin` | ✅ Limited | ✅ Full | User & outlet management |
| `supervisor` | ✅ View | ✅ Full | View reports, conduct training |
| `trainer` | ❌ No | ✅ Full | Conduct training only |
| `crew` | ❌ No | ✅ Limited | View own training |

### Training Rating System
- **BS** (Belum Selesai) - Not completed
- **B** (Baik) - Good
- **C** (Cukup) - Fair  
- **K** (Kurang) - Poor

## 🎨 Features Breakdown

### 🌐 Web Admin Panel

#### Modern Dashboard
- 📊 Real-time statistics cards with gradient design
- 📈 Daily visits trend chart (Last 7 days)
- 🕐 Recent activities timeline
- ⚡ Quick action cards for common tasks
- 🟢 Session indicator with timeout warning

#### User Management
- ➕ Create, edit, delete users
- 🎭 Role-based access control
- 📧 Email validation
- 🔒 Password management
- 📊 User activity tracking

#### Outlet Management
- 🏪 Complete outlet data
- 📍 Location with coordinates
- 📞 Contact information
- ✅ Active/inactive status

#### Checklist Management
- 📋 Division-based categories
- 🎨 Color-coded category cards
- ➕ Drag & drop item management
- 📝 Rich text descriptions
- 🔢 Numbering system

#### Modern UI Features
- 🎨 Gradient color scheme
- ✨ Smooth animations & transitions
- 📱 Fully responsive design
- 🌙 Clean minimalist interface
- 🔄 Loading states & skeletons

### 📱 Mobile App (Flutter)

#### Daily Training Module
- 📝 Per-crew training form
- ⭐ 4-level rating system (BS/B/C/K)
- 📸 Photo upload with compression
- ✍️ Digital signature capture
- 📄 PDF generation with logo

#### Training Management
- 📅 Training history with filters
- 🔍 Search functionality
- 📊 Training statistics
- 🔄 Sync status indicator
- 📥 Offline mode support

#### PDF Features
- 📄 Professional training report
- 🏢 Company logo & branding
- ✍️ Digital signatures (trainer & crew leader)
- 📸 Embedded training photos
- 📋 Complete crew listing with ratings

## 🔒 Security Features

### Authentication & Authorization
- 🔐 Password hashing (bcrypt)
- 🎫 JWT token-based auth
- ⏱️ Session timeout (30 minutes)
- 🚫 Rate limiting (5 req/min on sensitive endpoints)
- 👥 Role-based access control

### Data Protection
- 🛡️ SQL injection prevention (PDO prepared statements)
- ✅ Input validation & sanitization
- 🔒 HTTPS enforcement (production)
- 📝 Activity logging
- 🗑️ Secure file deletion

### Session Management
- ⏰ Auto logout after 30 min inactivity
- 🎯 Activity tracking (mouse, keyboard, scroll)
- ⚠️ Warning 5 minutes before timeout
- 🟢 Real-time session indicator
- 🔄 Automatic session refresh on activity

## 🛠️ Tech Stack

### Backend
- **PHP 7.4+** - Core backend language
- **MySQL 8.0** - Database
- **PDO** - Database abstraction
- **JWT** - Authentication tokens
- **GD Library** - Image processing

### Frontend Web
- **HTML5** - Structure
- **CSS3** - Styling with gradients & animations
- **JavaScript (ES6+)** - Interactivity
- **Bootstrap 5.3** - UI framework
- **SweetAlert2** - Modern alerts
- **Chart.js** - Data visualization
- **Font Awesome 6** - Icons

### Mobile App
- **Flutter 3.x** - Mobile framework
- **Dart** - Programming language
- **http** - API communication
- **pdf** - PDF generation
- **image_picker** - Photo capture
- **signature** - Digital signature
- **path_provider** - File storage

## 📱 Browser & Device Support

### Web Admin
- ✅ Chrome 80+
- ✅ Firefox 75+
- ✅ Safari 13+
- ✅ Edge 80+
- ✅ Responsive design (mobile, tablet, desktop)

### Mobile App
- ✅ Android 6.0+ (API 23+)
- ✅ iOS 11+
- ✅ Tablet support
- ✅ Both portrait & landscape

## 🎯 Roadmap & Future Features

### Phase 1 ✅ (Completed)
- [x] Web admin panel
- [x] User & outlet management
- [x] Checklist system
- [x] Basic reporting

### Phase 2 ✅ (Completed)
- [x] Mobile app (Flutter)
- [x] Daily training module
- [x] Digital signature
- [x] PDF generation
- [x] Photo upload

### Phase 3 🚧 (Current)
- [x] Modern UI redesign
- [x] Session timeout
- [x] Rate limiting
- [ ] Training dashboard analytics
- [ ] Advanced filtering

### Phase 4 📋 (Planned)
- [ ] Real-time notifications
- [ ] Email notifications
- [ ] Training scheduler
- [ ] Multi-language support
- [ ] Dark mode
- [ ] Export to Excel
- [ ] Backup & restore
- [ ] API documentation (Swagger)

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Development Guidelines
- Follow PSR-12 coding standards for PHP
- Use meaningful variable and function names
- Comment complex logic
- Test before committing
- Update documentation

## 📝 License

This project is proprietary software owned by **TND System**.

**Copyright © 2024-2025 TND System. All rights reserved.**

Unauthorized copying, modification, distribution, or use of this software, via any medium, is strictly prohibited without explicit permission from the copyright holders.

## 📞 Contact & Support

- **GitHub**: [elianafriliana9-eng/TnD-System](https://github.com/elianafriliana9-eng/TnD-System)
- **Production**: [https://tndsystem.online](https://tndsystem.online)
- **Email**: support@tndsystem.online

---

**Built with ❤️ by TND System Team**

*Last Updated: December 9, 2025*
