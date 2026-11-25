import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/machine_model.dart';
import '../../../data/models/product_model.dart';
import '../../../data/services/mock_data_service.dart';
import '../../authentication/application/auth_notifier.dart';
import '../../barcode_scanner/presentation/scanner_screen.dart';

class UnloadingScreen extends ConsumerStatefulWidget {
  const UnloadingScreen({super.key});

  @override
  ConsumerState<UnloadingScreen> createState() => _UnloadingScreenState();
}

class _UnloadingScreenState extends ConsumerState<UnloadingScreen> {
  final mock = MockDataService();
  Machine? _selectedMachine;
  Product? _scannedProduct;
  final _quantityController = TextEditingController(text: '10');
  String _selectedReason = 'Bottle collection';

  final List<String> _unloadingReasons = [
    'Bottle collection',
    'Stock transfer',
    'Damaged bottles',
    'Expired stock',
    'Machine maintenance',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    if (mock.machines.isNotEmpty) {
      _selectedMachine = mock.machines.first;
    }
  }

  void _submitUnloading() {
    if (_selectedMachine == null || _scannedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select machine and product to unload.')),
      );
      return;
    }

    final qty = int.tryParse(_quantityController.text) ?? 1;
    final user = ref.read(authProvider).currentUser;

    final prevStock = _selectedMachine!.currentCapacity;
    final updatedStock = (prevStock - qty).clamp(0, _selectedMachine!.maxCapacity);

    final entry = {
      'unloadingId': 'UNLOAD-${DateTime.now().millisecondsSinceEpoch}',
      'employeeId': user?.employeeId ?? 'EMP-OP',
      'machineId': _selectedMachine!.machineCode,
      'productId': _scannedProduct!.productId,
      'productName': _scannedProduct!.name,
      'quantity': qty,
      'reason': _selectedReason,
      'timestamp': DateTime.now().toIso8601String(),
      'status': 'APPROVED',
    };

    mock.unloadingHistory.insert(0, entry);

    // Update machine
    final idx = mock.machines.indexWhere((m) => m.id == _selectedMachine!.id);
    if (idx != -1) {
      mock.machines[idx] = Machine(
        id: _selectedMachine!.id,
        machineCode: _selectedMachine!.machineCode,
        name: _selectedMachine!.name,
        serialNumber: _selectedMachine!.serialNumber,
        location: _selectedMachine!.location,
        maxCapacity: _selectedMachine!.maxCapacity,
        currentCapacity: updatedStock,
        status: updatedStock == 0 ? MachineStatus.inactive : _selectedMachine!.status,
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Unloaded $qty bottles (${_selectedReason}) successfully!'),
        backgroundColor: AppColors.warning,
      ),
    );

    setState(() {
      _scannedProduct = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bottle Unloading & Bin Clearance'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Select Source Machine', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<Machine>(
                      value: _selectedMachine,
                      items: mock.machines.map((m) {
                        return DropdownMenuItem(
                          value: m,
                          child: Text('${m.name} (${m.currentCapacity} bottles inside)'),
                        );
                      }).toList(),
                      onChanged: (m) => setState(() => _selectedMachine = m),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Product to Unload', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    if (_scannedProduct == null)
                      OutlinedButton.icon(
                        icon: const Icon(Icons.qr_code_scanner),
                        label: const Text('Scan Product Barcode'),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ScannerScreen(
                                onProductScanned: (p) {
                                  setState(() => _scannedProduct = p);
                                  Navigator.pop(context);
                                },
                              ),
                            ),
                          );
                        },
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.warning.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.remove_shopping_cart, color: AppColors.warning, size: 28),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_scannedProduct!.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text('Barcode: ${_scannedProduct!.barcode}', style: const TextStyle(fontSize: 12)),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => setState(() => _scannedProduct = null),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _quantityController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Unloading Quantity'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedReason,
                      decoration: const InputDecoration(labelText: 'Unloading Reason'),
                      items: _unloadingReasons.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedReason = val);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
              icon: const Icon(Icons.inventory_2_outlined),
              label: const Text('Confirm Unloading & Supervisor Record'),
              onPressed: _submitUnloading,
            ),
            const SizedBox(height: 24),

            Text('Unloading History', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (mock.unloadingHistory.isEmpty)
              const Text('No unloading history recorded yet', style: TextStyle(color: Colors.grey))
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: mock.unloadingHistory.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (ctx, idx) {
                  final item = mock.unloadingHistory[idx];
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.upload_rounded, color: AppColors.warning),
                      title: Text('${item['productName']} (-${item['quantity']})'),
                      subtitle: Text('${item['machineId']} • Reason: ${item['reason']}'),
                      trailing: const Text('APPROVED', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 11)),
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

