import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/services/mock_data_service.dart';
import '../../authentication/application/auth_notifier.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  bool _isCheckedIn = false;
  DateTime? _checkInTime;
  DateTime? _checkOutTime;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).currentUser;
    final now = DateTime.now();
    final timeFormat = DateFormat('hh:mm a');
    final dateFormat = DateFormat('EEEE, MMMM d, y');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance & Time Tracking'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Today's Clock Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      dateFormat.format(now),
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      timeFormat.format(now),
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: _isCheckedIn ? AppColors.success.withOpacity(0.12) : AppColors.warning.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _isCheckedIn ? 'CURRENTLY CHECKED IN' : 'NOT CHECKED IN',
                        style: TextStyle(
                          color: _isCheckedIn ? AppColors.success : AppColors.warning,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Clock In / Clock Out Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isCheckedIn ? Colors.grey.shade300 : AppColors.success,
                              foregroundColor: _isCheckedIn ? Colors.grey.shade700 : Colors.white,
                            ),
                            icon: const Icon(Icons.login),
                            label: const Text('Check In'),
                            onPressed: _isCheckedIn
                                ? null
                                : () {
                                    setState(() {
                                      _isCheckedIn = true;
                                      _checkInTime = DateTime.now();
                                    });
                                    MockDataService().attendanceLogs.insert(0, {
                                      'employeeId': user?.employeeId ?? 'EMP-01',
                                      'employeeName': user?.name ?? 'Employee',
                                      'type': 'CHECK_IN',
                                      'time': DateTime.now().toIso8601String(),
                                      'method': 'Mobile App GPS',
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Checked in successfully!')),
                                    );
                                  },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: !_isCheckedIn ? Colors.grey.shade300 : AppColors.error,
                              foregroundColor: !_isCheckedIn ? Colors.grey.shade700 : Colors.white,
                            ),
                            icon: const Icon(Icons.logout),
                            label: const Text('Check Out'),
                            onPressed: !_isCheckedIn
                                ? null
                                : () {
                                    setState(() {
                                      _isCheckedIn = false;
                                      _checkOutTime = DateTime.now();
                                    });
                                    MockDataService().attendanceLogs.insert(0, {
                                      'employeeId': user?.employeeId ?? 'EMP-01',
                                      'employeeName': user?.name ?? 'Employee',
                                      'type': 'CHECK_OUT',
                                      'time': DateTime.now().toIso8601String(),
                                      'method': 'Mobile App GPS',
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Checked out successfully!')),
                                    );
                                  },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.qr_code_2),
                      label: const Text('Scan QR for Station Attendance'),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Opening Station Attendance QR Reader...')),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Attendance Logs
            Text('Recent Attendance Logs', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),

            if (MockDataService().attendanceLogs.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.history_toggle_off, size: 40, color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        const Text('No recent logs recorded today'),
                      ],
                    ),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: MockDataService().attendanceLogs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final log = MockDataService().attendanceLogs[index];
                  final isCheckIn = log['type'] == 'CHECK_IN';
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isCheckIn ? AppColors.success.withOpacity(0.15) : AppColors.error.withOpacity(0.15),
                        child: Icon(isCheckIn ? Icons.login : Icons.logout, color: isCheckIn ? AppColors.success : AppColors.error, size: 20),
                      ),
                      title: Text(log['employeeName'] ?? 'Employee'),
                      subtitle: Text('${log['method']} • ${log['type']}'),
                      trailing: Text(
                        DateFormat('hh:mm a').format(DateTime.parse(log['time'])),
                        style: const TextStyle(fontWeight: FontWeight.bold),
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

