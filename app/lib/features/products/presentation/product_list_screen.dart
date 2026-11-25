import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/product_model.dart';
import '../../../data/services/mock_data_service.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final mock = MockDataService();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filtered = mock.products.where((p) {
      return p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.brand.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.barcode.contains(_searchQuery);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bottle Product Master'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Add Liquor Product',
            onPressed: () => _showAddProductDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search brand, name, or barcode...',
                prefixIcon: Icon(Icons.search, size: 20),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('No products found'))
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final p = filtered[index];
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.liquor, color: AppColors.primary, size: 28),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                    const SizedBox(height: 2),
                                    Text('${p.brand} • ${p.bottleSize} • ${p.bottleCategory}',
                                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                    const SizedBox(height: 2),
                                    Text('Barcode: ${p.barcode}',
                                        style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Colors.blueGrey)),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.success.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            'Sale: \$${p.salePrice.toStringAsFixed(2)}',
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.success),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.warning.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            'Deposit Return: \$${p.returnRefundValue.toStringAsFixed(2)}',
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.warning),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
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

  void _showAddProductDialog() {
    final nameCtrl = TextEditingController();
    final brandCtrl = TextEditingController();
    final barcodeCtrl = TextEditingController();
    final sizeCtrl = TextEditingController(text: '750ml');
    final saleCtrl = TextEditingController(text: '25.00');
    final refundCtrl = TextEditingController(text: '1.00');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Bottle Product Master'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Product Name')),
              const SizedBox(height: 8),
              TextField(controller: brandCtrl, decoration: const InputDecoration(labelText: 'Brand')),
              const SizedBox(height: 8),
              TextField(controller: barcodeCtrl, decoration: const InputDecoration(labelText: 'EAN/UPC Barcode')),
              const SizedBox(height: 8),
              TextField(controller: sizeCtrl, decoration: const InputDecoration(labelText: 'Bottle Size (e.g. 750ml)')),
              const SizedBox(height: 8),
              TextField(controller: saleCtrl, decoration: const InputDecoration(labelText: 'Sale Price (\$)'), keyboardType: TextInputType.number),
              const SizedBox(height: 8),
              TextField(controller: refundCtrl, decoration: const InputDecoration(labelText: 'Return Deposit Value (\$)'), keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty && barcodeCtrl.text.isNotEmpty) {
                setState(() {
                  mock.products.add(
                    Product(
                      id: 'PRD-${DateTime.now().millisecondsSinceEpoch}',
                      productId: 'PRD-${DateTime.now().millisecondsSinceEpoch}',
                      name: nameCtrl.text,
                      brand: brandCtrl.text,
                      barcode: barcodeCtrl.text,
                      bottleSize: sizeCtrl.text,
                      bottleCategory: 'Glass Bottle',
                      salePrice: double.tryParse(saleCtrl.text) ?? 20.0,
                      returnRefundValue: double.tryParse(refundCtrl.text) ?? 1.0,
                    ),
                  );
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save Product'),
          ),
        ],
      ),
    );
  }
}

