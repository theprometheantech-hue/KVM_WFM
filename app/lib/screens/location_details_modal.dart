import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/localization/language_service.dart';
import '../../data/services/tracker_service.dart';
import '../../data/models/duty_log_model.dart';
import 'gate_pass_history_screen.dart';

class LocationDetailsModal extends StatelessWidget {
  final StationDutyLog station;
  final VoidCallback? onAdd;
  final VoidCallback? onAddEmployee;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const LocationDetailsModal({
    super.key,
    required this.station,
    this.onAdd,
    this.onAddEmployee,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final fillPercentage = ((station.todayBottlesReceived - station.todayBottlesPacked) / 300).clamp(0.0, 1.0);
    final inBinHolding = (station.todayBottlesReceived - station.todayBottlesPacked).clamp(0, 9999);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle pill
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(station.stationName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text('Machine Code: ${station.machineCode} • Station ID: ${station.stationId}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    if (station.address != null && station.address!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.pin_drop, size: 12, color: Colors.blueGrey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              station.address!,
                              style: const TextStyle(fontSize: 11, color: Colors.blueGrey, fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: station.isPresent ? AppColors.success.withOpacity(0.12) : AppColors.error.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  station.isPresent ? 'ON DUTY' : 'UNATTENDED',
                  style: TextStyle(
                    color: station.isPresent ? AppColors.success : AppColors.error,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24),

          // Worker Details Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.person, color: AppColors.primary, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        station.isPresent ? 'Assigned Worker: ${station.employeeName}' : 'No worker currently on shift',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Text(
                        station.isPresent ? 'Worker ID: ${station.employeeId} • Shift In: ${station.checkInTime ?? "08:00 AM"}' : 'Kiosk requires staff attendance',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (station.isPresent && station.checkinLatitude != null && station.checkinLongitude != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.location_on, color: Colors.blue.shade700, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Shift GPS Location Verified', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Text(
                          '${station.checkinLatitude!.toStringAsFixed(6)}, ${station.checkinLongitude!.toStringAsFixed(6)}',
                          style: TextStyle(fontSize: 11, color: Colors.blue.shade900, fontFamily: 'monospace'),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: const Size(100, 32),
                    ),
                    icon: const Icon(Icons.map, size: 14),
                    label: const Text('Google Maps', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    onPressed: () async {
                      final uri = Uri.parse(
                        'https://www.google.com/maps/search/?api=1&query=${station.checkinLatitude},${station.checkinLongitude}',
                      );
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),

          // Bottle Stats Grid
          Row(
            children: [
              Expanded(child: _metricBox('Deposited Today', '${station.todayBottlesReceived} btls', AppColors.primary)),
              const SizedBox(width: 8),
              Expanded(child: _metricBox('Packed & Sent', '${station.todayBottlesPacked} btls', AppColors.warning)),
              const SizedBox(width: 8),
              Expanded(child: _metricBox('Holding in Bin', '$inBinHolding btls', Colors.teal)),
            ],
          ),
          const SizedBox(height: 14),

          // Bin Capacity Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Internal Bin Fill Level:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              Text('$inBinHolding / 300 Bottles (${(fillPercentage * 100).toInt()}%)',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: fillPercentage,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(
              fillPercentage > 0.85 ? AppColors.error : (fillPercentage > 0.6 ? AppColors.warning : AppColors.primary),
            ),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 20),

          // Action Buttons: Primary (Edit & Add Employee) and Secondary (Add Location, Delete, Close)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Primary Row: Edit Location and Add Employee
              Row(
                children: [
                  if (onEdit != null) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.teal.shade800,
                          side: BorderSide(color: Colors.teal.shade500),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
                        ),
                        icon: const Icon(Icons.edit_note, size: 18),
                        label: Text(
                          tr('edit_rename'),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          onEdit!();
                        },
                      ),
                    ),
                    if (onAddEmployee != null) const SizedBox(width: 8),
                  ],
                  if (onAddEmployee != null) ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
                        ),
                        icon: const Icon(Icons.person_add, size: 18),
                        label: Text(
                          tr('add_employee'),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          onAddEmployee!();
                        },
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              // Secondary Row: Add Location, Delete, Close
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (onAdd != null)
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blueGrey.shade800,
                        side: BorderSide(color: Colors.grey.shade400),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      icon: const Icon(Icons.add_location_alt, size: 16),
                      label: Text(
                        tr('add_location'),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        onAdd!();
                      },
                    ),
                  if (onDelete != null)
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red.shade700,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      ),
                      icon: const Icon(Icons.delete_outline, size: 17, color: Colors.red),
                      label: Text(
                        tr('delete_station'),
                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        onDelete!();
                      },
                    ),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text(tr('close')),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _metricBox(String label, String val, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(val, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 9, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

