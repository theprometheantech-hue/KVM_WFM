import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/localization/language_service.dart';
import '../../data/models/onboarding_model.dart';
import '../../data/services/tracker_service.dart';
import '../../data/services/api_service.dart';

class AdminStaffManagementScreen extends StatefulWidget {
  const AdminStaffManagementScreen({super.key});

  @override
  State<AdminStaffManagementScreen> createState() => _AdminStaffManagementScreenState();
}

class _AdminStaffManagementScreenState extends State<AdminStaffManagementScreen> {
  final tracker = TrackerService();
  String _search = '';
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    tracker.addListener(_onTrackerUpdate);
    LanguageService().addListener(_onTrackerUpdate);
    // Silent background sync
    _silentSyncFromBackend();
  }

  @override
  void dispose() {
    tracker.removeListener(_onTrackerUpdate);
    LanguageService().removeListener(_onTrackerUpdate);
    super.dispose();
  }

  void _onTrackerUpdate() {
    if (mounted) setState(() {});
  }

  Future<void> _silentSyncFromBackend() async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);
    try {
      final apps = await ApiService.fetchOnboardingApplications();
      if (apps != null && mounted) {
        for (final app in apps) {
          final empId = app['employeeId'] ?? '';
          final exists = tracker.registeredEmployees.any((e) => e.employeeId == empId);
          if (!exists && empId.isNotEmpty) {
            tracker.registerNewEmployee(
              RegisteredEmployee(
                employeeId: empId,
                fullName: app['fullName'] ?? 'Staff',
                mobileNumber: app['mobileNumber'] ?? '',
                email: app['email'] ?? '',
                assignedStationId: app['assignedStationId'],
                assignedStationName: app['assignedStationName'] ?? 'Assigned Station',
                password: app['temporaryPassword'] ?? 'Kvm@2026',
                isTemporaryPassword: true,
                passwordSetDate: DateTime.now(),
                submittedDocuments: const [],
                onboardingStatus: 'VERIFIED',
                registeredAt: DateTime.tryParse(app['submittedAt'] ?? '') ?? DateTime.now(),
              ),
            );
          }
        }
      }
    } catch (_) {
      // Ignore background sync errors so UI is never blocked
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  void _showAddLocationDialog() {
    final locationNameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.add_location_alt, color: Colors.teal.shade700),
            ),
            const SizedBox(width: 10),
            const Text('Add New Station Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Create a new vending machine station in your fleet. It will immediately be available for staff assignment and duty operations.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: locationNameCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Location / Station Name *',
                hintText: 'e.g. Vellore New Bus Stand',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: codeCtrl,
              decoration: const InputDecoration(
                labelText: 'Station / Machine Code (Optional)',
                hintText: 'e.g. MCH-VEL-01 (Auto-generated if empty)',
                prefixIcon: Icon(Icons.qr_code),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal.shade700,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Add Station'),
            onPressed: () {
              final locName = locationNameCtrl.text.trim();
              if (locName.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a Location / Station Name.')),
                );
                return;
              }

              final newStation = tracker.addNewStationLocation(
                locationName: locName,
                machineCode: codeCtrl.text.trim().isNotEmpty ? codeCtrl.text.trim() : null,
              );

              // Sync to backend in background
              ApiService.addStationLocation(
                locationName: newStation.stationName,
                machineCode: newStation.machineCode,
              );

              Navigator.pop(dialogCtx);
              setState(() {});

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Station "${newStation.stationName}" added successfully to fleet!'),
                  backgroundColor: Colors.teal.shade800,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showAddEmployeeDialog() {
    final nameCtrl = TextEditingController();
    final mobileCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final machineCodeCtrl = TextEditingController();
    final stationNameCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    bool showMachineEditor = false;
    String selectedStationId = tracker.stations.isNotEmpty ? tracker.stations.first.stationId : 'STN-001';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final selectedStation = tracker.stations.firstWhere(
            (s) => s.stationId == selectedStationId,
            orElse: () => tracker.stations.first,
          );

          if (machineCodeCtrl.text.isEmpty && !showMachineEditor) {
            machineCodeCtrl.text = selectedStation.machineCode;
            stationNameCtrl.text = selectedStation.stationName;
            addressCtrl.text = selectedStation.address ?? '';
          }

          return AlertDialog(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.person_add_alt_1, color: AppColors.primary),
                ),
                const SizedBox(width: 10),
                const Text('Add New Employee', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            content: SingleChildScrollView(
              child: SizedBox(
                width: 500,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Admin Provisioning will auto-generate an Employee ID and temporary login password.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameCtrl,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Full Name *',
                        hintText: 'e.g. Ramesh Kumar',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: mobileCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Mobile Number *',
                        hintText: 'e.g. 9876543210',
                        prefixIcon: Icon(Icons.phone_android_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email Address (Optional)',
                        hintText: 'e.g. ramesh@example.com',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Assign Working Station Location *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        TextButton.icon(
                          style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                          icon: const Icon(Icons.add_location_alt, size: 16),
                          label: const Text('+ New Location', style: TextStyle(fontSize: 12)),
                          onPressed: () {
                            Navigator.pop(dialogCtx);
                            _showAddLocationDialog();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedStationId,
                          isExpanded: true,
                          items: tracker.stations.map((stn) {
                            final currentWorker = stn.employeeName.isNotEmpty && stn.employeeName != 'Unassigned'
                                ? ' (Current: ${stn.employeeName})'
                                : ' (Vacant)';
                            return DropdownMenuItem<String>(
                              value: stn.stationId,
                              child: Text(
                                '${stn.stationName} [${stn.machineCode}]$currentWorker',
                                style: const TextStyle(fontSize: 13),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setDialogState(() {
                                selectedStationId = val;
                                final st = tracker.stations.firstWhere((s) => s.stationId == val);
                                machineCodeCtrl.text = st.machineCode;
                                stationNameCtrl.text = st.stationName;
                                addressCtrl.text = st.address ?? '';
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Inline Machine Customization Toggle
                    InkWell(
                      onTap: () {
                        setDialogState(() {
                          showMachineEditor = !showMachineEditor;
                          if (showMachineEditor) {
                            machineCodeCtrl.text = selectedStation.machineCode;
                            stationNameCtrl.text = selectedStation.stationName;
                            addressCtrl.text = selectedStation.address ?? '';
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                        child: Row(
                          children: [
                            Icon(showMachineEditor ? Icons.keyboard_arrow_up : Icons.tune, size: 16, color: AppColors.primary),
                            const SizedBox(width: 6),
                            Text(
                              showMachineEditor ? 'Hide Machine Customization' : 'Customize Machine Details for this Station',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (showMachineEditor) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(top: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: machineCodeCtrl,
                                    decoration: const InputDecoration(
                                      labelText: 'Machine Code *',
                                      hintText: 'e.g. MCH-ARN-01',
                                      prefixIcon: Icon(Icons.qr_code, size: 18),
                                      isDense: true,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: stationNameCtrl,
                                    decoration: const InputDecoration(
                                      labelText: 'Station Name *',
                                      hintText: 'e.g. Arani Station Hub',
                                      prefixIcon: Icon(Icons.location_on, size: 18),
                                      isDense: true,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: addressCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Landmark / Area / Physical Address',
                                hintText: 'e.g. Near Old Bus Stand Platform 2',
                                prefixIcon: Icon(Icons.pin_drop_outlined, size: 18),
                                isDense: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: const Text('Provision & Assign'),
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  final mobile = mobileCtrl.text.trim();
                  final email = emailCtrl.text.trim();

                  if (name.isEmpty || mobile.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter Full Name and Mobile Number.')),
                    );
                    return;
                  }

                  final targetStationName = stationNameCtrl.text.trim().isNotEmpty
                      ? stationNameCtrl.text.trim()
                      : selectedStation.stationName;
                  final targetMachineCode = machineCodeCtrl.text.trim().isNotEmpty
                      ? machineCodeCtrl.text.trim()
                      : selectedStation.machineCode;
                  final targetAddress = addressCtrl.text.trim();

                  Navigator.pop(dialogCtx);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Saving employee $name and machine details to Hostinger...')),
                  );

                  // 1. Update machine details if customized
                  if (showMachineEditor) {
                    await tracker.updateStationDetails(
                      stationId: selectedStationId,
                      stationName: targetStationName,
                      machineCode: targetMachineCode,
                      address: targetAddress,
                      employeeName: name,
                    );
                  }

                  // 2. Add employee in local TrackerService (assigns station & notifies)
                  final createdEmp = tracker.addEmployeeByAdmin(
                    fullName: name,
                    mobileNumber: mobile,
                    email: email,
                    assignedStationId: selectedStationId,
                    assignedStationName: targetStationName,
                    machineCode: targetMachineCode,
                    address: targetAddress,
                  );

                  // 3. Sync to Hostinger MySQL Database
                  final apiRes = await ApiService.adminAddEmployee(
                    fullName: name,
                    mobileNumber: mobile,
                    email: email,
                    assignedStationId: selectedStationId,
                    assignedStationName: targetStationName,
                    machineCode: targetMachineCode,
                    address: targetAddress,
                  );

                  await tracker.syncWithCloud();
                  if (mounted) setState(() {});

                  if (apiRes != null && apiRes['success'] == true) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Employee $name & machine saved to Hostinger MySQL!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }

                  _showCredentialsDialog(createdEmp);
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _showCredentialsDialog(RegisteredEmployee emp) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            const Text('Employee Created & Assigned!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Employee: ${emp.fullName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 6),
            Text('Station Assigned: ${emp.assignedStationName}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
            const Divider(height: 24),
            const Text('Employee Login Credentials:', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('Employee ID: ', style: TextStyle(fontWeight: FontWeight.w600)),
                      SelectableText(emp.employeeId, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.blueAccent)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Text('Temp Password: ', style: TextStyle(fontWeight: FontWeight.w600)),
                      SelectableText(emp.password, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.blueAccent)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Hand over these credentials to the employee. They can log in immediately and will be prompted to set their personal password.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final employees = tracker.registeredEmployees.where((emp) {
      if (emp.employeeId == 'ADMIN-01') return false; // Admin is separate
      final q = _search.toLowerCase();
      return emp.fullName.toLowerCase().contains(q) ||
          emp.employeeId.toLowerCase().contains(q) ||
          emp.mobileNumber.contains(q) ||
          emp.email.toLowerCase().contains(q) ||
          (emp.assignedStationName ?? '').toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        title: Text(tr('staff_management_title')),
        actions: [
          const Center(
            child: Padding(
              padding: EdgeInsets.only(top: 10, bottom: 10, right: 8),
              child: LanguageToggleButton(isCompact: true),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_location_alt_outlined),
            tooltip: tr('add_location'),
            onPressed: _showAddLocationDialog,
          ),
          IconButton(
            icon: const Icon(Icons.person_add_alt),
            tooltip: tr('add_employee'),
            onPressed: _showAddEmployeeDialog,
          ),
          IconButton(
            icon: _isSyncing
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.refresh),
            tooltip: 'Sync Data',
            onPressed: _silentSyncFromBackend,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: const Text('+ Add New Employee'),
        onPressed: _showAddEmployeeDialog,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.blue.shade50,
            child: Row(
              children: [
                const Icon(Icons.admin_panel_settings, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Admin Direct Provisioning: Add employees, assign working stations, generate login credentials, or add new station locations to the fleet.',
                    style: TextStyle(fontSize: 13, color: Colors.blue.shade900),
                  ),
                ),
              ],
            ),
          ),

          // Search bar & Action Buttons
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search employee name, ID, mobile, or assigned station...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    ),
                    onChanged: (val) => setState(() => _search = val),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  ),
                  icon: const Icon(Icons.add_location_alt, size: 18),
                  label: const Text('+ Add Location'),
                  onPressed: _showAddLocationDialog,
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  icon: const Icon(Icons.person_add, size: 18),
                  label: const Text('+ Add Employee'),
                  onPressed: _showAddEmployeeDialog,
                ),
              ],
            ),
          ),

          // Employee Count & Status Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Active Provisioned Staff: ${employees.length} Employee(s)',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary),
                ),
                Text(
                  'Stations: ${tracker.stations.where((s) => s.employeeName != 'Unassigned').length} Assigned / ${tracker.stations.length} Total',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // List of Provisioned Employees
          Expanded(
            child: employees.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.badge_outlined, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text(
                            'No employees provisioned yet.',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Click the button below to add your first employee and assign them to a working station.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                            icon: const Icon(Icons.person_add),
                            label: const Text('Add First Employee'),
                            onPressed: _showAddEmployeeDialog,
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    itemCount: employees.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, idx) {
                      final emp = employees[idx];
                      final stationName = emp.assignedStationName ?? 'Unassigned';

                      return Card(
                        elevation: 1.5,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: AppColors.primary.withOpacity(0.12),
                                    child: Text(
                                      emp.fullName.isNotEmpty ? emp.fullName[0].toUpperCase() : 'E',
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(emp.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.green.shade100,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                'ACTIVE',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.green.shade900,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'ID: ${emp.employeeId} | Mobile: ${emp.mobileNumber}',
                                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                        ),
                                        if (emp.email.isNotEmpty)
                                          Text(
                                            'Email: ${emp.email}',
                                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.blue.shade200),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        const Text('Assigned Station', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w600)),
                                        Text(stationName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 20),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Text('Login Password: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                      SelectableText(
                                        emp.password,
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                                      ),
                                      const SizedBox(width: 6),
                                      if (emp.isTemporaryPassword)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(4)),
                                          child: Text('Temp / First Login', style: TextStyle(fontSize: 10, color: Colors.amber.shade900, fontWeight: FontWeight.w600)),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.grey.shade100,
                                            foregroundColor: Colors.black87,
                                            elevation: 0,
                                            minimumSize: const Size(0, 34),
                                          ),
                                          icon: const Icon(Icons.swap_horiz, size: 16),
                                          label: const Text('Reassign Station', style: TextStyle(fontSize: 12)),
                                          onPressed: () {
                                            _showReassignDialog(emp);
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      TextButton.icon(
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.red,
                                          visualDensity: VisualDensity.compact,
                                        ),
                                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                                        label: const Text('Remove', style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
                                        onPressed: () => _confirmDeleteEmployee(emp),
                                      ),
                                    ],
                                  ),
                                ],
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

  void _confirmDeleteEmployee(RegisteredEmployee emp) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.warning_amber_rounded, color: Colors.red),
            ),
            const SizedBox(width: 10),
            const Text('Remove Employee?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Text(
          'Are you sure you want to remove "${emp.fullName}" (${emp.employeeId})?\n\n'
          'This will revoke their mobile login credentials, unassign them from ${emp.assignedStationName ?? "their station"}, and permanently remove them from the Hostinger cloud database.',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Removing ${emp.fullName} from cloud database...')),
              );
              final success = await tracker.deleteEmployee(emp.employeeId);
              await tracker.syncWithCloud();
              if (mounted) {
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? 'Employee "${emp.fullName}" successfully removed.'
                        : 'Employee removed locally.'),
                    backgroundColor: success ? Colors.green : Colors.orange,
                  ),
                );
              }
            },
            child: const Text('Yes, Remove'),
          ),
        ],
      ),
    );
  }

  void _showReassignDialog(RegisteredEmployee emp) {
    String targetStationId = emp.assignedStationId ?? (tracker.stations.isNotEmpty ? tracker.stations.first.stationId : 'STN-001');

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Reassign ${emp.fullName}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select new working station location:'),
              const SizedBox(height: 12),
              DropdownButton<String>(
                value: targetStationId,
                isExpanded: true,
                items: tracker.stations.map((stn) {
                  return DropdownMenuItem<String>(
                    value: stn.stationId,
                    child: Text(stn.stationName, style: const TextStyle(fontSize: 13)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setDialogState(() => targetStationId = val);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final stn = tracker.stations.firstWhere((s) => s.stationId == targetStationId);
                tracker.assignEmployeeToStation(
                  empId: emp.employeeId,
                  empName: emp.fullName,
                  stationId: targetStationId,
                );
                final idx = tracker.registeredEmployees.indexWhere((e) => e.employeeId == emp.employeeId);
                if (idx != -1) {
                  tracker.registeredEmployees[idx] = emp.copyWith(
                    assignedStationId: targetStationId,
                    assignedStationName: stn.stationName,
                  );
                }
                Navigator.pop(dialogCtx);
                setState(() {});

                // Sync to Hostinger Cloud
                await ApiService.updateStationDetails(
                  stationId: targetStationId,
                  stationName: stn.stationName,
                  machineCode: stn.machineCode,
                  employeeId: emp.employeeId,
                  employeeName: emp.fullName,
                );
                await tracker.syncWithCloud();
                if (mounted) setState(() {});

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${emp.fullName} reassigned to ${stn.stationName} (Synced to Cloud)'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Reassign'),
            ),
          ],
        ),
      ),
    );
  }
}
