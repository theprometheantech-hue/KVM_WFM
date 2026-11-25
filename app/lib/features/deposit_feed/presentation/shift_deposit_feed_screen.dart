import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/shift_deposit_reading_model.dart';
import '../../../data/services/mock_data_service.dart';
import '../../authentication/application/auth_notifier.dart';

class ShiftDepositFeedScreen extends ConsumerStatefulWidget {
  const ShiftDepositFeedScreen({super.key});

  @override
  ConsumerState<ShiftDepositFeedScreen> createState() => _ShiftDepositFeedScreenState();
}

class _ShiftDepositFeedScreenState extends ConsumerState<ShiftDepositFeedScreen> {
  final mock = MockDataService();
  final _billedCountController = TextEditingController();
  final _collectedController = TextEditingController(text: '0');
  final _damagedController = TextEditingController(text: '0');
  final _remarksController = TextEditingController();
  String _selectedSlot = '11:00 AM Mid-Morning Audit';
  String _binFillLevel = 'Normal (35% Full)';

  final List<String> _slots = [
    '09:00 AM Shift Start Baseline',
    '11:00 AM Mid-Morning Audit',
    '02:00 PM Midday Peak Audit',
    '05:00 PM Afternoon Audit',
    '08:00 PM Shift Handover Final',
  ];

  final List<String> _fillLevels = [
    'Low (< 20% Full)',
    'Normal (35% Full)',
    'Moderate (65% Full)',
    'High Alert (85% Full - Needs Clearance)',
    'Critical (95%+ Full - Machine Stops)',
  ];

  final List<ShiftDepositReading> _todayReadings = [
    ShiftDepositReading(
      id: 'READ-001',
      locationName: 'Central Terminal 1 Concourse',
      machineId: 'MCH-001',
      employeeId: 'EMP-MOP-03',
      employeeName: 'David Zhao',
      recordedAt: DateTime.now().subtract(const Duration(hours: 3)),
      readingSlot: '09:00 AM Shift Start Baseline',
      cumulativeMachineBilledCount: 140,
      bottlesCollectedThisSlot: 0,
      bottlesBrokenOrDamaged: 0,
      binFillStatus: 'Normal (35% Full)',
      remarks: 'Machine counters zeroed and operational.',
    ),
    ShiftDepositReading(
      id: 'READ-002',
      locationName: 'Central Terminal 1 Concourse',
      machineId: 'MCH-001',
      employeeId: 'EMP-MOP-03',
      employeeName: 'David Zhao',
      recordedAt: DateTime.now().subtract(const Duration(minutes: 45)),
      readingSlot: '11:00 AM Mid-Morning Audit',
      cumulativeMachineBilledCount: 228,
      bottlesCollectedThisSlot: 80,
      bottlesBrokenOrDamaged: 2,
      binFillStatus: 'Moderate (65% Full)',
      remarks: 'Heavy customer bottle deposit activity. Cleared 80 units into crate 1.',
    ),
  ];

  void _submitReading() {
    if (_billedCountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the machine billed bottle counter reading.')),
      );
      return;
    }

    final user = ref.read(authProvider).currentUser;
    final billedCount = int.tryParse(_billedCountController.text) ?? 0;
    final collected = int.tryParse(_collectedController.text) ?? 0;
    final damaged = int.tryParse(_damagedController.text) ?? 0;

    final newReading = ShiftDepositReading(
      id: 'READ-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      locationName: user?.assignedLocation ?? 'Terminal 1 Concourse',
      machineId: user?.assignedMachineId ?? 'MCH-001',
      employeeId: user?.employeeId ?? 'EMP-01',
      employeeName: user?.name ?? 'Employee',
      recordedAt: DateTime.now(),
      readingSlot: _selectedSlot,
      cumulativeMachineBilledCount: billedCount,
      bottlesCollectedThisSlot: collected,
      bottlesBrokenOrDamaged: damaged,
      binFillStatus: _binFillLevel,
      remarks: _remarksController.text.isEmpty ? 'Periodic reading logged.' : _remarksController.text,
    );

    setState(() {
      _todayReadings.insert(0, newReading);
      _billedCountController.clear();
      _collectedController.text = '0';
      _damagedController.text = '0';
      _remarksController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reading saved and broadcasted to Supervisor dashboard! (Billed count: $billedCount)'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hourly Bottle Deposit Feed'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // On-Duty Machine Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.location_on, color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'On-Duty Station: ${user?.assignedLocation ?? "Terminal 1 Concourse"}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Assigned Unit: ${user?.assignedMachineId ?? "MCH-001"} • Duty Staff: ${user?.name ?? "David Zhao"}',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.greenAccent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.fiber_manual_record, color: Colors.greenAccent, size: 10),
                        SizedBox(width: 4),
                        Text('TRACKING ON', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Reading Entry Form Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.playlist_add_check_rounded, color: AppColors.primary, size: 22),
                        const SizedBox(width: 8),
                        Text('Feed Machine Reading & Deposit Count', style: Theme.of(context).textTheme.titleMedium),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Check the machine display meter and record customer bottle deposits regularly during your shift.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                    const Divider(height: 24),

                    // Audit Slot
                    const Text('Audit Time Slot', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _selectedSlot,
                      items: _slots.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13)))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedSlot = val);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Machine Billed Count Meter
                    const Text('Cumulative Billed/Deposited Meter Count (*from machine screen)',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _billedCountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: 'e.g. 245 bottles displayed on machine',
                        prefixIcon: Icon(Icons.speed, size: 20),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Secondary inputs
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Collected for Vendor (Units)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _collectedController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(hintText: '0'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Damaged / Broken Glass', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _damagedController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(hintText: '0'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Bin Fill Level Indicator
                    const Text('Physical Bin Fill Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _binFillLevel,
                      items: _fillLevels.map((lvl) => DropdownMenuItem(value: lvl, child: Text(lvl, style: const TextStyle(fontSize: 13)))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _binFillLevel = val);
                      },
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: _remarksController,
                      decoration: const InputDecoration(labelText: 'Audit Remarks / Crate Tag / Notes (Optional)'),
                    ),
                    const SizedBox(height: 20),

                    ElevatedButton.icon(
                      icon: const Icon(Icons.send_rounded),
                      label: const Text('Submit Reading to Fleet Monitor'),
                      onPressed: _submitReading,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Today's Audit Trail Feed
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Today\'s Audit Log Feed', style: Theme.of(context).textTheme.titleMedium),
                Text('${_todayReadings.length} Submitted', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 10),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _todayReadings.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (ctx, idx) {
                final r = _todayReadings[idx];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(r.readingSlot, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            Text(
                              DateFormat('hh:mm a').format(r.recordedAt),
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('${r.locationName} (${r.machineId})', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _feedPill('Meter Count', '${r.cumulativeMachineBilledCount} btls', AppColors.primary),
                            _feedPill('Collected Out', '${r.bottlesCollectedThisSlot} btls', AppColors.warning),
                            _feedPill('Damaged', '${r.bottlesBrokenOrDamaged} btls', AppColors.error),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('Bin Status: ${r.binFillStatus}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        if (r.remarks != null && r.remarks!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text('Remarks: ${r.remarks}', style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.blueGrey)),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _feedPill(String title, String val, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(title, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(val, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

