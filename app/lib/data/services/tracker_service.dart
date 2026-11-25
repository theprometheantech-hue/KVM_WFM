import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/duty_log_model.dart';
import '../models/duty_feed_entry.dart';
import '../models/onboarding_model.dart';
import '../models/cash_exchange_model.dart';
import 'api_service.dart';

class TrackerService extends ChangeNotifier {
  static final TrackerService _instance = TrackerService._internal();
  factory TrackerService() => _instance;
  TrackerService._internal() {
    _initStationsAndStaff();
    loadSavedCredentials();
    loadSavedStationOverrides();
    syncWithCloud();
  }

  Future<void> loadSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (int i = 0; i < registeredEmployees.length; i++) {
        final emp = registeredEmployees[i];
        final savedPass = prefs.getString('emp_password_${emp.employeeId}');
        final isTemp = prefs.getBool('emp_is_temp_${emp.employeeId}');
        if (savedPass != null && isTemp != null) {
          registeredEmployees[i] = emp.copyWith(
            password: savedPass,
            isTemporaryPassword: isTemp,
          );
        }
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> loadSavedStationOverrides() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final editedIds = prefs.getStringList('edited_station_ids') ?? [];
      for (final id in editedIds) {
        final stnIdx = stations.indexWhere((s) => s.stationId == id);
        final savedName = prefs.getString('stn_name_$id');
        final savedCode = prefs.getString('stn_code_$id');
        final savedAddr = prefs.getString('stn_addr_$id');
        final savedEmpId = prefs.getString('stn_emp_id_$id');
        final savedEmpName = prefs.getString('stn_emp_name_$id');

        if (stnIdx != -1) {
          stations[stnIdx] = stations[stnIdx].copyWith(
            stationName: savedName ?? stations[stnIdx].stationName,
            machineCode: savedCode ?? stations[stnIdx].machineCode,
            address: savedAddr ?? stations[stnIdx].address,
            employeeId: savedEmpId ?? stations[stnIdx].employeeId,
            employeeName: savedEmpName ?? stations[stnIdx].employeeName,
          );
        }
      }
      notifyListeners();
    } catch (_) {}
  }

  // ==========================================
  // Session Persistence & Auto-Login
  // ==========================================
  Future<void> saveLoginSession({
    required String role,
    required String userId,
    required String userName,
    String? stationId,
    bool rememberId = true,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('auth_is_logged_in', true);
      await prefs.setString('auth_role', role);
      await prefs.setString('auth_user_id', userId);
      await prefs.setString('auth_user_name', userName);
      if (stationId != null && stationId.isNotEmpty) {
        await prefs.setString('auth_station_id', stationId);
      }
      if (rememberId) {
        await prefs.setString('saved_login_id', userId);
      }
      currentRole = role;
      activeEmployeeId = userId;
      activeEmployeeName = userName;
      if (stationId != null && stationId.isNotEmpty) {
        activeStationId = stationId;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('[TrackerService] saveLoginSession error: $e');
    }
  }

  Future<void> clearLoginSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('auth_is_logged_in', false);
      await prefs.remove('auth_role');
      await prefs.remove('auth_user_id');
      await prefs.remove('auth_user_name');
      await prefs.remove('auth_station_id');
      currentRole = 'supervisor';
      activeEmployeeId = '';
      activeEmployeeName = '';
      notifyListeners();
    } catch (e) {
      debugPrint('[TrackerService] clearLoginSession error: $e');
    }
  }

  Future<Map<String, dynamic>?> getActiveSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('auth_is_logged_in') ?? false;
      if (!isLoggedIn) return null;

      final role = prefs.getString('auth_role');
      final userId = prefs.getString('auth_user_id');
      final userName = prefs.getString('auth_user_name');
      final stationId = prefs.getString('auth_station_id');

      if (role != null && userId != null) {
        currentRole = role;
        activeEmployeeId = userId;
        activeEmployeeName = userName ?? (role == 'supervisor' ? 'System Administrator' : 'Operator');
        if (stationId != null && stationId.isNotEmpty) {
          activeStationId = stationId;
        }
        notifyListeners();
        return {
          'role': role,
          'userId': userId,
          'userName': userName,
          'stationId': stationId,
        };
      }
    } catch (e) {
      debugPrint('[TrackerService] getActiveSession error: $e');
    }
    return null;
  }

  Future<String?> getSavedLoginId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('saved_login_id');
    } catch (_) {
      return null;
    }
  }

  Future<void> syncWithCloud() async {
    try {
      // 1. Fetch live fleet stations from Hostinger MySQL
      final liveStations = await ApiService.fetchLiveFleet();
      if (liveStations != null && liveStations.isNotEmpty) {
        stations.clear();
        stations.addAll(liveStations);

        // Preserve active logged-in employee session identity across background sync
        if (activeEmployeeName.isNotEmpty && activeStationId.isNotEmpty) {
          final activeIdx = stations.indexWhere((s) => s.stationId == activeStationId);
          if (activeIdx != -1) {
            stations[activeIdx] = stations[activeIdx].copyWith(
              employeeName: activeEmployeeName,
              employeeId: activeEmployeeId,
            );
          }
        }

        // Apply local saved station overrides and cumulative bottle counts so server sync NEVER overwrites user updates
        try {
          final prefs = await SharedPreferences.getInstance();
          final editedIds = prefs.getStringList('edited_station_ids') ?? [];
          for (final id in editedIds) {
            final stnIdx = stations.indexWhere((s) => s.stationId == id);
            if (stnIdx != -1) {
              final savedName = prefs.getString('stn_name_$id');
              final savedCode = prefs.getString('stn_code_$id');
              final savedAddr = prefs.getString('stn_addr_$id');
              final savedEmpId = prefs.getString('stn_emp_id_$id');
              final savedEmpName = prefs.getString('stn_emp_name_$id');

              stations[stnIdx] = stations[stnIdx].copyWith(
                stationName: savedName ?? stations[stnIdx].stationName,
                machineCode: savedCode ?? stations[stnIdx].machineCode,
                address: savedAddr ?? stations[stnIdx].address,
                employeeId: savedEmpId ?? stations[stnIdx].employeeId,
                employeeName: savedEmpName ?? stations[stnIdx].employeeName,
              );
            }
          }

          // Merge local cumulative bottle counts (preserves employee entries if server hasn't updated yet)
          for (int i = 0; i < stations.length; i++) {
            final stnId = stations[i].stationId;
            final localRecv = prefs.getInt('stn_recv_$stnId') ?? 0;
            final localPack = prefs.getInt('stn_pack_$stnId') ?? 0;
            final localCrates = prefs.getInt('stn_crates_$stnId') ?? 0;

            final effectiveRecv = localRecv > stations[i].todayBottlesReceived ? localRecv : stations[i].todayBottlesReceived;
            final effectivePack = localPack > stations[i].todayBottlesPacked ? localPack : stations[i].todayBottlesPacked;
            final effectiveCrates = localCrates > stations[i].todayCratesPacked ? localCrates : stations[i].todayCratesPacked;

            if (effectiveRecv != stations[i].todayBottlesReceived ||
                effectivePack != stations[i].todayBottlesPacked ||
                effectiveCrates != stations[i].todayCratesPacked) {
              stations[i] = stations[i].copyWith(
                todayBottlesReceived: effectiveRecv,
                todayBottlesPacked: effectivePack,
                todayCratesPacked: effectiveCrates,
              );
            }
          }
        } catch (_) {}
      }

      // 2. Fetch live employees from Hostinger MySQL
      final apps = await ApiService.fetchOnboardingApplications();
      if (apps != null) {
        final prefs = await SharedPreferences.getInstance();
        for (final app in apps) {
          final empId = app['employeeId'] ?? '';
          if (empId.isEmpty || empId == 'ADMIN-01') continue;
          final existingIdx = registeredEmployees.indexWhere((e) => e.employeeId == empId);

          // Check if permanent password was set locally or in database
          final localSavedPass = prefs.getString('emp_password_$empId');
          final localIsTemp = prefs.getBool('emp_is_temp_$empId');

          bool isTemp = true;
          if (localIsTemp != null) {
            isTemp = localIsTemp;
          } else if (app['isTemporaryPassword'] != null) {
            final val = app['isTemporaryPassword'];
            isTemp = val == 1 || val == true || val == '1';
          } else if (existingIdx != -1) {
            isTemp = registeredEmployees[existingIdx].isTemporaryPassword;
          }

          String effectivePassword = app['password'] ?? app['temporaryPassword'] ?? 'Kvm@2026';
          if (localSavedPass != null && localSavedPass.isNotEmpty) {
            effectivePassword = localSavedPass;
          } else if (existingIdx != -1 && !registeredEmployees[existingIdx].isTemporaryPassword) {
            effectivePassword = registeredEmployees[existingIdx].password;
          }

          final regEmp = RegisteredEmployee(
            employeeId: empId,
            fullName: app['fullName'] ?? 'Staff',
            mobileNumber: app['mobileNumber'] ?? '',
            email: app['email'] ?? '',
            assignedStationId: app['assignedStationId'] ?? 'STN-001',
            assignedStationName: app['assignedStationName'] ?? 'Assigned Station',
            password: effectivePassword,
            isTemporaryPassword: isTemp,
            passwordSetDate: DateTime.now(),
            submittedDocuments: const [],
            onboardingStatus: app['onboardingStatus'] ?? 'VERIFIED',
            registeredAt: DateTime.tryParse(app['submittedAt'] ?? '') ?? DateTime.now(),
          );
          if (existingIdx != -1) {
            registeredEmployees[existingIdx] = regEmp;
          } else {
            registeredEmployees.insert(0, regEmp);
          }
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('[TrackerService] syncWithCloud error: $e');
    }
  }

  String currentRole = 'supervisor';
  String activeEmployeeName = '';
  String activeEmployeeId = '';
  String activeStationId = 'STN-001';

  final List<StationDutyLog> stations = [];
  final List<DailyDutyLogEntry> recentDutyLogs = [];
  final List<RegisteredEmployee> registeredEmployees = [];
  final List<TruckLoadingRecord> truckDispatches = [];
  final List<ManualCashExchangeRecord> cashExchanges = [];

  // Working Locations List
  final List<String> operationalLocations = [
    'Arani',
    'Chengam',
    'Chetpet',
    'Cheyyar',
    'Vannamkulam',
    'Devikapuram',
    'Jamunamarathur',
    'Kalambur',
    'Kalasapakkam',
    'Kannamangalam',
    'Polur',
    'Santhavasal',
  ];

  void _initStationsAndStaff() {
    // 1. Initial Admin Account (No demo employees)
    registeredEmployees.add(
      RegisteredEmployee(
        employeeId: 'ADMIN-01',
        fullName: 'System Administrator',
        mobileNumber: '9999999999',
        email: 'admin@kvm.com',
        password: 'Password123',
        isTemporaryPassword: false,
        passwordSetDate: DateTime.now(),
        onboardingStatus: 'VERIFIED',
        registeredAt: DateTime.now(),
      ),
    );

    // 2. Real Operational Stations in your specific Tamil Nadu / Tiruvannamalai region (all starting clean as Unassigned)
    final regionalLocations = [
      {'name': 'Arani Station Hub', 'code': 'MCH-ARN-01'},
      {'name': 'Chengam Town Station', 'code': 'MCH-CGM-01'},
      {'name': 'Chetpet Main Bus Stand', 'code': 'MCH-CPT-01'},
      {'name': 'Cheyyar SIPCOT Point', 'code': 'MCH-CYR-01'},
      {'name': 'Vannamkulam Junction Kiosk', 'code': 'MCH-VKL-01'},
      {'name': 'Devikapuram Temple Road', 'code': 'MCH-DVK-01'},
      {'name': 'Jamunamarathur Hills Depot', 'code': 'MCH-JMM-01'},
      {'name': 'Kalambur Market Yard', 'code': 'MCH-KLM-01'},
      {'name': 'Kalasapakkam Block Station', 'code': 'MCH-KLS-01'},
      {'name': 'Kannamangalam Bazaar Center', 'code': 'MCH-KMG-01'},
      {'name': 'Polur Town Bus Stand', 'code': 'MCH-PLR-01'},
      {'name': 'Santhavasal Forest Gate', 'code': 'MCH-STV-01'},
    ];

    for (int i = 0; i < regionalLocations.length; i++) {
      final loc = regionalLocations[i];
      final stnId = 'STN-${(i + 1).toString().padLeft(3, '0')}';

      stations.add(
        StationDutyLog(
          stationId: stnId,
          stationName: loc['name'] as String,
          machineCode: loc['code'] as String,
          employeeName: 'Unassigned',
          employeeId: '',
          isPresent: false,
          checkInTime: null,
          todayBottlesReceived: 0,
          todayBottlesPacked: 0,
          todayCratesPacked: 0,
          lastUpdatedTime: 'Ready for Shift',
        ),
      );
    }
  }

  StationDutyLog get activeStation {
    return stations.firstWhere(
      (s) => s.stationId == activeStationId,
      orElse: () => stations.first,
    );
  }

  void switchActiveStation(String stationId) {
    activeStationId = stationId;
    // Synchronize station employee name with logged-in employee if assigned
    final idx = stations.indexWhere((s) => s.stationId == stationId);
    if (idx != -1 && activeEmployeeName.isNotEmpty) {
      final current = stations[idx];
      stations[idx] = current.copyWith(
        employeeName: activeEmployeeName,
        employeeId: activeEmployeeId,
      );
    }
    notifyListeners();
  }

  void assignEmployeeToStation({required String empId, required String empName, required String stationId}) {
    activeEmployeeId = empId;
    activeEmployeeName = empName;
    activeStationId = stationId;

    final idx = stations.indexWhere((s) => s.stationId == stationId);
    if (idx != -1) {
      final current = stations[idx];
      stations[idx] = current.copyWith(
        employeeName: empName,
        employeeId: empId,
      );
    }

    // Bidirectional sync: also update the employee in registeredEmployees
    final empIdx = registeredEmployees.indexWhere((e) => e.employeeId == empId);
    if (empIdx != -1) {
      final stnName = idx != -1 ? stations[idx].stationName : 'Assigned Station';
      registeredEmployees[empIdx] = registeredEmployees[empIdx].copyWith(
        assignedStationId: stationId,
        assignedStationName: stnName,
      );
    }
    notifyListeners();
  }

  RegisteredEmployee? findEmployeeByLogin(String identifier, String password) {
    try {
      return registeredEmployees.firstWhere((e) =>
          (e.employeeId.toLowerCase() == identifier.trim().toLowerCase() ||
           e.email.toLowerCase() == identifier.trim().toLowerCase() ||
           e.mobileNumber.replaceAll(' ', '') == identifier.replaceAll(' ', '')) &&
          e.password == password);
    } catch (_) {
      return null;
    }
  }

  RegisteredEmployee? findEmployeeByEmail(String email) {
    try {
      return registeredEmployees.firstWhere((e) => e.email.toLowerCase() == email.trim().toLowerCase());
    } catch (_) {
      return null;
    }
  }

  void registerNewEmployee(RegisteredEmployee emp) {
    registeredEmployees.insert(0, emp);
    notifyListeners();
  }

  StationDutyLog addNewStationLocation({
    required String locationName,
    String? machineCode,
  }) {
    final newIndex = stations.length + 1;
    final stnId = 'STN-${newIndex.toString().padLeft(3, '0')}';
    
    // Auto-generate machine code if not provided (e.g. MCH-LOC-01)
    String code = machineCode?.trim() ?? '';
    if (code.isEmpty) {
      final words = locationName.trim().split(RegExp(r'\s+'));
      final prefix = words.first.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
      final shortPrefix = prefix.length >= 3 ? prefix.substring(0, 3) : prefix.padRight(3, 'X');
      code = 'MCH-$shortPrefix-01';
    }

    final newStation = StationDutyLog(
      stationId: stnId,
      stationName: locationName.trim(),
      machineCode: code,
      employeeName: 'Unassigned',
      employeeId: '',
      isPresent: false,
      checkInTime: null,
      todayBottlesReceived: 0,
      todayBottlesPacked: 0,
      todayCratesPacked: 0,
      lastUpdatedTime: 'New Station Added',
    );

    stations.add(newStation);
    if (!operationalLocations.contains(locationName.trim())) {
      operationalLocations.add(locationName.trim());
    }
    notifyListeners();
    return newStation;
  }

  Future<bool> deleteStation(String stationId) async {
    final success = await ApiService.deleteStation(stationId);
    stations.removeWhere((s) => s.stationId == stationId);
    for (int i = 0; i < registeredEmployees.length; i++) {
      if (registeredEmployees[i].assignedStationId == stationId) {
        registeredEmployees[i] = registeredEmployees[i].copyWith(
          assignedStationId: null,
          assignedStationName: 'Unassigned',
        );
      }
    }
    notifyListeners();
    return success;
  }

  RegisteredEmployee addEmployeeByAdmin({
    required String fullName,
    required String mobileNumber,
    required String email,
    required String assignedStationId,
    required String assignedStationName,
    String? machineCode,
    String? address,
  }) {
    // Generate clean sequential EMP ID: e.g. EMP-101, EMP-102
    final empCount = registeredEmployees.where((e) => e.employeeId.startsWith('EMP-')).length;
    final generatedId = 'EMP-${(101 + empCount).toString()}';
    final generatedTempPassword = 'Kvm@${DateTime.now().year}';

    final newEmployee = RegisteredEmployee(
      employeeId: generatedId,
      fullName: fullName.trim(),
      mobileNumber: mobileNumber.trim(),
      email: email.trim().isEmpty ? '$generatedId@kvm.com' : email.trim(),
      assignedStationId: assignedStationId,
      assignedStationName: assignedStationName,
      password: generatedTempPassword,
      isTemporaryPassword: true,
      passwordSetDate: DateTime.now(),
      onboardingStatus: 'VERIFIED',
      registeredAt: DateTime.now(),
    );

    registeredEmployees.insert(0, newEmployee);

    // Update the station's assigned worker and machine code if customized
    final idx = stations.indexWhere((s) => s.stationId == assignedStationId);
    if (idx != -1) {
      final current = stations[idx];
      stations[idx] = current.copyWith(
        stationName: assignedStationName.trim(),
        machineCode: (machineCode != null && machineCode.trim().isNotEmpty) ? machineCode.trim() : current.machineCode,
        address: (address != null && address.trim().isNotEmpty) ? address.trim() : current.address,
        employeeName: fullName.trim(),
        employeeId: generatedId,
      );
    }

    notifyListeners();
    return newEmployee;
  }

  Future<bool> updateStationDetails({
    required String stationId,
    required String stationName,
    required String machineCode,
    String? address,
    String? employeeId,
    String? employeeName,
  }) async {
    final cleanName = stationName.trim();
    final cleanCode = machineCode.trim();
    final cleanAddr = address?.trim();
    final cleanEmpId = (employeeId != null && employeeId.isNotEmpty && employeeId != 'Unassigned') ? employeeId : '';
    final cleanEmpName = (employeeName != null && employeeName.isNotEmpty && employeeName != 'Unassigned') ? employeeName : 'Unassigned';

    // 1. Update in-memory stations list
    final idx = stations.indexWhere((s) => s.stationId == stationId);
    if (idx != -1) {
      final current = stations[idx];
      stations[idx] = current.copyWith(
        stationName: cleanName,
        machineCode: cleanCode,
        address: cleanAddr,
        employeeId: cleanEmpId,
        employeeName: cleanEmpName,
        lastUpdatedTime: 'Machine Updated',
      );
      notifyListeners();
    }

    // 2. Persist permanently to local device storage (SharedPreferences)
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('stn_name_$stationId', cleanName);
      await prefs.setString('stn_code_$stationId', cleanCode);
      if (cleanAddr != null) {
        await prefs.setString('stn_addr_$stationId', cleanAddr);
      }
      await prefs.setString('stn_emp_id_$stationId', cleanEmpId);
      await prefs.setString('stn_emp_name_$stationId', cleanEmpName);

      final editedIds = prefs.getStringList('edited_station_ids') ?? [];
      if (!editedIds.contains(stationId)) {
        editedIds.add(stationId);
        await prefs.setStringList('edited_station_ids', editedIds);
      }
    } catch (e) {
      debugPrint('[TrackerService] SharedPreferences station save error: $e');
    }

    // 3. Send update to Hostinger MySQL
    final success = await ApiService.updateStationDetails(
      stationId: stationId,
      stationName: cleanName,
      machineCode: cleanCode,
      address: cleanAddr,
      employeeId: cleanEmpId,
      employeeName: cleanEmpName,
    );
    return success;
  }

  Future<bool> updatePasswordForEmployee(String empId, String newPassword) async {
    // 1. Update in local memory
    final idx = registeredEmployees.indexWhere((e) => e.employeeId == empId);
    if (idx != -1) {
      final current = registeredEmployees[idx];
      registeredEmployees[idx] = current.copyWith(
        password: newPassword,
        isTemporaryPassword: false,
        passwordSetDate: DateTime.now(),
      );
      notifyListeners();
    }

    // 2. Persist permanently to local device storage (SharedPreferences)
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('emp_password_$empId', newPassword);
      await prefs.setBool('emp_is_temp_$empId', false);
      await prefs.setString('emp_password_date_$empId', DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('[TrackerService] SharedPreferences error: $e');
    }

    // 3. Persist to Hostinger MySQL Database
    final success = await ApiService.updateEmployeePassword(empId, newPassword);
    return success;
  }

  Future<bool> deleteEmployee(String employeeId) async {
    final success = await ApiService.deleteEmployee(employeeId);
    registeredEmployees.removeWhere((e) => e.employeeId == employeeId);
    for (int i = 0; i < stations.length; i++) {
      if (stations[i].employeeId == employeeId) {
        stations[i] = stations[i].copyWith(
          employeeName: 'Unassigned',
          employeeId: '',
          isPresent: false,
          checkinLatitude: null,
          checkinLongitude: null,
          checkinAddress: null,
          lastUpdatedTime: 'Staff removed',
        );
      }
    }
    notifyListeners();
    return success;
  }

  void toggleAttendance() {
    final idx = stations.indexWhere((s) => s.stationId == activeStationId);
    if (idx != -1) {
      final current = stations[idx];
      final newPresence = !current.isPresent;
      stations[idx] = current.copyWith(
        isPresent: newPresence,
        checkInTime: newPresence ? 'Today, Live' : null,
        lastUpdatedTime: 'Just now',
      );
      notifyListeners();

      ApiService.sendAttendance(
        employeeId: activeEmployeeId.isNotEmpty ? activeEmployeeId : current.employeeId,
        employeeName: activeEmployeeName.isNotEmpty ? activeEmployeeName : current.employeeName,
        stationId: current.stationId,
        isPresent: newPresence,
      );
    }
  }

  Future<void> checkInEmployeeWithLocation({
    required bool isPresent,
    double? latitude,
    double? longitude,
    String? address,
  }) async {
    final idx = stations.indexWhere((s) => s.stationId == activeStationId);
    if (idx != -1) {
      final current = stations[idx];
      stations[idx] = current.copyWith(
        isPresent: isPresent,
        checkInTime: isPresent ? DateTime.now().toIso8601String() : null,
        checkinLatitude: latitude,
        checkinLongitude: longitude,
        checkinAddress: address,
        lastUpdatedTime: isPresent ? 'Shift Started (GPS Verified)' : 'Shift Ended',
      );
      notifyListeners();

      await ApiService.sendAttendance(
        employeeId: activeEmployeeId.isNotEmpty ? activeEmployeeId : current.employeeId,
        employeeName: activeEmployeeName.isNotEmpty ? activeEmployeeName : current.employeeName,
        stationId: current.stationId,
        isPresent: isPresent,
        latitude: latitude,
        longitude: longitude,
        locationName: address ?? current.stationName,
      );
    }
  }

  Future<void> addBottlesReceived(int count) async {
    final idx = stations.indexWhere((s) => s.stationId == activeStationId);
    if (idx != -1) {
      final current = stations[idx];
      final newTotal = current.todayBottlesReceived + count;
      stations[idx] = current.copyWith(
        todayBottlesReceived: newTotal,
        lastUpdatedTime: 'Just now',
      );

      recentDutyLogs.insert(
        0,
        DailyDutyLogEntry(
          id: 'LOG-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
          stationId: current.stationId,
          machineCode: current.machineCode,
          employeeName: current.employeeName,
          employeeId: current.employeeId,
          entryType: 'RECEIVED',
          bottleCount: count,
          timestamp: 'Just now (${current.stationName})',
        ),
      );

      // 1. Persist locally to SharedPreferences
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('stn_recv_${current.stationId}', newTotal);
      } catch (e) {
        debugPrint('[TrackerService] local save bottle count error: $e');
      }

      notifyListeners();

      // 2. Sync to Hostinger MySQL Database via ApiService
      try {
        await ApiService.postBottlesReceived(
          stationId: current.stationId,
          employeeId: activeEmployeeId.isNotEmpty ? activeEmployeeId : current.employeeId,
          bottleCount: count,
        );
      } catch (e) {
        debugPrint('[TrackerService] cloud sync bottle count error: $e');
      }
    }
  }

  Future<void> addBottlesPacked(int bottleCount, int crateCount, {String? vendor, String? driver}) async {
    final idx = stations.indexWhere((s) => s.stationId == activeStationId);
    if (idx != -1) {
      final current = stations[idx];
      final newBottlesTotal = current.todayBottlesPacked + bottleCount;
      final newCratesTotal = current.todayCratesPacked + crateCount;

      stations[idx] = current.copyWith(
        todayBottlesPacked: newBottlesTotal,
        todayCratesPacked: newCratesTotal,
        lastUpdatedTime: 'Just now',
      );

      recentDutyLogs.insert(
        0,
        DailyDutyLogEntry(
          id: 'LOG-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
          stationId: current.stationId,
          machineCode: current.machineCode,
          employeeName: current.employeeName,
          employeeId: current.employeeId,
          entryType: 'PACKED',
          bottleCount: bottleCount,
          crateCount: crateCount,
          vendorName: vendor ?? 'EcoRecycle Logistics',
          vehicleOrDriver: driver ?? 'Scheduled Vendor Truck',
          timestamp: 'Just now (${current.stationName})',
        ),
      );

      // 1. Persist locally to SharedPreferences
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('stn_pack_${current.stationId}', newBottlesTotal);
        await prefs.setInt('stn_crates_${current.stationId}', newCratesTotal);
      } catch (e) {
        debugPrint('[TrackerService] local save packed count error: $e');
      }

      notifyListeners();

      // 2. Sync to Hostinger MySQL Database via ApiService
      try {
        await ApiService.postBottlesPacked(
          stationId: current.stationId,
          employeeId: activeEmployeeId.isNotEmpty ? activeEmployeeId : current.employeeId,
          bottleCount: bottleCount,
          crateCount: crateCount,
          vendorName: vendor ?? 'EcoRecycle Logistics',
          driverOrVehicle: driver ?? 'Scheduled Vendor Truck',
        );
      } catch (e) {
        debugPrint('[TrackerService] cloud sync packed count error: $e');
      }
    }
  }

  void recordTruckLoading(TruckLoadingRecord record) {
    truckDispatches.insert(0, record);

    recentDutyLogs.insert(
      0,
      DailyDutyLogEntry(
        id: record.loadingId,
        stationId: record.stationId,
        machineCode: record.machineCode,
        employeeName: record.employeeName,
        employeeId: record.employeeId,
        entryType: 'TRUCK_LOADED',
        bottleCount: record.totalBottlesLoaded,
        crateCount: record.packagesCount,
        vendorName: record.vendorName,
        vehicleOrDriver: '${record.driverName} (${record.truckVehicleNumber})',
        timestamp: 'Just now',
      ),
    );

    notifyListeners();
  }

  void recordCashExchange(ManualCashExchangeRecord exchange) {
    cashExchanges.insert(0, exchange);

    // If deposited into machine, increment station's received bottle count
    if (exchange.isDepositedIntoMachine) {
      final idx = stations.indexWhere((s) => s.stationId == exchange.stationId);
      if (idx != -1) {
        final current = stations[idx];
        stations[idx] = current.copyWith(
          todayBottlesReceived: current.todayBottlesReceived + exchange.bottlesCollected,
          lastUpdatedTime: 'Just now',
        );
      }
    }

    // Add to shift timeline feed
    recentDutyLogs.insert(
      0,
      DailyDutyLogEntry(
        id: exchange.id,
        stationId: exchange.stationId,
        machineCode: exchange.machineCode,
        employeeName: exchange.employeeName,
        employeeId: exchange.employeeId,
        entryType: 'CASH_EXCHANGE',
        bottleCount: exchange.bottlesCollected,
        vendorName: 'Manual Cash: ₹${exchange.cashPaidToCustomer.toStringAsFixed(0)} (Fed to ${exchange.machineCode})',
        vehicleOrDriver: exchange.isDigitallyReimbursed ? 'Reimbursed Digitally ✓' : 'Reimbursement Pending',
        timestamp: exchange.timestamp,
      ),
    );

    notifyListeners();
  }
}
