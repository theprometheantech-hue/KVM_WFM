const express = require('express');
const cors = require('cors');
const PDFDocument = require('pdfkit');
const ExcelJS = require('exceljs');

const app = express();
const PORT = process.env.PORT || 5000;

app.use(cors());
app.use(express.json());

// In-Memory Seed State
let inventory = [
  { barcode: '5010106113125', name: 'Highland Reserve 12Y Single Malt', brand: 'Highland', size: '750ml', salePrice: 48.5, returnDeposit: 1.5, stock: 120 },
  { barcode: '7312040017034', name: 'Glacier Blue Ultra Vodka', brand: 'Glacier', size: '750ml', salePrice: 28.0, returnDeposit: 1.0, stock: 85 },
  { barcode: '088004011855', name: 'Oak & Barrel Kentucky Bourbon', brand: 'Oak & Barrel', size: '1000ml', salePrice: 36.0, returnDeposit: 2.0, stock: 94 },
  { barcode: '5000299223017', name: 'Botanical London Dry Gin', brand: 'Botanical Craft', size: '700ml', salePrice: 32.5, returnDeposit: 1.25, stock: 60 },
  { barcode: '018200001680', name: 'Canyon Amber Lager 6-Pack Cans', brand: 'Canyon Brewery', size: '330ml x 6', salePrice: 14.0, returnDeposit: 0.60, stock: 150 }
];

let machines = [
  { id: 'MCH-001', code: 'MCH-001', name: 'Station Alpha - Reverse & Dispense Unit', serial: 'RVM-X900-8812', location: 'Terminal 1 Concourse', maxCapacity: 600, currentCapacity: 342, status: 'active' },
  { id: 'MCH-002', code: 'MCH-002', name: 'Bay Area Metro Dual Vender', serial: 'RVM-X900-9041', location: 'Civic Plaza East', maxCapacity: 500, currentCapacity: 480, status: 'active' },
  { id: 'MCH-003', code: 'MCH-003', name: 'Grand Central Return Pod', serial: 'RVM-REV-3301', location: 'Gate 4 Arrival', maxCapacity: 450, currentCapacity: 440, status: 'full' },
  { id: 'MCH-004', code: 'MCH-004', name: 'Westside Harbor Vender', serial: 'RVM-X700-1120', location: 'Pier 39 Pavilion', maxCapacity: 500, currentCapacity: 120, status: 'maintenance' }
];

let employees = [
  { id: 'usr_001', employee_id: 'ADMIN-01', name: 'System Administrator', email: 'admin@kvm.com', role: 'admin', designation: 'Operations Director', location: 'HQ' }
];

let transactions = [
  { id: 'TXN-9021', machineId: 'MCH-001', type: 'SALE', productName: 'Highland Reserve 12Y Single Malt', barcode: '5010106113125', quantity: 1, unitPrice: 48.5, totalAmount: 48.5, status: 'SUCCESS', timestamp: new Date(Date.now() - 45 * 60000).toISOString() },
  { id: 'TXN-9022', machineId: 'MCH-001', type: 'RETURN', productName: 'Glacier Blue Ultra Vodka', barcode: '7312040017034', quantity: 2, unitPrice: 1.0, totalAmount: 2.0, status: 'ACCEPTED', timestamp: new Date(Date.now() - 25 * 60000).toISOString() },
  { id: 'TXN-9023', machineId: 'MCH-002', type: 'RETURN', productName: 'Oak & Barrel Kentucky Bourbon', barcode: '088004011855', quantity: 1, unitPrice: 2.0, totalAmount: 2.0, status: 'ACCEPTED', timestamp: new Date(Date.now() - 10 * 60000).toISOString() }
];

let loadingRecords = [];
let unloadingRecords = [];
let attendanceLogs = [];
let machineEvents = [];
let shiftReadings = [];

const registerFleetEndpoints = require('./routes/fleet_routes');
const registerOnboardingAndTruckRoutes = require('./routes/onboarding_routes');

registerFleetEndpoints(app, {
  inventory,
  machines,
  employees,
  transactions,
  loadingRecords,
  unloadingRecords,
  attendanceLogs,
  machineEvents,
  shiftReadings
});

