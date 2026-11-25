import 'package:flutter/foundation.dart';

enum ReadingShift {
  morning,
  afternoon,
  evening,
  night,
}

class ShiftDepositReading {
  final String id;
  final String locationName;
  final String machineId;
  final String employeeId;
  final String employeeName;
  final DateTime recordedAt;
  final String readingSlot; // e.g. "11:00 AM Audit", "02:30 PM Midday Audit"
  final int cumulativeMachineBilledCount;
  final int bottlesCollectedThisSlot;
  final int bottlesBrokenOrDamaged;
  final String binFillStatus; // 'Normal (30%)', 'Moderate (65%)', 'Near Full (90%)'
  final String? remarks;

  const ShiftDepositReading({
    required this.id,
    required this.locationName,
    required this.machineId,
    required this.employeeId,
    required this.employeeName,
    required this.recordedAt,
    required this.readingSlot,
    required this.cumulativeMachineBilledCount,
    required this.bottlesCollectedThisSlot,
    this.bottlesBrokenOrDamaged = 0,
    required this.binFillStatus,
    this.remarks,
  });

  factory ShiftDepositReading.fromJson(Map<String, dynamic> json) {
    return ShiftDepositReading(
      id: json['id'] ?? '',
      locationName: json['location_name'] ?? '',
      machineId: json['machine_id'] ?? '',
      employeeId: json['employee_id'] ?? '',
      employeeName: json['employee_name'] ?? '',
      recordedAt: json['recorded_at'] != null ? DateTime.parse(json['recorded_at']) : DateTime.now(),
      readingSlot: json['reading_slot'] ?? '',
      cumulativeMachineBilledCount: (json['cumulative_billed_count'] as num?)?.toInt() ?? 0,
      bottlesCollectedThisSlot: (json['bottles_collected'] as num?)?.toInt() ?? 0,
      bottlesBrokenOrDamaged: (json['bottles_damaged'] as num?)?.toInt() ?? 0,
      binFillStatus: json['bin_fill_status'] ?? 'Normal',
      remarks: json['remarks'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'location_name': locationName,
      'machine_id': machineId,
      'employee_id': employeeId,
      'employee_name': employeeName,
      'recorded_at': recordedAt.toIso8601String(),
      'reading_slot': readingSlot,
      'cumulative_billed_count': cumulativeMachineBilledCount,
      'bottles_collected': bottlesCollectedThisSlot,
      'bottles_damaged': bottlesBrokenOrDamaged,
      'bin_fill_status': binFillStatus,
      'remarks': remarks,
    };
  }
}

class LocationFleetOverview {
  final String locationCode;
  final String locationName;
  final String machineId;
  final String machineSerialNumber;
  final String? assignedEmployeeName;
  final String? assignedEmployeeId;
  final bool isStaffPresent;
  final DateTime? checkInTimestamp;
  final int todayTotalDeposited;
  final int todayTotalDispatchedToVendor;
  final int currentBinHoldings;
  final int machineMaxCapacity;
  final DateTime? lastReadingTime;

  const LocationFleetOverview({
    required this.locationCode,
    required this.locationName,
    required this.machineId,
    required this.machineSerialNumber,
    this.assignedEmployeeName,
    this.assignedEmployeeId,
    required this.isStaffPresent,
    this.checkInTimestamp,
    required this.todayTotalDeposited,
    required this.todayTotalDispatchedToVendor,
    required this.currentBinHoldings,
    required this.machineMaxCapacity,
    this.lastReadingTime,
  });
}

