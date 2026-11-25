import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/services/tracker_service.dart';

class CashReconciliationScreen extends StatefulWidget {
  const CashReconciliationScreen({super.key});

  @override
  State<CashReconciliationScreen> createState() => _CashReconciliationScreenState();
}

class _CashReconciliationScreenState extends State<CashReconciliationScreen> {
  final tracker = TrackerService();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: tracker,
      builder: (context, _) {
        final totalCashGiven = tracker.cashExchanges.fold<double>(0, (sum, e) => sum + e.cashPaidToCustomer);
        final totalBottlesCollected = tracker.cashExchanges.fold<int>(0, (sum, e) => sum + e.bottlesCollected);
        final reimbursedCount = tracker.cashExchanges.where((e) => e.isDigitallyReimbursed).length;
        final pendingCount = tracker.cashExchanges.where((e) => !e.isDigitallyReimbursed).length;

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Manual Cash & Machine Audit',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          body: Column(
            children: [
              // SUMMARY HEADER BANNER
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.blue.shade50,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _statTile(
                            'Total Cash Given to Cust.',
                            '₹${totalCashGiven.toStringAsFixed(0)}',
                            Icons.payments_outlined,
                            Colors.blue.shade900,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _statTile(
                            'Bottles Recycled in Machine',
                            '$totalBottlesCollected btls',
                            Icons.recycling,
                            Colors.green.shade800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle, color: Colors.green, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  '$reimbursedCount Digital Credits Verified',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.green.shade900),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (pendingCount > 0) ...[
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.hourglass_bottom, color: Colors.amber.shade900, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    '$pendingCount Machine Payout Pending',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.amber.shade900),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // TRANSACTIONS LIST
              Expanded(
                child: tracker.cashExchanges.isEmpty
                    ? const Center(
                        child: Text(
                          'No manual cash transactions logged yet.\nWhen employees hand over cash and feed bottles into the machine, they will appear here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, height: 1.5),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: tracker.cashExchanges.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, idx) {
                          final item = tracker.cashExchanges[idx];

                          return Card(
                            elevation: 1.5,
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(item.stationName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                      Text(
                                        '₹${item.cashPaidToCustomer.toStringAsFixed(0)} Paid',
                                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade800, fontSize: 16),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text('Machine: ${item.machineCode} • Worker: ${item.employeeName} (${item.employeeId})',
                                      style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
                                  const Divider(height: 16),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 6,
                                    children: [
                                      _badge(
                                        Icons.check,
                                        '${item.bottlesCollected} Bottles Fed into Machine',
                                        Colors.teal,
                                      ),
                                      _badge(
                                        item.isDigitallyReimbursed ? Icons.qr_code : Icons.warning_amber,
                                        item.isDigitallyReimbursed ? 'Digital Payout Received' : 'Reimbursement Pending',
                                        item.isDigitallyReimbursed ? Colors.green : Colors.amber.shade900,
                                      ),
                                    ],
                                  ),
                                  if (item.note != null && item.note!.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text('Note: ${item.note}', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                                  ],
                                  const SizedBox(height: 6),
                                  Text('Time: ${item.timestamp}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
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
      },
    );
  }

  Widget _statTile(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.12),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
                Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
