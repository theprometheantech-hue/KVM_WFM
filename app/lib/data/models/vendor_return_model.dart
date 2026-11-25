enum VendorBatchStatus {
  inBin,
  collected,
  supervisorApproved,
  handedOverToVendor,
}

extension VendorBatchStatusExt on VendorBatchStatus {
  String get displayName {
    switch (this) {
      case VendorBatchStatus.inBin:
        return 'In Machine Bin';
      case VendorBatchStatus.collected:
        return 'Collected in Crates';
      case VendorBatchStatus.supervisorApproved:
        return 'Supervisor Approved';
      case VendorBatchStatus.handedOverToVendor:
        return 'Dispatched to Vendor';
    }
  }
}

class VendorReturnBatch {
  final String batchCode;
  final String machineId;
  final String machineName;
  final String collectorEmployeeId;
  final String collectorName;
  final String vendorName;
  final String bottleCategory; // e.g. '750ml Premium Glass', '1000ml Heavy Glass', 'Aluminum Cans'
  final int totalBottles;
  final double estimatedCreditValue;
  final VendorBatchStatus status;
  final DateTime collectedAt;
  final String? supervisorRemarks;

  const VendorReturnBatch({
    required this.batchCode,
    required this.machineId,
    required this.machineName,
    required this.collectorEmployeeId,
    required this.collectorName,
    required this.vendorName,
    required this.bottleCategory,
    required this.totalBottles,
    required this.estimatedCreditValue,
    required this.status,
    required this.collectedAt,
    this.supervisorRemarks,
  });

  factory VendorReturnBatch.fromJson(Map<String, dynamic> json) {
    return VendorReturnBatch(
      batchCode: json['batch_code'] ?? '',
      machineId: json['machine_id'] ?? '',
      machineName: json['machine_name'] ?? '',
      collectorEmployeeId: json['collector_employee_id'] ?? '',
      collectorName: json['collector_name'] ?? '',
      vendorName: json['vendor_name'] ?? 'EcoRecycle Logistics Ltd.',
      bottleCategory: json['bottle_category'] ?? 'Glass Bottles',
      totalBottles: (json['total_bottles'] as num?)?.toInt() ?? 0,
      estimatedCreditValue: (json['estimated_credit_value'] as num?)?.toDouble() ?? 0.0,
      status: VendorBatchStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => VendorBatchStatus.collected,
      ),
      collectedAt: json['collected_at'] != null
          ? DateTime.parse(json['collected_at'])
          : DateTime.now(),
      supervisorRemarks: json['supervisor_remarks'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'batch_code': batchCode,
      'machine_id': machineId,
      'machine_name': machineName,
      'collector_employee_id': collectorEmployeeId,
      'collector_name': collectorName,
      'vendor_name': vendorName,
      'bottle_category': bottleCategory,
      'total_bottles': totalBottles,
      'estimated_credit_value': estimatedCreditValue,
      'status': status.name,
      'collected_at': collectedAt.toIso8601String(),
      'supervisor_remarks': supervisorRemarks,
    };
  }
}

