enum MachineStatus {
  active,
  inactive,
  offline,
  maintenance,
  full,
}

extension MachineStatusExt on MachineStatus {
  String get displayName {
    switch (this) {
      case MachineStatus.active:
        return 'Active';
      case MachineStatus.inactive:
        return 'Inactive';
      case MachineStatus.offline:
        return 'Offline';
      case MachineStatus.maintenance:
        return 'Maintenance';
      case MachineStatus.full:
        return 'Full';
    }
  }

  static MachineStatus fromString(String? status) {
    switch (status?.toLowerCase()) {
      case 'active':
        return MachineStatus.active;
      case 'inactive':
        return MachineStatus.inactive;
      case 'maintenance':
        return MachineStatus.maintenance;
      case 'full':
        return MachineStatus.full;
      case 'offline':
      default:
        return MachineStatus.offline;
    }
  }
}

class Machine {
  final String id;
  final String machineCode;
  final String name;
  final String serialNumber;
  final String location;
  final int maxCapacity;
  final int currentCapacity;
  final MachineStatus status;
  final List<String> assignedEmployeeIds;
  final DateTime? lastMaintenanceDate;

  const Machine({
    required this.id,
    required this.machineCode,
    required this.name,
    required this.serialNumber,
    required this.location,
    required this.maxCapacity,
    required this.currentCapacity,
    required this.status,
    this.assignedEmployeeIds = const [],
    this.lastMaintenanceDate,
  });

  factory Machine.fromJson(Map<String, dynamic> json) {
    return Machine(
      id: json['id']?.toString() ?? '',
      machineCode: json['machine_code'] ?? json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      serialNumber: json['serial_number'] ?? '',
      location: json['location'] ?? '',
      maxCapacity: (json['max_capacity'] as num?)?.toInt() ?? 500,
      currentCapacity: (json['current_capacity'] as num?)?.toInt() ?? 0,
      status: MachineStatusExt.fromString(json['status']),
      assignedEmployeeIds: (json['assigned_employee_ids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      lastMaintenanceDate: json['last_maintenance_date'] != null
          ? DateTime.tryParse(json['last_maintenance_date'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'machine_code': machineCode,
      'name': name,
      'serial_number': serialNumber,
      'location': location,
      'max_capacity': maxCapacity,
      'current_capacity': currentCapacity,
      'status': status.name,
      'assigned_employee_ids': assignedEmployeeIds,
      'last_maintenance_date': lastMaintenanceDate?.toIso8601String(),
    };
  }
}

