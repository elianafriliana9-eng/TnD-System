# TND System - Laragon Configuration Guide

## Laragon Setup untuk TND System

### 1. Persiapan Laragon
Pastikan Laragon sudah terinstall dan dikonfigurasi dengan benar:

#### Versi yang Direkomendasikan:
- **Laragon Full** (includes PHP, Apache, MySQL, phpMyAdmin)
- **PHP**: 7.4, 8.0, 8.1, atau 8.2
- **MySQL**: 5.7 atau 8.0
- **Apache**: 2.4

#### Cara Start Laragon:
1. Buka Laragon
2. Klik "Start All" 
3. Pastikan status Apache dan MySQL: **Running** (hijau)

### 2. Struktur Folder di Laragon
```
C:\laragon\www\
└── tnd_system\
    └── tnd_system\          # Project folder
        ├── backend-web\     # PHP Backend
        ├── frontend-web\    # Web Admin
        ├── tnd_mobile\      # Flutter (future)
        └── setup-database.bat
```

### 3. Database Configuration
File: `backend-web\config\database.php`
```php
// Konfigurasi untuk Laragon
define('DB_HOST', '127.0.0.1');    // Laragon MySQL host
define('DB_NAME', 'tnd_system');   // Database name
define('DB_USERNAME', 'root');     // Default Laragon user
define('DB_PASSWORD', '');         // Default Laragon: empty
define('DB_PORT', '3306');         // Default MySQL port
```

### 4. Virtual Host (Opsional)
Untuk URL yang lebih bersih, buat virtual host di Laragon:

1. **Klik kanan Laragon > Apache > sites-enabled > Add...**
2. **Nama**: `tnd-system.test`
3. **Path**: `C:\laragon\www\tnd_system\tnd_system\frontend-web`

Akses dengan: `http://tnd-system.test`

### 5. SSL Certificate (Opsional)
Untuk HTTPS development:
1. **Klik kanan Laragon > Apache > SSL > tnd-system.test**
2. Akses dengan: `https://tnd-system.test`

### 6. Pretty URLs dengan htaccess
File `.htaccess` sudah dibuat untuk:
- API routing: `backend-web\api\.htaccess`
- CORS headers
- Security headers

### 7. Troubleshooting Laragon

#### Masalah Umum:

**1. Port 80/443 sudah digunakan:**
```
- Stop IIS (World Wide Web Publishing Service)
- Stop Skype (gunakan port alternatif)
- Restart Laragon
```

**2. MySQL tidak start:**
```
- Check port 3306 tidak digunakan aplikasi lain
- Restart Laragon as Administrator
- Check Laragon logs
```

**3. Database connection error:**
```php
// Test koneksi manual
$host = '127.0.0.1';
$port = '3306';
$dbname = 'tnd_system';
$username = 'root';
$password = '';

try {
    $pdo = new PDO("mysql:host=$host;port=$port;dbname=$dbname", $username, $password);
    echo "Connection successful!";
} catch (PDOException $e) {
    echo "Connection failed: " . $e->getMessage();
}
```

**4. htaccess tidak bekerja:**
- Pastikan mod_rewrite enabled di Apache
- Check Apache error logs di Laragon

### 8. Development Workflow

#### Start Development:
1. Buka Laragon
2. Start All services
3. Akses: `http://localhost/tnd_system/tnd_system/frontend-web/login.html`

#### Database Management:
- phpMyAdmin: `http://localhost/phpmyadmin`
- Kredensial: root / (kosong)

#### API Testing:
- Health check: `http://localhost/tnd_system/tnd_system/backend-web/api/health`
- Run: `test-api.ps1` untuk automated testing

### 9. File Permissions
Laragon biasanya tidak ada masalah permissions di Windows, tapi pastikan:
- Folder project: Read/Write access
- PHP dapat write ke `storage` folders (jika ada)

### 10. Environment Specific Settings

#### Development (Laragon):
```php
// Error reporting ON
error_reporting(E_ALL);
ini_set('display_errors', 1);

// Debug mode
define('DEBUG_MODE', true);
```

#### Production:
```php
// Error reporting OFF
error_reporting(0);
ini_set('display_errors', 0);

// Debug mode OFF
define('DEBUG_MODE', false);
```

### 11. Backup & Restore

#### Backup Database:
```bash
# Via Laragon terminal
mysqldump -u root tnd_system > tnd_system_backup.sql
```

#### Restore Database:
```bash
# Via Laragon terminal  
mysql -u root tnd_system < tnd_system_backup.sql
```

### 12. Performance Tips

#### Untuk Development di Laragon:
- Enable OPcache untuk PHP
- Increase PHP memory_limit jika diperlukan
- Use MySQL query cache
- Enable Apache compression

### Support
Jika ada masalah dengan setup Laragon, check:
1. Laragon documentation
2. Laragon GitHub issues
3. TND System logs di `storage/logs/` (jika ada)

---
**Note**: Configuration ini khusus untuk development dengan Laragon. Untuk production, gunakan konfigurasi server yang sesuai.