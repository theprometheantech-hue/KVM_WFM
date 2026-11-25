import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/machine_model.dart';
import '../../../data/models/vendor_return_model.dart';
import '../../../data/services/mock_data_service.dart';
import '../../authentication/application/auth_notifier.dart';

class VendorReturnScreen extends ConsumerStatefulWidget {
  const VendorReturnScreen({super.key});

  @override
  ConsumerState<VendorReturnScreen> createState() => _VendorReturnScreenState();
}

class _VendorReturnScreenState extends ConsumerState<VendorReturnScreen> {
  final mock = MockDataService();
  final List<VendorReturnBatch> _batches = [
    VendorReturnBatch(
      batchCode: 'VND-BAT-2026-081',
      machineId: 'MCH-001',
      machineName: 'Station Alpha - Terminal 1',
      collectorEmployeeId: 'EMP-MOP-03',
      collectorName: 'David Zhao',
      vendorName: 'EcoRecycle Solutions Hub',
      bottleCategory: '750ml Premium Glass',
      totalBottles: 120,
      estimatedCreditValue: 180.00,
      status: VendorBatchStatus.handedOverToVendor,
      collectedAt: DateTime.now().subtract(const Duration(hours: 3)),
      supervisorRemarks: 'Count verified and sealed in 5 crates.',
    ),
    VendorReturnBatch(
      batchCode: 'VND-BAT-2026-082',
      machineId: 'MCH-002',
      machineName: 'Bay Area Metro Dual Vender',
      collectorEmployeeId: 'EMP-MOP-03',
      collectorName: 'David Zhao',
      vendorName: 'Distributor Glass Reclamation',
      bottleCategory: 'Standard Spirits & Beer Cans',
      totalBottles: 85,
      estimatedCreditValue: 85.00,
      status: VendorBatchStatus.supervisorApproved,
      collectedAt: DateTime.now().subtract(const Duration(minutes: 50)),
      supervisorRemarks: 'Waiting for vendor pickup vehicle.',
    ),
  ];

