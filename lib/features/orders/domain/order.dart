enum OrderKind {
  buyNow,
  customOrder,
  unknown;

  factory OrderKind.fromWire(Object? value) => switch (value) {
    'BUY_NOW' => buyNow,
    'CUSTOM_ORDER' => customOrder,
    _ => unknown,
  };
}

enum OrderStatus {
  paid,
  confirmed,
  shipping,
  deposited,
  awaitingMockupApproval,
  inProduction,
  readyToShip,
  delivered,
  completed,
  unknown;

  factory OrderStatus.fromWire(Object? value) => switch (value) {
    'PAID' => paid,
    'CONFIRMED' => confirmed,
    'SHIPPING' => shipping,
    'DEPOSITED' => deposited,
    'AWAITING_MOCKUP_APPROVAL' => awaitingMockupApproval,
    'IN_PRODUCTION' => inProduction,
    'READY_TO_SHIP' => readyToShip,
    'DELIVERED' => delivered,
    'COMPLETED' => completed,
    _ => unknown,
  };

  String get wire => switch (this) {
    paid => 'PAID',
    confirmed => 'CONFIRMED',
    shipping => 'SHIPPING',
    deposited => 'DEPOSITED',
    awaitingMockupApproval => 'AWAITING_MOCKUP_APPROVAL',
    inProduction => 'IN_PRODUCTION',
    readyToShip => 'READY_TO_SHIP',
    delivered => 'DELIVERED',
    completed => 'COMPLETED',
    unknown => 'UNKNOWN',
  };

  String get label => switch (this) {
    paid => 'Đã thanh toán',
    confirmed => 'Shop đã xác nhận',
    shipping => 'Đang giao hàng',
    deposited => 'Đã đặt cọc',
    awaitingMockupApproval => 'Chờ duyệt mẫu',
    inProduction => 'Đang sản xuất',
    readyToShip => 'Sẵn sàng giao',
    delivered => 'Đã giao',
    completed => 'Hoàn thành',
    unknown => 'Đang cập nhật',
  };
}

final class Order {
  const Order({
    required this.id,
    required this.kind,
    required this.status,
    required this.vendorId,
    required this.vendorName,
    required this.paymentGroupId,
    required this.itemsAmount,
    required this.shippingFee,
    required this.discountAmount,
    required this.totalAmount,
    required this.depositAmount,
    required this.remainingAmount,
    required this.interprovince,
    required this.hasCustom,
    required this.recipientName,
    required this.recipientPhone,
    required this.provinceCode,
    required this.addressDetail,
    required this.deliveryDate,
    required this.deliveryMethod,
    required this.trackingCode,
    required this.invoiceInfo,
    required this.hasInvoiceFile,
    required this.deliveredAt,
    required this.receivedConfirmedAt,
    required this.complaintDeadline,
    required this.disputeOpen,
    required this.createdAt,
    required this.items,
  });

  factory Order.fromJson(Map<String, Object?> json) => Order(
    id: _string(json, 'id'),
    kind: OrderKind.fromWire(json['kind']),
    status: OrderStatus.fromWire(json['status']),
    vendorId: _string(json, 'vendorId'),
    vendorName: _string(json, 'vendorName'),
    paymentGroupId: _string(json, 'paymentGroupId'),
    itemsAmount: _integer(json['itemsAmount']),
    shippingFee: _integer(json['shippingFee']),
    discountAmount: _integer(json['discountAmount']),
    totalAmount: _integer(json['totalAmount']),
    depositAmount: _nullableInteger(json['depositAmount']),
    remainingAmount: _nullableInteger(json['remainingAmount']),
    interprovince: json['interprovince'] == true,
    hasCustom: json['hasCustom'] == true,
    recipientName: _string(json, 'recipientName'),
    recipientPhone: _string(json, 'recipientPhone'),
    provinceCode: _string(json, 'provinceCode'),
    addressDetail: _string(json, 'addressDetail'),
    deliveryDate: _string(json, 'deliveryDate'),
    deliveryMethod: _string(json, 'deliveryMethod'),
    trackingCode: _string(json, 'trackingCode'),
    invoiceInfo: json['invoiceInfo'] is Map
        ? OrderInvoice.fromJson(_map(json['invoiceInfo']))
        : null,
    hasInvoiceFile: json['hasInvoiceFile'] == true,
    deliveredAt: _date(json['deliveredAt']),
    receivedConfirmedAt: _date(json['receivedConfirmedAt']),
    complaintDeadline: _date(json['complaintDeadline']),
    disputeOpen: json['disputeOpen'] == true,
    createdAt: _date(json['createdAt']),
    items: json['items'] is List
        ? (json['items']! as List)
              .map((item) => OrderLine.fromJson(_map(item)))
              .toList(growable: false)
        : const [],
  );

