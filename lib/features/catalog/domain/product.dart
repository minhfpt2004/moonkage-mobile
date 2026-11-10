final class Product {
  const Product({
    required this.id,
    required this.vendorId,
    required this.vendorName,
    required this.provinceCode,
    required this.name,
    required this.description,
    required this.crustCodes,
    required this.fillingCodes,
    required this.brand,
    required this.origin,
    required this.piecesPerBox,
    required this.listPrice,
    required this.stock,
    required this.inStock,
    required this.expiryDate,
    required this.deliveryLabel,
    required this.quoteThreshold,
    required this.imageUrls,
    required this.ratingAvg,
    required this.ratingCount,
    required this.vendorAcceptsOrders,
    required this.isOwn,
  });

  final String id;
  final String vendorId;
  final String vendorName;
  final String provinceCode;
  final String name;
  final String description;
  final List<String> crustCodes;
  final List<String> fillingCodes;
  final String brand;
  final String origin;
  final int piecesPerBox;
  final int listPrice;
  final int stock;
  final bool inStock;
  final String expiryDate;
  final String deliveryLabel;
  final int? quoteThreshold;
  final List<String> imageUrls;
  final double ratingAvg;
  final int ratingCount;
  final bool vendorAcceptsOrders;
  final bool isOwn;

  factory Product.fromJson(Map<String, Object?> json) => Product(
    id: _string(json, 'id'),
    vendorId: _string(json, 'vendorId'),
    vendorName: _string(json, 'vendorName'),
    provinceCode: _string(json, 'provinceCode'),
    name: _string(json, 'name'),
    description: _string(json, 'description'),
    crustCodes: _strings(json['crustCodes']),
    fillingCodes: _strings(json['fillingCodes']),
    brand: _string(json, 'brand'),
    origin: _string(json, 'origin'),
    piecesPerBox: _integer(json['piecesPerBox']),
    listPrice: _integer(json['listPrice']),
    stock: _integer(json['stock']),
    inStock: json['inStock'] == true,
    expiryDate: _string(json, 'expiryDate'),
    deliveryLabel: _string(json, 'deliveryLabel'),
    quoteThreshold: json['quoteThreshold'] is num ? (json['quoteThreshold']! as num).toInt() : null,
    imageUrls: _strings(json['imageUrls']),
    ratingAvg: json['ratingAvg'] is num ? (json['ratingAvg']! as num).toDouble() : 0,
    ratingCount: _integer(json['ratingCount']),
    vendorAcceptsOrders: json['vendorAcceptsOrders'] == true,
    isOwn: json['isOwn'] == true,
  );

  static String _string(Map<String, Object?> json, String key) =>
      json[key] is String ? json[key]! as String : '';
  static int _integer(Object? value) => value is num ? value.toInt() : 0;
  static List<String> _strings(Object? value) =>
      value is List ? value.whereType<String>().toList(growable: false) : const [];
}

final class ProductPage {
  const ProductPage({
    required this.content,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
  });

  final List<Product> content;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;
}

final class ProductReview {
  const ProductReview({
    required this.id,
    required this.rating,
    required this.content,
    required this.createdAt,
  });

  final String id;
  final int rating;
  final String content;
  final DateTime? createdAt;

  factory ProductReview.fromJson(Map<String, Object?> json) => ProductReview(
    id: json['reviewId'] is String ? json['reviewId']! as String : '',
    rating: json['rating'] is num ? (json['rating']! as num).toInt() : 0,
    content: json['content'] is String ? json['content']! as String : '',
    createdAt: json['createdAt'] is String ? DateTime.tryParse(json['createdAt']! as String) : null,
  );
}

String formatVnd(int value) {
  final digits = value.abs().toString();
  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) buffer.write('.');
    buffer.write(digits[index]);
  }
  return '${value < 0 ? '-' : ''}${buffer.toString()} ₫';
}
