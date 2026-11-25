// HTTP API Service for Cloud Sync (Works with Hostinger VPS, Railway, Render, or Localhost)
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/duty_log_model.dart';
import '../models/duty_feed_entry.dart';

class ApiService {
  // Hostinger Subdomain Production URL
  static String baseUrl = 'https://wfm-api.e2s2.in/api';

  static void setServerUrl(String url) {
    baseUrl = url;
  }

  // 0. Admin Provisions New Employee directly (with optional machine customization)
  static Future<Map<String, dynamic>?> adminAddEmployee({
    required String fullName,
    required String mobileNumber,
    required String email,
    required String assignedStationId,
    required String assignedStationName,
    String? machineCode,
    String? address,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/employee/admin-add'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fullName': fullName,
          'mobileNumber': mobileNumber,
          'email': email,
          'assignedStationId': assignedStationId,
          'assignedStationName': assignedStationName,
          'machineCode': machineCode,
          'address': address,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('[ApiService] adminAddEmployee error: $e');
      return null;
    }
  }

  // Update Machine Details & Location on Cloud
  static Future<bool> updateStationDetails({
    required String stationId,
    required String stationName,
    required String machineCode,
    String? address,
    String? employeeId,
    String? employeeName,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/fleet/station/update'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'stationId': stationId,
          'stationName': stationName,
          'machineCode': machineCode,
          'address': address,
          'employeeId': employeeId,
          'employeeName': employeeName,
        }),
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[ApiService] updateStationDetails error: $e');
      return false;
    }
  }

  // Update Employee Permanent Password
  static Future<bool> updateEmployeePassword(String employeeId, String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/employee/update-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'employeeId': employeeId,
          'password': newPassword,
        }),
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[ApiService] updateEmployeePassword error: $e');
      return false;
    }
  }

  // Add new station location
  static Future<Map<String, dynamic>?> addStationLocation({
    required String locationName,
    required String machineCode,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/fleet/station/add'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': locationName,
          'code': machineCode,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('[ApiService] addStationLocation error: $e');
      return null;
    }
  }

  // Delete station location
  static Future<bool> deleteStation(String stationId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/fleet/station/delete'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'stationId': stationId}),
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[ApiService] deleteStation error: $e');
      return false;
    }
  }

  // Legacy compatibility stub
  static Future<Map<String, dynamic>?> submitEmployeeOnboarding({
    required String fullName,
    required String mobileNumber,
    required String email,
    required String residentialAddress,
    required List<String> documents,
  }) async {
    return adminAddEmployee(
      fullName: fullName,
      mobileNumber: mobileNumber,
      email: email,
      assignedStationId: 'STN-001',
      assignedStationName: residentialAddress,
    );
  }

  // 0B. Fetch all submitted applications from backend
  static Future<List<dynamic>?> fetchOnboardingApplications() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/employee/onboarding-list'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['applications'] as List<dynamic>?;
      }
      return null;
    } catch (e) {
      debugPrint('[ApiService] fetchOnboardingApplications error: $e');
      return null;
    }
  }

  // 0C. Approve / Verify Employee in backend
  static Future<bool> verifyEmployee(String employeeId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/employee/verify'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'employeeId': employeeId}),
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // 0D. Delete Employee from Hostinger Cloud Database & Unassign from Stations
  static Future<bool> deleteEmployee(String employeeId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/employee/delete'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'employeeId': employeeId}),
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[ApiService] deleteEmployee error: $e');
      return false;
    }
  }

  static Future<bool> sendAttendance({
    required String employeeId,
    required String employeeName,
    required String stationId,
    required bool isPresent,
    double? latitude,
    double? longitude,
    String? locationName,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/attendance/shift-checkin'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'employeeId': employeeId,
          'employeeName': employeeName,
          'machineId': stationId,
          'status': isPresent ? 'ON_DUTY' : 'OFF_DUTY',
          'latitude': latitude,
          'longitude': longitude,
          'locationName': locationName,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      // Graceful offline fallback
      return false;
    }
  }

  // 2. Post Inflow: Customer Bottles Received to Cloud DB
  static Future<bool> postBottlesReceived({
    required String stationId,
    required String employeeId,
    required int bottleCount,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/fleet/readings'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'machineId': stationId,
          'employeeId': employeeId,
          'entryType': 'RECEIVED',
          'cumulativeBilledCount': bottleCount,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  // 3. Post Outflow: Bottles & Crates Packed for Vendors to Cloud DB
  static Future<bool> postBottlesPacked({
    required String stationId,
    required String employeeId,
    required int bottleCount,
    required int crateCount,
    required String vendorName,
    required String driverOrVehicle,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/fleet/readings'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'machineId': stationId,
          'employeeId': employeeId,
          'entryType': 'PACKED',
          'bottlesCollected': bottleCount,
          'cratesCount': crateCount,
          'vendorName': vendorName,
          'driverOrVehicle': driverOrVehicle,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  // 4. Fetch 100+ Live Stations for Supervisor Monitor
  static Future<List<StationDutyLog>?> fetchLiveFleet() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/fleet/overview'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> list = data['locations'] ?? [];
        return list.map((json) {
          return StationDutyLog(
            stationId: json['machineId'] ?? 'STN-001',
            stationName: json['locationName'] ?? 'Station',
            machineCode: json['machineCode'] ?? json['machineId'] ?? 'MCH-001',
            employeeName: json['assignedOperator'] ?? 'Unassigned',
            employeeId: json['employeeId'] ?? '',
            isPresent: json['isStaffPresent'] ?? false,
            checkInTime: json['checkInTime'],
            checkinLatitude: json['checkinLatitude'] != null ? (json['checkinLatitude'] as num).toDouble() : null,
            checkinLongitude: json['checkinLongitude'] != null ? (json['checkinLongitude'] as num).toDouble() : null,
            checkinAddress: json['checkinAddress'],
            address: json['address'],
            binCapacity: json['binCapacity'] ?? 500,
            todayBottlesReceived: json['todayTotalDeposited'] ?? 0,
            todayBottlesPacked: json['todayTotalDispatchedToVendor'] ?? 0,
            todayCratesPacked: ((json['todayTotalDispatchedToVendor'] ?? 0) ~/ 24),
            lastUpdatedTime: 'Live from Hostinger',
          );
        }).toList();
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}

