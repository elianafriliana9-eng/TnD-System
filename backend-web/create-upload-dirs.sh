#!/bin/bash
# ====================================
# TND System - Create Upload Directories
# Run this script in cPanel Terminal or SSH
# ====================================

echo "Creating upload directories for TND System..."

# Navigate to backend-web directory
cd ~/public_html/backend-web || exit

# Create main uploads directory
mkdir -p uploads
chmod 755 uploads

# Create subdirectories
mkdir -p uploads/visit_photos
mkdir -p uploads/profile_photos
mkdir -p uploads/training_photos
mkdir -p uploads/temp

# Set permissions
chmod 755 uploads/visit_photos
chmod 755 uploads/profile_photos
chmod 755 uploads/training_photos
chmod 755 uploads/temp

# Create .htaccess for uploads directory (security)
cat > uploads/.htaccess << 'EOF'
# Prevent PHP execution in uploads directory
<FilesMatch "\.(?i:php|php3|php4|php5|phtml|pl|py|jsp|asp|sh|cgi)$">
    Order Deny,Allow
    Deny from all
</FilesMatch>

# Allow image access
<FilesMatch "\.(jpg|jpeg|png|gif|webp)$">
    Order Allow,Deny
    Allow from all
</FilesMatch>

Options -Indexes
EOF

echo "✅ Upload directories created successfully!"
echo ""
echo "Directory structure:"
echo "  backend-web/uploads/"
echo "    ├── visit_photos/"
echo "    ├── profile_photos/"
echo "    ├── training_photos/"
echo "    └── temp/"
echo ""
echo "Permissions set to 755 (read/write/execute for owner)"
echo "Security .htaccess added to prevent PHP execution"
