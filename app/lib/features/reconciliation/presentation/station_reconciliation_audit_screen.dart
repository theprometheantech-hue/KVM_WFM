import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';

class StationReconciliationAuditScreen extends ConsumerStatefulWidget {
  const StationReconciliationAuditScreen({super.key});

  @override
  ConsumerState<StationReconciliationAuditScreen> createState() => _StationReconciliationAuditScreenState();
}

class _StationReconciliationAuditScreenState extends ConsumerState<StationReconciliationAuditScreen> {
  String _selectedStation = 'LOC-001 (Terminal 1 Concourse - MCH-001)';

  final List<String> _stationList = [
    'LOC-001 (Terminal 1 Concourse - MCH-001)',
    'LOC-002 (Civic Plaza East Station - MCH-002)',
    'LOC-003 (Grand Central Gate 4 Arrival - MCH-003)',
    'LOC-004 (Westside Harbor Pier 39 - MCH-004)',
    'LOC-005 (North Metro Interchange - MCH-005)',
  ];

  // Daily Ledger Numbers for Selected Station
  final int _openingStock = 0;
  final int _customerDepositedBilled = 342; // machine sensor count
  final int _employeeCollectedFromBin = 338; // what operator cleared into crates
  final int _reportedDamagedBroken = 4;     // broken glass declared
  final int _dispatchedToVendors = 270;     // loaded into vendor trucks
  // Formula: In-crate remaining = Collected - Dispatched = 338 - 270 = 68
  // Formula: Variance / Shrinkage = Customer Deposited - (Collected + Damaged) = 342 - (338 + 4) = 0

  @override
  Widget build(BuildContext context) {
    final variance = _customerDepositedBilled - (_employeeCollectedFromBin + _reportedDamagedBroken);
    final inCratesHolding = (_employeeCollectedFromBin - _dispatchedToVendors).clamp(0, 9999);
    final isBalanced = variance == 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Three-Way Bottle Reconciliation'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share Audit Report',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Reconciliation report prepared for Supervisor & Accounting export!')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Station Selector
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Select Station / Vending Unit to Audit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedStation,
                      items: _stationList.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 12)))).toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _selectedStation = v);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Reconciliation Health Status Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isBalanced ? AppColors.success.withOpacity(0.1) : AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isBalanced ? AppColors.success : AppColors.error),
              ),
              child: Row(
                children: [
                  Icon(
                    isBalanced ? Icons.verified : Icons.warning_amber_rounded,
                    color: isBalanced ? AppColors.success : AppColors.error,
                    size: 32,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isBalanced ? 'PERFECT RECONCILIATION BALANCE' : 'AUDIT DISCREPANCY DETECTED',
                          style: TextStyle(
                            color: isBalanced ? AppColors.success : AppColors.error,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isBalanced
                              ? 'All deposited bottles match physical collections, vendor dispatches and declared breakage.'
                              : 'Unaccounted shortage of $variance bottle(s) between machine meter and physical crate counts.',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Step-by-Step Mathematical Ledger Breakdown
            Text('Daily Balance Breakdown', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _ledgerRow('1. Customer Billed Deposits (Machine Meter)', '+$_customerDepositedBilled btls', AppColors.primary, isBold: true),
                    const Divider(height: 16),
                    _ledgerRow('2. Bottles Cleared by Operator into Crates', '+$_employeeCollectedFromBin btls', Colors.teal),
                    _ledgerRow('3. Documented Damaged / Broken Glass', '+$_reportedDamagedBroken btls', AppColors.error),
                    _ledgerRow('4. Dispatched & Handed Over to Vendors', '-$_dispatchedToVendors btls', AppColors.warning),
                    const Divider(height: 20),
                    _ledgerRow('Bottles Still in Crates at Station (Ready for Truck)', '$inCratesHolding btls', AppColors.primary, isBold: true),
                    _ledgerRow('Discrepancy / Shrinkage Unaccounted', '$variance btls', isBalanced ? AppColors.success : AppColors.error, isBold: true),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Comparative Chart
            Text('Inflow vs Clearance vs Vendor Dispatched', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    SizedBox(
                      height: 180,
                      child: BarChart(
                        BarChartData(
                          maxY: 400,
                          alignment: BarChartAlignment.spaceAround,
                          barTouchData: BarTouchData(enabled: true),
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (val, meta) {
                                  switch (val.toInt()) {
                                    case 0:
                                      return const Text('Deposits', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold));
                                    case 1:
                                      return const Text('Collected', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold));
                                    case 2:
                                      return const Text('Vendor Sent', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold));
                                    case 3:
                                      return const Text('In Crates', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold));
                                    default:
                                      return const Text('');
                                  }
                                },
                              ),
                            ),
                            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 32)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          borderData: FlBorderData(show: false),
                          gridData: const FlGridData(show: true, drawVerticalLine: false),
                          barGroups: [
                            BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: _customerDepositedBilled.toDouble(), color: AppColors.primary, width: 22, borderRadius: BorderRadius.circular(4))]),
                            BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: _employeeCollectedFromBin.toDouble(), color: Colors.teal, width: 22, borderRadius: BorderRadius.circular(4))]),
                            BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: _dispatchedToVendors.toDouble(), color: AppColors.warning, width: 22, borderRadius: BorderRadius.circular(4))]),
                            BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: inCratesHolding.toDouble(), color: Colors.indigo, width: 22, borderRadius: BorderRadius.circular(4))]),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _ledgerRow(String label, String value, Color color, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: isBold ? AppColors.textPrimary : AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

