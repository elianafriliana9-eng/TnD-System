<?php
$dbHost = 'localhost';
$dbUser = 'root';
$dbPass = '';
$dbName = 'tnd_db';

try {
    $conn = new PDO("mysql:host=$dbHost;dbname=$dbName", $dbUser, $dbPass);
    $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // First, get current categories count
    $stmt = $conn->query('SELECT COUNT(*) as cnt FROM training_categories');
    $count = $stmt->fetch(PDO::FETCH_ASSOC)['cnt'];
    echo "Current categories count: $count\n";
    
    // Delete all and reset auto_increment
    $conn->exec('TRUNCATE TABLE training_categories');
    echo "Truncated training_categories\n\n";
    
    // Insert new categories 1-10
    $categories = [
        'Basic Operations',
        'Customer Service',
        'Safety Procedures',
        'Equipment Maintenance',
        'Quality Control',
        'Team Communication',
        'Inventory Management',
        'Compliance & Regulations',
        'Problem Solving',
        'Product Knowledge'
    ];
    
    foreach ($categories as $index => $name) {
        $id = $index + 1;
        $stmt = $conn->prepare('INSERT INTO training_categories (id, name, description, is_active, created_at) VALUES (?, ?, ?, 1, NOW())');
        $stmt->execute([$id, $name, "Category $id description"]);
        echo "Created category $id: $name\n";
    }
    
    echo "\nReset complete! New categories:\n";
    $stmt = $conn->query('SELECT * FROM training_categories ORDER BY id');
    $newCats = $stmt->fetchAll(PDO::FETCH_ASSOC);
    foreach ($newCats as $cat) {
        echo "  ID: {$cat['id']}, Name: {$cat['name']}\n";
    }
    
} catch (Exception $e) {
    echo 'Error: ' . $e->getMessage();
}
?>
