final class Cart {
  const Cart({required this.provinceCode, required this.groups, required this.totalAmount});

  factory Cart.fromJson(Map<String, Object?> json) => Cart(
    provinceCode: _string(json, 'provinceCode'),
    groups: json['groups'] is List
        ? (json['groups']! as List)
              .whereType<Map<dynamic, dynamic>>()
              .map((value) => CartGroup.fromJson(_stringMap(value)))
              .toList(growable: false)
        : const [],
    totalAmount: _integer(json['totalAmount']),
  );

  final String provinceCode;
  final List<CartGroup> groups;
  final int totalAmount;

  int get itemCount => groups.fold(
    0,
    (total, group) => total + group.items.fold(0, (sum, item) => sum + item.quantity),
  );

  bool get isEmpty => groups.every((group) => group.items.isEmpty);
}

final class CartGroup {
  const CartGroup({
    required this.vendorId,
    required this.vendorName,
    required this.deliverable,
    required this.interprovince,
    required this.shippingFee,
    required this.subtotal,
    required this.items,
  });

  factory CartGroup.fromJson(Map<String, Object?> json) => CartGroup(
    vendorId: _string(json, 'vendorId'),
    vendorName: _string(json, 'vendorName'),
    deliverable: json['deliverable'] == true,
    interprovince: json['interprovince'] == true,
    shippingFee: json['shippingFee'] is num ? (json['shippingFee']! as num).toInt() : null,
    subtotal: _integer(json['subtotal']),
    items: json['items'] is List
        ? (json['items']! as List)
              .whereType<Map<dynamic, dynamic>>()
              .map((value) => CartLine.fromJson(_stringMap(value)))
              .toList(growable: false)
        : const [],
  );

  final String vendorId;
  final String vendorName;
  final bool deliverable;
  final bool interprovince;
  final int? shippingFee;
  final int subtotal;
  final List<CartLine> items;

  int get total => deliverable ? subtotal + (shippingFee ?? 0) : subtotal;
}

final class CartLine {
  const CartLine({
    required this.itemId,
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    required this.available,
  });

  factory CartLine.fromJson(Map<String, Object?> json) => CartLine(
    itemId: _string(json, 'itemId'),
    productId: _string(json, 'productId'),
    productName: _string(json, 'productName'),
    unitPrice: _integer(json['unitPrice']),
    quantity: _integer(json['quantity']),
    available: json['available'] == true,
  );

  final String itemId;
  final String productId;
  final String productName;
  final int unitPrice;
  final int quantity;
  final bool available;

  int get lineTotal => unitPrice * quantity;
}

Map<String, Object?> _stringMap(Map<dynamic, dynamic> value) =>
    value.map((key, item) => MapEntry(key.toString(), item));
String _string(Map<String, Object?> value, String key) =>
    value[key] is String ? value[key]! as String : '';
int _integer(Object? value) => value is num ? value.toInt() : 0;
