import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/mock_data_service.dart';

class EmployeeListScreen extends StatefulWidget {
  const EmployeeListScreen({super.key});

  @override
  State<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends State<EmployeeListScreen> {
  final mock = MockDataService();
  String _searchQuery = '';
  UserRole? _filterRole;

  @override
  Widget build(BuildContext context) {
    final filtered = mock.employees.where((e) {
      final matchesSearch = e.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.employeeId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.email.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesRole = _filterRole == null || e.role == _filterRole;
      return matchesSearch && matchesRole;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1),
            tooltip: 'Add New Employee',
            onPressed: () => _showAddEmployeeDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search by employee ID, name or email...',
                    prefixIcon: Icon(Icons.search, size: 20),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('All Roles'),
                        selected: _filterRole == null,
                        onSelected: (_) => setState(() => _filterRole = null),
                      ),
                      const SizedBox(width: 6),
                      FilterChip(
                        label: const Text('Admin'),
                        selected: _filterRole == UserRole.admin,
                        onSelected: (_) => setState(() => _filterRole = UserRole.admin),
                      ),
                      const SizedBox(width: 6),
                      FilterChip(
                        label: const Text('Supervisor'),
                        selected: _filterRole == UserRole.supervisor,
                        onSelected: (_) => setState(() => _filterRole = UserRole.supervisor),
                      ),
                      const SizedBox(width: 6),
                      FilterChip(
                        label: const Text('Operator'),
                        selected: _filterRole == UserRole.machineOperator,
                        onSelected: (_) => setState(() => _filterRole = UserRole.machineOperator),
                      ),
                      const SizedBox(width: 6),
                      FilterChip(
                        label: const Text('Employee'),
                        selected: _filterRole == UserRole.employee,
                        onSelected: (_) => setState(() => _filterRole = UserRole.employee),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // List
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('No employees found matching criteria'))
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final emp = filtered[index];
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: AppColors.primaryLight.withOpacity(0.15),
                                child: Text(
                                  emp.name[0],
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(emp.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withOpacity(0.08),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            emp.role.nameString,
                                            style: const TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text('${emp.employeeId} • ${emp.designation ?? "Staff"}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                    Text('Location: ${emp.assignedLocation ?? "Unassigned"}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.more_vert),
                                onPressed: () => _showEmployeeActionSheet(emp),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showEmployeeActionSheet(User emp) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.badge_outlined),
              title: Text('View Profile: ${emp.name}'),
              subtitle: Text('ID: ${emp.employeeId} | ${emp.email}'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('View Attendance History'),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Displaying attendance for ${emp.name}')));
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit Details'),
              onTap: () => Navigator.pop(ctx),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.error),
              title: const Text('Deactivate Employee', style: TextStyle(color: AppColors.error)),
              onTap: () {
                setState(() => mock.employees.removeWhere((e) => e.id == emp.id));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Employee deactivated')));
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddEmployeeDialog() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final idCtrl = TextEditingController(text: 'EMP-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}');
    final desigCtrl = TextEditingController();
    UserRole selectedRole = UserRole.employee;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add New Employee'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: idCtrl, decoration: const InputDecoration(labelText: 'Employee ID')),
                const SizedBox(height: 10),
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name')),
                const SizedBox(height: 10),
                TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Work Email')),
                const SizedBox(height: 10),
                TextField(controller: desigCtrl, decoration: const InputDecoration(labelText: 'Designation')),
                const SizedBox(height: 12),
                DropdownButtonFormField<UserRole>(
                  value: selectedRole,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: UserRole.values.map((r) => DropdownMenuItem(value: r, child: Text(r.nameString))).toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedRole = val);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.isNotEmpty && emailCtrl.text.isNotEmpty) {
                  setState(() {
                    mock.employees.add(
                      User(
                        id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
                        employeeId: idCtrl.text,
                        name: nameCtrl.text,
                        email: emailCtrl.text,
                        role: selectedRole,
                        designation: desigCtrl.text.isEmpty ? 'Staff' : desigCtrl.text,
                        assignedLocation: 'Station Main',
                      ),
                    );
                  });
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Save Employee'),
            ),
          ],
        ),
      ),
    );
  }
}

