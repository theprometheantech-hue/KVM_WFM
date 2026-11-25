<?php
// KVM Workforce Tracker - Hostinger Native PHP REST API
// Zero Node.js required - runs on Apache / LiteSpeed natively

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS, PUT, DELETE");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With");
header("Content-Type: application/json; charset=UTF-8");

// Handle CORS Preflight OPTIONS
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once __DIR__ . '/config.php';

$pdo = getDbConnection();

// Auto-migrate schema columns on the fly so manual SQL imports are never required
function autoMigrateColumns($pdo)
{
    try {
        $cols = [
            'stations' => [
                'checkin_latitude' => 'DECIMAL(10, 8) DEFAULT NULL',
                'checkin_longitude' => 'DECIMAL(11, 8) DEFAULT NULL',
                'checkin_address' => 'TEXT DEFAULT NULL',
                'address' => 'TEXT DEFAULT NULL',
                'bin_capacity' => 'INT DEFAULT 500',
            ]
        ];
        foreach ($cols as $tbl => $colList) {
            $existing = [];
            $q = $pdo->query("SHOW COLUMNS FROM `$tbl`");
            if ($q) {
                while ($row = $q->fetch()) {
                    $existing[] = strtolower($row['Field']);
                }
            }
            foreach ($colList as $col => $def) {
                if (!in_array(strtolower($col), $existing)) {
                    $pdo->exec("ALTER TABLE `$tbl` ADD COLUMN `$col` $def");
                }
            }
        }
    } catch (Exception $e) {
        // Table may not exist yet before setup
    }
}
autoMigrateColumns($pdo);

// Parse requested route
$uri = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
// Normalize trailing slash and remove script name if present
$scriptName = dirname($_SERVER['SCRIPT_NAME']);
if ($scriptName !== '/' && strpos($uri, $scriptName) === 0) {
    $uri = substr($uri, strlen($scriptName));
}
$uri = '/' . trim($uri, '/');
$method = $_SERVER['REQUEST_METHOD'];

// Helper to read JSON request body
function getJsonBody()
{
    $input = file_get_contents('php://input');
    return json_decode($input, true) ?: [];
}

// -------------------------------------------------------------
// ROUTES
// -------------------------------------------------------------

// 1. Root & Health Check
if ($uri === '' || $uri === '/' || $uri === '/api' || $uri === '/api/health') {
    echo json_encode([
        'status' => 'ONLINE',
        'service' => 'KVM Workforce Tracker API (Hostinger PHP)',
        'subdomain' => 'wfm-api.e2s2.in',
        'database' => DB_NAME,
        'timestamp' => date('c')
    ]);
    exit();
}

