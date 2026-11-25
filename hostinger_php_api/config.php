<?php
// Hostinger Database Configuration for KVM Workforce Tracker
define('DB_HOST', 'localhost');
define('DB_NAME', 'u269575760_WFM');
define('DB_USER', 'u269575760_kvm_wfm');
define('DB_PASS', 'cKNRq3>D');
define('DB_PORT', 3306);

function getDbConnection() {
    static $pdo = null;
    if ($pdo === null) {
        $dsn = "mysql:host=" . DB_HOST . ";port=" . DB_PORT . ";dbname=" . DB_NAME . ";charset=utf8mb4";
        try {
            $pdo = new PDO($dsn, DB_USER, DB_PASS, [
                PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                PDO::ATTR_EMULATE_PREPARES => false,
            ]);
        } catch (PDOException $e) {
            http_response_code(500);
            echo json_encode([
                'success' => false,
                'error' => 'Database connection failed: ' . $e->getMessage()
            ]);
            exit();
        }
    }
    return $pdo;
}
