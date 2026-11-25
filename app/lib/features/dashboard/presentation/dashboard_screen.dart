import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/machine_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/mock_data_service.dart';
import '../../authentication/application/auth_notifier.dart';
import '../../authentication/presentation/login_screen.dart';
import '../../employees/presentation/employee_list_screen.dart';
import '../../attendance/presentation/attendance_screen.dart';
import '../../machines/presentation/machine_list_screen.dart';
import '../../products/presentation/product_list_screen.dart';
import '../../loading/presentation/loading_screen.dart';
import '../../unloading/presentation/unloading_screen.dart';
import '../../transactions/presentation/transaction_screen.dart';
import '../../barcode_scanner/presentation/scanner_screen.dart';
import '../../reports/presentation/reports_screen.dart';
import '../../vendor_returns/presentation/vendor_return_screen.dart';
import '../../fleet_monitor/presentation/fleet_presence_monitor_screen.dart';
import '../../deposit_feed/presentation/shift_deposit_feed_screen.dart';
import '../../attendance/presentation/shift_attendance_location_screen.dart';
import '../../employee_daily_feed/presentation/employee_daily_bottle_log_screen.dart';
import '../../reconciliation/presentation/station_reconciliation_audit_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.currentUser;
    final role = user?.role ?? UserRole.employee;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('KVM Smart Vending', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text(
                  '${role.nameString} • ${user?.name ?? ""}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Quick Barcode Scanner',
            icon: const Icon(Icons.qr_code_scanner, color: AppColors.primary),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ScannerScreen()),
              );
            },
          ),
          IconButton(
            tooltip: 'Sign Out',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: _buildAppDrawer(context, user, role),
      body: _buildDashboardContent(role),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTabIndex,
        onTap: (index) {
          setState(() => _selectedTabIndex = index);
          if (index == 1) {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ScannerScreen()));
          } else if (index == 2) {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TransactionScreen()));
          } else if (index == 3) {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AttendanceScreen()));
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Overview'),
          BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner), label: 'Scan & Vend'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Transactions'),
          BottomNavigationBarItem(icon: Icon(Icons.access_time_filled), label: 'Attendance'),
        ],
      ),
    );
  }

  Widget _buildAppDrawer(BuildContext context, User? user, UserRole role) {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: AppColors.primary),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'U',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ),
            accountName: Text(user?.name ?? 'KVM User', style: const TextStyle(fontWeight: FontWeight.bold)),
            accountEmail: Text('${user?.email ?? ""} (${role.nameString})'),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                  leading: const Icon(Icons.dashboard_outlined),
                  title: const Text('Dashboard'),
                  selected: true,
                  onTap: () => Navigator.pop(context),
                ),
                if (role == UserRole.admin || role == UserRole.superAdmin || role == UserRole.manager) ...[
                  ListTile(
                    leading: const Icon(Icons.people_alt_outlined),
                    title: const Text('Employee Management'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const EmployeeListScreen()));
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.precision_manufacturing_outlined),
                    title: const Text('Vending Machines'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const MachineListScreen()));
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.liquor_outlined),
                    title: const Text('Bottle Product Master'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductListScreen()));
                    },
                  ),
                ],
                ListTile(
                  leading: const Icon(Icons.download_rounded),
                  title: const Text('Bottle Loading'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const LoadingScreen()));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.upload_rounded),
                  title: const Text('Bottle Unloading'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const UnloadingScreen()));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.local_shipping_outlined, color: AppColors.primary),
                  title: const Text('Vendor Return Logistics'),
                  subtitle: const Text('Crate manifests & driver handover', style: TextStyle(fontSize: 11)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const VendorReturnScreen()));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.point_of_sale),
                  title: const Text('Customer Transactions'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const TransactionScreen()));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.calculate_outlined, color: Colors.teal),
                  title: const Text('Three-Way Bottle Reconciliation'),
                  subtitle: const Text('Deposits vs Collections vs Vendor Dispatches', style: TextStyle(fontSize: 11)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const StationReconciliationAuditScreen()));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.assessment_outlined),
                  title: const Text('Reports & Analytics'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen()));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.sync_alt_rounded, color: AppColors.primary),
                  title: const Text('Daily Received & Sent to Vendors', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Add bottles collected from machine & dispatched', style: TextStyle(fontSize: 11)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const EmployeeDailyBottleLogScreen()));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.hub_outlined, color: AppColors.primary),
                  title: const Text('100+ Location Fleet Tracker', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Live staff presence & bottle metrics', style: TextStyle(fontSize: 11)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const FleetPresenceMonitorScreen()));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.add_chart_rounded, color: AppColors.accent),
                  title: const Text('Hourly Bottle Deposit Feed'),
                  subtitle: const Text('Record machine billed deposits & dispatch', style: TextStyle(fontSize: 11)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ShiftDepositFeedScreen()));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.how_to_reg_outlined),
                  title: const Text('My Daily Shift & Geo-Attendance'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ShiftAttendanceLocationScreen()));
                  },
                ),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.error),
            title: const Text('Log Out', style: TextStyle(color: AppColors.error)),
            onTap: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildDashboardContent(UserRole role) {
    final mock = MockDataService();
    final totalEmployees = mock.employees.length;
    final totalMachines = mock.machines.length;
    final activeMachines = mock.machines.where((m) => m.status == MachineStatus.active).length;
    final totalProducts = mock.products.length;
    final totalTxns = mock.customerTransactions.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Role Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Live Operations Control',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Dual-mode Liquor Vending & Deposit Return Active',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.fiber_manual_record, color: Colors.greenAccent, size: 12),
                      SizedBox(width: 6),
                      Text('SYSTEM LIVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Key Operational Metrics Grid
          Text('Key Metrics Summary', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _metricCard('Total Machines', '$totalMachines ($activeMachines Active)', Icons.precision_manufacturing, AppColors.primaryLight),
              _metricCard('Bottles in Fleet', '1,382 Units', Icons.liquor, AppColors.accent),
              _metricCard('Today\'s Sold', '\$428.50', Icons.point_of_sale, AppColors.success),
              _metricCard('Returned Bottles', '142 Bottles', Icons.recycling, AppColors.warning),
              _metricCard('Staff Present', '$totalEmployees Active', Icons.people_outline, Colors.teal),
              _metricCard('Unload Approval', '2 Pending', Icons.assignment_late, Colors.deepPurple),
              _metricCard('Total Catalog', '$totalProducts SKUs', Icons.category_outlined, Colors.indigo),
              _metricCard('Customer Txns', '$totalTxns Recorded', Icons.receipt_long, Colors.blueGrey),
            ],
          ),

          const SizedBox(height: 24),
          // Fl_chart Analytics Card
          Text('Fleet Hourly Activity & Returns', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Bottle Flow vs. Returns (Today)', style: TextStyle(fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          Icon(Icons.circle, color: AppColors.primary, size: 10),
                          SizedBox(width: 4),
                          Text('Dispensed', style: TextStyle(fontSize: 12)),
                          SizedBox(width: 12),
                          Icon(Icons.circle, color: AppColors.warning, size: 10),
                          SizedBox(width: 4),
                          Text('Returned', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 200,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: 60,
                        barTouchData: BarTouchData(enabled: true),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (val, meta) {
                                switch (val.toInt()) {
                                  case 0:
                                    return const Text('08:00', style: TextStyle(fontSize: 10));
                                  case 1:
                                    return const Text('11:00', style: TextStyle(fontSize: 10));
                                  case 2:
                                    return const Text('14:00', style: TextStyle(fontSize: 10));
                                  case 3:
                                    return const Text('17:00', style: TextStyle(fontSize: 10));
                                  case 4:
                                    return const Text('20:00', style: TextStyle(fontSize: 10));
                                  default:
                                    return const Text('');
                                }
                              },
                            ),
                          ),
                          leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: true, reservedSize: 28),
                          ),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        gridData: const FlGridData(show: true, drawVerticalLine: false),
                        borderData: FlBorderData(show: false),
                        barGroups: [
                          _buildBarGroup(0, 18, 12),
                          _buildBarGroup(1, 35, 24),
                          _buildBarGroup(2, 48, 38),
                          _buildBarGroup(3, 52, 44),
                          _buildBarGroup(4, 30, 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
          // Quick Action Shortcuts
          Text('Priority Operational Actions', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _actionButton(
                  context,
                  title: 'Daily Received & Sent',
                  subtitle: 'Add bottles collected & dispatched',
                  icon: Icons.sync_alt_rounded,
                  color: AppColors.primary,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmployeeDailyBottleLogScreen())),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _actionButton(
                  context,
                  title: 'Feed Deposit Meter',
                  subtitle: 'Log machine billed count',
                  icon: Icons.add_chart_rounded,
                  color: AppColors.accent,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShiftDepositFeedScreen())),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _actionButton(
                  context,
                  title: '100+ Fleet Monitor',
                  subtitle: 'Live staff & deposit status',
                  icon: Icons.hub_rounded,
                  color: Colors.teal,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FleetPresenceMonitorScreen())),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _actionButton(
                  context,
                  title: 'Shift Geo-Attendance',
                  subtitle: 'Clock in & station verification',
                  icon: Icons.verified_user_rounded,
                  color: AppColors.success,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShiftAttendanceLocationScreen())),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  BarChartGroupData _buildBarGroup(int x, double dispensed, double returned) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(toY: dispensed, color: AppColors.primary, width: 12, borderRadius: BorderRadius.circular(4)),
        BarChartRodData(toY: returned, color: AppColors.warning, width: 12, borderRadius: BorderRadius.circular(4)),
      ],
    );
  }

  Widget _metricCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
