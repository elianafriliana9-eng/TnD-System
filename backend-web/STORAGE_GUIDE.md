# 📦 TND System - Storage Management

## 🎯 Overview

Sistem storage TND menggunakan **Storage Abstraction Layer** yang memungkinkan switch antara Local Storage (development) dan Cloud Storage (production) tanpa perlu ubah banyak code.

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────┐
│         Storage Factory                  │
│  (Auto-select based on config)          │
└─────────────────┬───────────────────────┘
                  │
        ┌─────────┴─────────┐
        │                   │
┌───────▼─────────┐  ┌──────▼──────────┐
│ Local Storage   │  │ Cloud Storage   │
│ (Development)   │  │ (Production)    │
│                 │  │                 │
│ • uploads/      │  │ • Cloudinary    │
│ • Backend dir   │  │ • Global CDN    │
│ • Simple        │  │ • Scalable      │
└─────────────────┘  └─────────────────┘
```

---

## 📁 File Structure

```
backend-web/
├── config/
│   └── storage.php          ← Storage configuration
├── utils/
│   ├── StorageInterface.php ← Interface definition
│   ├── Storage.php          ← Factory class
│   ├── LocalStorage.php     ← Local implementation
│   └── CloudinaryStorage.php← Cloud implementation
└── uploads/                 ← Local upload directory
    ├── visit_photos/
    ├── profile_photos/
    └── outlet_photos/
```

---

## 🚀 Usage

### Basic Upload Example

```php
<?php
require_once __DIR__ . '/utils/Storage.php';

// Upload file
$result = Storage::getInstance()->upload($_FILES['photo'], 'visit_photos');

if ($result['success']) {
    $photoUrl = $result['url'];      // Full public URL
    $photoPath = $result['path'];    // Relative path
    
    // Save to database
    $stmt = $db->prepare("INSERT INTO visit_photos (photo_path) VALUES (?)");
    $stmt->execute([$photoPath]);
    
    echo "Photo uploaded: " . $photoUrl;
} else {
    echo "Upload failed: " . $result['message'];
}
```

### Delete File

```php
// Delete by path
$success = Storage::getInstance()->delete('visit_photos/img_123.jpg');

// Delete by URL
$success = Storage::getInstance()->delete($photoUrl);
```

### Get URL

```php
// Get full URL from path
$url = Storage::getInstance()->getUrl('visit_photos/img_123.jpg');
```

### Check if File Exists

```php
$exists = Storage::getInstance()->exists('visit_photos/img_123.jpg');
```

---

## ⚙️ Configuration

### Current: Local Storage (Development)

**File:** `config/storage.php`

```php
define('STORAGE_TYPE', 'local'); // Using local storage
```

### Future: Cloudinary (Production)

**Step 1:** Update config

```php
define('STORAGE_TYPE', 'cloudinary'); // Switch to cloud
```

**Step 2:** Add Cloudinary credentials

```php
putenv('CLOUDINARY_CLOUD_NAME=your-cloud-name');
putenv('CLOUDINARY_API_KEY=your-api-key');
putenv('CLOUDINARY_API_SECRET=your-api-secret');
```

**Step 3:** Install Cloudinary SDK

```bash
composer require cloudinary/cloudinary_php
```

**Step 4:** Uncomment Cloudinary code in `CloudinaryStorage.php`

Done! ✅ No other code changes needed.

---

## 🔄 Migration Guide (Local → Cloudinary)

### Prerequisites

1. Cloudinary account (free tier available)
2. Composer installed on server

### Migration Steps

#### 1. Get Cloudinary Credentials

- Sign up: https://cloudinary.com/users/register/free
- Get credentials from Dashboard
- Note: Cloud Name, API Key, API Secret

#### 2. Install Cloudinary SDK

```bash
cd backend-web
composer require cloudinary/cloudinary_php
```

#### 3. Update Configuration

Edit `config/storage.php`:

```php
// Change this
define('STORAGE_TYPE', 'cloudinary');

