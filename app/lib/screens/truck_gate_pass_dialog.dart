import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/onboarding_model.dart';

class TruckGatePassDialog extends StatelessWidget {
  final TruckLoadingRecord record;

  const TruckGatePassDialog({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with Company Stamp
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('VENDOR GATE PASS', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    Text('Pass ID: ${record.loadingId}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.green)),
                  child: const Text('AUTHORIZED', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11)),
                ),
              ],
            ),
            const Divider(height: 24),

            // Logistics Details Grid
            _receiptRow('Origin Station', '${record.stationId} (${record.machineCode})'),
            _receiptRow('Recycling / Vendor', record.vendorName),
            _receiptRow('Packages Loaded', '${record.packagesCount} Crates / Bags'),
            _receiptRow('Total Bottle Count', '${record.totalBottlesLoaded} Bottles'),
            _receiptRow('Truck Vehicle No.', record.truckVehicleNumber),
            _receiptRow('Driver Name', record.driverName),
            _receiptRow('Driver Mobile', record.driverMobile.isEmpty ? 'N/A' : record.driverMobile),
            _receiptRow('Dispatch Timestamp', record.timestamp),
            _receiptRow('Cleared By Worker', '${record.employeeName} (${record.employeeId})'),

            const Divider(height: 24),

            // Driver Acknowledgement Note
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(8)),
              child: const Row(
                children: [
                  Icon(Icons.verified_user, color: Colors.teal, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Driver custody confirmed. Scanned and verified for gate exit and transport to vendor hub.',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.share, size: 18),
                    label: const Text('Share PDF Pass'),
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Gate Pass PDF shared to Vendor Driver & Supervisor!')),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Done'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _receiptRow(String title, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          Text(val, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}

