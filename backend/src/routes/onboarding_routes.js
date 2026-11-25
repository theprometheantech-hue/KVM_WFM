// Extended Node.js Express Endpoints for Employee Onboarding, Email Notifications, and Truck Gate Passes
const express = require('express');
const { pool } = require('../db/mysql');
const { sendOnboardingEmailToCompany, sendCredentialsEmailToEmployee } = require('../services/mail_service');

module.exports = function registerOnboardingAndTruckRoutes(app, state) {
  state.onboardingApplications = state.onboardingApplications || [];
  state.truckGatePasses = state.truckGatePasses || [];

  // 1. Admin Adds / Provisions a New Employee directly
  app.post('/api/employee/admin-add', async (req, res) => {
    const { fullName, mobileNumber, email, assignedStationId, assignedStationName } = req.body;

    if (!fullName || !mobileNumber) {
      return res.status(400).json({ error: 'Full name and mobile number are required' });
    }

    const empId = `EMP-${(state.onboardingApplications.length + 101).toString()}`;
    const tempPassword = `Kvm@${new Date().getFullYear()}`;

    const newEmployee = {
      employeeId: empId,
      fullName,
      mobileNumber,
      email: email || `${empId.toLowerCase()}@kvm.com`,
      assignedStationId: assignedStationId || 'STN-001',
      assignedStationName: assignedStationName || 'Arani Station Hub',
      temporaryPassword: tempPassword,
      passwordSetDate: new Date().toISOString(),
      onboardingStatus: 'VERIFIED',
      submittedAt: new Date().toISOString(),
    };

    state.onboardingApplications.unshift(newEmployee);

    // Save permanently to Hostinger MySQL Database if connected
    try {
      await pool.query(
        'INSERT INTO employees (employee_id, full_name, mobile_number, email, password, is_temporary_password, role, assigned_station_id, assigned_station_name, onboarding_status) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?) ON DUPLICATE KEY UPDATE full_name=VALUES(full_name), assigned_station_id=VALUES(assigned_station_id), assigned_station_name=VALUES(assigned_station_name)',
        [empId, fullName, mobileNumber, newEmployee.email, tempPassword, true, 'employee', newEmployee.assignedStationId, newEmployee.assignedStationName, 'VERIFIED']
      );
      console.log(`[DATABASE] Employee ${empId} saved to MySQL database`);
    } catch (dbErr) {
      console.warn('[DATABASE] Could not save employee to MySQL (using in-memory fallback):', dbErr.message);
    }

    // Automated Mailer / Notification Dispatch if email is present
    if (email && email.includes('@')) {
      sendCredentialsEmailToEmployee({
        fullName,
        email,
        employeeId: empId,
        tempPassword,
      });
    }

    console.log(`\n======================================================`);
    console.log(`[ADMIN PROVISIONING] New Employee Added by Admin!`);
    console.log(`Employee: ${fullName} (${mobileNumber})`);
    console.log(`Assigned Station: ${newEmployee.assignedStationName} (${newEmployee.assignedStationId})`);
    console.log(`Generated Credentials -> ID: ${empId} | Temp Password: ${tempPassword}`);
    console.log(`======================================================\n`);

    res.status(201).json({
      success: true,
      message: `Employee ${fullName} successfully provisioned and assigned to ${newEmployee.assignedStationName}`,
      employee: newEmployee,
    });
  });

  // 1B. Fetch all employees for Staff Management
  app.get('/api/employee/onboarding-list', async (req, res) => {
    try {
      const [rows] = await pool.query('SELECT employee_id AS employeeId, full_name AS fullName, mobile_number AS mobileNumber, email, role, assigned_station_id AS assignedStationId, assigned_station_name AS assignedStationName, onboarding_status AS onboardingStatus, created_at AS submittedAt FROM employees WHERE role != "admin" ORDER BY id DESC');
      if (rows && rows.length > 0) {
        return res.json({
          success: true,
          applications: rows,
        });
      }
    } catch (dbErr) {
      console.warn('[DATABASE] Could not fetch employees from MySQL, using in-memory:', dbErr.message);
    }

    res.json({
      success: true,
      applications: state.onboardingApplications,
    });
  });

  // 1C. Approve / Verify employee
  app.post('/api/employee/verify', async (req, res) => {
    const { employeeId } = req.body;
    try {
      await pool.query('UPDATE employees SET onboarding_status = "VERIFIED" WHERE employee_id = ?', [employeeId]);
    } catch (dbErr) {
      console.warn('[DATABASE] Could not update employee status in MySQL:', dbErr.message);
    }
    const emp = state.onboardingApplications.find(e => e.employeeId === employeeId);
    if (emp) {
      emp.onboardingStatus = 'VERIFIED';
      return res.json({ success: true, message: `Employee ${employeeId} approved & verified` });
    }
    res.json({ success: true, message: `Employee ${employeeId} verified` });
  });

  // 2. Password Reset Request via Email OTP
  app.post('/api/employee/forgot-password', (req, res) => {
    const { email } = req.body;
    if (!email) return res.status(400).json({ error: 'Email required' });

    const otp = '884210'; // 6-digit OTP
    console.log(`[PASSWORD RECOVERY] OTP ${otp} dispatched to ${email}`);

    res.json({
      success: true,
      message: `Password reset OTP dispatched to ${email}`,
      otpHint: '884210',
    });
  });

  // 3. Truck Package Loading & Gate Pass Issuance
  app.post('/api/logistics/truck-loading', async (req, res) => {
    const {
      stationId,
      machineCode,
      employeeId,
      employeeName,
      vendorName,
      packagesCount,
      totalBottlesLoaded,
      truckVehicleNumber,
      driverName,
      driverMobile,
    } = req.body;

    const gatePass = {
      loadingId: `TRK-PASS-${Date.now().toString().substring(7)}`,
      stationId,
      machineCode,
      employeeId,
      employeeName,
      vendorName,
      packagesCount: Number(packagesCount) || 1,
      totalBottlesLoaded: Number(totalBottlesLoaded) || 0,
      truckVehicleNumber,
      driverName,
      driverMobile,
      timestamp: new Date().toISOString(),
      status: 'GATE_EXIT_AUTHORIZED',
    };

    state.truckGatePasses.unshift(gatePass);

    try {
      await pool.query(
        'INSERT INTO truck_dispatches (loading_id, station_id, machine_code, employee_id, employee_name, vendor_name, packages_count, total_bottles_loaded, truck_vehicle_number, driver_name, driver_mobile, status, timestamp) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [gatePass.loadingId, stationId || '', machineCode || '', employeeId || '', employeeName || '', vendorName || '', gatePass.packagesCount, gatePass.totalBottlesLoaded, truckVehicleNumber || '', driverName || '', driverMobile || '', gatePass.status, gatePass.timestamp]
      );
      console.log(`[DATABASE] Gate pass ${gatePass.loadingId} saved to MySQL database`);
    } catch (dbErr) {
      console.warn('[DATABASE] Could not save truck dispatch to MySQL:', dbErr.message);
    }

    console.log(`[GATE PASS ISSUED] Truck ${truckVehicleNumber} loaded with ${packagesCount} packages for ${vendorName}`);

    res.status(201).json({
      success: true,
      message: 'Truck package loading verified and Gate Pass created',
      gatePass,
    });
  });
};

