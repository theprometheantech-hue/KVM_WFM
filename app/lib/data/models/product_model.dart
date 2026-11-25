class Product {
  final String id;
  final String productId;
  final String name;
  final String brand;
  final String barcode;
  final String bottleSize;
  final String bottleCategory;
  final String? imageUrl;
  final double salePrice;
  final double returnRefundValue;
  final bool isEligibleForReturn;

  const Product({
    required this.id,
    required this.productId,
    required this.name,
    required this.brand,
    required this.barcode,
    required this.bottleSize,
    required this.bottleCategory,
    this.imageUrl,
    required this.salePrice,
    required this.returnRefundValue,
    this.isEligibleForReturn = true,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id']?.toString() ?? '',
      productId: json['product_id'] ?? json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      brand: json['brand'] ?? '',
      barcode: json['barcode'] ?? '',
      bottleSize: json['bottle_size'] ?? '750ml',
      bottleCategory: json['bottle_category'] ?? 'Glass',
      imageUrl: json['image_url'],
      salePrice: (json['sale_price'] as num?)?.toDouble() ?? 0.0,
      returnRefundValue: (json['return_refund_value'] as num?)?.toDouble() ?? 0.0,
      isEligibleForReturn: json['is_eligible_for_return'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'name': name,
      'brand': brand,
      'barcode': barcode,
      'bottle_size': bottleSize,
      'bottle_category': bottleCategory,
      'image_url': imageUrl,
      'sale_price': salePrice,
      'return_refund_value': returnRefundValue,
      'is_eligible_for_return': isEligibleForReturn,
    };
  }
}