// 1B. One-Click Database Table Auto-Setup & Seeding
// GET /setup or /api/setup
if ($uri === '/setup' || $uri === '/api/setup') {
    try {
        $schemaSql = file_exists(__DIR__ . '/schema.sql') ? file_get_contents(__DIR__ . '/schema.sql') : '';
        if (empty($schemaSql)) {
            // Built-in SQL fallback if schema.sql was not uploaded
            $schemaSql = "
            CREATE TABLE IF NOT EXISTS employees (
                id INT AUTO_INCREMENT PRIMARY KEY,
                employee_id VARCHAR(50) UNIQUE NOT NULL,
                full_name VARCHAR(150) NOT NULL,
                mobile_number VARCHAR(30) NOT NULL,
                email VARCHAR(150),
                password VARCHAR(255) NOT NULL,
                is_temporary_password BOOLEAN DEFAULT TRUE,
                role VARCHAR(50) DEFAULT 'employee',
                assigned_station_id VARCHAR(50),
                assigned_station_name VARCHAR(150),
                onboarding_status VARCHAR(50) DEFAULT 'VERIFIED',
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
            CREATE TABLE IF NOT EXISTS stations (
                id INT AUTO_INCREMENT PRIMARY KEY,
                station_id VARCHAR(50) UNIQUE NOT NULL,
                station_name VARCHAR(150) NOT NULL,
                machine_code VARCHAR(50) UNIQUE NOT NULL,
                employee_name VARCHAR(150) DEFAULT 'Unassigned',
                employee_id VARCHAR(50) DEFAULT '',
                is_present BOOLEAN DEFAULT FALSE,
                check_in_time VARCHAR(100) NULL,
                today_bottles_received INT DEFAULT 0,
                today_bottles_packed INT DEFAULT 0,
                today_crates_packed INT DEFAULT 0,
                last_updated_time VARCHAR(100) DEFAULT 'Ready for Shift',
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
            CREATE TABLE IF NOT EXISTS duty_logs (
                id INT AUTO_INCREMENT PRIMARY KEY,
                log_id VARCHAR(50) UNIQUE NOT NULL,
                station_id VARCHAR(50) NOT NULL,
                machine_code VARCHAR(50) NOT NULL,
                employee_id VARCHAR(50),
                employee_name VARCHAR(150),
                entry_type VARCHAR(50) NOT NULL,
                bottle_count INT DEFAULT 0,
                crate_count INT DEFAULT 0,
                vendor_name VARCHAR(150) NULL,
                vehicle_or_driver VARCHAR(150) NULL,
                timestamp VARCHAR(100) NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
            CREATE TABLE IF NOT EXISTS cash_exchanges (
                id INT AUTO_INCREMENT PRIMARY KEY,
                exchange_id VARCHAR(50) UNIQUE NOT NULL,
                station_id VARCHAR(50) NOT NULL,
                machine_code VARCHAR(50) NOT NULL,
                employee_id VARCHAR(50),
                employee_name VARCHAR(150),
                cash_paid_to_customer DECIMAL(10, 2) NOT NULL,
                bottles_collected INT NOT NULL,
                is_deposited_into_machine BOOLEAN DEFAULT TRUE,
                is_digitally_reimbursed BOOLEAN DEFAULT FALSE,
                timestamp VARCHAR(100) NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
            CREATE TABLE IF NOT EXISTS truck_dispatches (
                id INT AUTO_INCREMENT PRIMARY KEY,
                loading_id VARCHAR(50) UNIQUE NOT NULL,
                station_id VARCHAR(50) NOT NULL,
                machine_code VARCHAR(50) NOT NULL,
                employee_id VARCHAR(50),
                employee_name VARCHAR(150),
                vendor_name VARCHAR(150) NOT NULL,
                packages_count INT NOT NULL,
                total_bottles_loaded INT NOT NULL,
                truck_vehicle_number VARCHAR(50) NOT NULL,
                driver_name VARCHAR(150) NOT NULL,
                driver_mobile VARCHAR(30) NOT NULL,
                status VARCHAR(50) DEFAULT 'GATE_EXIT_AUTHORIZED',
                timestamp VARCHAR(100) NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
            INSERT INTO employees (employee_id, full_name, mobile_number, email, password, is_temporary_password, role)
            VALUES ('ADMIN-01', 'System Administrator', '9999999999', 'admin@kvm.com', 'Password123', FALSE, 'admin')
            ON DUPLICATE KEY UPDATE full_name=VALUES(full_name);
            INSERT INTO stations (station_id, station_name, machine_code, employee_name, employee_id, is_present, today_bottles_received, today_bottles_packed, today_crates_packed, last_updated_time)
            VALUES
            ('STN-001', 'Arani Station Hub', 'MCH-ARN-01', 'Unassigned', '', FALSE, 0, 0, 0, 'Ready for Shift'),
            ('STN-002', 'Chengam Town Station', 'MCH-CGM-01', 'Unassigned', '', FALSE, 0, 0, 0, 'Ready for Shift'),
            ('STN-003', 'Chetpet Main Bus Stand', 'MCH-CPT-01', 'Unassigned', '', FALSE, 0, 0, 0, 'Ready for Shift'),
            ('STN-004', 'Cheyyar SIPCOT Point', 'MCH-CYR-01', 'Unassigned', '', FALSE, 0, 0, 0, 'Ready for Shift'),
            ('STN-005', 'Vannamkulam Junction Kiosk', 'MCH-VKL-01', 'Unassigned', '', FALSE, 0, 0, 0, 'Ready for Shift'),
            ('STN-006', 'Devikapuram Temple Road', 'MCH-DVK-01', 'Unassigned', '', FALSE, 0, 0, 0, 'Ready for Shift'),
            ('STN-007', 'Jamunamarathur Hills Depot', 'MCH-JMM-01', 'Unassigned', '', FALSE, 0, 0, 0, 'Ready for Shift'),
            ('STN-008', 'Kalambur Market Yard', 'MCH-KLM-01', 'Unassigned', '', FALSE, 0, 0, 0, 'Ready for Shift'),
            ('STN-009', 'Kalasapakkam Block Station', 'MCH-KLS-01', 'Unassigned', '', FALSE, 0, 0, 0, 'Ready for Shift'),
            ('STN-010', 'Kannamangalam Bazaar Center', 'MCH-KMG-01', 'Unassigned', '', FALSE, 0, 0, 0, 'Ready for Shift'),
            ('STN-011', 'Polur Town Bus Stand', 'MCH-PLR-01', 'Unassigned', '', FALSE, 0, 0, 0, 'Ready for Shift'),
            ('STN-012', 'Santhavasal Forest Gate', 'MCH-STV-01', 'Unassigned', '', FALSE, 0, 0, 0, 'Ready for Shift')
            ON DUPLICATE KEY UPDATE station_name=VALUES(station_name), machine_code=VALUES(machine_code);
            ";
        }

        $pdo->exec($schemaSql);
        echo json_encode([
            'success' => true,
            'message' => 'All MySQL tables and initial 12 regional stations created successfully in ' . DB_NAME . '!',
            'tables' => ['employees', 'stations', 'duty_logs', 'cash_exchanges', 'truck_dispatches'],
            'initialStationsCount' => 12
        ]);
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(['error' => 'Database setup failed: ' . $e->getMessage()]);
    }
    exit();
}

// 1C. Reset Stations to Default 12 Regional Locations
// GET /api/fleet/reset-default-stations
if ($uri === '/api/fleet/reset-default-stations' || $uri === '/fleet/reset-default-stations') {
    try {
        $regional = [
            ['STN-001', 'Arani Station Hub', 'MCH-ARN-01'],
            ['STN-002', 'Chengam Town Station', 'MCH-CGM-01'],
            ['STN-003', 'Chetpet Main Bus Stand', 'MCH-CPT-01'],
            ['STN-004', 'Cheyyar SIPCOT Point', 'MCH-CYR-01'],
            ['STN-005', 'Vannamkulam Junction Kiosk', 'MCH-VKL-01'],
            ['STN-006', 'Devikapuram Temple Road', 'MCH-DVK-01'],
            ['STN-007', 'Jamunamarathur Hills Depot', 'MCH-JMM-01'],
            ['STN-008', 'Kalambur Market Yard', 'MCH-KLM-01'],
            ['STN-009', 'Kalasapakkam Block Station', 'MCH-KLS-01'],
            ['STN-010', 'Kannamangalam Bazaar Center', 'MCH-KMG-01'],
            ['STN-011', 'Polur Town Bus Stand', 'MCH-PLR-01'],
            ['STN-012', 'Santhavasal Forest Gate', 'MCH-STV-01'],
        ];

        // Ensure table exists
        $pdo->exec("CREATE TABLE IF NOT EXISTS stations (
            id INT AUTO_INCREMENT PRIMARY KEY,
            station_id VARCHAR(50) UNIQUE NOT NULL,
            station_name VARCHAR(150) NOT NULL,
            machine_code VARCHAR(50) UNIQUE NOT NULL,
            employee_name VARCHAR(150) DEFAULT 'Unassigned',
            employee_id VARCHAR(50) DEFAULT '',
            is_present BOOLEAN DEFAULT FALSE,
            check_in_time VARCHAR(100) NULL,
            today_bottles_received INT DEFAULT 0,
            today_bottles_packed INT DEFAULT 0,
            today_crates_packed INT DEFAULT 0,
            last_updated_time VARCHAR(100) DEFAULT 'Ready for Shift',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )");

        $pdo->exec("TRUNCATE TABLE stations");

        $insertStmt = $pdo->prepare("INSERT INTO stations (station_id, station_name, machine_code, employee_name, employee_id, is_present, today_bottles_received, today_bottles_packed, today_crates_packed, last_updated_time) VALUES (?, ?, ?, 'Unassigned', '', FALSE, 0, 0, 0, 'Ready for Shift')");

        foreach ($regional as $stn) {
            $insertStmt->execute([$stn[0], $stn[1], $stn[2]]);
        }

        echo json_encode([
            'success' => true,
            'message' => 'All 12 regional operational stations reset successfully in ' . DB_NAME . '!',
            'stations' => $regional
        ]);
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(['error' => 'Reset failed: ' . $e->getMessage()]);
    }
    exit();
}

// 2. Multi-Location Fleet Overview
// GET /api/fleet/overview
if (($uri === '/api/fleet/overview' || $uri === '/fleet/overview') && $method === 'GET') {
    try {
        // Safe check for coordinate and address columns
        try {
            $pdo->exec("ALTER TABLE stations ADD COLUMN IF NOT EXISTS checkin_latitude DECIMAL(10, 7) NULL");
            $pdo->exec("ALTER TABLE stations ADD COLUMN IF NOT EXISTS checkin_longitude DECIMAL(10, 7) NULL");
            $pdo->exec("ALTER TABLE stations ADD COLUMN IF NOT EXISTS checkin_address VARCHAR(255) NULL");
            $pdo->exec("ALTER TABLE stations ADD COLUMN IF NOT EXISTS address VARCHAR(255) NULL");
            $pdo->exec("ALTER TABLE stations ADD COLUMN IF NOT EXISTS bin_capacity INT DEFAULT 500");
        } catch (Exception $e) { /* Ignore if exists */
        }

        $stmt = $pdo->query("SELECT station_id AS machineId, station_name AS locationName, machine_code AS machineCode, is_present AS isStaffPresent, employee_name AS assignedOperator, employee_id AS employeeId, check_in_time AS checkInTime, checkin_latitude AS checkinLatitude, checkin_longitude AS checkinLongitude, checkin_address AS checkinAddress, address, bin_capacity AS binCapacity, today_bottles_received AS todayTotalDeposited, today_bottles_packed AS todayTotalDispatchedToVendor, today_crates_packed AS currentBinHoldings, last_updated_time AS lastReadingTime FROM stations ORDER BY id ASC");
        $stations = $stmt->fetchAll();

        // Convert boolean/integer/float fields for Flutter JSON parity
        foreach ($stations as &$stn) {
            $stn['isStaffPresent'] = (bool) $stn['isStaffPresent'];
            $stn['todayTotalDeposited'] = (int) $stn['todayTotalDeposited'];
            $stn['todayTotalDispatchedToVendor'] = (int) $stn['todayTotalDispatchedToVendor'];
            $stn['currentBinHoldings'] = (int) $stn['currentBinHoldings'];
            $stn['binCapacity'] = (int) ($stn['binCapacity'] ?? 500);
            $stn['checkinLatitude'] = !empty($stn['checkinLatitude']) ? (float) $stn['checkinLatitude'] : null;
            $stn['checkinLongitude'] = !empty($stn['checkinLongitude']) ? (float) $stn['checkinLongitude'] : null;
        }

        echo json_encode([
            'totalLocations' => count($stations),
            'locations' => $stations
        ]);
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(['error' => $e->getMessage()]);
    }
    exit();
}

// 2B. Update Machine & Station Details
// POST /api/fleet/station/update
if (($uri === '/api/fleet/station/update' || $uri === '/fleet/station/update') && ($method === 'POST' || $method === 'PUT')) {
    $data = getJsonBody();
    $stationId = trim($data['stationId'] ?? '');
    $stationName = trim($data['stationName'] ?? '');
    $machineCode = trim($data['machineCode'] ?? '');
    $address = trim($data['address'] ?? '');
    $employeeId = trim($data['employeeId'] ?? '');
    $employeeName = trim($data['employeeName'] ?? '');

    if (empty($stationId) || empty($stationName)) {
        http_response_code(400);
        echo json_encode(['error' => 'Station ID and Station Name are required']);
        exit();
    }

    try {
        try {
            $pdo->exec("ALTER TABLE stations ADD COLUMN IF NOT EXISTS address VARCHAR(255) NULL");
            $pdo->exec("ALTER TABLE stations ADD COLUMN IF NOT EXISTS bin_capacity INT DEFAULT 500");
        } catch (Exception $e) {
        }

        $empNameVal = (!empty($employeeName) && $employeeName !== 'Unassigned') ? $employeeName : 'Unassigned';
        $empIdVal = (!empty($employeeId) && $employeeId !== 'Unassigned') ? $employeeId : '';

        $stmt = $pdo->prepare("UPDATE stations SET station_name = ?, machine_code = COALESCE(NULLIF(?, ''), machine_code), address = COALESCE(NULLIF(?, ''), address), employee_name = ?, employee_id = ? WHERE station_id = ? OR machine_code = ?");
        $stmt->execute([$stationName, $machineCode, $address, $empNameVal, $empIdVal, $stationId, $stationId]);

        // Sync employee assignment in employees table
        if (!empty($empIdVal)) {
            $empStmt = $pdo->prepare("UPDATE employees SET assigned_station_id = ?, assigned_station_name = ? WHERE employee_id = ?");
            $empStmt->execute([$stationId, $stationName, $empIdVal]);
        } else {
            $clearStmt = $pdo->prepare("UPDATE employees SET assigned_station_id = NULL, assigned_station_name = 'Unassigned' WHERE assigned_station_id = ?");
            $clearStmt->execute([$stationId]);
        }

        echo json_encode([
            'success' => true,
            'message' => "Station $stationId details updated successfully",
            'station' => [
                'stationId' => $stationId,
                'stationName' => $stationName,
                'machineCode' => $machineCode,
                'address' => $address,
                'employeeId' => $employeeId,
                'employeeName' => $employeeName
            ]
        ]);
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(['error' => $e->getMessage()]);
    }
    exit();
}

// 2C. Delete Station Location from Fleet
// POST /api/fleet/station/delete
if (($uri === '/api/fleet/station/delete' || $uri === '/fleet/station/delete') && ($method === 'POST' || $method === 'DELETE')) {
    $data = getJsonBody();
    $stationId = trim($data['stationId'] ?? '');

    if (empty($stationId)) {
        http_response_code(400);
        echo json_encode(['error' => 'Station ID is required']);
        exit();
    }

    try {
        $stmt = $pdo->prepare("DELETE FROM stations WHERE station_id = ?");
        $stmt->execute([$stationId]);

        // Unassign any employee assigned to this deleted station
        $empStmt = $pdo->prepare("UPDATE employees SET assigned_station_id = NULL, assigned_station_name = 'Unassigned' WHERE assigned_station_id = ?");
        $empStmt->execute([$stationId]);

        echo json_encode([
            'success' => true,
            'message' => "Station $stationId has been successfully removed from fleet.",
            'deletedStationId' => $stationId
        ]);
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(['error' => $e->getMessage()]);
    }
    exit();
}

// 3. Admin Provisions New Employee
// POST /api/employee/admin-add
if (($uri === '/api/employee/admin-add' || $uri === '/employee/admin-add') && $method === 'POST') {
    $data = getJsonBody();
    $fullName = trim($data['fullName'] ?? '');
    $mobileNumber = trim($data['mobileNumber'] ?? '');
    $email = trim($data['email'] ?? '');
    $assignedStationId = trim($data['assignedStationId'] ?? 'STN-001');
    $assignedStationName = trim($data['assignedStationName'] ?? 'Arani Station Hub');
    $customMachineCode = trim($data['machineCode'] ?? '');
    $address = trim($data['address'] ?? '');

    if (empty($fullName) || empty($mobileNumber)) {
        http_response_code(400);
        echo json_encode(['error' => 'Full name and mobile number are required']);
        exit();
    }

    try {
        $countStmt = $pdo->query("SELECT COUNT(*) AS total FROM employees WHERE role != 'admin'");
        $count = (int) $countStmt->fetch()['total'] + 101;
        $empId = "EMP-" . $count;
        $tempPassword = "Kvm@" . date('Y');
        $emailVal = !empty($email) ? $email : strtolower($empId) . "@kvm.com";

        $insertStmt = $pdo->prepare("INSERT INTO employees (employee_id, full_name, mobile_number, email, password, is_temporary_password, role, assigned_station_id, assigned_station_name, onboarding_status) VALUES (?, ?, ?, ?, ?, TRUE, 'employee', ?, ?, 'VERIFIED') ON DUPLICATE KEY UPDATE full_name=VALUES(full_name), assigned_station_id=VALUES(assigned_station_id), assigned_station_name=VALUES(assigned_station_name)");
        $insertStmt->execute([$empId, $fullName, $mobileNumber, $emailVal, $tempPassword, $assignedStationId, $assignedStationName]);

        // Also update stations table linking the employee and updating machine code if specified
        if (!empty($customMachineCode)) {
            $stnUpdate = $pdo->prepare("UPDATE stations SET station_name = ?, machine_code = ?, employee_name = ?, employee_id = ? WHERE station_id = ?");
            $stnUpdate->execute([$assignedStationName, $customMachineCode, $fullName, $empId, $assignedStationId]);
        } else {
            $stnUpdate = $pdo->prepare("UPDATE stations SET station_name = ?, employee_name = ?, employee_id = ? WHERE station_id = ?");
            $stnUpdate->execute([$assignedStationName, $fullName, $empId, $assignedStationId]);
        }

        http_response_code(201);
        echo json_encode([
            'success' => true,
            'message' => "Employee $fullName successfully provisioned and assigned to $assignedStationName",
            'employee' => [
                'employeeId' => $empId,
                'fullName' => $fullName,
                'mobileNumber' => $mobileNumber,
                'email' => $emailVal,
                'assignedStationId' => $assignedStationId,
                'assignedStationName' => $assignedStationName,
                'machineCode' => $customMachineCode,
                'temporaryPassword' => $tempPassword,
                'onboardingStatus' => 'VERIFIED'
            ]
        ]);
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(['error' => $e->getMessage()]);
    }
    exit();
}

// 4. Fetch All Employees
// GET /api/employee/onboarding-list
if (($uri === '/api/employee/onboarding-list' || $uri === '/employee/onboarding-list') && $method === 'GET') {
    try {
        $stmt = $pdo->query("SELECT employee_id AS employeeId, full_name AS fullName, mobile_number AS mobileNumber, email, role, password, is_temporary_password AS isTemporaryPassword, assigned_station_id AS assignedStationId, assigned_station_name AS assignedStationName, onboarding_status AS onboardingStatus, created_at AS submittedAt FROM employees WHERE role != 'admin' ORDER BY id DESC");
        $employees = $stmt->fetchAll();
        echo json_encode([
            'success' => true,
            'applications' => $employees
        ]);
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(['error' => $e->getMessage()]);
    }
    exit();
}

// 4B. Update Employee Password (Permanent Password Set)
// POST /api/employee/update-password
if (($uri === '/api/employee/update-password' || $uri === '/employee/update-password') && $method === 'POST') {
    $data = getJsonBody();
    $empId = trim($data['employeeId'] ?? '');
    $newPassword = trim($data['password'] ?? '');

    if (empty($empId) || empty($newPassword)) {
        http_response_code(400);
        echo json_encode(['error' => 'Employee ID and new password are required']);
        exit();
    }

    try {
        $stmt = $pdo->prepare("UPDATE employees SET password = ?, is_temporary_password = FALSE WHERE employee_id = ?");
        $stmt->execute([$newPassword, $empId]);
        echo json_encode([
            'success' => true,
            'message' => "Permanent password updated successfully for employee $empId"
        ]);
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(['error' => $e->getMessage()]);
    }
    exit();
}

// 5. Verify Employee
// POST /api/employee/verify
if (($uri === '/api/employee/verify' || $uri === '/employee/verify') && $method === 'POST') {
    $data = getJsonBody();
    $employeeId = $data['employeeId'] ?? '';
    try {
        $stmt = $pdo->prepare("UPDATE employees SET onboarding_status = 'VERIFIED' WHERE employee_id = ?");
        $stmt->execute([$employeeId]);
        echo json_encode(['success' => true, 'message' => "Employee $employeeId verified"]);
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(['error' => $e->getMessage()]);
    }
    exit();
}

// 5B. Delete / Remove Employee from System
// POST /api/employee/delete
if (($uri === '/api/employee/delete' || $uri === '/employee/delete') && ($method === 'POST' || $method === 'DELETE')) {
    $data = getJsonBody();
    $employeeId = trim($data['employeeId'] ?? '');

    if (empty($employeeId)) {
        http_response_code(400);
        echo json_encode(['error' => 'Employee ID is required']);
        exit();
    }

    if ($employeeId === 'ADMIN-01') {
        http_response_code(403);
        echo json_encode(['error' => 'System Administrator cannot be deleted']);
        exit();
    }

    try {
        // 1. Delete from employees table
        $delStmt = $pdo->prepare("DELETE FROM employees WHERE employee_id = ?");
        $delStmt->execute([$employeeId]);

        // 2. Unassign from any linked station in stations table
        $unassignStmt = $pdo->prepare("UPDATE stations SET employee_name = 'Unassigned', employee_id = '', is_present = FALSE, checkin_latitude = NULL, checkin_longitude = NULL WHERE employee_id = ?");
        $unassignStmt->execute([$employeeId]);

        echo json_encode([
            'success' => true,
            'message' => "Employee $employeeId has been successfully removed and unassigned from stations.",
            'deletedEmployeeId' => $employeeId
        ]);
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(['error' => $e->getMessage()]);
    }
    exit();
}

// 6. Shift Check-In (Attendance & GPS Location)
// POST /api/attendance/shift-checkin
if (($uri === '/api/attendance/shift-checkin' || $uri === '/attendance/shift-checkin') && $method === 'POST') {
    $data = getJsonBody();
    $employeeId = $data['employeeId'] ?? '';
    $employeeName = $data['employeeName'] ?? '';
    $machineId = $data['machineId'] ?? '';
    $latitude = isset($data['latitude']) && $data['latitude'] !== null ? (float) $data['latitude'] : null;
    $longitude = isset($data['longitude']) && $data['longitude'] !== null ? (float) $data['longitude'] : null;
    $locationName = $data['locationName'] ?? '';
    $now = date('c');

    try {
        // Safe check for coordinate columns
        try {
            $pdo->exec("ALTER TABLE stations ADD COLUMN IF NOT EXISTS checkin_latitude DECIMAL(10, 7) NULL");
            $pdo->exec("ALTER TABLE stations ADD COLUMN IF NOT EXISTS checkin_longitude DECIMAL(10, 7) NULL");
            $pdo->exec("ALTER TABLE stations ADD COLUMN IF NOT EXISTS checkin_address VARCHAR(255) NULL");
        } catch (Exception $e) { /* Ignore if exists */
        }

        $stmt = $pdo->prepare("UPDATE stations SET is_present = TRUE, employee_name = ?, employee_id = ?, check_in_time = ?, last_updated_time = ?, checkin_latitude = ?, checkin_longitude = ?, checkin_address = ? WHERE station_id = ? OR machine_code = ?");
        $stmt->execute([$employeeName, $employeeId, $now, 'Present on Shift', $latitude, $longitude, $locationName, $machineId, $machineId]);

        // Also record in duty_logs
        $logId = "ATT-" . time();
        $coordsSummary = ($latitude && $longitude) ? "GPS: $latitude, $longitude" : "Checkin: $locationName";
        $logStmt = $pdo->prepare("INSERT INTO duty_logs (log_id, station_id, machine_code, employee_id, employee_name, entry_type, bottle_count, crate_count, vehicle_or_driver, timestamp) VALUES (?, ?, ?, ?, ?, 'SHIFT_CHECKIN', 0, 0, ?, ?)");
        $logStmt->execute([$logId, $machineId, $machineId, $employeeId, $employeeName, $coordsSummary, $now]);

        http_response_code(201);
        echo json_encode([
            'success' => true,
            'message' => 'Shift attendance and GPS location verified',
            'record' => [
                'employeeId' => $employeeId,
                'employeeName' => $employeeName,
                'machineId' => $machineId,
                'checkInTime' => $now,
                'latitude' => $latitude,
                'longitude' => $longitude,
                'status' => 'ON_DUTY'
            ]
        ]);
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(['error' => $e->getMessage()]);
    }
    exit();
}

// 7. Hourly Deposit Readings Feed (Bottles Received / Packed)
// POST /api/fleet/readings
if (($uri === '/api/fleet/readings' || $uri === '/fleet/readings') && $method === 'POST') {
    $data = getJsonBody();
    $machineId = $data['machineId'] ?? '';
    $entryType = $data['entryType'] ?? '';
    $cumulativeBilled = (int) ($data['cumulativeBilledCount'] ?? 0);
    $bottlesCollected = (int) ($data['bottlesCollected'] ?? 0);
    $cratesCount = (int) ($data['cratesCount'] ?? 0);

    try {
        if ($entryType === 'RECEIVED') {
            $stmt = $pdo->prepare("UPDATE stations SET today_bottles_received = today_bottles_received + ? WHERE station_id = ? OR machine_code = ?");
            $stmt->execute([$cumulativeBilled, $machineId, $machineId]);
        } else {
            $stmt = $pdo->prepare("UPDATE stations SET today_bottles_packed = today_bottles_packed + ?, today_crates_packed = today_crates_packed + ? WHERE station_id = ? OR machine_code = ?");
            $stmt->execute([$bottlesCollected, $cratesCount, $machineId, $machineId]);
        }
        http_response_code(201);
        echo json_encode(['success' => true, 'message' => 'Deposit reading updated in database']);
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(['error' => $e->getMessage()]);
    }
    exit();
}

// 8. Admin Adds Station Location
// POST /api/fleet/station/add
if (($uri === '/api/fleet/station/add' || $uri === '/fleet/station/add') && $method === 'POST') {
    $data = getJsonBody();
    $name = trim($data['name'] ?? '');
    $code = trim($data['code'] ?? '');

    if (empty($name)) {
        http_response_code(400);
        echo json_encode(['error' => 'Station name is required']);
        exit();
    }

    try {
        $countStmt = $pdo->query("SELECT COUNT(*) AS total FROM stations");
        $nextNum = (int) $countStmt->fetch()['total'] + 1;
        $stnId = "STN-" . str_pad($nextNum, 3, "0", STR_PAD_LEFT);
        $stnCode = !empty($code) ? $code : "MCH-NEW-" . str_pad($nextNum, 2, "0", STR_PAD_LEFT);

        $stmt = $pdo->prepare("INSERT INTO stations (station_id, station_name, machine_code, employee_name, is_present, today_bottles_received, today_bottles_packed, today_crates_packed, last_updated_time) VALUES (?, ?, ?, 'Unassigned', FALSE, 0, 0, 0, 'Ready for Shift') ON DUPLICATE KEY UPDATE station_name=VALUES(station_name)");
        $stmt->execute([$stnId, $name, $stnCode]);

        http_response_code(201);
        echo json_encode([
            'success' => true,
            'message' => "Station $name successfully added to fleet",
            'station' => [
                'id' => $stnId,
                'name' => $name,
                'code' => $stnCode
            ]
        ]);
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(['error' => $e->getMessage()]);
    }
    exit();
}

// 9. Truck Gate Pass Loading
// POST /api/logistics/truck-loading
if (($uri === '/api/logistics/truck-loading' || $uri === '/logistics/truck-loading') && $method === 'POST') {
    $data = getJsonBody();
    $loadingId = "TRK-PASS-" . substr((string) time(), 4);
    $stationId = $data['stationId'] ?? '';
    $machineCode = $data['machineCode'] ?? '';
    $employeeId = $data['employeeId'] ?? '';
    $employeeName = $data['employeeName'] ?? '';
    $vendorName = $data['vendorName'] ?? '';
    $packagesCount = (int) ($data['packagesCount'] ?? 1);
    $totalBottlesLoaded = (int) ($data['totalBottlesLoaded'] ?? 0);
    $truckVehicleNumber = $data['truckVehicleNumber'] ?? '';
    $driverName = $data['driverName'] ?? '';
    $driverMobile = $data['driverMobile'] ?? '';
    $timestamp = date('c');

    try {
        $stmt = $pdo->prepare("INSERT INTO truck_dispatches (loading_id, station_id, machine_code, employee_id, employee_name, vendor_name, packages_count, total_bottles_loaded, truck_vehicle_number, driver_name, driver_mobile, status, timestamp) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'GATE_EXIT_AUTHORIZED', ?)");
        $stmt->execute([$loadingId, $stationId, $machineCode, $employeeId, $employeeName, $vendorName, $packagesCount, $totalBottlesLoaded, $truckVehicleNumber, $driverName, $driverMobile, $timestamp]);

        http_response_code(201);
        echo json_encode([
            'success' => true,
            'message' => 'Truck package loading verified and Gate Pass created',
            'gatePass' => [
                'loadingId' => $loadingId,
                'truckVehicleNumber' => $truckVehicleNumber,
                'vendorName' => $vendorName,
                'status' => 'GATE_EXIT_AUTHORIZED'
            ]
        ]);
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(['error' => $e->getMessage()]);
    }
    exit();
}

// 10. Manual Cash Exchange Reconciliation
// POST /api/cash/exchange
if (($uri === '/api/cash/exchange' || $uri === '/cash/exchange') && $method === 'POST') {
    $data = getJsonBody();
    $exchangeId = "EXCH-" . time();
    $stationId = $data['stationId'] ?? '';
    $machineCode = $data['machineCode'] ?? '';
    $employeeId = $data['employeeId'] ?? '';
    $employeeName = $data['employeeName'] ?? '';
    $cashPaid = (float) ($data['cashPaidToCustomer'] ?? 0);
    $bottles = (int) ($data['bottlesCollected'] ?? 0);
    $timestamp = date('c');

    try {
        $stmt = $pdo->prepare("INSERT INTO cash_exchanges (exchange_id, station_id, machine_code, employee_id, employee_name, cash_paid_to_customer, bottles_collected, is_deposited_into_machine, is_digitally_reimbursed, timestamp) VALUES (?, ?, ?, ?, ?, ?, ?, TRUE, FALSE, ?)");
        $stmt->execute([$exchangeId, $stationId, $machineCode, $employeeId, $employeeName, $cashPaid, $bottles, $timestamp]);

        http_response_code(201);
        echo json_encode([
            'success' => true,
            'exchangeId' => $exchangeId
        ]);
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(['error' => $e->getMessage()]);
    }
    exit();
}

// Fallback: 404 Not Found
http_response_code(404);
echo json_encode([
    'error' => 'Endpoint not found',
    'uri' => $uri,
    'method' => $method
]);
