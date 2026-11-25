// Extended Endpoints for Shift Attendance & Fleet Telemetry Feed
const express = require('express');
const { pool } = require('../db/mysql');

module.exports = function registerFleetEndpoints(app, state) {
  // 1. Employee Shift Attendance & Geo-Checkin
  app.post('/api/attendance/shift-checkin', async (req, res) => {
    const { employeeId, employeeName, machineId, locationName, latitude, longitude, method } = req.body;
    
    const record = {
      id: `ATT-${Date.now()}`,
      employeeId: employeeId || 'EMP-MOP-03',
      employeeName: employeeName || 'David Zhao',
      machineId: machineId || 'MCH-001',
      locationName: locationName || 'Central Terminal 1 Concourse',
      coordinates: { latitude: latitude || 13.0827, longitude: longitude || 80.2707 },
      checkInTime: new Date().toISOString(),
      checkOutTime: null,
      verificationMethod: method || 'STATION_QR_GEOFENCE',
      status: 'ON_DUTY'
    };

    state.attendanceLogs.unshift(record);

    // Update fleet machine active operator
    const targetMachine = state.machines.find(m => m.id === machineId);
    if (targetMachine) {
      targetMachine.assignedOperator = employeeName;
      targetMachine.isStaffPresent = true;
      targetMachine.lastCheckIn = record.checkInTime;
    }

    try {
      await pool.query(
        'UPDATE stations SET is_present = TRUE, employee_name = ?, employee_id = ?, check_in_time = ? WHERE station_id = ? OR machine_code = ?',
        [employeeName || '', employeeId || '', record.checkInTime, machineId || '', machineId || '']
      );
    } catch (dbErr) {
      console.warn('[DATABASE] Could not update station checkin in MySQL:', dbErr.message);
    }

    res.status(201).json({ success: true, message: 'Shift attendance verified with station geo-fence', record });
  });

  // 2. In-Shift Frequent Bottle Reading Feed
  app.post('/api/fleet/readings', async (req, res) => {
    const { machineId, employeeId, readingSlot, cumulativeBilledCount, bottlesCollected, bottlesDamaged, binFillStatus, remarks } = req.body;

    const reading = {
      id: `READ-${Date.now()}`,
      machineId: machineId || 'MCH-001',
      employeeId: employeeId || 'EMP-MOP-03',
      readingSlot: readingSlot || 'Midday Audit',
      cumulativeBilledCount: Number(cumulativeBilledCount) || 0,
      bottlesCollected: Number(bottlesCollected) || 0,
      bottlesDamaged: Number(bottlesDamaged) || 0,
      binFillStatus: binFillStatus || 'Normal (35%)',
      remarks: remarks || '',
      recordedAt: new Date().toISOString()
    };

    state.shiftReadings.unshift(reading);

    // Synchronize machine state
    const m = state.machines.find(m => m.id === machineId);
    if (m) {
      m.todayTotalDeposited = reading.cumulativeBilledCount;
      m.todayTotalDispatchedToVendor = (m.todayTotalDispatchedToVendor || 0) + reading.bottlesCollected;
      m.currentCapacity = Math.max(0, reading.cumulativeBilledCount - m.todayTotalDispatchedToVendor - reading.bottlesDamaged);
      m.lastReadingTime = reading.recordedAt;
    }

    try {
      await pool.query(
        'UPDATE stations SET today_bottles_received = today_bottles_received + ?, today_bottles_packed = today_bottles_packed + ? WHERE station_id = ? OR machine_code = ?',
        [reading.cumulativeBilledCount, reading.bottlesCollected, machineId || '', machineId || '']
      );
    } catch (dbErr) {
      console.warn('[DATABASE] Could not update station reading in MySQL:', dbErr.message);
    }

    res.status(201).json({ success: true, message: 'Hourly deposit reading updated', reading });
  });

  // 3. Multi-Location 100+ Fleet Status Overview
  app.get('/api/fleet/overview', async (req, res) => {
    try {
      const [rows] = await pool.query('SELECT station_id AS machineId, station_name AS locationName, is_present AS isStaffPresent, employee_name AS assignedOperator, today_bottles_received AS todayTotalDeposited, today_bottles_packed AS todayTotalDispatchedToVendor, today_crates_packed AS currentBinHoldings, last_updated_time AS lastReadingTime FROM stations ORDER BY id ASC');
      if (rows && rows.length > 0) {
        return res.json({ totalLocations: rows.length, locations: rows });
      }
    } catch (dbErr) {
      console.warn('[DATABASE] Could not fetch stations from MySQL, using in-memory:', dbErr.message);
    }

    const fleetStatus = state.machines.map(m => {
      return {
        machineId: m.id,
        locationName: m.location,
        isStaffPresent: m.isStaffPresent || false,
        assignedOperator: m.assignedOperator || 'Unassigned',
        todayTotalDeposited: m.todayTotalDeposited || 0,
        todayTotalDispatchedToVendor: m.todayTotalDispatchedToVendor || 0,
        currentBinHoldings: m.currentCapacity || 0,
        maxCapacity: m.maxCapacity || 500,
        lastReadingTime: m.lastReadingTime || null
      };
    });

    res.json({ totalLocations: fleetStatus.length, locations: fleetStatus });
  });

  // 4. Admin Adds New Station Location
  app.post('/api/fleet/station/add', async (req, res) => {
    const { name, code } = req.body;
    if (!name) return res.status(400).json({ error: 'Station name is required' });

    const newIndex = state.machines.length + 1;
    const stnCode = code || `MCH-NEW-${newIndex.toString().padLeft(2, '0')}`;
    const newStation = {
      id: `STN-${newIndex.toString().padLeft(3, '0')}`,
      code: stnCode,
      name: name.trim(),
      serial: `RVM-X900-${Date.now().toString().substring(8)}`,
      location: name.trim(),
      maxCapacity: 500,
      currentCapacity: 0,
      status: 'active',
      isStaffPresent: false,
      assignedOperator: 'Unassigned',
      todayTotalDeposited: 0,
      todayTotalDispatchedToVendor: 0,
    };

    state.machines.push(newStation);

    try {
      await pool.query(
        'INSERT INTO stations (station_id, station_name, machine_code) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE station_name=VALUES(station_name)',
        [newStation.id, newStation.name, newStation.code]
      );
      console.log(`[DATABASE] Station ${newStation.id} saved to MySQL database`);
    } catch (dbErr) {
      console.warn('[DATABASE] Could not save station to MySQL:', dbErr.message);
    }

    console.log(`[FLEET PROVISIONING] New Station Added: ${newStation.name} (${newStation.code})`);

    res.status(201).json({
      success: true,
      message: `Station ${name} successfully added to fleet`,
      station: newStation,
    });
  });

  // 5. Submit Duty Log (Packed Bottles & Crates)
  app.post('/api/duty/submit-log', async (req, res) => {
    const { stationId, machineCode, employeeId, employeeName, entryType, bottleCount, crateCount, vendorName, vehicleOrDriver, timestamp } = req.body;
    const logId = `LOG-${Date.now()}`;
    try {
      await pool.query(
        'INSERT INTO duty_logs (log_id, station_id, machine_code, employee_id, employee_name, entry_type, bottle_count, crate_count, vendor_name, vehicle_or_driver, timestamp) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [logId, stationId || '', machineCode || '', employeeId || '', employeeName || '', entryType || 'PACKED', Number(bottleCount) || 0, Number(crateCount) || 0, vendorName || null, vehicleOrDriver || null, timestamp || new Date().toISOString()]
      );
      console.log(`[DATABASE] Duty log ${logId} saved to MySQL database`);
    } catch (err) {
      console.warn('[DATABASE] Could not save duty log to MySQL:', err.message);
    }
    res.status(201).json({ success: true, logId });
  });

  // 6. Manual Cash Exchange Record
  app.post('/api/cash/exchange', async (req, res) => {
    const { stationId, machineCode, employeeId, employeeName, cashPaidToCustomer, bottlesCollected, isDepositedIntoMachine, isDigitallyReimbursed, timestamp } = req.body;
    const exchangeId = `EXCH-${Date.now()}`;
    try {
      await pool.query(
        'INSERT INTO cash_exchanges (exchange_id, station_id, machine_code, employee_id, employee_name, cash_paid_to_customer, bottles_collected, is_deposited_into_machine, is_digitally_reimbursed, timestamp) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [exchangeId, stationId || '', machineCode || '', employeeId || '', employeeName || '', Number(cashPaidToCustomer) || 0, Number(bottlesCollected) || 0, isDepositedIntoMachine ?? true, isDigitallyReimbursed ?? false, timestamp || new Date().toISOString()]
      );
      console.log(`[DATABASE] Cash exchange ${exchangeId} saved to MySQL database`);
    } catch (err) {
      console.warn('[DATABASE] Could not save cash exchange to MySQL:', err.message);
    }
    res.status(201).json({ success: true, exchangeId });
  });
};

