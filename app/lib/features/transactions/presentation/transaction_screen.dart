import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/product_model.dart';
import '../../../data/services/mock_data_service.dart';
import '../../barcode_scanner/presentation/scanner_screen.dart';

enum WorkflowMode {
  bottleSelling,
  bottleReturn,
}

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  final mock = MockDataService();
  WorkflowMode _mode = WorkflowMode.bottleSelling;
  Product? _selectedProduct;
  int _quantity = 1;
  bool _isProcessing = false;

  void _executeTransaction() async {
    if (_selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please scan or select a bottle product')),
      );
      return;
    }

    setState(() => _isProcessing = true);
    await Future.delayed(const Duration(milliseconds: 600));

    final isSale = _mode == WorkflowMode.bottleSelling;
    final unitPrice = isSale ? _selectedProduct!.salePrice : _selectedProduct!.returnRefundValue;
    final total = unitPrice * _quantity;

    final txn = {
      'id': 'TXN-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      'machineId': 'MCH-001',
      'type': isSale ? 'SALE' : 'RETURN',
      'productName': _selectedProduct!.name,
      'barcode': _selectedProduct!.barcode,
      'quantity': _quantity,
      'unitPrice': unitPrice,
      'totalAmount': total,
      'status': isSale ? 'SUCCESS' : 'ACCEPTED',
      'timestamp': DateTime.now().toIso8601String(),
    };

    mock.customerTransactions.insert(0, txn);

    setState(() {
      _isProcessing = false;
      _selectedProduct = null;
      _quantity = 1;
    });

    if (mounted) {
      _showReceiptDialog(txn);
    }
  }

  void _showReceiptDialog(Map<String, dynamic> txn) {
    final isSale = txn['type'] == 'SALE';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isSale ? Icons.receipt_long : Icons.recycling,
              color: isSale ? AppColors.success : AppColors.warning,
            ),
            const SizedBox(width: 8),
            Text(isSale ? 'Dispense Receipt' : 'Return Voucher'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Transaction ID: ${txn['id']}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const Divider(),
            Text('Item: ${txn['productName']}'),
            Text('Qty: ${txn['quantity']} unit(s)'),
            Text('Rate: \$${(txn['unitPrice'] as double).toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            Text(
              isSale ? 'Total Charged: \$${(txn['totalAmount'] as double).toStringAsFixed(2)}' : 'Refund Issued: \$${(txn['totalAmount'] as double).toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSale ? AppColors.primary : AppColors.warning,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(6)),
              child: const Text('Status: HARDWARE DISPENSED / DEPOSIT REFUND CONFIRMED', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSale = _mode == WorkflowMode.bottleSelling;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Transactions'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Mode Segment Switcher
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _mode = WorkflowMode.bottleSelling),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSale ? AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            'Bottle Selling Workflow',
                            style: TextStyle(
                              color: isSale ? Colors.white : AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _mode = WorkflowMode.bottleReturn),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !isSale ? AppColors.warning : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            'Empty Bottle Return (RVM)',
                            style: TextStyle(
                              color: !isSale ? Colors.white : AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Scan / Select Container
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isSale ? 'Dispense Liquor Bottle' : 'Accept Empty Returned Bottle',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isSale ? 'Scan customer selected bottle or pick from menu' : 'Customer inserts bottle into scanner flap',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                    const SizedBox(height: 16),

                    if (_selectedProduct == null)
                      OutlinedButton.icon(
                        icon: const Icon(Icons.qr_code_scanner),
                        label: Text(isSale ? 'Scan Bottle for Purchase' : 'Scan Return Barcode'),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ScannerScreen(
                                onProductScanned: (p) {
                                  setState(() => _selectedProduct = p);
                                  Navigator.pop(context);
                                },
                              ),
                            ),
                          );
                        },
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: (isSale ? AppColors.primary : AppColors.warning).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(isSale ? Icons.liquor : Icons.recycling, color: isSale ? AppColors.primary : AppColors.warning, size: 28),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_selectedProduct!.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text(
                                    isSale ? 'Price: \$${_selectedProduct!.salePrice.toStringAsFixed(2)}' : 'Refund Value: \$${_selectedProduct!.returnRefundValue.toStringAsFixed(2)}',
                                    style: TextStyle(color: isSale ? AppColors.primary : AppColors.warning, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => setState(() => _selectedProduct = null),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Quantity:'),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                            ),
                            Text('$_quantity', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: () => setState(() => _quantity++),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isSale ? AppColors.primary : AppColors.warning,
              ),
              onPressed: _isProcessing ? null : _executeTransaction,
              child: _isProcessing
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(isSale ? 'Process Payment & Dispense' : 'Accept Bottle & Issue Refund/Reward'),
            ),
            const SizedBox(height: 24),

            // Live Transaction Log Table
            Text('Transaction History Ledger', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: mock.customerTransactions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, idx) {
                final t = mock.customerTransactions[idx];
                final isTxnSale = t['type'] == 'SALE';
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isTxnSale ? AppColors.primary.withOpacity(0.12) : AppColors.warning.withOpacity(0.12),
                      child: Icon(
                        isTxnSale ? Icons.arrow_outward : Icons.arrow_downward,
                        color: isTxnSale ? AppColors.primary : AppColors.warning,
                        size: 20,
                      ),
                    ),
                    title: Text(t['productName'] ?? 'Product'),
                    subtitle: Text('${t['id']} • Qty: ${t['quantity']} • ${t['machineId']}'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '\$${(t['totalAmount'] as double).toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isTxnSale ? AppColors.primary : AppColors.warning,
                          ),
                        ),
                        Text(t['status'], style: const TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
                      ],
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

