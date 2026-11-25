class DailyDutyLogEntry {
  final String id;
  final String stationId;
  final String machineCode;
  final String employeeName;
  final String employeeId;
  final String entryType; // 'RECEIVED' (from customer) or 'PACKED' (for vendor)
  final int bottleCount;
  final int? crateCount;
  final String? vendorName;
  final String? vehicleOrDriver;
  final String timestamp;

  const DailyDutyLogEntry({
    required this.id,
    required this.stationId,
    required this.machineCode,
    required this.employeeName,
    required this.employeeId,
    required this.entryType,
    required this.bottleCount,
    this.crateCount,
    this.vendorName,
    this.vehicleOrDriver,
    required this.timestamp,
  });
}