registerOnboardingAndTruckRoutes(app, {
  employees,
  machines
});

const { pool, testConnection } = require('./db/mysql');

// Root Route & Health Check
app.get('/', (req, res) => {
  res.json({
    status: 'ONLINE',
    service: 'KVM Workforce Tracker API',
    subdomain: 'wfm-api.e2s2.in',
    database: process.env.DB_NAME || 'u269575760_WFM',
    timestamp: new Date()
  });
});

app.get('/api/health', (req, res) => {
  res.json({ status: 'UP', service: 'KVM Smart Vending & WFM Backend', timestamp: new Date() });
});

// Auth Endpoint
app.post('/api/auth/login', (req, res) => {
  const { email, password } = req.body;
  if (!email) return res.status(400).json({ error: 'Email required' });

  const found = employees.find(e => e.email.toLowerCase() === email.toLowerCase());
  const user = found || {
    id: `usr_${Date.now()}`,
    employee_id: 'EMP-GEN-01',
    name: 'Operator User',
    email,
    role: 'machine_operator',
    designation: 'Field Tech'
  };

  res.json({
    token: `jwt_token_${Date.now()}`,
    user
  });
});

// Products & Barcode Lookup
app.get('/api/products', (req, res) => res.json(inventory));
app.get('/api/products/lookup/:barcode', (req, res) => {
  const item = inventory.find(p => p.barcode === req.params.barcode);
  if (!item) return res.status(404).json({ error: 'Barcode not found', barcode: req.params.barcode });
  res.json(item);
});

// Machines
app.get('/api/machines', (req, res) => res.json(machines));
app.patch('/api/machines/:id/status', (req, res) => {
  const m = machines.find(m => m.id === req.params.id);
  if (!m) return res.status(404).json({ error: 'Machine not found' });
  if (req.body.status) m.status = req.body.status;
  res.json(m);
});

// Transactions
app.get('/api/transactions', (req, res) => res.json(transactions));
app.post('/api/transactions', (req, res) => {
  const { machineId, type, barcode, quantity } = req.body;
  const item = inventory.find(p => p.barcode === barcode);
  const qty = Number(quantity) || 1;
  const isSale = type === 'SALE';
  const unitPrice = isSale ? (item ? item.salePrice : 20.0) : (item ? item.returnDeposit : 1.0);
  const total = unitPrice * qty;

  const txn = {
    id: `TXN-${Date.now().toString().substring(7)}`,
    machineId: machineId || 'MCH-001',
    type: isSale ? 'SALE' : 'RETURN',
    productName: item ? item.name : 'Unknown Product',
    barcode: barcode || 'N/A',
    quantity: qty,
    unitPrice,
    totalAmount: total,
    status: isSale ? 'SUCCESS' : 'ACCEPTED',
    timestamp: new Date().toISOString()
  };

  transactions.unshift(txn);

  // Update target machine capacity
  const targetMachine = machines.find(m => m.id === machineId);
  if (targetMachine) {
    if (isSale) {
      targetMachine.currentCapacity = Math.max(0, targetMachine.currentCapacity - qty);
    } else {
      targetMachine.currentCapacity = Math.min(targetMachine.maxCapacity, targetMachine.currentCapacity + qty);
      if (targetMachine.currentCapacity >= targetMachine.maxCapacity) {
        targetMachine.status = 'full';
      }
    }
  }

  res.status(201).json(txn);
});

// Loading & Unloading
app.post('/api/loading', (req, res) => {
  const record = { id: `LOAD-${Date.now()}`, ...req.body, timestamp: new Date().toISOString() };
  loadingRecords.unshift(record);
  res.status(201).json(record);
});

app.post('/api/unloading', (req, res) => {
  const record = { id: `UNLOAD-${Date.now()}`, ...req.body, status: 'APPROVED', timestamp: new Date().toISOString() };
  unloadingRecords.unshift(record);
  res.status(201).json(record);
});

