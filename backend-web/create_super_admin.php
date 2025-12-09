<?php
/**
 * SCRIPT UNTUK GENERATE PASSWORD HASH & CREATE SUPER ADMIN
 * Email: tndsrt@gmail.com
 * Password: Srttnd2025!
 */

// Database configuration
$host = 'localhost';
$dbname = 'u211765246_tnd_db';
$username = 'u211765246_tnd_user';
$password = 'Tnd@2024';

// Super Admin credentials
$admin_username = 'superadmin';
$admin_password = 'Srttnd2025!';
$admin_email = 'tndsrt@gmail.com';
$admin_fullname = 'Super Administrator';

try {
    // Connect to database
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8mb4", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    echo "=== CREATE SUPER ADMIN SCRIPT ===\n\n";
    
    // Generate password hash
    $password_hash = password_hash($admin_password, PASSWORD_BCRYPT);
    echo "Password Hash Generated: $password_hash\n\n";
    
    // Step 1: Delete old super admin
    echo "Step 1: Deleting old super admin accounts...\n";
    $stmt = $pdo->prepare("DELETE FROM users WHERE username = 'super_admin' OR username = 'superadmin' OR email = ?");
    $stmt->execute([$admin_email]);
    echo "Deleted " . $stmt->rowCount() . " old admin account(s)\n\n";
    
    // Step 2: Create new super admin
    echo "Step 2: Creating new super admin...\n";
    $stmt = $pdo->prepare("
        INSERT INTO users (
            username, 
            password, 
            full_name, 
            email, 
            role, 
            division, 
            phone, 
            is_active,
            created_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, NOW())
    ");
    
    $stmt->execute([
        $admin_username,      // username
        $password_hash,       // password (hashed)
        $admin_fullname,      // full_name
        $admin_email,         // email
        'super_admin',        // role
        null,                 // division
        null,                 // phone
        1                     // is_active
    ]);
    
    echo "✓ Super Admin created successfully!\n\n";
    
    // Step 3: Verify creation
    echo "Step 3: Verifying super admin...\n";
    $stmt = $pdo->prepare("SELECT id, username, full_name, email, role, is_active, created_at FROM users WHERE email = ?");
    $stmt->execute([$admin_email]);
    $admin = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if ($admin) {
        echo "✓ Super Admin verified!\n\n";
        echo "=== SUPER ADMIN DETAILS ===\n";
        echo "ID           : " . $admin['id'] . "\n";
        echo "Username     : " . $admin['username'] . "\n";
        echo "Full Name    : " . $admin['full_name'] . "\n";
        echo "Email        : " . $admin['email'] . "\n";
        echo "Role         : " . $admin['role'] . "\n";
        echo "Status       : " . ($admin['is_active'] ? 'Active' : 'Inactive') . "\n";
        echo "Created      : " . $admin['created_at'] . "\n\n";
        
        echo "=== LOGIN CREDENTIALS ===\n";
        echo "URL          : https://tndsystem.online/backend-web/\n";
        echo "Username     : $admin_username\n";
        echo "Password     : $admin_password\n";
        echo "Email        : $admin_email\n\n";
        
        echo "=== SUCCESS! ===\n";
        echo "Super Admin account has been created successfully.\n";
        echo "You can now login to the web dashboard.\n";
    } else {
        echo "✗ ERROR: Super Admin not found after creation!\n";
    }
    
} catch (PDOException $e) {
    echo "ERROR: " . $e->getMessage() . "\n";
    exit(1);
}

// Optional: Show all users in database
echo "\n=== ALL USERS IN DATABASE ===\n";
try {
    $stmt = $pdo->query("SELECT id, username, full_name, email, role, division FROM users ORDER BY id");
    $users = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    if (count($users) > 0) {
        echo "Total users: " . count($users) . "\n\n";
        foreach ($users as $user) {
            echo "ID: {$user['id']} | Username: {$user['username']} | Name: {$user['full_name']} | Role: {$user['role']} | Division: {$user['division']}\n";
        }
    } else {
        echo "No users found in database.\n";
    }
} catch (PDOException $e) {
    echo "Error fetching users: " . $e->getMessage() . "\n";
}

echo "\n=== DONE ===\n";
?>