  void _showCreateBatchDialog() {
    Machine? selectedMachine = mock.machines.first;
    String selectedVendor = 'EcoRecycle Solutions Hub';
    String selectedCategory = '750ml Premium Glass Bottles';
    final qtyCtrl = TextEditingController(text: '50');
    final remarksCtrl = TextEditingController(text: 'Emptied from return compartment');

    final vendors = [
      'EcoRecycle Solutions Hub',
      'Distributor Glass Reclamation',
      'Pacific Beverage Logistics',
    ];

    final categories = [
      '750ml Premium Glass Bottles',
      '1000ml Heavy Bourbon Glass',
      'Standard Beer & Spirits Cans',
      'Mixed Recycling Containers',
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create Vendor Return Batch'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Source Vending Machine', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                DropdownButtonFormField<Machine>(
                  value: selectedMachine,
                  items: mock.machines.map((m) {
                    return DropdownMenuItem(value: m, child: Text('${m.name} (${m.currentCapacity} bottles inside)'));
                  }).toList(),
                  onChanged: (m) => setDialogState(() => selectedMachine = m),
                ),
                const SizedBox(height: 12),
                const Text('Target Recycling Vendor', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  value: selectedVendor,
                  items: vendors.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                  onChanged: (v) => setDialogState(() => selectedVendor = v!),
                ),
                const SizedBox(height: 12),
                const Text('Bottle Category / Type', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (c) => setDialogState(() => selectedCategory = c!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: qtyCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Quantity of Bottles Collected (Units)'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: remarksCtrl,
                  decoration: const InputDecoration(labelText: 'Crate Label / Packaging Remarks'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final qty = int.tryParse(qtyCtrl.text) ?? 1;
                final user = ref.read(authProvider).currentUser;
                final rate = selectedCategory.contains('Premium') ? 1.50 : 1.00;

                final newBatch = VendorReturnBatch(
                  batchCode: 'VND-BAT-2026-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
                  machineId: selectedMachine?.machineCode ?? 'MCH-001',
                  machineName: selectedMachine?.name ?? 'Machine',
                  collectorEmployeeId: user?.employeeId ?? 'EMP-OP',
                  collectorName: user?.name ?? 'Employee',
                  vendorName: selectedVendor,
                  bottleCategory: selectedCategory,
                  totalBottles: qty,
                  estimatedCreditValue: qty * rate,
                  status: VendorBatchStatus.collected,
                  collectedAt: DateTime.now(),
                  supervisorRemarks: remarksCtrl.text,
                );

                setState(() => _batches.insert(0, newBatch));

                // Decrement return bin count in machine
                if (selectedMachine != null) {
                  final idx = mock.machines.indexWhere((m) => m.id == selectedMachine!.id);
                  if (idx != -1) {
                    final updatedCap = (mock.machines[idx].currentCapacity - qty).clamp(0, mock.machines[idx].maxCapacity);
                    mock.machines[idx] = Machine(
                      id: mock.machines[idx].id,
                      machineCode: mock.machines[idx].machineCode,
                      name: mock.machines[idx].name,
                      serialNumber: mock.machines[idx].serialNumber,
                      location: mock.machines[idx].location,
                      maxCapacity: mock.machines[idx].maxCapacity,
                      currentCapacity: updatedCap,
                      status: updatedCap == 0 ? MachineStatus.active : mock.machines[idx].status,
                    );
                  }
                }

                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Batch ${newBatch.batchCode} ($qty bottles) staged for vendor pickup!'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
              child: const Text('Stage for Dispatch'),
            ),
          ],
        ),
      ),
    );
  }

  void _showHandoverModal(VendorReturnBatch batch, int index) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(batch.batchCode, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Text(batch.status.displayName, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 11)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text('Vendor: ${batch.vendorName}'),
            Text('From Machine: ${batch.machineName} (${batch.machineId})'),
            Text('Collected By: ${batch.collectorName} (${batch.collectorEmployeeId})'),
            Text('Bottle Class: ${batch.bottleCategory}'),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total Units: ${batch.totalBottles} bottles', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('Estimated Deposit Credit: \$${batch.estimatedCreditValue.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.success)),
              ],
            ),
            const SizedBox(height: 20),
            if (batch.status == VendorBatchStatus.collected)
              ElevatedButton.icon(
                icon: const Icon(Icons.verified_outlined),
                label: const Text('Supervisor Sign-off & Approve'),
                onPressed: () {
                  setState(() {
                    _batches[index] = VendorReturnBatch(
                      batchCode: batch.batchCode,
                      machineId: batch.machineId,
                      machineName: batch.machineName,
                      collectorEmployeeId: batch.collectorEmployeeId,
                      collectorName: batch.collectorName,
                      vendorName: batch.vendorName,
                      bottleCategory: batch.bottleCategory,
                      totalBottles: batch.totalBottles,
                      estimatedCreditValue: batch.estimatedCreditValue,
                      status: VendorBatchStatus.supervisorApproved,
                      collectedAt: batch.collectedAt,
                      supervisorRemarks: 'Supervisor approved for truck loading.',
                    );
                  });
                  Navigator.pop(ctx);
                },
              )
            else if (batch.status == VendorBatchStatus.supervisorApproved)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                icon: const Icon(Icons.local_shipping_outlined),
                label: const Text('Vendor Driver Handover & Seal Manifest'),
                onPressed: () {
                  setState(() {
                    _batches[index] = VendorReturnBatch(
                      batchCode: batch.batchCode,
                      machineId: batch.machineId,
                      machineName: batch.machineName,
                      collectorEmployeeId: batch.collectorEmployeeId,
                      collectorName: batch.collectorName,
                      vendorName: batch.vendorName,
                      bottleCategory: batch.bottleCategory,
                      totalBottles: batch.totalBottles,
                      estimatedCreditValue: batch.estimatedCreditValue,
                      status: VendorBatchStatus.handedOverToVendor,
                      collectedAt: batch.collectedAt,
                      supervisorRemarks: 'Transferred to vendor driver with digital signature.',
                    );
                  });
                  Navigator.pop(ctx);
                },
              )
            else
              OutlinedButton.icon(
                icon: const Icon(Icons.print_outlined),
                label: const Text('Print Vendor Consignment Manifest (PDF)'),
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Downloading Vendor Consignment Manifest...')),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalBottlesCollected = _batches.fold<int>(0, (sum, b) => sum + b.totalBottles);
    final totalVendorCredit = _batches.fold<double>(0.0, (sum, b) => sum + b.estimatedCreditValue);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendor Return & Custody Handover'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_outlined),
            tooltip: 'Log New Vendor Batch',
            onPressed: () => _showCreateBatchDialog(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Summary Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Vendor Logistics Summary', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 6),
                  Text(
                    '$totalBottlesCollected Bottles Cleared from Fleet',
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Vendor Refund Claim: \$${totalVendorCredit.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.lightGreenAccent, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Active Vendor Return Batches', style: Theme.of(context).textTheme.titleMedium),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(minimumSize: const Size(120, 36)),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Collect Batch'),
                  onPressed: () => _showCreateBatchDialog(),
                ),
              ],
            ),
            const SizedBox(height: 12),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _batches.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (ctx, idx) {
                final b = _batches[idx];
                final isDone = b.status == VendorBatchStatus.handedOverToVendor;

                return Card(
                  child: InkWell(
                    onTap: () => _showHandoverModal(b, idx),
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(b.batchCode, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: (isDone ? AppColors.success : AppColors.warning).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  b.status.displayName,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isDone ? AppColors.success : AppColors.warning,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text('${b.machineName} • ${b.bottleCategory}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          Text('Vendor: ${b.vendorName}', style: const TextStyle(fontSize: 12)),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Quantity: ${b.totalBottles} units', style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text('Claim: \$${b.estimatedCreditValue.toStringAsFixed(2)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                              Text(
                                DateFormat('hh:mm a').format(b.collectedAt),
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

