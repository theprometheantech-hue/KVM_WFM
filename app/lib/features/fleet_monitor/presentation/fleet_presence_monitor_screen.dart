import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/shift_deposit_reading_model.dart';

class FleetPresenceMonitorScreen extends StatefulWidget {
  const FleetPresenceMonitorScreen({super.key});

  @override
  State<FleetPresenceMonitorScreen> createState() => _FleetPresenceMonitorScreenState();
}

class _FleetPresenceMonitorScreenState extends State<FleetPresenceMonitorScreen> {
  String _searchQuery = '';
  String _filterStatus = 'All'; // 'All', 'Staff Present', 'Unattended'

  // Mock sample from the 100+ active locations
  final List<LocationFleetOverview> _locations = [
    LocationFleetOverview(
      locationCode: 'LOC-001',
      locationName: 'Central Terminal 1 Concourse',
      machineId: 'MCH-001',
      machineSerialNumber: 'RVM-X900-8812',
      assignedEmployeeName: 'David Zhao',
      assignedEmployeeId: 'EMP-MOP-03',
      isStaffPresent: true,
      checkInTimestamp: DateTime.now().subtract(const Duration(hours: 4, minutes: 12)),
      todayTotalDeposited: 342,
      todayTotalDispatchedToVendor: 120,
      currentBinHoldings: 222,
      machineMaxCapacity: 600,
      lastReadingTime: DateTime.now().subtract(const Duration(minutes: 35)),
    ),
    LocationFleetOverview(
      locationCode: 'LOC-002',
      locationName: 'Civic Plaza East Station',
      machineId: 'MCH-002',
      machineSerialNumber: 'RVM-X900-9041',
      assignedEmployeeName: 'Elena Rostova',
      assignedEmployeeId: 'EMP-EMP-04',
      isStaffPresent: true,
      checkInTimestamp: DateTime.now().subtract(const Duration(hours: 3)),
      todayTotalDeposited: 480,
      todayTotalDispatchedToVendor: 85,
      currentBinHoldings: 395,
      machineMaxCapacity: 500,
      lastReadingTime: DateTime.now().subtract(const Duration(minutes: 15)),
    ),
    LocationFleetOverview(
      locationCode: 'LOC-003',
      locationName: 'Grand Central Gate 4 Arrival',
      machineId: 'MCH-003',
      machineSerialNumber: 'RVM-REV-3301',
      assignedEmployeeName: 'Unassigned',
      assignedEmployeeId: null,
      isStaffPresent: false,
      checkInTimestamp: null,
      todayTotalDeposited: 440,
      todayTotalDispatchedToVendor: 0,
      currentBinHoldings: 440,
      machineMaxCapacity: 450,
      lastReadingTime: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    LocationFleetOverview(
      locationCode: 'LOC-004',
      locationName: 'Westside Harbor Pier 39 Pavilion',
      machineId: 'MCH-004',
      machineSerialNumber: 'RVM-X700-1120',
      assignedEmployeeName: 'Robert Lang',
      assignedEmployeeId: 'EMP-MOP-07',
      isStaffPresent: true,
      checkInTimestamp: DateTime.now().subtract(const Duration(hours: 2)),
      todayTotalDeposited: 120,
      todayTotalDispatchedToVendor: 120,
      currentBinHoldings: 0,
      machineMaxCapacity: 500,
      lastReadingTime: DateTime.now().subtract(const Duration(minutes: 55)),
    ),
    LocationFleetOverview(
      locationCode: 'LOC-005',
      locationName: 'North Metro Interchange Kiosk 2',
      machineId: 'MCH-005',
      machineSerialNumber: 'RVM-X900-4491',
      assignedEmployeeName: 'Priya Sharma',
      assignedEmployeeId: 'EMP-MOP-09',
      isStaffPresent: true,
      checkInTimestamp: DateTime.now().subtract(const Duration(hours: 5)),
      todayTotalDeposited: 285,
      todayTotalDispatchedToVendor: 200,
      currentBinHoldings: 85,
      machineMaxCapacity: 500,
      lastReadingTime: DateTime.now().subtract(const Duration(minutes: 20)),
    ),
    LocationFleetOverview(
      locationCode: 'LOC-006',
      locationName: 'South Tech Park Gateway Mall',
      machineId: 'MCH-006',
      machineSerialNumber: 'RVM-X900-5120',
      assignedEmployeeName: 'Unassigned',
      assignedEmployeeId: null,
      isStaffPresent: false,
      checkInTimestamp: null,
      todayTotalDeposited: 190,
      todayTotalDispatchedToVendor: 0,
      currentBinHoldings: 190,
      machineMaxCapacity: 450,
      lastReadingTime: DateTime.now().subtract(const Duration(hours: 4)),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _locations.where((l) {
      final matchesSearch = l.locationName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          l.machineId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (l.assignedEmployeeName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);

      final matchesFilter = _filterStatus == 'All' ||
          (_filterStatus == 'Staff Present' && l.isStaffPresent) ||
          (_filterStatus == 'Unattended' && !l.isStaffPresent);

      return matchesSearch && matchesFilter;
    }).toList();

    final totalActiveStaff = _locations.where((l) => l.isStaffPresent).length;
    final totalFleetDeposits = _locations.fold<int>(0, (sum, l) => sum + l.todayTotalDeposited);
    final totalVendorDispatched = _locations.fold<int>(0, (sum, l) => sum + l.todayTotalDispatchedToVendor);

    return Scaffold(
      appBar: AppBar(
        title: const Text('100+ Location Fleet & Staff Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Refreshing all 100+ station telemetry feeds...')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Fleet Metric Header Cards
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _statPill('Stations Active', '${_locations.length} Units', Icons.location_city, AppColors.primary),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _statPill('Staff On-Duty', '$totalActiveStaff Present', Icons.badge, AppColors.success),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _statPill('Total Deposited', '$totalFleetDeposits Btls', Icons.arrow_downward, AppColors.accent),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _statPill('Sent to Vendor', '$totalVendorDispatched Btls', Icons.local_shipping, AppColors.warning),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search across 100+ locations, machine codes, or staff...',
                    prefixIcon: Icon(Icons.search, size: 20),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    FilterChip(
                      label: const Text('All Stations'),
                      selected: _filterStatus == 'All',
                      onSelected: (_) => setState(() => _filterStatus = 'All'),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Staff Present'),
                      selected: _filterStatus == 'Staff Present',
                      onSelected: (_) => setState(() => _filterStatus = 'Staff Present'),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Unattended Station Alert'),
                      selected: _filterStatus == 'Unattended',
                      onSelected: (_) => setState(() => _filterStatus = 'Unattended'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Station List
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('No matching stations found'))
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (ctx, idx) {
                      final item = filtered[idx];
                      final fillPct = (item.currentBinHoldings / item.machineMaxCapacity).clamp(0.0, 1.0);

                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: item.isStaffPresent ? AppColors.success.withOpacity(0.12) : Colors.red.withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                            item.isStaffPresent ? Icons.check_circle_outline : Icons.warning_amber_rounded,
                                            color: item.isStaffPresent ? AppColors.success : Colors.red,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(item.locationName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                              Text('${item.machineId} • S/N: ${item.machineSerialNumber}',
                                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: item.isStaffPresent ? AppColors.success.withOpacity(0.12) : AppColors.error.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      item.isStaffPresent ? 'STAFF ON-DUTY' : 'UNATTENDED',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: item.isStaffPresent ? AppColors.success : AppColors.error,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Employee Details & Shift Check-in Info
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceVariant,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.person_pin, size: 18, color: AppColors.primary),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        item.isStaffPresent
                                            ? 'Active Operator: ${item.assignedEmployeeName} (${item.assignedEmployeeId})'
                                            : 'No operator currently checked in for this shift',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: item.isStaffPresent ? AppColors.textPrimary : Colors.red.shade700,
                                        ),
                                      ),
                                    ),
                                    if (item.checkInTimestamp != null)
                                      Text(
                                        'In: ${DateFormat('hh:mm a').format(item.checkInTimestamp!)}',
                                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),

                              // 3-Way Metrics: Deposited vs Dispatched vs In-Bin
                              Row(
                                children: [
                                  Expanded(
                                    child: _metricBox('Deposited Today', '${item.todayTotalDeposited} Btls', AppColors.accent),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _metricBox('Sent to Vendor', '${item.todayTotalDispatchedToVendor} Btls', AppColors.warning),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _metricBox('Holding in Bin', '${item.currentBinHoldings} Btls', AppColors.primary),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // Bin Fill Gauge
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Bin Capacity: ${item.currentBinHoldings}/${item.machineMaxCapacity} (${(fillPct * 100).toInt()}%)',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                  if (item.lastReadingTime != null)
                                    Text(
                                      'Last Feed: ${DateFormat('hh:mm a').format(item.lastReadingTime!)}',
                                      style: const TextStyle(fontSize: 10, color: Colors.blueGrey),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              LinearProgressIndicator(
                                value: fillPct,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  fillPct > 0.8 ? AppColors.error : (fillPct > 0.6 ? AppColors.warning : AppColors.primary),
                                ),
                                minHeight: 6,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _statPill(String title, String val, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 4),
          Text(val, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          Text(title, style: const TextStyle(fontSize: 9, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _metricBox(String title, String val, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(val, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

