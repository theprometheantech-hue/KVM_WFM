import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/services/mock_data_service.dart';
import '../../authentication/application/auth_notifier.dart';

class ShiftAttendanceLocationScreen extends ConsumerStatefulWidget {
  const ShiftAttendanceLocationScreen({super.key});

  @override
  ConsumerState<ShiftAttendanceLocationScreen> createState() => _ShiftAttendanceLocationScreenState();
}

class _ShiftAttendanceLocationScreenState extends ConsumerState<ShiftAttendanceLocationScreen> {
  bool _isCheckedIn = true;
  DateTime _shiftStartTime = DateTime.now().subtract(const Duration(hours: 3, minutes: 25));
  String _currentShift = 'Morning Shift (08:00 AM - 04:00 PM)';
  String _verifiedLocation = 'Terminal 1 Concourse Kiosk (Machine MCH-001)';
  String _gpsCoordinates = '13.0827° N, 80.2707° E (Geo-Fence Verified)';

  final List<Map<String, String>> _recentDays = [
    {
      'date': 'Yesterday (Nov 18)',
      'in': '08:02 AM',
      'out': '04:15 PM',
      'duration': '8h 13m',
      'location': 'Terminal 1 Concourse (MCH-001)',
      'status': 'VERIFIED'
    },
    {
      'date': 'Mon (Nov 17)',
      'in': '07:58 AM',
      'out': '04:05 PM',
      'duration': '8h 07m',
      'location': 'Terminal 1 Concourse (MCH-001)',
      'status': 'VERIFIED'
    },
    {
      'date': 'Sun (Nov 16)',
      'in': '08:15 AM',
      'out': '04:30 PM',
      'duration': '8h 15m',
      'location': 'Terminal 1 Concourse (MCH-001)',
      'status': 'VERIFIED'
    },
  ];

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).currentUser;
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Shift & Location Attendance'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Active Shift Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user?.name ?? 'David Zhao', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Text('Emp ID: ${user?.employeeId ?? "EMP-MOP-03"} • ${user?.role.name ?? "Operator"}',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: _isCheckedIn ? AppColors.success.withOpacity(0.12) : AppColors.error.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.fiber_manual_record, color: _isCheckedIn ? AppColors.success : AppColors.error, size: 10),
                              const SizedBox(width: 4),
                              Text(
                                _isCheckedIn ? 'ON-DUTY' : 'OFF-DUTY',
                                style: TextStyle(
                                  color: _isCheckedIn ? AppColors.success : AppColors.error,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),

                    // Station & GPS Geo-Tag
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.location_on, color: AppColors.primary, size: 18),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(_verifiedLocation,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.gps_fixed, color: AppColors.textSecondary, size: 14),
                              const SizedBox(width: 6),
                              Text(_gpsCoordinates, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.schedule, color: AppColors.textSecondary, size: 14),
                              const SizedBox(width: 6),
                              Text(_currentShift, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Shift Duration Counter
                    if (_isCheckedIn) ...[
                      const Text('Shift Time Elapsed Today', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(
                        '03h 25m Active',
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                      Text('Clocked in at ${DateFormat('hh:mm a').format(_shiftStartTime)}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      const SizedBox(height: 20),
                    ],

                    // Check In / Check Out Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isCheckedIn ? Colors.grey.shade300 : AppColors.success,
                              foregroundColor: _isCheckedIn ? Colors.grey.shade600 : Colors.white,
                            ),
                            icon: const Icon(Icons.login),
                            label: const Text('Shift Check-In'),
                            onPressed: _isCheckedIn
                                ? null
                                : () {
                                    setState(() {
                                      _isCheckedIn = true;
                                      _shiftStartTime = DateTime.now();
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Shift check-in recorded with geo-tag at Machine MCH-001!')),
                                    );
                                  },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: !_isCheckedIn ? Colors.grey.shade300 : AppColors.error,
                              foregroundColor: !_isCheckedIn ? Colors.grey.shade600 : Colors.white,
                            ),
                            icon: const Icon(Icons.logout),
                            label: const Text('Shift Check-Out'),
                            onPressed: !_isCheckedIn
                                ? null
                                : () {
                                    setState(() => _isCheckedIn = false);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Shift check-out recorded! Hours submitted for supervisor approval.')),
                                    );
                                  },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.qr_code_scanner),
                      label: const Text('Re-Scan Station QR to Verify Presence'),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Scanning Machine QR tag... Geo-location verified!')),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Past Daily Attendance Logs
            Text('My Daily Attendance History', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),

            ..._recentDays.map(
              (d) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(d['date']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 2),
                          Text('${d['in']} - ${d['out']} (${d['duration']})', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          Text(d['location']!, style: const TextStyle(fontSize: 11, color: Colors.blueGrey)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.success.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                        child: Text(d['status']!, style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 10)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

