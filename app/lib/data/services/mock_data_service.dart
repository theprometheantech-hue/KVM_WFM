import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/product_model.dart';
import '../models/machine_model.dart';

/// Mock data store for production-grade offline/standalone demo & test runs
class MockDataService {
  static final MockDataService _instance = MockDataService._internal();
  factory MockDataService() => _instance;
  MockDataService._internal() {
    _initDefaults();
  }

  final List<User> employees = [];
  final List<Product> products = [];
  final List<Machine> machines = [];
  final List<Map<String, dynamic>> attendanceLogs = [];
  final List<Map<String, dynamic>> stockLedger = [];
  final List<Map<String, dynamic>> customerTransactions = [];
  final List<Map<String, dynamic>> loadingHistory = [];
  final List<Map<String, dynamic>> unloadingHistory = [];

  void _initDefaults() {
    // 1. Initial users
    employees.addAll([
      const User(
        id: 'usr_001',
        employeeId: 'EMP-ADM-01',
        name: 'Sarah Jenkins',
        email: 'admin@kvm.com',
        mobile: '+1-555-0199',
        role: UserRole.admin,
        designation: 'Operations Director',
        department: 'Operations',
        assignedLocation: 'Central Hub',
      ),
      const User(
        id: 'usr_002',
        employeeId: 'EMP-SUP-02',
        name: 'Marcus Vance',
        email: 'supervisor@kvm.com',
        mobile: '+1-555-0144',
        role: UserRole.supervisor,
        designation: 'Inventory Supervisor',
        department: 'Logistics',
        assignedLocation: 'Downtown Zone',
      ),
      const User(
        id: 'usr_003',
        employeeId: 'EMP-MOP-03',
        name: 'David Zhao',
        email: 'operator@kvm.com',
        mobile: '+1-555-0182',
        role: UserRole.machineOperator,
        designation: 'Field Vending Operator',
        department: 'Field Maintenance',
        assignedLocation: 'Terminal 1 Concourse',
        assignedMachineId: 'MCH-001',
      ),
      const User(
        id: 'usr_004',
        employeeId: 'EMP-EMP-04',
        name: 'Elena Rostova',
        email: 'employee@kvm.com',
        mobile: '+1-555-0133',
        role: UserRole.employee,
        designation: 'Service Representative',
        department: 'Customer Care',
        assignedLocation: 'West Wing Station',
      ),
    ]);

    // 2. Liquor Bottle Products Master
    products.addAll([
      const Product(
        id: 'PRD-01',
        productId: 'PRD-01',
        name: 'Highland Reserve 12Y Single Malt',
        brand: 'Highland',
        barcode: '5010106113125',
        bottleSize: '750ml',
        bottleCategory: 'Premium Glass',
        salePrice: 48.50,
        returnRefundValue: 1.50,
        isEligibleForReturn: true,
      ),
      const Product(
        id: 'PRD-02',
        productId: 'PRD-02',
        name: 'Glacier Blue Ultra Vodka',
        brand: 'Glacier',
        barcode: '7312040017034',
        bottleSize: '750ml',
        bottleCategory: 'Standard Glass',
        salePrice: 28.00,
        returnRefundValue: 1.00,
        isEligibleForReturn: true,
      ),
      const Product(
        id: 'PRD-03',
        productId: 'PRD-03',
        name: 'Oak & Barrel Kentucky Bourbon',
        brand: 'Oak & Barrel',
        barcode: '088004011855',
        bottleSize: '1000ml',
        bottleCategory: 'Heavy Glass',
        salePrice: 36.00,
        returnRefundValue: 2.00,
        isEligibleForReturn: true,
      ),
      const Product(
        id: 'PRD-04',
        productId: 'PRD-04',
        name: 'Botanical London Dry Gin',
        brand: 'Botanical Craft',
        barcode: '5000299223017',
        bottleSize: '700ml',
        bottleCategory: 'Clear Glass',
        salePrice: 32.50,
        returnRefundValue: 1.25,
        isEligibleForReturn: true,
      ),
      const Product(
        id: 'PRD-05',
        productId: 'PRD-05',
        name: 'Canyon Amber Lager 6-Pack Cans',
        brand: 'Canyon Brewery',
        barcode: '018200001680',
        bottleSize: '330ml x 6',
        bottleCategory: 'Aluminum Can',
        salePrice: 14.00,
        returnRefundValue: 0.60,
        isEligibleForReturn: true,
      ),
    ]);

    // 3. Vending / Reverse Vending Machines
    machines.addAll([
      const Machine(
        id: 'MCH-001',
        machineCode: 'MCH-001',
        name: 'Station Alpha - Reverse & Dispense Unit',
        serialNumber: 'RVM-X900-8812',
        location: 'Terminal 1 Concourse',
        maxCapacity: 600,
        currentCapacity: 342,
        status: MachineStatus.active,
        assignedEmployeeIds: ['usr_003'],
      ),
      const Machine(
        id: 'MCH-002',
        machineCode: 'MCH-002',
        name: 'Bay Area Metro Dual Vender',
        serialNumber: 'RVM-X900-9041',
        location: 'Civic Plaza East',
        maxCapacity: 500,
        currentCapacity: 480,
        status: MachineStatus.active,
        assignedEmployeeIds: ['usr_003'],
      ),
      const Machine(
        id: 'MCH-003',
        machineCode: 'MCH-003',
        name: 'Grand Central Return Pod',
        serialNumber: 'RVM-REV-3301',
        location: 'Gate 4 Arrival',
        maxCapacity: 450,
        currentCapacity: 440,
        status: MachineStatus.full,
        assignedEmployeeIds: [],
      ),
      const Machine(
        id: 'MCH-004',
        machineCode: 'MCH-004',
        name: 'Westside Harbor Vender',
        serialNumber: 'RVM-X700-1120',
        location: 'Pier 39 Pavilion',
        maxCapacity: 500,
        currentCapacity: 120,
        status: MachineStatus.maintenance,
        assignedEmployeeIds: [],
      ),
    ]);

    // 4. Initial customer transactions
    customerTransactions.addAll([
      {
        'id': 'TXN-9021',
        'machineId': 'MCH-001',
        'type': 'SALE',
        'productName': 'Highland Reserve 12Y Single Malt',
        'barcode': '5010106113125',
        'quantity': 1,
        'unitPrice': 48.50,
        'totalAmount': 48.50,
        'status': 'SUCCESS',
        'timestamp': DateTime.now().subtract(const Duration(minutes: 45)).toIso8601String(),
      },
      {
        'id': 'TXN-9022',
        'machineId': 'MCH-001',
        'type': 'RETURN',
        'productName': 'Glacier Blue Ultra Vodka',
        'barcode': '7312040017034',
        'quantity': 2,
        'unitPrice': 1.00,
        'totalAmount': 2.00,
        'status': 'ACCEPTED',
        'timestamp': DateTime.now().subtract(const Duration(minutes: 25)).toIso8601String(),
      },
      {
        'id': 'TXN-9023',
        'machineId': 'MCH-002',
        'type': 'RETURN',
        'productName': 'Oak & Barrel Kentucky Bourbon',
        'barcode': '088004011855',
        'quantity': 1,
        'unitPrice': 2.00,
        'totalAmount': 2.00,
        'status': 'ACCEPTED',
        'timestamp': DateTime.now().subtract(const Duration(minutes: 10)).toIso8601String(),
      },
    ]);
  }
}