  final String id;
  final OrderKind kind;
  final OrderStatus status;
  final String vendorId;
  final String vendorName;
  final String paymentGroupId;
  final int itemsAmount;
  final int shippingFee;
  final int discountAmount;
  final int totalAmount;
  final int? depositAmount;
  final int? remainingAmount;
  final bool interprovince;
  final bool hasCustom;
  final String recipientName;
  final String recipientPhone;
  final String provinceCode;
  final String addressDetail;
  final String deliveryDate;
  final String deliveryMethod;
  final String trackingCode;
  final OrderInvoice? invoiceInfo;
  final bool hasInvoiceFile;
  final DateTime? deliveredAt;
  final DateTime? receivedConfirmedAt;
  final DateTime? complaintDeadline;
  final bool disputeOpen;
  final DateTime? createdAt;
  final List<OrderLine> items;
}

final class OrderLine {
  const OrderLine({
    required this.productId,
    required this.productName,
    required this.imageUrl,
    required this.unitPrice,
    required this.quantity,
    required this.subtotal,
  });

  factory OrderLine.fromJson(Map<String, Object?> json) => OrderLine(
    productId: _string(json, 'productId'),
    productName: _string(json, 'productName'),
    imageUrl: _string(json, 'imageUrl'),
    unitPrice: _integer(json['unitPrice']),
    quantity: _integer(json['quantity']),
    subtotal: _integer(json['subtotal']),
  );

  final String productId;
  final String productName;
  final String imageUrl;
  final int unitPrice;
  final int quantity;
  final int subtotal;
}

final class OrderInvoice {
  const OrderInvoice({
    required this.name,
    required this.taxCode,
    required this.address,
    required this.email,
  });

  factory OrderInvoice.fromJson(Map<String, Object?> json) => OrderInvoice(
    name: _string(json, 'name'),
    taxCode: _string(json, 'taxCode'),
    address: _string(json, 'address'),
    email: _string(json, 'email'),
  );

  final String name;
  final String taxCode;
  final String address;
  final String email;
}

final class OrderProgress {
  const OrderProgress({
    required this.milestone,
    required this.note,
    required this.photoKeys,
    required this.createdAt,
  });

  factory OrderProgress.fromJson(Map<String, Object?> json) => OrderProgress(
    milestone: OrderStatus.fromWire(json['milestone']),
    note: _string(json, 'note'),
    photoKeys: json['photoKeys'] is List
        ? (json['photoKeys']! as List).whereType<String>().toList(growable: false)
        : const [],
    createdAt: _date(json['createdAt']),
  );

  final OrderStatus milestone;
  final String note;
  final List<String> photoKeys;
  final DateTime? createdAt;
}

final class OrderReview {
  const OrderReview({
    required this.id,
    required this.productId,
    required this.rating,
    required this.content,
    required this.createdAt,
  });

  factory OrderReview.fromJson(Map<String, Object?> json) => OrderReview(
    id: _string(json, 'reviewId'),
    productId: _string(json, 'productId'),
    rating: _integer(json['rating']),
    content: _string(json, 'content'),
    createdAt: _date(json['createdAt']),
  );

  final String id;
  final String productId;
  final int rating;
  final String content;
  final DateTime? createdAt;
}

final class OrderReviewDraft {
  const OrderReviewDraft({
    required this.productId,
    required this.rating,
    required this.content,
  });

  final String productId;
  final int rating;
  final String content;

  Map<String, Object?> toJson() => {
    'productId': productId,
    'rating': rating,
    'content': content.trim(),
  };
}

final class OrderPage {
  const OrderPage({
    required this.content,
    required this.page,
    required this.totalElements,
    required this.totalPages,
  });

  final List<Order> content;
  final int page;
  final int totalElements;
  final int totalPages;
}

final class PaymentLink {
  const PaymentLink({required this.paymentId, required this.paymentUrl});

  final String paymentId;
  final String paymentUrl;
}

Map<String, Object?> _map(Object? value) {
  if (value is! Map) return const {};
  return value.map((key, item) => MapEntry(key.toString(), item));
}

String _string(Map<String, Object?> json, String key) =>
    json[key] is String ? json[key]! as String : '';
int _integer(Object? value) => value is num ? value.toInt() : 0;
int? _nullableInteger(Object? value) => value is num ? value.toInt() : null;
DateTime? _date(Object? value) => value is String ? DateTime.tryParse(value)?.toLocal() : null;
