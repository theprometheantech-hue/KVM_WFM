enum UserRole {
  superAdmin,
  admin,
  manager,
  supervisor,
  machineOperator,
  employee,
}

extension UserRoleExtension on UserRole {
  String get nameString {
    switch (this) {
      case UserRole.superAdmin:
        return 'Super Admin';
      case UserRole.admin:
        return 'Admin';
      case UserRole.manager:
        return 'Manager';
      case UserRole.supervisor:
        return 'Supervisor';
      case UserRole.machineOperator:
        return 'Machine Operator';
      case UserRole.employee:
        return 'Employee';
    }
  }

  static UserRole fromString(String? role) {
    switch (role?.toLowerCase()) {
      case 'super_admin':
      case 'superadmin':
        return UserRole.superAdmin;
      case 'admin':
        return UserRole.admin;
      case 'manager':
        return UserRole.manager;
      case 'supervisor':
        return UserRole.supervisor;
      case 'operator':
      case 'machine_operator':
        return UserRole.machineOperator;
      case 'employee':
      default:
        return UserRole.employee;
    }
  }
}

class User {
  final String id;
  final String employeeId;
  final String name;
  final String email;
  final String? mobile;
  final UserRole role;
  final String? designation;
  final String? department;
  final String? assignedLocation;
  final String? assignedMachineId;
  final String? token;

  const User({
    required this.id,
    required this.employeeId,
    required this.name,
    required this.email,
    this.mobile,
    required this.role,
    this.designation,
    this.department,
    this.assignedLocation,
    this.assignedMachineId,
    this.token,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      employeeId: json['employee_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      mobile: json['mobile'],
      role: UserRoleExtension.fromString(json['role']),
      designation: json['designation'],
      department: json['department'],
      assignedLocation: json['assigned_location'],
      assignedMachineId: json['assigned_machine_id'],
      token: json['token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employee_id': employeeId,
      'name': name,
      'email': email,
      'mobile': mobile,
      'role': role.toString().split('.').last,
      'designation': designation,
      'department': department,
      'assigned_location': assignedLocation,
      'assigned_machine_id': assignedMachineId,
      'token': token,
    };
  }
}

