<?php
/**
 * SCRIPT UNTUK MEMBERSIHKAN DATA SAMPLE/TEST
 * HATI-HATI: Script ini akan menghapus SEMUA data kecuali:
 * - Checklist categories dan points
 * - Outlets
 * - Super admin yang baru dibuat
 */

// Database configuration
$host = 'localhost';
$dbname = 'u211765246_tnd_db';
$username = 'u211765246_tnd_user';
$password = 'Tnd@2024';

echo "=== CLEANUP SAMPLE DATA SCRIPT ===\n";
echo "WARNING: This will delete all sample/test data!\n\n";

// Confirm before proceeding
echo "Data yang akan dihapus:\n";
echo "- Semua visit photos\n";
echo "- Semua visit checklist responses\n";
echo "- Semua visits\n";
echo "- Semua improvement recommendations\n";
echo "- Semua users KECUALI super admin (tndsrt@gmail.com)\n\n";

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8mb4", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // Start transaction
    $pdo->beginTransaction();
    
    echo "Starting cleanup...\n\n";
    
    // Step 1: Delete visit photos
    echo "Step 1: Deleting visit photos...\n";
    $stmt = $pdo->exec("DELETE FROM visit_photos");
    echo "Deleted $stmt visit photos\n\n";
    
    // Step 2: Delete visit checklist responses
    echo "Step 2: Deleting visit checklist responses...\n";
    $stmt = $pdo->exec("DELETE FROM visit_checklist_responses");
    echo "Deleted $stmt checklist responses\n\n";
    
    // Step 3: Delete visits
    echo "Step 3: Deleting visits...\n";
    $stmt = $pdo->exec("DELETE FROM visits");
    echo "Deleted $stmt visits\n\n";
    
    // Step 4: Delete improvement recommendations
    echo "Step 4: Deleting improvement recommendations...\n";
    $stmt = $pdo->exec("DELETE FROM improvement_recommendations");
    echo "Deleted $stmt recommendations\n\n";
    
    // Step 5: Delete all users except super admin
    echo "Step 5: Deleting sample users (keeping super admin)...\n";
    $stmt = $pdo->prepare("DELETE FROM users WHERE email != ? AND role != 'super_admin'");
    $stmt->execute(['tndsrt@gmail.com']);
    echo "Deleted " . $stmt->rowCount() . " sample users\n\n";
    
    // Commit transaction
    $pdo->commit();
    
    echo "=== CLEANUP COMPLETED ===\n\n";
    
    // Show remaining data
    echo "Remaining data in database:\n\n";
    
    // Count checklist categories
    $stmt = $pdo->query("SELECT COUNT(*) as count FROM checklist_categories");
    $count = $stmt->fetch(PDO::FETCH_ASSOC)['count'];
    echo "Checklist Categories: $count\n";
    
    // Count checklist points
    $stmt = $pdo->query("SELECT COUNT(*) as count FROM checklist_points");
    $count = $stmt->fetch(PDO::FETCH_ASSOC)['count'];
    echo "Checklist Points: $count\n";
    
    // Count outlets
    $stmt = $pdo->query("SELECT COUNT(*) as count FROM outlets");
    $count = $stmt->fetch(PDO::FETCH_ASSOC)['count'];
    echo "Outlets: $count\n";
    
    // Count users
    $stmt = $pdo->query("SELECT COUNT(*) as count FROM users");
    $count = $stmt->fetch(PDO::FETCH_ASSOC)['count'];
    echo "Users: $count\n";
    
    // List remaining users
    echo "\nRemaining users:\n";
    $stmt = $pdo->query("SELECT id, username, full_name, email, role FROM users ORDER BY id");
    $users = $stmt->fetchAll(PDO::FETCH_ASSOC);
    foreach ($users as $user) {
        echo "- {$user['username']} ({$user['full_name']}) - {$user['role']}\n";
    }
    
    echo "\n=== Database is now clean and ready for production! ===\n";
    
} catch (PDOException $e) {
    // Rollback on error
    if ($pdo->inTransaction()) {
        $pdo->rollBack();
    }
    echo "ERROR: " . $e->getMessage() . "\n";
    echo "Cleanup aborted. No changes made.\n";
    exit(1);
}
?>
