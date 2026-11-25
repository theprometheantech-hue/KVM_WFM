import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/services/mock_data_service.dart';
import '../../authentication/application/auth_notifier.dart';

class EmployeeDailyBottleLogScreen extends ConsumerStatefulWidget {
  const EmployeeDailyBottleLogScreen({super.key});

  @override
  ConsumerState<EmployeeDailyBottleLogScreen> createState() => _EmployeeDailyBottleLogScreenState();
}

class _EmployeeDailyBottleLogScreenState extends ConsumerState<EmployeeDailyBottleLogScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final mock = MockDataService();

  // Inflow form controllers (Bottles Received from Machine Bins)
  final _receivedBilledCountCtrl = TextEditingController();
  final _damagedBottlesCtrl = TextEditingController(text: '0');
  final _inflowRemarksCtrl = TextEditingController();
  String _selectedSlot = '11:00 AM Midday Clearance';

  // Outflow form controllers (Bottles Sent to Vendors)
  final _sentCountCtrl = TextEditingController();
  final _cratesCountCtrl = TextEditingController(text: '4');
  final _driverNameCtrl = TextEditingController();
  final _vehicleNoCtrl = TextEditingController();
  final _outflowRemarksCtrl = TextEditingController();
  String _selectedVendor = 'EcoRecycle Solutions Ltd.';
  String _selectedCategory = '750ml Premium Liquor Glass';

  final List<String> _slots = [
    '09:00 AM Shift Opening Audit',
    '11:00 AM Midday Clearance',
    '02:30 PM Peak Hours Collection',
    '05:00 PM Afternoon Clearance',
    '08:00 PM Shift Handover Final',
  ];

  final List<String> _vendors = [
    'EcoRecycle Solutions Ltd.',
    'Distributor Bottle Reclamation Hub',
    'Pacific Glass & Metal Logistics',
    'Direct Brewery Return Depot',
  ];

  final List<String> _categories = [
    '750ml Premium Liquor Glass',
    '1000ml Heavy Bourbon Glass',
    'Standard Beer & Beverage Cans',
    'Mixed Assorted Bottles',
  ];

  // In-memory feed logs for the employee
  final List<Map<String, dynamic>> _inflowLogs = [
    {
      'id': 'RCV-001',
      'slot': '09:00 AM Shift Opening Audit',
      'bottles': 95,
      'damaged': 1,
      'net': 94,
      'time': DateTime.now().subtract(const Duration(hours: 4)).toIso8601String(),
      'status': 'VERIFIED'
    },
    {
      'id': 'RCV-002',
      'slot': '11:00 AM Midday Clearance',
      'bottles': 140,
      'damaged': 2,
      'net': 138,
      'time': DateTime.now().subtract(const Duration(hours: 1, minutes: 20)).toIso8601String(),
      'status': 'VERIFIED'
    },
  ];

  final List<Map<String, dynamic>> _outflowLogs = [
    {
      'id': 'VND-DISP-081',
      'vendor': 'EcoRecycle Solutions Ltd.',
      'category': '750ml Premium Liquor Glass',
      'bottles': 150,
      'crates': 6,
      'vehicle': 'KA-01-EA-4491',
      'driver': 'Vikram Singh',
      'time': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
      'status': 'HANDED OVER TO VENDOR'
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _receivedBilledCountCtrl.dispose();
    _damagedBottlesCtrl.dispose();
    _inflowRemarksCtrl.dispose();
    _sentCountCtrl.dispose();
    _cratesCountCtrl.dispose();
    _driverNameCtrl.dispose();
    _vehicleNoCtrl.dispose();
    _outflowRemarksCtrl.dispose();
    super.dispose();
  }

  void _submitReceivedEntry() {
    if (_receivedBilledCountCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the number of bottles received from machine.')),
      );
      return;
    }

    final gross = int.tryParse(_receivedBilledCountCtrl.text) ?? 0;
    final damaged = int.tryParse(_damagedBottlesCtrl.text) ?? 0;
    final net = (gross - damaged).clamp(0, gross);

    setState(() {
      _inflowLogs.insert(0, {
        'id': 'RCV-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
        'slot': _selectedSlot,
        'bottles': gross,
        'damaged': damaged,
        'net': net,
        'time': DateTime.now().toIso8601String(),
        'status': 'VERIFIED'
      });
      _receivedBilledCountCtrl.clear();
      _damagedBottlesCtrl.text = '0';
      _inflowRemarksCtrl.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Received $gross bottles recorded! (Net good: $net)'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _submitSentToVendorEntry() {
    if (_sentCountCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the number of bottles sent to vendor.')),
      );
      return;
    }

    final qty = int.tryParse(_sentCountCtrl.text) ?? 0;
    final crates = int.tryParse(_cratesCountCtrl.text) ?? 1;

    setState(() {
      _outflowLogs.insert(0, {
        'id': 'VND-DISP-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
        'vendor': _selectedVendor,
        'category': _selectedCategory,
        'bottles': qty,
        'crates': crates,
        'vehicle': _vehicleNoCtrl.text.isEmpty ? 'Scheduled Truck' : _vehicleNoCtrl.text,
        'driver': _driverNameCtrl.text.isEmpty ? 'Vendor Agent' : _driverNameCtrl.text,
        'time': DateTime.now().toIso8601String(),
        'status': 'HANDED OVER TO VENDOR'
      });
      _sentCountCtrl.clear();
      _cratesCountCtrl.text = '4';
      _driverNameCtrl.clear();
      _vehicleNoCtrl.clear();
      _outflowRemarksCtrl.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sent $qty bottles to $_selectedVendor successfully recorded!'),
        backgroundColor: AppColors.warning,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).currentUser;

    final totalReceivedToday = _inflowLogs.fold<int>(0, (sum, item) => sum + (item['net'] as int));
    final totalSentToVendorToday = _outflowLogs.fold<int>(0, (sum, item) => sum + (item['bottles'] as int));
    final currentlyInCrates = (totalReceivedToday - totalSentToVendorToday).clamp(0, 9999);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Bottle Receipts & Vendor Dispatch'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(icon: Icon(Icons.arrow_downward), text: '1. Received from Machine'),
            Tab(icon: Icon(Icons.local_shipping_outlined), text: '2. Sent to Vendor'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Station & Daily Net Banner
          Container(
            padding: const EdgeInsets.all(14),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Station: ${user?.assignedLocation ?? "Terminal 1 Concourse (MCH-001)"}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Text('Operator: ${user?.name ?? "Employee"} (ID: ${user?.employeeId ?? "EMP-01"})',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                  ),
                  child: Column(
                    children: [
                      const Text('Ready in Crates', style: TextStyle(fontSize: 9, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                      Text('$currentlyInCrates btls', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // TAB 1: BOTTLES RECEIVED FROM MACHINE
                _buildReceivedTab(totalReceivedToday),

                // TAB 2: BOTTLES SENT TO VENDOR
                _buildSentTab(totalSentToVendorToday),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceivedTab(int totalReceivedToday) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Entry Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.arrow_downward, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 10),
                      const Text('Add Bottles Received / Collected', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text('Enter the count when you open the machine bin to collect billed/returned bottles.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  const Divider(height: 20),

                  const Text('Collection Slot / Time', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: _selectedSlot,
                    items: _slots.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13)))).toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedSlot = v);
                    },
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total Bottles Collected', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _receivedBilledCountCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                hintText: 'e.g. 120',
                                prefixIcon: Icon(Icons.liquor, size: 20),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Damaged / Broken', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _damagedBottlesCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(hintText: '0'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: _inflowRemarksCtrl,
                    decoration: const InputDecoration(labelText: 'Bin Condition / Notes (Optional)'),
                  ),
                  const SizedBox(height: 18),

                  ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Save Received Bottles Entry'),
                    onPressed: _submitReceivedEntry,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Inflow History List
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Today\'s Collections from Machine', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Text('Total: $totalReceivedToday btls', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _inflowLogs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (ctx, idx) {
              final item = _inflowLogs[idx];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withOpacity(0.12),
                    child: const Icon(Icons.arrow_downward, color: AppColors.primary, size: 20),
                  ),
                  title: Text('${item['slot']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: Text(
                    'Collected: ${item['bottles']} | Broken: ${item['damaged']} | Net Good: ${item['net']}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('+${item['net']} Btls', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13)),
                      Text(DateFormat('hh:mm a').format(DateTime.parse(item['time'])), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSentTab(int totalSentToVendorToday) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Outflow Entry Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.local_shipping_outlined, color: AppColors.warning, size: 20),
                      ),
                      const SizedBox(width: 10),
                      const Text('Add Bottles Sent to Vendor', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text('Record the crates and bottles loaded onto the vendor or recycling transport.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  const Divider(height: 20),

                  const Text('Select Target Vendor', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: _selectedVendor,
                    items: _vendors.map((v) => DropdownMenuItem(value: v, child: Text(v, style: const TextStyle(fontSize: 13)))).toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedVendor = v);
                    },
                  ),
                  const SizedBox(height: 12),

                  const Text('Bottle Category / Type', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13)))).toList(),
                    onChanged: (c) {
                      if (c != null) setState(() => _selectedCategory = c);
                    },
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Bottles Sent (Units)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _sentCountCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                hintText: 'e.g. 150',
                                prefixIcon: Icon(Icons.check_box_outlined, size: 20),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Crates Packed', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _cratesCountCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(hintText: '4'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _driverNameCtrl,
                          decoration: const InputDecoration(labelText: 'Driver / Agent Name', prefixIcon: Icon(Icons.person, size: 18)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _vehicleNoCtrl,
                          decoration: const InputDecoration(labelText: 'Truck / Vehicle No.', prefixIcon: Icon(Icons.directions_car, size: 18)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
                    icon: const Icon(Icons.send_rounded),
                    label: const Text('Record Dispatch to Vendor'),
                    onPressed: _submitSentToVendorEntry,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Outflow History List
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Today\'s Dispatches to Vendors', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Text('Total: $totalSentToVendorToday btls', style: const TextStyle(color: AppColors.warning, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _outflowLogs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (ctx, idx) {
              final item = _outflowLogs[idx];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.warning.withOpacity(0.12),
                    child: const Icon(Icons.local_shipping, color: AppColors.warning, size: 20),
                  ),
                  title: Text('${item['vendor']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: Text(
                    '${item['category']} • ${item['crates']} crates\nDriver: ${item['driver']} (${item['vehicle']})',
                    style: const TextStyle(fontSize: 11),
                  ),
                  isThreeLine: true,
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('-${item['bottles']} Btls', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.warning, fontSize: 13)),
                      Text(DateFormat('hh:mm a').format(DateTime.parse(item['time'])), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

