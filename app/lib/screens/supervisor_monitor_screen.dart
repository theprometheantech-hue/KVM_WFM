import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/localization/language_service.dart';
import '../../data/models/onboarding_model.dart';
import '../../data/models/duty_log_model.dart';
import '../../data/services/tracker_service.dart';
import '../../data/services/api_service.dart';
import 'gate_pass_history_screen.dart';
import 'admin_staff_management_screen.dart';
import 'cash_reconciliation_screen.dart';
import 'location_details_modal.dart';
import 'login_screen.dart';

class SupervisorMonitorScreen extends StatefulWidget {
  const SupervisorMonitorScreen({super.key});

  @override
  State<SupervisorMonitorScreen> createState() => _SupervisorMonitorScreenState();
}

class _SupervisorMonitorScreenState extends State<SupervisorMonitorScreen> {
  final tracker = TrackerService();
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    tracker.addListener(_refreshState);
    LanguageService().addListener(_refreshState);
    tracker.syncWithCloud();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    tracker.removeListener(_refreshState);
    LanguageService().removeListener(_refreshState);
    super.dispose();
  }

  void _refreshState() {
    if (mounted) setState(() {});
  }

  void _showAddEmployeeModal({String? preselectedStationId}) {
    final nameCtrl = TextEditingController();
    final mobileCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final machineCodeCtrl = TextEditingController();
    final stationNameCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    bool showMachineEditor = false;
    bool isSaving = false;
    String selectedStationId = preselectedStationId ??
        (tracker.stations.isNotEmpty ? tracker.stations.first.stationId : 'STN-001');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) {
          final selectedStation = tracker.stations.firstWhere(
            (s) => s.stationId == selectedStationId,
            orElse: () => tracker.stations.isNotEmpty
                ? tracker.stations.first
                : StationDutyLog(
                    stationId: 'STN-001',
                    stationName: 'Default Station',
                    machineCode: 'MCH-001',
                    employeeId: '',
                    employeeName: 'Unassigned',
                    isPresent: false,
                    todayBottlesReceived: 0,
                    todayBottlesPacked: 0,
                    todayCratesPacked: 0,
                    lastUpdatedTime: 'Just now',
                  ),
          );

          if (machineCodeCtrl.text.isEmpty && !showMachineEditor) {
            machineCodeCtrl.text = selectedStation.machineCode;
            stationNameCtrl.text = selectedStation.stationName;
            addressCtrl.text = selectedStation.address ?? '';
          }

          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 16,
              left: 20,
              right: 20,
              top: 12,
            ),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.90,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.person_add_alt_1, color: Colors.green.shade700, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Add New Employee', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          Text('Provision credentials & assign to station', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const Divider(height: 20),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Admin will auto-generate Corporate Employee ID & temporary login password. The worker is directly assigned to the station.',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: nameCtrl,
                          autofocus: true,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          decoration: InputDecoration(
                            labelText: 'Full Name *',
                            hintText: 'e.g. Ramesh Kumar',
                            prefixIcon: const Icon(Icons.badge_outlined, color: Colors.green),
                            filled: true,
                            fillColor: Colors.green.shade50.withOpacity(0.3),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: mobileCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: 'Mobile Number *',
                            hintText: 'e.g. 9876543210',
                            prefixIcon: const Icon(Icons.phone_android_outlined),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Email Address (Optional)',
                            hintText: 'e.g. ramesh@example.com',
                            prefixIcon: const Icon(Icons.email_outlined),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Flexible(
                              child: Text(
                                'Assign Station *',
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: isSaving
                                  ? null
                                  : () {
                                      Navigator.pop(ctx);
                                      _showAddLocationModal();
                                    },
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.teal.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.teal.shade200),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.add_location_alt, size: 14, color: Colors.teal.shade700),
                                    const SizedBox(width: 4),
                                    Text(
                                      '+ New Location',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.teal.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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
                              onChanged: isSaving ? null : (val) {
                                if (val != null) {
                                  setModalState(() {
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
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: () {
                            setModalState(() {
                              showMachineEditor = !showMachineEditor;
                              if (showMachineEditor) {
                                machineCodeCtrl.text = selectedStation.machineCode;
                                stationNameCtrl.text = selectedStation.stationName;
                                addressCtrl.text = selectedStation.address ?? '';
                              }
                            });
                          },
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(showMachineEditor ? Icons.keyboard_arrow_up : Icons.tune, size: 18, color: AppColors.primary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    showMachineEditor ? 'Hide Machine Customization' : 'Customize Machine Details for this Station',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (showMachineEditor) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(top: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: machineCodeCtrl,
                                        decoration: InputDecoration(
                                          labelText: 'Machine Code *',
                                          hintText: 'e.g. MCH-ARN-01',
                                          prefixIcon: const Icon(Icons.qr_code, size: 18),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                          isDense: true,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextField(
                                        controller: stationNameCtrl,
                                        decoration: InputDecoration(
                                          labelText: 'Station Name *',
                                          hintText: 'e.g. Arani Station Hub',
                                          prefixIcon: const Icon(Icons.location_on, size: 18),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                          isDense: true,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                TextField(
                                  controller: addressCtrl,
                                  decoration: InputDecoration(
                                    labelText: 'Landmark / Area / Physical Address',
                                    hintText: 'e.g. Near Old Bus Stand Platform 2',
                                    prefixIcon: const Icon(Icons.pin_drop_outlined, size: 18),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    isDense: true,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),

                        SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade700,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: isSaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.check_circle_outline, size: 20),
                            label: Text(
                              isSaving ? 'Provisioning & Saving...' : 'Provision & Assign Employee',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            onPressed: isSaving ? null : () async {
                              final name = nameCtrl.text.trim();
                              final mobile = mobileCtrl.text.trim();
                              final email = emailCtrl.text.trim();

                              if (name.isEmpty || mobile.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please enter Full Name and Mobile Number.')),
                                );
                                return;
                              }

                              setModalState(() => isSaving = true);

                              final targetStationName = stationNameCtrl.text.trim().isNotEmpty
                                  ? stationNameCtrl.text.trim()
                                  : selectedStation.stationName;
                              final targetMachineCode = machineCodeCtrl.text.trim().isNotEmpty
                                  ? machineCodeCtrl.text.trim()
                                  : selectedStation.machineCode;
                              final targetAddress = addressCtrl.text.trim();

                              if (showMachineEditor) {
                                await tracker.updateStationDetails(
                                  stationId: selectedStationId,
                                  stationName: targetStationName,
                                  machineCode: targetMachineCode,
                                  address: targetAddress,
                                  employeeName: name,
                                );
                              }

                              final createdEmp = tracker.addEmployeeByAdmin(
                                fullName: name,
                                mobileNumber: mobile,
                                email: email,
                                assignedStationId: selectedStationId,
                                assignedStationName: targetStationName,
                                machineCode: targetMachineCode,
                                address: targetAddress,
                              );

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

                              Navigator.pop(ctx);

                              if (apiRes != null && apiRes['success'] == true) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Employee $name & machine saved to Hostinger MySQL!'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }

                              _showCredentialsModal(createdEmp);
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                        Center(
                          child: TextButton(
                            onPressed: isSaving ? null : () => Navigator.pop(ctx),
                            child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showEditStationModal(StationDutyLog stn) {
    final nameCtrl = TextEditingController(text: stn.stationName);
    final codeCtrl = TextEditingController(text: stn.machineCode);
    final addressCtrl = TextEditingController(text: stn.address ?? '');
    String selectedWorkerId = stn.employeeId;
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 16,
            left: 20,
            right: 20,
            top: 12,
          ),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.88,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top drag pill
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.edit_location_alt, color: Colors.teal.shade700, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Edit Location',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        Text(
                          '${stn.stationName} • ID: ${stn.stationId}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(height: 20),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Update location name, machine code, physical address, or reassign operator.',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: nameCtrl,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        decoration: InputDecoration(
                          labelText: 'Location / Station Name *',
                          hintText: 'e.g. Arani Central Hub',
                          prefixIcon: const Icon(Icons.location_on_outlined, color: Colors.teal),
                          filled: true,
                          fillColor: Colors.teal.shade50.withOpacity(0.35),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: codeCtrl,
                        decoration: InputDecoration(
                          labelText: 'Machine Hardware Code *',
                          hintText: 'e.g. MCH-ARN-01',
                          prefixIcon: const Icon(Icons.qr_code_2),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: addressCtrl,
                        decoration: InputDecoration(
                          labelText: 'Landmark / Area Physical Address',
                          hintText: 'e.g. Opposite Old Bus Stand Platform 2',
                          prefixIcon: const Icon(Icons.pin_drop_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text('Assigned Operator', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: tracker.registeredEmployees.any((e) => e.employeeId == selectedWorkerId) ? selectedWorkerId : '',
                            isExpanded: true,
                            items: [
                              const DropdownMenuItem<String>(
                                value: '',
                                child: Text('Unassigned (Vacant)', style: TextStyle(color: Colors.grey)),
                              ),
                              ...tracker.registeredEmployees.where((e) => e.employeeId != 'ADMIN-01').map((emp) {
                                return DropdownMenuItem<String>(
                                  value: emp.employeeId,
                                  child: Text('${emp.fullName} (${emp.employeeId})'),
                                );
                              }),
                            ],
                            onChanged: isSaving ? null : (val) {
                              if (val != null) {
                                setModalState(() => selectedWorkerId = val);
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Primary Save Button (Full Width, prominent, with loading spinner)
                      SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal.shade700,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.check_circle_outline, size: 20),
                          label: Text(
                            isSaving ? 'Saving Changes...' : 'Save Changes',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          onPressed: isSaving ? null : () async {
                            final newName = nameCtrl.text.trim();
                            final newCode = codeCtrl.text.trim();
                            final newAddress = addressCtrl.text.trim();

                            if (newName.isEmpty || newCode.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Machine Code and Station Name cannot be empty.')),
                              );
                              return;
                            }

                            setModalState(() => isSaving = true);

                            String workerName = 'Unassigned';
                            if (selectedWorkerId.isNotEmpty) {
                              final found = tracker.registeredEmployees.where((e) => e.employeeId == selectedWorkerId);
                              if (found.isNotEmpty) workerName = found.first.fullName;
                            }

                            await tracker.updateStationDetails(
                              stationId: stn.stationId,
                              stationName: newName,
                              machineCode: newCode,
                              address: newAddress,
                              employeeId: selectedWorkerId,
                              employeeName: workerName,
                            );

                            // Update registered employees mapping
                            for (int i = 0; i < tracker.registeredEmployees.length; i++) {
                              final emp = tracker.registeredEmployees[i];
                              if (emp.employeeId == selectedWorkerId) {
                                tracker.registeredEmployees[i] = emp.copyWith(
                                  assignedStationId: stn.stationId,
                                  assignedStationName: newName,
                                );
                              } else if (emp.assignedStationId == stn.stationId && emp.employeeId != selectedWorkerId) {
                                tracker.registeredEmployees[i] = emp.copyWith(
                                  assignedStationId: null,
                                  assignedStationName: 'Unassigned',
                                );
                              }
                            }

                            await tracker.syncWithCloud();
                            if (mounted) setState(() {});

                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Station ${stn.stationId} saved as "$newName" successfully!'),
                                backgroundColor: Colors.teal.shade800,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Secondary Actions Row: Delete Station & Cancel
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red.shade700,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                            label: const Text(
                              'Delete Station',
                              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            onPressed: isSaving ? null : () {
                              Navigator.pop(ctx);
                              _confirmDeleteStation(stn);
                            },
                          ),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                            onPressed: isSaving ? null : () => Navigator.pop(ctx),
                            child: const Text('Cancel'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReassignStationStaffModal(StationDutyLog stn) {
    String selectedWorkerId = stn.employeeId;
    final staff = tracker.registeredEmployees.where((e) => e.employeeId != 'ADMIN-01').toList();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 16,
            left: 20,
            right: 20,
            top: 12,
          ),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top drag pill
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.swap_horiz, color: Colors.indigo.shade700, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tr('reassign_staff'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        Text('${stn.stationName} • ID: ${stn.stationId}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(height: 20),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Select an existing registered staff operator or provision a new staff member for this station:',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 14),
                      const Text('Choose Assigned Staff Operator *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: staff.any((e) => e.employeeId == selectedWorkerId) ? selectedWorkerId : '',
                            isExpanded: true,
                            items: [
                              const DropdownMenuItem<String>(
                                value: '',
                                child: Text('Unassigned (Vacant)', style: TextStyle(color: Colors.grey)),
                              ),
                              ...staff.map((emp) {
                                return DropdownMenuItem<String>(
                                  value: emp.employeeId,
                                  child: Text('${emp.fullName} (🪪 ${emp.employeeId})'),
                                );
                              }),
                            ],
                            onChanged: isSaving ? null : (val) {
                              if (val != null) {
                                setModalState(() => selectedWorkerId = val);
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.person_add, size: 18),
                        label: const Text('+ Provision New Staff Member', style: TextStyle(fontWeight: FontWeight.w600)),
                        onPressed: isSaving ? null : () {
                          Navigator.pop(ctx);
                          _showAddEmployeeModal(preselectedStationId: stn.stationId);
                        },
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.check_circle_outline, size: 20),
                          label: Text(
                            isSaving ? 'Saving Assignment...' : 'Save Assignment',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          onPressed: isSaving ? null : () async {
                            setModalState(() => isSaving = true);
                            String workerName = 'Unassigned';
                            if (selectedWorkerId.isNotEmpty) {
                              final found = staff.where((e) => e.employeeId == selectedWorkerId);
                              if (found.isNotEmpty) workerName = found.first.fullName;
                            }

                            await tracker.updateStationDetails(
                              stationId: stn.stationId,
                              stationName: stn.stationName,
                              machineCode: stn.machineCode,
                              address: stn.address,
                              employeeId: selectedWorkerId,
                              employeeName: workerName,
                            );

                            for (int i = 0; i < tracker.registeredEmployees.length; i++) {
                              final emp = tracker.registeredEmployees[i];
                              if (emp.employeeId == selectedWorkerId) {
                                tracker.registeredEmployees[i] = emp.copyWith(
                                  assignedStationId: stn.stationId,
                                  assignedStationName: stn.stationName,
                                );
                              } else if (emp.assignedStationId == stn.stationId && emp.employeeId != selectedWorkerId) {
                                tracker.registeredEmployees[i] = emp.copyWith(
                                  assignedStationId: null,
                                  assignedStationName: 'Unassigned',
                                );
                              }
                            }

                            await tracker.syncWithCloud();
                            if (mounted) setState(() {});
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Staff for "${stn.stationName}" updated to $workerName!'),
                                backgroundColor: Colors.teal.shade800,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: TextButton(
                          onPressed: isSaving ? null : () => Navigator.pop(ctx),
                          child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCredentialsModal(RegisteredEmployee emp) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Employee Created & Assigned!'),
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
              'Hand over these credentials to the employee. They can log in immediately and set their password.',
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

  void _showAllLocationsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final stns = tracker.stations;
            return Container(
              height: MediaQuery.of(context).size.height * 0.82,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.location_on, color: AppColors.primary, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${tr('locations')} (${stns.length} Total)',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Manage fleet stations: Add, edit names, or delete units.',
                                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.teal.shade800,
                              side: BorderSide(color: Colors.teal.shade400),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            icon: const Icon(Icons.add_location_alt, size: 15),
                            label: Text(tr('add_location'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            onPressed: () {
                              Navigator.pop(ctx);
                              _showAddLocationModal();
                            },
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            icon: const Icon(Icons.person_add, size: 15),
                            label: Text(tr('add_employee'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            onPressed: () {
                              Navigator.pop(ctx);
                              _showAddEmployeeModal();
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Expanded(
                    child: ListView.separated(
                      itemCount: stns.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, idx) {
                        final s = stns[idx];
                        final isVacant = s.employeeName == 'Unassigned' || s.employeeName.isEmpty;
                        return Card(
                          elevation: 1.5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: Colors.teal.shade50,
                                      child: Text('${idx + 1}', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal.shade800, fontSize: 11)),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(s.stationName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), overflow: TextOverflow.ellipsis),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: s.isPresent ? Colors.green.shade50 : Colors.red.shade50,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        s.isPresent ? tr('staff_present') : tr('unattended'),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: s.isPresent ? Colors.green.shade800 : Colors.red.shade800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'ID: ${s.stationId} • Machine: ${s.machineCode} • Worker: ${isVacant ? tr('unassigned_vacant') : s.employeeName}',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                ),
                                if (s.address != null && s.address!.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'Address: ${s.address}',
                                    style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade700),
                                  ),
                                ],
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.teal.shade800,
                                          side: BorderSide(color: Colors.teal.shade300),
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          minimumSize: const Size(0, 32),
                                        ),
                                        icon: const Icon(Icons.edit_note, size: 16),
                                        label: Text(tr('edit_rename'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                        onPressed: () {
                                          Navigator.pop(ctx);
                                          _showEditStationModal(s);
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    TextButton.icon(
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.red.shade700,
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        minimumSize: const Size(0, 32),
                                      ),
                                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 16),
                                      label: Text(tr('delete_station'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red)),
                                      onPressed: () {
                                        Navigator.pop(ctx);
                                        _confirmDeleteStation(s);
                                      },
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
          },
        );
      },
    );
  }

  void _showAddLocationModal() {
    final locationNameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 16,
            left: 20,
            right: 20,
            top: 12,
          ),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.add_location_alt, color: Colors.teal.shade700, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Add New Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        Text('Add a new operational vending station', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(height: 20),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Create a new operational vending station. It will instantly appear on your fleet grid.',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: locationNameCtrl,
                        autofocus: true,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        decoration: InputDecoration(
                          labelText: 'Location / Station Name *',
                          hintText: 'e.g. Vellore Bus Terminus Hub',
                          prefixIcon: const Icon(Icons.location_on_outlined, color: Colors.teal),
                          filled: true,
                          fillColor: Colors.teal.shade50.withOpacity(0.35),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: codeCtrl,
                        decoration: InputDecoration(
                          labelText: 'Station / Machine Code (Optional)',
                          hintText: 'e.g. MCH-VEL-01 (Auto-generated if empty)',
                          prefixIcon: const Icon(Icons.qr_code),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal.shade700,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.check, size: 20),
                          label: Text(
                            isSaving ? 'Adding Station...' : 'Add Station',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          onPressed: isSaving ? null : () async {
                            final locName = locationNameCtrl.text.trim();
                            if (locName.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please enter a Location / Station Name.')),
                              );
                              return;
                            }

                            setModalState(() => isSaving = true);

                            final newStation = tracker.addNewStationLocation(
                              locationName: locName,
                              machineCode: codeCtrl.text.trim().isNotEmpty ? codeCtrl.text.trim() : null,
                            );

                            await ApiService.addStationLocation(
                              locationName: newStation.stationName,
                              machineCode: newStation.machineCode,
                            );

                            await tracker.syncWithCloud();
                            if (mounted) setState(() {});
                            Navigator.pop(ctx);

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Station "${newStation.stationName}" added to fleet!'),
                                backgroundColor: Colors.teal.shade800,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: TextButton(
                          onPressed: isSaving ? null : () => Navigator.pop(ctx),
                          child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showStaffOnDutyModal() {
    final onDutyStations = tracker.stations.where((s) => s.isPresent).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            left: 20,
            right: 20,
            top: 12,
          ),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag pill
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.badge, color: Colors.green.shade700, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Staff On Duty (${onDutyStations.length} Active)',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        const Text(
                          'Real-time personnel attendance & shift performance',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(height: 20),
              if (onDutyStations.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_off_outlined, size: 54, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text(
                          'No staff currently on shift.',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Personnel check-ins will appear live here automatically.',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.badge_outlined, size: 16),
                          label: const Text('View All Staff Directory'),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _showStaffRosterSheet();
                          },
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: onDutyStations.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, idx) {
                      final stn = onDutyStations[idx];
                      final isUnassigned = stn.employeeName == 'Unassigned' || stn.employeeName.isEmpty;
                      final workerName = isUnassigned ? 'Field Operator' : stn.employeeName;

                      return Card(
                        elevation: 1.5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.green.shade100),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: Colors.green.shade50,
                                    child: Text(
                                      workerName.isNotEmpty ? workerName[0].toUpperCase() : 'O',
                                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade800),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          workerName,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                        ),
                                        Text(
                                          'ID: ${stn.employeeId.isNotEmpty ? stn.employeeId : "Active"} • Machine: ${stn.machineCode}',
                                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.green.shade300),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 7,
                                          height: 7,
                                          decoration: BoxDecoration(color: Colors.green.shade600, shape: BoxShape.circle),
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          'ON DUTY',
                                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              // Location row
                              Row(
                                children: [
                                  const Icon(Icons.location_on, size: 14, color: Colors.teal),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      'Station: ${stn.stationName}',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              if (stn.checkinAddress != null && stn.checkinAddress!.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Padding(
                                  padding: const EdgeInsets.only(left: 18),
                                  child: Text(
                                    'GPS: ${stn.checkinAddress}',
                                    style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade700),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 10),
                              // Live metrics chips
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    Column(
                                      children: [
                                        Text(
                                          '${stn.todayBottlesReceived}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.accent),
                                        ),
                                        const Text('Bottles Inflow', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                                      ],
                                    ),
                                    Container(width: 1, height: 24, color: Colors.grey.shade300),
                                    Column(
                                      children: [
                                        Text(
                                          '${stn.todayBottlesPacked}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.warning),
                                        ),
                                        const Text('Packed to Vendor', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                                      ],
                                    ),
                                    Container(width: 1, height: 24, color: Colors.grey.shade300),
                                    Column(
                                      children: [
                                        Text(
                                          '${stn.todayCratesPacked}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.teal),
                                        ),
                                        const Text('Crates Packed', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                                      ],
                                    ),
                                  ],
                                ),
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
      },
    );
  }

  void _showStaffRosterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        final staff = tracker.registeredEmployees.where((e) => e.employeeId != 'ADMIN-01').toList();

        return Container(
          padding: const EdgeInsets.all(20),
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Staff Directory (${staff.length} Employees)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(),
              if (staff.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.badge_outlined, size: 56, color: Colors.grey.shade400),
                        const SizedBox(height: 10),
                        const Text('No employees provisioned yet.', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.person_add),
                          label: const Text('+ Add First Employee'),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _showAddEmployeeModal();
                          },
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: staff.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, idx) {
                      final emp = staff[idx];
                      return Card(
                        elevation: 1.5,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: AppColors.primary.withOpacity(0.12),
                                    child: Text(
                                      emp.fullName.isNotEmpty ? emp.fullName[0].toUpperCase() : 'E',
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          emp.fullName,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 3),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.shade50,
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: Colors.blue.shade200),
                                          ),
                                          child: Text(
                                            '🪪 ID: ${emp.employeeId}',
                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.blue.shade900),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                    tooltip: 'Remove Employee',
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      _confirmDeleteEmployee(emp);
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      'Station: ${emp.assignedStationName ?? "Unassigned"}',
                                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.phone_android_outlined, size: 13, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(
                                        emp.mobileNumber.isNotEmpty ? emp.mobileNumber : 'No mobile',
                                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.shade50,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: Colors.amber.shade200),
                                    ),
                                    child: Text(
                                      'Pass: ${emp.password}',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.amber.shade900),
                                    ),
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
      },
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
          'This will revoke their login access, unassign them from ${emp.assignedStationName ?? "their station"}, and permanently remove them from the Hostinger database.',
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
                        ? 'Employee "${emp.fullName}" removed successfully.'
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

  void _confirmDeleteStation(StationDutyLog stn) {
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
            const Text('Delete Station?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Text(
          'Are you sure you want to delete station "${stn.stationName}" (${stn.stationId})?\n\n'
          'This will remove it from the fleet grid and unassign any employee linked to it in Hostinger.',
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
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Deleting station ${stn.stationId} from database...')),
              );
              final ok = await tracker.deleteStation(stn.stationId);
              await tracker.syncWithCloud();
              if (mounted) {
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(ok
                        ? 'Station "${stn.stationName}" deleted successfully.'
                        : 'Station deleted locally.'),
                    backgroundColor: ok ? Colors.green : Colors.orange,
                  ),
                );
              }
            },
            child: const Text('Yes, Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stations = tracker.stations;
    final totalPresent = stations.where((s) => s.isPresent).length;
    final totalReceived = stations.fold<int>(0, (sum, s) => sum + s.todayBottlesReceived);
    final totalPacked = stations.fold<int>(0, (sum, s) => sum + s.todayBottlesPacked);
    final totalCrates = stations.fold<int>(0, (sum, s) => sum + s.todayCratesPacked);
    final totalCashHandedOut = tracker.cashExchanges.fold<double>(0, (sum, e) => sum + e.cashPaidToCustomer);
    final totalExchangedBottles = tracker.cashExchanges.fold<int>(0, (sum, e) => sum + e.bottlesCollected);
    final activeStaffCount = tracker.registeredEmployees.where((e) => e.employeeId != 'ADMIN-01').length;

    final filtered = stations.where((s) {
      final matchesSearch = s.stationName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.machineCode.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.employeeName.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesFilter = _filter == 'All' ||
          (_filter == 'Present' && s.isPresent) ||
          (_filter == 'Absent' && !s.isPresent);

      return matchesSearch && matchesFilter;
    }).toList();

    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        title: Text(
          isMobile ? (LanguageService().isTamil ? 'கண்காணிப்பு' : 'Fleet Monitor') : tr('admin_monitor_title'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        actions: [
          const Center(
            child: Padding(
              padding: EdgeInsets.only(top: 10, bottom: 10, right: 8),
              child: LanguageToggleButton(isCompact: true),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.sync, color: Colors.blueAccent),
            tooltip: tr('sync_cloud'),
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('sync_cloud') + '...')));
              await tracker.syncWithCloud();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr('cloud_sync_complete')), backgroundColor: Colors.green));
              }
            },
          ),
          if (isMobile) ...[
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              tooltip: 'More Fleet Options',
              onSelected: (val) {
                if (val == 'cash') {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const CashReconciliationScreen()));
                } else if (val == 'staff_roster') {
                  _showStaffRosterSheet();
                } else if (val == 'staff_mgmt') {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminStaffManagementScreen()));
                } else if (val == 'gate_pass') {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const GatePassHistoryScreen()));
                } else if (val == 'logout') {
                  tracker.clearLoginSession();
                  Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const SimpleLoginScreen()), (route) => false);
                }
              },
              itemBuilder: (ctx) => [
                PopupMenuItem(
                  value: 'cash',
                  child: Row(
                    children: [
                      const Icon(Icons.currency_rupee, color: Colors.green, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          LanguageService().isTamil ? 'ரொக்க தணிக்கை' : 'Cash Audit (Float)',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'staff_roster',
                  child: Row(
                    children: [
                      const Icon(Icons.badge_outlined, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          LanguageService().isTamil ? 'பணியாளர் பட்டியல்' : 'Staff Directory',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'staff_mgmt',
                  child: Row(
                    children: [
                      const Icon(Icons.people_alt_outlined, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          LanguageService().isTamil ? 'பணியாளர் மேலாண்மை' : 'Staff Management',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'gate_pass',
                  child: Row(
                    children: [
                      const Icon(Icons.receipt_long, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          LanguageService().isTamil ? 'லாரி கேட் பாஸ்' : 'Truck Gate Passes',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      const Icon(Icons.logout, color: Colors.redAccent, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          tr('logout'),
                          style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.currency_rupee, color: Colors.green),
              tooltip: tr('cash_audit_title'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CashReconciliationScreen()),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.badge_outlined),
              tooltip: tr('view_all_staff'),
              onPressed: _showStaffRosterSheet,
            ),
            IconButton(
              icon: const Icon(Icons.people_alt_outlined),
              tooltip: tr('staff_management_title'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminStaffManagementScreen()),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.receipt_long),
              tooltip: tr('gate_pass_title'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GatePassHistoryScreen()),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.redAccent),
              tooltip: tr('logout'),
              onPressed: () {
                tracker.clearLoginSession();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const SimpleLoginScreen()),
                  (route) => false,
                );
              },
            ),
          ],
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => tracker.syncWithCloud(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // 1. SCROLLABLE UPPER FLEET TOTALS & ACTIONS
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (isMobile) ...[
                      Row(
                        children: [
                          Expanded(
                            child: _statPill(
                              tr('locations'),
                              '${stations.length}',
                              Icons.location_on,
                              AppColors.primary,
                              onTap: _showAllLocationsModal,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _statPill(
                              tr('staff_on_duty'),
                              '$totalPresent',
                              Icons.person,
                              AppColors.success,
                              onTap: _showStaffOnDutyModal,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _statPill(tr('total_received'), '$totalReceived', Icons.arrow_downward, AppColors.accent),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _statPill(tr('total_packed'), '$totalPacked ($totalCrates crt)', Icons.inventory_2, AppColors.warning),
                          ),
                        ],
                      ),
                    ] else ...[
                      Row(
                        children: [
                          Expanded(
                            child: _statPill(
                              tr('locations'),
                              '${stations.length}',
                              Icons.location_on,
                              AppColors.primary,
                              onTap: _showAllLocationsModal,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _statPill(
                              tr('staff_on_duty'),
                              '$totalPresent',
                              Icons.person,
                              AppColors.success,
                              onTap: _showStaffOnDutyModal,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _statPill(tr('total_received'), '$totalReceived', Icons.arrow_downward, AppColors.accent),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _statPill(tr('total_packed'), '$totalPacked ($totalCrates crt)', Icons.inventory_2, AppColors.warning),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 12),

                    // Harmonized Action Bar for Add Employee & Add Location
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: isMobile
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tr('fleet_management_actions'),
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Staff: $activeStaffCount Provisioned | Stations: ${stations.length} Total',
                                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.teal.shade800,
                                          backgroundColor: Colors.teal.shade50.withOpacity(0.4),
                                          side: BorderSide(color: Colors.teal.shade400, width: 1.2),
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                          minimumSize: const Size(0, 36),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        icon: const Icon(Icons.add_location_alt, size: 15),
                                        label: Text(tr('add_location'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                        onPressed: _showAddLocationModal,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.green.shade800,
                                          backgroundColor: Colors.green.shade50.withOpacity(0.4),
                                          side: BorderSide(color: Colors.green.shade600, width: 1.2),
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                          minimumSize: const Size(0, 36),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        icon: const Icon(Icons.person_add, size: 15),
                                        label: Text(tr('add_employee'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                        onPressed: () => _showAddEmployeeModal(),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        tr('fleet_management_actions'),
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Staff: $activeStaffCount Provisioned | Stations: ${stations.length} Total',
                                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.teal.shade800,
                                    backgroundColor: Colors.teal.shade50.withOpacity(0.4),
                                    side: BorderSide(color: Colors.teal.shade400, width: 1.2),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    minimumSize: const Size(0, 36),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  icon: const Icon(Icons.add_location_alt, size: 15),
                                  label: Text(tr('add_location'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  onPressed: _showAddLocationModal,
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.green.shade800,
                                    backgroundColor: Colors.green.shade50.withOpacity(0.4),
                                    side: BorderSide(color: Colors.green.shade600, width: 1.2),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    minimumSize: const Size(0, 36),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  icon: const Icon(Icons.person_add, size: 15),
                                  label: Text(tr('add_employee'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  onPressed: () => _showAddEmployeeModal(),
                                ),
                              ],
                            ),
                    ),

                    if (totalCashHandedOut > 0) ...[
                      const SizedBox(height: 10),
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const CashReconciliationScreen()),
                          );
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            border: Border.all(color: Colors.green.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.currency_rupee, color: Colors.green.shade800, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Manual Cash Given to Customers: ₹${totalCashHandedOut.toStringAsFixed(0)} ($totalExchangedBottles btls into machine)',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade900, fontSize: 13),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: Colors.green.shade700, borderRadius: BorderRadius.circular(12)),
                                child: Text(tr('audit_float'), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // 2. STICKY / PINNED SEARCH & FILTER BAR
            SliverPersistentHeader(
              pinned: true,
              delegate: _FleetFilterHeaderDelegate(
                searchController: _searchCtrl,
                onSearchChanged: (val) => setState(() => _searchQuery = val),
                selectedFilter: _filter,
                onFilterChanged: (filter) => setState(() => _filter = filter),
                onViewAllStaff: _showStaffRosterSheet,
              ),
            ),

            // 3. SCROLLABLE STATION LIST
            if (filtered.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 56, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(
                        tr('no_stations_match'),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final stn = filtered[index];
                      final isVacant = stn.employeeName == 'Unassigned' || stn.employeeName.isEmpty;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Card(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                                builder: (_) => LocationDetailsModal(
                                  station: stn,
                                  onAdd: _showAddLocationModal,
                                  onAddEmployee: () => _showAddEmployeeModal(preselectedStationId: stn.stationId),
                                  onEdit: () => _showEditStationModal(stn),
                                  onDelete: () => _confirmDeleteStation(stn),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(stn.stationName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                            Text('Station ID: ${stn.stationId} | Machine: ${stn.machineCode}',
                                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                          ],
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          if (stn.isPresent && stn.checkinLatitude != null) ...[
                                            IconButton(
                                              icon: const Icon(Icons.my_location, size: 18, color: Colors.green),
                                              tooltip: 'GPS Verified (${stn.checkinLatitude!.toStringAsFixed(3)}, ${stn.checkinLongitude!.toStringAsFixed(3)})',
                                              onPressed: () {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text('Staff check-in GPS verified: ${stn.checkinLatitude!.toStringAsFixed(4)}, ${stn.checkinLongitude!.toStringAsFixed(4)}'),
                                                    backgroundColor: Colors.green.shade800,
                                                  ),
                                                );
                                              },
                                            ),
                                          ],
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: stn.isPresent ? Colors.green.shade50 : Colors.red.shade50,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              stn.isPresent ? tr('staff_present') : tr('no_staff_absent'),
                                              style: TextStyle(
                                                color: stn.isPresent ? Colors.green.shade700 : Colors.red.shade700,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),

                                  Row(
                                    children: [
                                      Icon(
                                        Icons.badge,
                                        size: 16,
                                        color: isVacant ? Colors.grey : AppColors.primary,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          isVacant ? 'Worker: Unassigned' : 'Worker: ${stn.employeeName} (${stn.employeeId})',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: isVacant ? Colors.grey.shade700 : Colors.black87,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text('Updated: ${stn.lastUpdatedTime}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                    ],
                                  ),
                                  const SizedBox(height: 10),

                                  // Dedicated Action Buttons Row
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: isVacant ? Colors.green.shade600 : Colors.blue.shade50,
                                            foregroundColor: isVacant ? Colors.white : Colors.blue.shade900,
                                            elevation: 0,
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                            minimumSize: const Size(0, 34),
                                          ),
                                          icon: Icon(isVacant ? Icons.person_add : Icons.swap_horiz, size: 14),
                                          label: Text(
                                            isVacant ? tr('assign_staff') : tr('reassign_staff'),
                                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          onPressed: () {
                                            _showReassignStationStaffModal(stn);
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.teal.shade800,
                                            side: BorderSide(color: Colors.teal.shade400),
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                            minimumSize: const Size(0, 34),
                                          ),
                                          icon: const Icon(Icons.edit_note, size: 16),
                                          label: Text(
                                            tr('edit_rename'),
                                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          onPressed: () {
                                            _showEditStationModal(stn);
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                        tooltip: tr('delete_station'),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                                        onPressed: () {
                                          _confirmDeleteStation(stn);
                                        },
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _cardPill(tr('customer_deposits'), '${stn.todayBottlesReceived} Bottles', AppColors.primary),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: _cardPill(tr('bottles_packed'), '${stn.todayBottlesPacked} Bottles', AppColors.warning),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: _cardPill(tr('crates_ready'), '${stn.todayCratesPacked} Crates', Colors.teal),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: filtered.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _statPill(String title, String val, IconData icon, Color color, {VoidCallback? onTap}) {
    final content = Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: onTap != null ? Border.all(color: color.withOpacity(0.35), width: 1.2) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(title, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis),
              ),
              if (onTap != null)
                Icon(Icons.touch_app, size: 12, color: color.withOpacity(0.85)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(val, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
              if (onTap != null) ...[
                const SizedBox(width: 4),
                Text(tr('view_manage'), style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color.withOpacity(0.8))),
              ],
            ],
          ),
        ],
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: content,
        ),
      );
    }

    return content;
  }

  Widget _cardPill(String title, String val, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
          const SizedBox(height: 2),
          Text(val, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: color)),
        ],
      ),
    );
  }
}

class _FleetFilterHeaderDelegate extends SliverPersistentHeaderDelegate {
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;
  final VoidCallback onViewAllStaff;

  _FleetFilterHeaderDelegate({
    required this.searchController,
    required this.onSearchChanged,
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.onViewAllStaff,
  });

  @override
  double get minExtent => 98.0;

  @override
  double get maxExtent => 98.0;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: overlapsContent ? Colors.grey.shade300 : Colors.grey.shade200,
            width: 1,
          ),
        ),
        boxShadow: overlapsContent
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 38,
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: tr('search_hint'),
                prefixIcon: const Icon(Icons.search, size: 18),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
                fillColor: Colors.grey.shade50,
                filled: true,
              ),
              onChanged: onSearchChanged,
            ),
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                FilterChip(
                  label: Text(tr('all_stations')),
                  selected: selectedFilter == 'All',
                  onSelected: (_) => onFilterChanged('All'),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: Text(tr('present')),
                  selected: selectedFilter == 'Present',
                  onSelected: (_) => onFilterChanged('Present'),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: Text(tr('absent')),
                  selected: selectedFilter == 'Absent',
                  onSelected: (_) => onFilterChanged('Absent'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(color: AppColors.primary.withOpacity(0.4)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.groups, size: 16),
                  label: Text(tr('view_all_staff'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  onPressed: onViewAllStaff,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _FleetFilterHeaderDelegate oldDelegate) {
    return oldDelegate.selectedFilter != selectedFilter;
  }
}
