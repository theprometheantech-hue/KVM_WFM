import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/product_model.dart';
import '../../../data/services/mock_data_service.dart';

class ScannerScreen extends StatefulWidget {
  final Function(Product product)? onProductScanned;
  const ScannerScreen({super.key, this.onProductScanned});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController _cameraController = MobileScannerController();
  final _manualInputController = TextEditingController();
  bool _isProcessing = false;
  Product? _detectedProduct;

  @override
  void dispose() {
    _cameraController.dispose();
    _manualInputController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;
    final barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        _handleBarcode(barcode.rawValue!);
        break;
      }
    }
  }

  void _handleBarcode(String rawCode) {
    setState(() => _isProcessing = true);
    final trimmed = rawCode.trim();

    final found = MockDataService().products.where(
      (p) => p.barcode == trimmed || p.productId == trimmed,
    );

    if (found.isNotEmpty) {
      final product = found.first;
      setState(() {
        _detectedProduct = product;
        _isProcessing = false;
      });
      if (widget.onProductScanned != null) {
        widget.onProductScanned!(product);
      }
    } else {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unregistered Barcode: $trimmed. Fallback to manual entry or add to catalog.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Industrial Barcode Scanner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _cameraController.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: () => _cameraController.switchCamera(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Camera Viewport
          Expanded(
            flex: 3,
            child: Stack(
              alignment: Alignment.center,
              children: [
                MobileScanner(
                  controller: _cameraController,
                  onDetect: _onDetect,
                ),
                // Scanning Target Overlay
                Container(
                  width: 260,
                  height: 180,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.greenAccent, width: 2.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                Positioned(
                  top: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.65),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Align EAN-13, UPC or QR inside frame',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Manual Entry & Quick-Test Barcodes
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _manualInputController,
                        decoration: const InputDecoration(
                          hintText: 'Manual Barcode / SKU entry...',
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(minimumSize: const Size(80, 48)),
                      onPressed: () {
                        if (_manualInputController.text.isNotEmpty) {
                          _handleBarcode(_manualInputController.text);
                        }
                      },
                      child: const Text('Lookup'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      const Text('Quick Test SKUs: ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ...MockDataService().products.map(
                            (p) => Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ActionChip(
                                label: Text(p.name.split(' ').first, style: const TextStyle(fontSize: 10)),
                                onPressed: () {
                                  _manualInputController.text = p.barcode;
                                  _handleBarcode(p.barcode);
                                },
                              ),
                            ),
                          ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Scanned Product Confirmation Card
          if (_detectedProduct != null)
            Container(
              padding: const EdgeInsets.all(16),
              color: AppColors.background,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.check_circle, color: AppColors.success, size: 22),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _detectedProduct!.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('Brand: ${_detectedProduct!.brand} | Size: ${_detectedProduct!.bottleSize}'),
                      Text('Barcode: ${_detectedProduct!.barcode}', style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Text('Sale Price: \$${_detectedProduct!.salePrice.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                          const SizedBox(width: 16),
                          Text('Return Deposit: \$${_detectedProduct!.returnRefundValue.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.warning)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

