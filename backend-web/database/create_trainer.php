<?php
/**
 * Generate Password Hash for Trainer User
 */

$password = 'password';
$hash = password_hash($password, PASSWORD_DEFAULT);

echo "Password: $password\n";
echo "Hash: $hash\n";
echo "\n";

// Create INSERT statement
$sql = "INSERT INTO users (name, email, password, role, is_active) VALUES ('Trainer Demo', 'trainer@tnd.com', '$hash', 'trainer', 1);";
echo "SQL:\n$sql\n";
?>
