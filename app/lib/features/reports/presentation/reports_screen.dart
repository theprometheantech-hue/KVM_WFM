import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/services/mock_data_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _selectedFilter = 'Today';
  final List<String> _filters = ['Today', 'Yesterday', 'Last 7 days', 'This month'];

  @override
  Widget build(BuildContext context) {
    final mock = MockDataService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Audit Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'Export PDF Report',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Generating PDF audit report... Export complete.')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.table_chart_outlined),
            tooltip: 'Export Excel Sheet',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Generating Excel dataset... Export complete.')),
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
            // Filter Pills
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filters.map((f) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(f),
                      selected: _selectedFilter == f,
                      onSelected: (_) => setState(() => _selectedFilter = f),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Financial & Stock Reconciliation Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Audit & Reconciliation Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 14),
                    _reportRow('Gross Bottle Sales Volume', '\$428.50', Colors.green),
                    _reportRow('Deposit Refunds Disbursed', '\$142.00', Colors.orange),
                    _reportRow('Net Fleet Revenue', '\$286.50', AppColors.primary),
                    const Divider(height: 20),
                    _reportRow('Total Stock In (Loading)', '340 Bottles', Colors.blueGrey),
                    _reportRow('Total Stock Out (Unloading)', '82 Bottles', Colors.blueGrey),
                    _reportRow('Discrepancy / Shrinkage Rate', '0.00%', Colors.green),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Machine Performance Breakdown
            Text('Machine Fleet Performance', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            ...mock.machines.map(
              (m) => Card(
                child: ListTile(
                  leading: const Icon(Icons.precision_manufacturing, color: AppColors.primary),
                  title: Text(m.name),
                  subtitle: Text('${m.location} • Status: ${m.status.name.toUpperCase()}'),
                  trailing: Text(
                    '${m.currentCapacity}/${m.maxCapacity}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _reportRow(String title, String val, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          Text(val, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color)),
        ],
      ),
    );
  }
}

