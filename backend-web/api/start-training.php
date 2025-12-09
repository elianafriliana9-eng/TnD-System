<?php
header('Content-Type: application/json');
include '../config/database.php';
include '../utils/response.php';

$data = json_decode(file_get_contents('php://input'));

if (!isset($data->training_id)) {
    Response::send(400, 'Bad Request', ['error' => 'Training ID is required']);
    exit();
}

$training_id = $data->training_id;
$pdo = new PDO("mysql:host=$host;dbname=$dbname", $user, $pass);
$pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

try {
    $stmt = $pdo->prepare("UPDATE trainings SET status = 'ongoing' WHERE id = ?");
    $stmt->execute([$training_id]);

    if ($stmt->rowCount() > 0) {
        Response::send(200, 'Success', ['message' => 'Training started successfully']);
    } else {
        Response::send(404, 'Not Found', ['error' => 'Training not found or status already ongoing']);
    }
} catch (PDOException $e) {
    Response::send(500, 'Internal Server Error', ['error' => $e->getMessage()]);
}
