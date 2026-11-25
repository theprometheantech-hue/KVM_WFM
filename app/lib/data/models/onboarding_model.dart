class RegisteredEmployee {
  final String employeeId;
  final String fullName;
  final String mobileNumber;
  final String email;
  final String? assignedStationId;
  final String? assignedStationName;
  final String password;
  final bool isTemporaryPassword;
  final DateTime passwordSetDate;
  final List<String> submittedDocuments; // file names / urls
  final String onboardingStatus; // 'SUBMITTED', 'VERIFIED', 'ACTIVE'
  final DateTime registeredAt;

  const RegisteredEmployee({
    required this.employeeId,
    required this.fullName,
    required this.mobileNumber,
    required this.email,
    this.assignedStationId,
    this.assignedStationName,
    required this.password,
    this.isTemporaryPassword = true,
    required this.passwordSetDate,
    this.submittedDocuments = const [],
    this.onboardingStatus = 'SUBMITTED',
    required this.registeredAt,
  });

  bool get isPasswordExpired {
    final diff = DateTime.now().difference(passwordSetDate).inDays;
    return diff >= 90; // 3 months expiry
  }

  RegisteredEmployee copyWith({
    String? password,
    bool? isTemporaryPassword,
    DateTime? passwordSetDate,
    String? onboardingStatus,
    String? assignedStationId,
    String? assignedStationName,
  }) {
    return RegisteredEmployee(
      employeeId: employeeId,
      fullName: fullName,
      mobileNumber: mobileNumber,
      email: email,
      assignedStationId: assignedStationId ?? this.assignedStationId,
      assignedStationName: assignedStationName ?? this.assignedStationName,
      password: password ?? this.password,
      isTemporaryPassword: isTemporaryPassword ?? this.isTemporaryPassword,
      passwordSetDate: passwordSetDate ?? this.passwordSetDate,
      submittedDocuments: submittedDocuments,
      onboardingStatus: onboardingStatus ?? this.onboardingStatus,
      registeredAt: registeredAt,
    );
  }
}

class TruckLoadingRecord {
  final String loadingId;
  final String stationId;
  final String machineCode;
  final String employeeName;
  final String employeeId;
  final String vendorName;
  final int packagesCount; // e.g. crates or sealed bulk bags
  final int totalBottlesLoaded;
  final String truckVehicleNumber;
  final String driverName;
  final String driverMobile;
  final String timestamp;
  final String status; // 'LOADED_AND_DISPATCHED'

  const TruckLoadingRecord({
    required this.loadingId,
    required this.stationId,
    required this.machineCode,
    required this.employeeName,
    required this.employeeId,
    required this.vendorName,
    required this.packagesCount,
    required this.totalBottlesLoaded,
    required this.truckVehicleNumber,
    required this.driverName,
    required this.driverMobile,
    required this.timestamp,
    this.status = 'LOADED_AND_DISPATCHED',
  });
}

