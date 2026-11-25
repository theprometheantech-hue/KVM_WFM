class ManualCashExchangeRecord {
  final String id;
  final String stationId;
  final String stationName;
  final String machineCode;
  final String employeeName;
  final String employeeId;
  final int bottlesCollected;
  final double cashPaidToCustomer;
  final bool isDepositedIntoMachine;
  final bool isDigitallyReimbursed;
  final String? note;
  final String timestamp;
  final DateTime createdAt;

  const ManualCashExchangeRecord({
    required this.id,
    required this.stationId,
    required this.stationName,
    required this.machineCode,
    required this.employeeName,
    required this.employeeId,
    required this.bottlesCollected,
    required this.cashPaidToCustomer,
    this.isDepositedIntoMachine = true,
    this.isDigitallyReimbursed = true,
    this.note,
    required this.timestamp,
    required this.createdAt,
  });
}
