-- Schema for Smart Vending & Employee Management System (KVM_WFM)
-- PostgreSQL DDL Script

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. Roles & Users
CREATE TYPE user_role AS ENUM (
    'super_admin',
    'admin',
    'manager',
    'supervisor',
    'machine_operator',
    'employee'
);

CREATE TABLE employees (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_code VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(150) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    mobile VARCHAR(30),
    role user_role NOT NULL DEFAULT 'employee',
    designation VARCHAR(100),
    department VARCHAR(100),
    joining_date DATE DEFAULT CURRENT_DATE,
    assigned_location VARCHAR(150),
    assigned_machine_id VARCHAR(50),
    shift VARCHAR(50) DEFAULT 'Day Shift',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 2. Vending Machines
CREATE TYPE machine_status AS ENUM (
    'active',
    'inactive',
    'offline',
    'maintenance',
    'full'
);

CREATE TABLE vending_machines (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    machine_code VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(150) NOT NULL,
    serial_number VARCHAR(100) UNIQUE NOT NULL,
    location VARCHAR(200) NOT NULL,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    max_capacity INT NOT NULL DEFAULT 500,
    current_capacity INT NOT NULL DEFAULT 0,
    status machine_status NOT NULL DEFAULT 'active',
    last_ping TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_maintenance_date TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 3. Bottle Products Master
CREATE TABLE bottle_products (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_code VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(200) NOT NULL,
    brand VARCHAR(100) NOT NULL,
    barcode VARCHAR(100) UNIQUE NOT NULL,
    bottle_size VARCHAR(50) NOT NULL,
    bottle_category VARCHAR(50) DEFAULT 'Glass Bottle',
    image_url TEXT,
    sale_price DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    return_refund_value DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    is_eligible_for_return BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 4. Attendance Ledger
CREATE TABLE attendance_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID REFERENCES employees(id) ON DELETE CASCADE,
    check_in_time TIMESTAMP WITH TIME ZONE NOT NULL,
    check_out_time TIMESTAMP WITH TIME ZONE,
    attendance_date DATE NOT NULL DEFAULT CURRENT_DATE,
    working_hours DECIMAL(5, 2) DEFAULT 0.00,
    verification_method VARCHAR(50) DEFAULT 'MOBILE_GPS',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 5. Machine Inventory Ledger (Dual-Ledger: For Sale vs Collected Returns)
CREATE TYPE inventory_type AS ENUM ('SALE_STOCK', 'RETURNED_DEPOSIT');

CREATE TABLE machine_inventory (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    machine_id UUID REFERENCES vending_machines(id) ON DELETE CASCADE,
    product_id UUID REFERENCES bottle_products(id) ON DELETE CASCADE,
    inventory_type inventory_type NOT NULL DEFAULT 'SALE_STOCK',
    quantity INT NOT NULL DEFAULT 0,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_machine_product_type UNIQUE (machine_id, product_id, inventory_type)
);

-- 6. Loading Transactions
CREATE TABLE loading_records (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    loading_code VARCHAR(60) UNIQUE NOT NULL,
    employee_id UUID REFERENCES employees(id),
    machine_id UUID REFERENCES vending_machines(id),
    product_id UUID REFERENCES bottle_products(id),
    quantity INT NOT NULL,
    previous_stock INT NOT NULL,
    updated_stock INT NOT NULL,
    remarks TEXT,
    approval_status VARCHAR(30) DEFAULT 'CONFIRMED',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 7. Unloading Transactions
CREATE TABLE unloading_records (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    unloading_code VARCHAR(60) UNIQUE NOT NULL,
    employee_id UUID REFERENCES employees(id),
    machine_id UUID REFERENCES vending_machines(id),
    product_id UUID REFERENCES bottle_products(id),
    quantity INT NOT NULL,
    reason VARCHAR(100) NOT NULL,
    remarks TEXT,
    supervisor_approval_status VARCHAR(30) DEFAULT 'PENDING',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 8. Customer Transactions (Sale / Return)
CREATE TYPE transaction_type AS ENUM ('SALE', 'RETURN');
CREATE TYPE transaction_status AS ENUM ('SUCCESS', 'ACCEPTED', 'REJECTED', 'FAILED');

CREATE TABLE customer_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    transaction_code VARCHAR(60) UNIQUE NOT NULL,
    machine_id UUID REFERENCES vending_machines(id),
    product_id UUID REFERENCES bottle_products(id),
    type transaction_type NOT NULL,
    quantity INT NOT NULL DEFAULT 1,
    unit_amount DECIMAL(10, 2) NOT NULL,
    total_amount DECIMAL(10, 2) NOT NULL,
    status transaction_status NOT NULL,
    rejection_reason VARCHAR(150),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for lightning fast lookups
CREATE INDEX idx_products_barcode ON bottle_products(barcode);
CREATE INDEX idx_transactions_created_at ON customer_transactions(created_at);
CREATE INDEX idx_attendance_date ON attendance_logs(attendance_date);
CREATE INDEX idx_machine_status ON vending_machines(status);

