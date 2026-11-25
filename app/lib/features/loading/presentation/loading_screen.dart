import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/machine_model.dart';
import '../../../data/models/product_model.dart';
import '../../../data/services/mock_data_service.dart';
import '../../authentication/application/auth_notifier.dart';
import '../../barcode_scanner/presentation/scanner_screen.dart';

class LoadingScreen extends ConsumerStatefulWidget {
  const LoadingScreen({super.key});

  @override
  ConsumerState<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends ConsumerState<LoadingScreen> {
  final mock = MockDataService();
  Machine? _selectedMachine;
  Product? _scannedProduct;
  final _quantityController = TextEditingController(text: '12');
  final _remarksController = TextEditingController(text: 'Scheduled morning replenishment');

  @override
  void initState() {
    super.initState();
    if (mock.machines.isNotEmpty) {
      _selectedMachine = mock.machines.first;
    }
  }

  void _submitLoading() {
    if (_selectedMachine == null || _scannedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select machine and scan a bottle product.')),
      );
      return;
    }

    final qty = int.tryParse(_quantityController.text) ?? 1;
    final user = ref.read(authProvider).currentUser;

    final prevStock = _selectedMachine!.currentCapacity;
    final updatedStock = prevStock + qty;

    final entry = {
      'loadingId': 'LOAD-${DateTime.now().millisecondsSinceEpoch}',
      'employeeId': user?.employeeId ?? 'EMP-OP',
      'machineId': _selectedMachine!.machineCode,
      'productId': _scannedProduct!.productId,
      'productName': _scannedProduct!.name,
      'barcode': _scannedProduct!.barcode,
      'quantity': qty,
      'timestamp': DateTime.now().toIso8601String(),
      'previousStock': prevStock,
      'updatedStock': updatedStock,
      'remarks': _remarksController.text,
      'status': 'CONFIRMED',
    };

    mock.loadingHistory.insert(0, entry);

    // Update machine capacity
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
        status: updatedStock >= _selectedMachine!.maxCapacity ? MachineStatus.full : _selectedMachine!.status,
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Loaded $qty bottles into ${_selectedMachine!.name} successfully!'),
        backgroundColor: AppColors.success,
      ),
    );

    setState(() {
      _scannedProduct = null;
      _quantityController.text = '12';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bottle Loading Operation'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Target Machine Dropdown
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Select Target Machine', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<Machine>(
                      value: _selectedMachine,
                      items: mock.machines.map((m) {
                        return DropdownMenuItem(
                          value: m,
                          child: Text('${m.name} (${m.currentCapacity}/${m.maxCapacity})'),
                        );
                      }).toList(),
                      onChanged: (m) => setState(() => _selectedMachine = m),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Scan Bottle Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Bottle Product to Load', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    if (_scannedProduct == null)
                      OutlinedButton.icon(
                        icon: const Icon(Icons.qr_code_scanner),
                        label: const Text('Scan Bottle Barcode'),
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
                          color: AppColors.primary.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.liquor, color: AppColors.primary, size: 30),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_scannedProduct!.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text('${_scannedProduct!.brand} • Barcode: ${_scannedProduct!.barcode}',
                                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.grey),
                              onPressed: () => setState(() => _scannedProduct = null),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _quantityController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Loading Quantity (Bottles)'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _remarksController,
                      decoration: const InputDecoration(labelText: 'Remarks / Batch Code'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            ElevatedButton.icon(
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Confirm & Save Loading'),
              onPressed: _submitLoading,
            ),
            const SizedBox(height: 24),

            // Recent Loading Feed
            Text('Recent Loading History', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (mock.loadingHistory.isEmpty)
              const Text('No loadings logged yet today', style: TextStyle(color: Colors.grey))
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: mock.loadingHistory.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (ctx, idx) {
                  final item = mock.loadingHistory[idx];
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.add_shopping_cart, color: AppColors.primary),
                      title: Text('${item['productName']} (x${item['quantity']})'),
                      subtitle: Text('${item['machineId']} • Prev: ${item['previousStock']} -> New: ${item['updatedStock']}'),
                      trailing: const Text('CONFIRMED', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 11)),
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

