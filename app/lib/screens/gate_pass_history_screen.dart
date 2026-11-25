import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/services/tracker_service.dart';
import 'truck_gate_pass_dialog.dart';

class GatePassHistoryScreen extends StatelessWidget {
  const GatePassHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tracker = TrackerService();
    final passes = tracker.truckDispatches;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendor Gate Pass Archive'),
      ),
      body: passes.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  const Text('No gate passes issued yet today', style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: passes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final p = passes[index];
                return Card(
                  child: InkWell(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => TruckGatePassDialog(record: p),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(p.loadingId, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.green.shade300),
                                ),
                                child: const Text(
                                  'GATE EXIT AUTHORIZED',
                                  style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text('${p.vendorName} • ${p.packagesCount} Packages (${p.totalBottlesLoaded} btls)',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text('Truck: ${p.truckVehicleNumber} • Driver: ${p.driverName} (${p.driverMobile})',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Station: ${p.stationId} (${p.machineCode})',
                                  style: const TextStyle(fontSize: 11, color: Colors.blueGrey)),
                              Text(p.timestamp, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

