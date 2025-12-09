# TnD System - Backend API

Quality Control and Training Management System - Backend REST API

## 📁 Project Structure

```
backend-web/
├── api/                          # API endpoints
│   ├── login.php                # User authentication
│   ├── outlets-list.php         # Get outlets
│   ├── visit-save.php           # Create/update visits
│   ├── checklist-*.php          # Checklist endpoints
│   ├── visit-photo-upload.php   # Photo uploads
│   └── ...
├── classes/                      # PHP classes
│   └── Database.php             # Database connection class
├── config/                       # Configuration files
│   ├── Env.php                  # Environment loader
│   ├── database.php             # Database config
│   └── cors.php                 # CORS configuration
├── database/                     # Database scripts
│   ├── schema.sql               # Database structure
│   ├── create_db_user.sql       # DB user setup
│   ├── backup_database.php      # Backup script
│   └── restore_database.php     # Restore script
├── utils/                        # Utility classes
│   ├── Auth.php                 # JWT authentication
│   ├── RateLimiter.php          # Rate limiting
│   └── cors_headers.php         # CORS headers
├── uploads/                      # Uploaded files (gitignored)
│   ├── visit_photos/
│   ├── profile_photos/
│   └── training/photos/
├── logs/                         # Application logs (gitignored)
│   ├── error.log
│   └── ratelimit/
├── .env                          # Environment variables (gitignored)
├── .env.example                 # Environment template
├── .htaccess                    # Apache security config
├── .gitignore                   # Git ignore rules
├── DEPLOYMENT.md                # Deployment guide
├── PRODUCTION_CHECKLIST.md      # Pre-deployment checklist
└── README.md                    # This file
```

## 🚀 Quick Start

### Development Setup

1. **Clone repository**
   ```bash
   git clone https://github.com/yourusername/tnd-system.git
   cd tnd-system/backend-web
   ```

2. **Configure environment**
   ```bash
   # Copy environment template
   cp .env.example .env
   
   # Edit .env with your local database credentials
   ```

3. **Create database**
   ```sql
   CREATE DATABASE tnd_system CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
   ```

4. **Import database**
   ```bash
   mysql -u root -p tnd_system < database/schema.sql
   ```

5. **Create upload directories**
   ```bash
   php create-upload-dirs.php
   ```

6. **Test connection**
   ```bash
   php test-db-connection.php
   ```

7. **Access API**
   ```
   http://localhost/tnd_system/backend-web/api/
   ```

## 🔧 Configuration

### Environment Variables (.env)

```env
# Application Environment (development/production)
APP_ENV=development

# Database Configuration
DB_HOST=127.0.0.1
DB_NAME=tnd_system
DB_USERNAME=root
DB_PASSWORD=

# JWT Secret Key (use strong random string in production)
JWT_SECRET_KEY=your_secret_key_here

# CORS Allowed Origins (comma-separated)
CORS_ALLOWED_ORIGINS=http://localhost,http://127.0.0.1
```

### Production Configuration

For production deployment, see **[DEPLOYMENT.md](DEPLOYMENT.md)** for complete guide.

## 📚 API Documentation

### Authentication

**POST** `/api/login.php`
- Login and get JWT token
- Rate limited: 5 attempts per minute

```json
Request:
{
  "email": "user@example.com",
  "password": "password123"
}

Response:
{
  "token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "user_id": 1,
  "name": "John Doe"
}
```

### Outlets

**GET** `/api/outlets-list.php`
- Get all outlets
- Requires authentication

### Visits

**GET** `/api/visits-list.php`
- Get user's visits
- Requires authentication

**POST** `/api/visit-save.php`
- Create/update visit
- Requires authentication

**GET** `/api/visit-detail.php?visit_id=123`
- Get visit details with responses and findings
- Requires authentication

### Checklist

**GET** `/api/checklist-points-list.php`
- Get all checklist points grouped by category

**POST** `/api/checklist-responses-save.php`
- Save checklist responses for a visit

### Photos

**POST** `/api/visit-photo-upload.php`
- Upload finding photos
- Max size: 5MB
- Allowed: JPG, PNG
- MIME type validation

## 🔒 Security Features

- ✅ JWT authentication
- ✅ Rate limiting (login endpoint)
- ✅ CORS restriction
- ✅ File upload validation (size, type, MIME)
- ✅ SQL injection prevention (PDO prepared statements)
- ✅ XSS protection
- ✅ Security headers (CSP, HSTS, X-Frame-Options)
- ✅ Environment-based error handling
- ✅ Sensitive file protection (.htaccess)

## 🧪 Testing

### Manual Testing

```bash
# Test login
curl -X POST http://localhost/tnd_system/backend-web/api/login.php \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@test.com","password":"admin123"}'

# Test authenticated endpoint
curl http://localhost/tnd_system/backend-web/api/outlets-list.php \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

### Rate Limiting Test

Try logging in 6 times with wrong password - 6th attempt should return HTTP 429.

## 📦 Database Backup & Restore

### Create Backup

```bash
# Manual backup
php database/backup_database.php

# Or using mysqldump directly
mysqldump -u root -p tnd_system > backup.sql
```

### Restore Backup

```bash
# Using restore script
php database/restore_database.php backups/backup_file.sql

# Or using mysql directly
mysql -u root -p tnd_system < backup.sql
```

### Automated Backups (Production)

Add to crontab for daily backups:

```bash
0 2 * * * cd /path/to/backend-web/database && php backup_database.php
```

## 🐛 Troubleshooting

### Database Connection Failed

1. Check `.env` credentials
2. Ensure database exists
3. Verify user has proper privileges
4. Run `php test-db-connection.php`

### CORS Errors

1. Check `CORS_ALLOWED_ORIGINS` in `.env`
2. Ensure domain matches exactly (including protocol)
3. Clear browser cache

### File Upload Failed

1. Check directory permissions (755 for uploads/)
2. Verify PHP `upload_max_filesize` ≥ 5MB
3. Check web server has write access

### Rate Limiting Issues

Clear rate limit data:
```bash
rm -rf logs/ratelimit/*
```

## 📋 Development Checklist

Before deploying to production:

- [ ] All test/debug files removed
- [ ] `.env` configured for production
- [ ] Strong JWT secret generated
- [ ] CORS restricted to production domain
- [ ] Database user with limited privileges
- [ ] SSL certificate installed
- [ ] Error logging configured
- [ ] Backup strategy in place

See **[PRODUCTION_CHECKLIST.md](PRODUCTION_CHECKLIST.md)** for complete list.

## 📄 License

Proprietary - All rights reserved

## 👥 Team

**Developer:** [Your Name]  
**Project Manager:** [PM Name]  
**Company:** [Company Name]

## 📞 Support

For issues or questions:
- Email: support@yourdomain.com
- Documentation: See DEPLOYMENT.md

---

**Version:** 1.0.0 (Phase 1 - QC System)  
**Last Updated:** October 28, 2025