// Hardware Event Ingestion (Raspberry Pi, industrial barcode reader, weight sensors)
app.post('/api/hardware/event', (req, res) => {
  const { machineId, eventType, barcode, weightGrams, sensorStatus } = req.body;
  const eventRecord = {
    id: `EVT-${Date.now()}`,
    machineId,
    eventType,
    barcode,
    weightGrams,
    sensorStatus,
    timestamp: new Date().toISOString()
  };
  machineEvents.unshift(eventRecord);

  let responseData = { status: 'RECEIVED', eventId: eventRecord.id };
  if (eventType === 'BOTTLE_INSERTION') {
    const item = inventory.find(p => p.barcode === barcode);
    if (item) {
      responseData.decision = 'ACCEPTED';
      responseData.refundValue = item.returnDeposit;
      responseData.bottleName = item.name;
    } else {
      responseData.decision = 'REJECTED';
      responseData.reason = 'Unrecognized barcode';
    }
  }

  res.json(responseData);
});

// Export PDF Report
app.get('/api/reports/export/pdf', (req, res) => {
  const doc = new PDFDocument({ margin: 50 });
  res.setHeader('Content-Type', 'application/pdf');
  res.setHeader('Content-Disposition', 'attachment; filename=kvm_wfm_audit_report.pdf');

  doc.pipe(res);

  // PDF Header
  doc.fontSize(20).text('Smart Vending & WFM - Audit & Operations Report', { align: 'center' });
  doc.moveDown(0.5);
  doc.fontSize(10).text(`Generated: ${new Date().toLocaleString()}`, { align: 'center' });
  doc.moveDown(1.5);

  // Summary Table
  doc.fontSize(14).text('Operational Metrics Summary', { underline: true });
  doc.moveDown(0.5);
  doc.fontSize(11);
  doc.text(`Total Registered Machines: ${machines.length}`);
  doc.text(`Active Machines: ${machines.filter(m => m.status === 'active').length}`);
  doc.text(`Total Product SKUs in Catalog: ${inventory.length}`);
  doc.text(`Total Transactions Recorded: ${transactions.length}`);

  const totalSales = transactions.filter(t => t.type === 'SALE').reduce((acc, t) => acc + t.totalAmount, 0);
  const totalRefunds = transactions.filter(t => t.type === 'RETURN').reduce((acc, t) => acc + t.totalAmount, 0);
  doc.text(`Total Sales Revenue: $${totalSales.toFixed(2)}`);
  doc.text(`Total Deposit Refunds Disbursed: $${totalRefunds.toFixed(2)}`);
  doc.text(`Net Fleet Yield: $${(totalSales - totalRefunds).toFixed(2)}`);

  doc.moveDown(1.5);
  doc.fontSize(14).text('Recent Transactions Audit Trail', { underline: true });
  doc.moveDown(0.5);

  transactions.forEach((t, i) => {
    doc.fontSize(10).text(
      `${i + 1}. [${t.type}] ID: ${t.id} | Machine: ${t.machineId} | Item: ${t.productName} | Qty: ${t.quantity} | Total: $${t.totalAmount.toFixed(2)}`
    );
  });

  doc.end();
});

// Export Excel Report
app.get('/api/reports/export/excel', async (req, res) => {
  const workbook = new ExcelJS.Workbook();
  const sheet = workbook.addWorksheet('Transactions Audit');

  sheet.columns = [
    { header: 'Transaction ID', key: 'id', width: 16 },
    { header: 'Machine ID', key: 'machineId', width: 14 },
    { header: 'Type', key: 'type', width: 10 },
    { header: 'Product Name', key: 'productName', width: 32 },
    { header: 'Barcode', key: 'barcode', width: 18 },
    { header: 'Quantity', key: 'quantity', width: 10 },
    { header: 'Unit Price ($)', key: 'unitPrice', width: 14 },
    { header: 'Total Amount ($)', key: 'totalAmount', width: 16 },
    { header: 'Status', key: 'status', width: 12 },
    { header: 'Timestamp', key: 'timestamp', width: 24 }
  ];

  transactions.forEach(t => sheet.addRow(t));

  res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
  res.setHeader('Content-Disposition', 'attachment; filename=kvm_wfm_transactions.xlsx');

  await workbook.xlsx.write(res);
  res.end();
});

app.listen(PORT, async () => {
  console.log(`[KVM_WFM Backend] Running on http://localhost:${PORT}`);
  await testConnection();
});
