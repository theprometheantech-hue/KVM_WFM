class StationDutyLog {
  final String stationId;
  final String stationName;
  final String machineCode;
  final String employeeName;
  final String employeeId;
  final bool isPresent;
  final String? checkInTime;
  final double? checkinLatitude;
  final double? checkinLongitude;
  final String? checkinAddress;
  final String? address;
  final int binCapacity;
  final int todayBottlesReceived;
  final int todayBottlesPacked;
  final int todayCratesPacked;
  final String lastUpdatedTime;

  StationDutyLog({
    required this.stationId,
    required this.stationName,
    required this.machineCode,
    required this.employeeName,
    required this.employeeId,
    required this.isPresent,
    this.checkInTime,
    this.checkinLatitude,
    this.checkinLongitude,
    this.checkinAddress,
    this.address,
    this.binCapacity = 500,
    required this.todayBottlesReceived,
    required this.todayBottlesPacked,
    required this.todayCratesPacked,
    required this.lastUpdatedTime,
  });

  StationDutyLog copyWith({
    String? stationName,
    String? machineCode,
    String? employeeName,
    String? employeeId,
    bool? isPresent,
    String? checkInTime,
    double? checkinLatitude,
    double? checkinLongitude,
    String? checkinAddress,
    String? address,
    int? binCapacity,
    int? todayBottlesReceived,
    int? todayBottlesPacked,
    int? todayCratesPacked,
    String? lastUpdatedTime,
  }) {
    return StationDutyLog(
      stationId: stationId,
      stationName: stationName ?? this.stationName,
      machineCode: machineCode ?? this.machineCode,
      employeeName: employeeName ?? this.employeeName,
      employeeId: employeeId ?? this.employeeId,
      isPresent: isPresent ?? this.isPresent,
      checkInTime: checkInTime ?? this.checkInTime,
      checkinLatitude: checkinLatitude ?? this.checkinLatitude,
      checkinLongitude: checkinLongitude ?? this.checkinLongitude,
      checkinAddress: checkinAddress ?? this.checkinAddress,
      address: address ?? this.address,
      binCapacity: binCapacity ?? this.binCapacity,
      todayBottlesReceived: todayBottlesReceived ?? this.todayBottlesReceived,
      todayBottlesPacked: todayBottlesPacked ?? this.todayBottlesPacked,
      todayCratesPacked: todayCratesPacked ?? this.todayCratesPacked,
      lastUpdatedTime: lastUpdatedTime ?? this.lastUpdatedTime,
    );
  }
}

