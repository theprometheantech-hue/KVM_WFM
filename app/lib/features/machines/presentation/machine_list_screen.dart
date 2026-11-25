import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/machine_model.dart';
import '../../../data/services/mock_data_service.dart';

class MachineListScreen extends StatefulWidget {
  const MachineListScreen({super.key});

  @override
  State<MachineListScreen> createState() => _MachineListScreenState();
}

class _MachineListScreenState extends State<MachineListScreen> {
  final mock = MockDataService();

  Color _getStatusColor(MachineStatus status) {
    switch (status) {
      case MachineStatus.active:
        return AppColors.success;
      case MachineStatus.full:
        return AppColors.warning;
      case MachineStatus.maintenance:
        return Colors.purple;
      case MachineStatus.inactive:
      case MachineStatus.offline:
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vending Machine Fleet'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Register Machine',
            onPressed: () => _showAddMachineDialog(),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: mock.machines.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final mch = mock.machines[index];
          final fillPct = (mch.currentCapacity / mch.maxCapacity).clamp(0.0, 1.0);
          final statusColor = _getStatusColor(mch.status);

          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.precision_manufacturing, color: AppColors.primary, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(mch.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              Text('${mch.machineCode} • S/N: ${mch.serialNumber}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          mch.status.displayName,
                          style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(mch.location, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Capacity Progress
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Internal Bin Capacity:', style: TextStyle(fontSize: 12)),
                      Text('${mch.currentCapacity} / ${mch.maxCapacity} Bottles (${(fillPct * 100).toInt()}%)',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: fillPct,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      fillPct > 0.85 ? AppColors.warning : AppColors.primary,
                    ),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),

                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.settings_outlined, size: 18),
                        label: const Text('Configure'),
                        onPressed: () {},
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(120, 36),
                          backgroundColor: AppColors.primary,
                        ),
                        icon: const Icon(Icons.sync_alt, size: 16),
                        label: const Text('Inspect'),
                        onPressed: () => _showMachineDetails(mch),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showMachineDetails(Machine m) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(m.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Machine Code: ${m.machineCode} | Serial: ${m.serialNumber}'),
            const Divider(height: 24),
            Text('Location: ${m.location}'),
            const SizedBox(height: 6),
            Text('Max Storage Capacity: ${m.maxCapacity} units'),
            const SizedBox(height: 6),
            Text('Current Storage Count: ${m.currentCapacity} units'),
            const SizedBox(height: 6),
            Text('Hardware Status: ${m.status.displayName}'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close Details'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddMachineDialog() {
    final codeCtrl = TextEditingController(text: 'MCH-00${mock.machines.length + 1}');
    final nameCtrl = TextEditingController();
    final serialCtrl = TextEditingController(text: 'RVM-X900-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}');
    final locCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Register New Vending Machine'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Machine Code')),
              const SizedBox(height: 10),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Machine Name')),
              const SizedBox(height: 10),
              TextField(controller: serialCtrl, decoration: const InputDecoration(labelText: 'Hardware Serial Number')),
              const SizedBox(height: 10),
              TextField(controller: locCtrl, decoration: const InputDecoration(labelText: 'Installation Location')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty && locCtrl.text.isNotEmpty) {
                setState(() {
                  mock.machines.add(
                    Machine(
                      id: codeCtrl.text,
                      machineCode: codeCtrl.text,
                      name: nameCtrl.text,
                      serialNumber: serialCtrl.text,
                      location: locCtrl.text,
                      maxCapacity: 500,
                      currentCapacity: 0,
                      status: MachineStatus.active,
                    ),
                  );
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Register Unit'),
          ),
        ],
      ),
    );
  }
}

