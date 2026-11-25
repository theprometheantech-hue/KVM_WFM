-- KVM Workforce Tracker & Reverse Vending Machine Database Schema
-- Database: u269575760_WFM
-- Target Server: Hostinger MySQL (srv669.hstgr.io)

-- 1. Employees Table
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

-- 2. Stations Fleet Table
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
    checkin_latitude DECIMAL(10, 8) DEFAULT NULL,
    checkin_longitude DECIMAL(11, 8) DEFAULT NULL,
    checkin_address TEXT DEFAULT NULL,
    address TEXT DEFAULT NULL,
    bin_capacity INT DEFAULT 500,
    last_updated_time VARCHAR(100) DEFAULT 'Ready for Shift',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. Daily Duty Logs Table
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

-- 4. Manual Cash Exchange Reconciliation Table
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

-- 5. Truck Dispatches & Gate Passes Table
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

-- Seed Initial Administrator Account
INSERT INTO employees (employee_id, full_name, mobile_number, email, password, is_temporary_password, role)
VALUES ('ADMIN-01', 'System Administrator', '9999999999', 'admin@kvm.com', 'Password123', FALSE, 'admin')
ON DUPLICATE KEY UPDATE full_name=VALUES(full_name);

-- Seed Initial Stations (Stations 1 to 12 - Tamil Nadu Regional Vending Fleet)
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
