<?php
/**
 * Database Seed Runner for Training Module
 * Run this file via browser: http://localhost/tnd_system/backend-web/database/run_seed.php
 */

require_once __DIR__ . '/../config/database.php';

header('Content-Type: text/html; charset=utf-8');
echo "<h1>Training Module - Seed Sample Data</h1>";
echo "<hr>";

try {
    $db = Database::getInstance()->getConnection();
    
    // Read seed file
    $seedFile = __DIR__ . '/seeds/seed_training_data.sql';
    
    if (!file_exists($seedFile)) {
        throw new Exception("Seed file not found: $seedFile");
    }
    
    $sql = file_get_contents($seedFile);
    
    // Split by semicolon and execute each statement
    $statements = explode(';', $sql);
    
    echo "<h2>Seeding Sample Data...</h2>";
    echo "<pre>";
    
    $successCount = 0;
    $errorCount = 0;
    
    foreach ($statements as $statement) {
        $statement = trim($statement);
        
        // Skip empty statements and comments
        if (empty($statement) || substr($statement, 0, 2) === '--') {
            continue;
        }
        
        try {
            $db->exec($statement);
            $successCount++;
            
            // Show statement summary
            if (stripos($statement, 'INSERT INTO training_checklists') !== false) {
                echo "✓ Inserted training checklist\n";
            } elseif (stripos($statement, 'INSERT INTO training_categories') !== false) {
                echo "✓ Inserted training categories\n";
            } elseif (stripos($statement, 'INSERT INTO training_points') !== false) {
                echo "✓ Inserted training points\n";
            } elseif (stripos($statement, 'INSERT INTO users') !== false) {
                echo "✓ Created sample trainer user\n";
            } elseif (stripos($statement, 'INSERT INTO training_sessions') !== false) {
                echo "✓ Created sample training session\n";
            } elseif (stripos($statement, 'INSERT INTO training_participants') !== false) {
                echo "✓ Added sample participants\n";
            } elseif (stripos($statement, 'INSERT INTO training_responses') !== false) {
                echo "✓ Added sample responses\n";
            }
            
        } catch (PDOException $e) {
            $errorCount++;
            $errorMsg = $e->getMessage();
            // Don't show duplicate entry errors
            if (stripos($errorMsg, 'Duplicate entry') === false) {
                echo "✗ Error: " . $errorMsg . "\n";
            }
        }
    }
    
    echo "</pre>";
    echo "<hr>";
    echo "<h2>Seed Summary:</h2>";
    echo "<p>✓ Successful inserts: <strong>$successCount</strong></p>";
    echo "<p>✗ Failed inserts: <strong>$errorCount</strong></p>";
    
    echo "<hr>";
    echo "<h2>Sample Data Created:</h2>";
    
    // Show created data
    echo "<h3>Training Checklist:</h3>";
    $stmt = $db->query("
        SELECT 
            tc.name,
            (SELECT COUNT(*) FROM training_categories WHERE checklist_id = tc.id) as categories,
            (SELECT COUNT(*) FROM training_points tp 
             INNER JOIN training_categories tcat ON tp.category_id = tcat.id 
             WHERE tcat.checklist_id = tc.id) as total_points
        FROM training_checklists tc
        ORDER BY tc.id DESC
        LIMIT 1
    ");
    
    echo "<table border='1' cellpadding='10' style='border-collapse: collapse;'>";
    echo "<tr><th>Checklist Name</th><th>Categories</th><th>Total Points</th></tr>";
    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        echo "<tr>";
        echo "<td>{$row['name']}</td>";
        echo "<td>{$row['categories']}</td>";
        echo "<td>{$row['total_points']}</td>";
        echo "</tr>";
    }
    echo "</table>";
    
    // Show trainer
    echo "<h3>Sample Trainer:</h3>";
    $stmt = $db->query("
        SELECT username, full_name, email, specialization
        FROM users
        WHERE role = 'trainer'
        LIMIT 1
    ");
    
    echo "<table border='1' cellpadding='10' style='border-collapse: collapse;'>";
    echo "<tr><th>Username</th><th>Full Name</th><th>Email</th><th>Specialization</th></tr>";
    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        echo "<tr>";
        echo "<td>{$row['username']}</td>";
        echo "<td>{$row['full_name']}</td>";
        echo "<td>{$row['email']}</td>";
        echo "<td>{$row['specialization']}</td>";
        echo "</tr>";
    }
    echo "</table>";
    
    // Show sample session
    echo "<h3>Sample Training Session:</h3>";
    $stmt = $db->query("
        SELECT 
            ts.id,
            o.name as outlet_name,
            u.full_name as trainer_name,
            ts.session_date,
            ts.total_staff,
            ROUND(ts.average_score, 1) as avg_score,
            ts.status
        FROM training_sessions ts
        LEFT JOIN outlets o ON ts.outlet_id = o.id
        LEFT JOIN users u ON ts.trainer_id = u.id
        ORDER BY ts.id DESC
        LIMIT 1
    ");
    
    if ($stmt->rowCount() > 0) {
        echo "<table border='1' cellpadding='10' style='border-collapse: collapse;'>";
        echo "<tr><th>ID</th><th>Outlet</th><th>Trainer</th><th>Date</th><th>Staff</th><th>Avg Score</th><th>Status</th></tr>";
        while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
            echo "<tr>";
            echo "<td>{$row['id']}</td>";
            echo "<td>{$row['outlet_name']}</td>";
            echo "<td>{$row['trainer_name']}</td>";
            echo "<td>{$row['session_date']}</td>";
            echo "<td>{$row['total_staff']}</td>";
            echo "<td>{$row['avg_score']} ⭐</td>";
            echo "<td>{$row['status']}</td>";
            echo "</tr>";
        }
        echo "</table>";
        
        // Show participants
        echo "<h3>Sample Participants:</h3>";
        $sessionId = $stmt->fetch(PDO::FETCH_ASSOC)['id'] ?? null;
        
        $stmt2 = $db->query("
            SELECT staff_name, position, average_score, notes
            FROM training_participants
            ORDER BY id DESC
            LIMIT 5
        ");
        
        echo "<table border='1' cellpadding='10' style='border-collapse: collapse;'>";
        echo "<tr><th>Staff Name</th><th>Position</th><th>Avg Score</th><th>Notes</th></tr>";
        while ($row = $stmt2->fetch(PDO::FETCH_ASSOC)) {
            echo "<tr>";
            echo "<td>{$row['staff_name']}</td>";
            echo "<td>{$row['position']}</td>";
            echo "<td>{$row['average_score']} ⭐</td>";
            echo "<td>{$row['notes']}</td>";
            echo "</tr>";
        }
        echo "</table>";
    }
    
    echo "<hr>";
    echo "<h2 style='color: green;'>✓ Sample data seeded successfully!</h2>";
    
    echo "<hr>";
    echo "<h2>Credentials for Testing:</h2>";
    echo "<ul>";
    echo "<li><strong>Username:</strong> trainer1</li>";
    echo "<li><strong>Password:</strong> password</li>";
    echo "<li><strong>Role:</strong> Trainer</li>";
    echo "</ul>";
    
    echo "<hr>";
    echo "<h2>Next Steps:</h2>";
    echo "<ol>";
    echo "<li>Create Backend APIs ✓ (Next)</li>";
    echo "<li>Build Flutter Models</li>";
    echo "<li>Implement Training Screens</li>";
    echo "</ol>";
    
} catch (Exception $e) {
    echo "<h3 style='color: red;'>✗ Seeding Failed!</h3>";
    echo "<p>Error: " . $e->getMessage() . "</p>";
}

echo "<hr>";
echo "<p><a href='../../'>Back to Home</a></p>";
?>