// Add credentials
putenv('CLOUDINARY_CLOUD_NAME=your-cloud-name');
putenv('CLOUDINARY_API_KEY=your-api-key');
putenv('CLOUDINARY_API_SECRET=your-api-secret');
```

#### 4. Uncomment Cloudinary Code

Edit `utils/CloudinaryStorage.php` - uncomment all SDK code (marked with /* ... */)

#### 5. Migrate Existing Photos (Optional)

Run migration script:

```bash
php scripts/migrate-to-cloudinary.php
```

(Script to be created when needed)

#### 6. Test

Upload test photo and verify URL starts with `https://res.cloudinary.com/`

---

## 🧪 Testing

### Test Local Storage

```php
// Test upload
$testFile = [
    'tmp_name' => '/path/to/test.jpg',
    'name' => 'test.jpg',
    'type' => 'image/jpeg',
    'size' => 50000
];

$result = Storage::getInstance()->upload($testFile, 'test');
var_dump($result);

// Expected output:
// array(
//   'success' => true,
//   'url' => 'http://localhost/.../uploads/test/img_123.jpg',
//   'path' => 'test/img_123.jpg'
// )
```

---

## 📊 Storage Comparison

| Feature | Local Storage | Cloudinary |
|---------|--------------|------------|
| **Cost** | Free (server disk) | Free tier: 25GB |
| **Setup** | ✅ Ready | Need account |
| **CDN** | ❌ No | ✅ Yes (global) |
| **Bandwidth** | Server limit | Included |
| **Backup** | Manual | Automatic |
| **Optimization** | Manual | Automatic |
| **Migration** | - | Easy switch |

---

## 🔐 Security

### File Validation

- **Type check**: Only JPG, PNG, GIF allowed
- **Size limit**: Max 5MB per file
- **Filename**: Auto-generated unique names
- **Path traversal**: Prevented by design

### Cloudinary Benefits

- **DDoS protection**: Built-in
- **Hotlink protection**: Available
- **Signed URLs**: For private content
- **Transformation**: On-the-fly resize/crop

---

## 🚨 Troubleshooting

### Upload Fails (Local)

**Problem:** Permission denied

**Solution:**
```bash
chmod 755 backend-web/uploads/
chmod 755 backend-web/uploads/visit_photos/
```

### Cloudinary Not Working

**Problem:** "Cloudinary SDK not installed"

**Solution:**
```bash
composer require cloudinary/cloudinary_php
```

**Problem:** "Cloudinary not configured"

**Solution:** Check credentials in `config/storage.php`

---

## 📝 API Examples

### Update Profile Photo API

```php
<?php
require_once __DIR__ . '/../utils/Storage.php';

// Upload new photo
$result = Storage::getInstance()->upload($_FILES['photo'], 'profile_photos');

if ($result['success']) {
    // Delete old photo if exists
    if (!empty($oldPhotoPath)) {
        Storage::getInstance()->delete($oldPhotoPath);
    }
    
    // Update database
    $stmt = $db->prepare("UPDATE users SET photo_path = ? WHERE id = ?");
    $stmt->execute([$result['path'], $userId]);
    
    Response::success(['photo_url' => $result['url']]);
} else {
    Response::error($result['message'], 400);
}
```

---

## 🎯 Best Practices

### 1. Always Use Storage Class

❌ **Bad:**
```php
move_uploaded_file($file['tmp_name'], 'uploads/photo.jpg');
```

✅ **Good:**
```php
$result = Storage::getInstance()->upload($file, 'visit_photos');
```

### 2. Store Relative Paths in Database

❌ **Bad:**
```sql
photo_path: http://localhost/uploads/photo.jpg
```

✅ **Good:**
```sql
photo_path: visit_photos/img_123.jpg
```

Then use `Storage::getUrl()` when needed.

### 3. Delete Old Files

```php
// Before update
if (!empty($oldPath)) {
    Storage::getInstance()->delete($oldPath);
}

// Upload new
$result = Storage::getInstance()->upload($file);
```

---

## 📞 Support

Need help with:
- Migration to Cloudinary
- Custom storage provider
- Performance optimization

Contact: [Your contact info]

---

## 📅 Changelog

### v1.0.0 (Current)
- ✅ Storage abstraction layer
- ✅ Local storage implementation
- ✅ Cloudinary placeholder
- ✅ Easy configuration switch

### v1.1.0 (Planned - Production)
- 🔄 Activate Cloudinary
- 🔄 Migration script
- 🔄 Batch upload optimization

---

Made with ❤️ for TND System
