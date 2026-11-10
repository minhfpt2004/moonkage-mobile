enum QuoteRequestType {
  direct('DIRECT', 'Gửi trực tiếp'),
  open('OPEN', 'Mời nhiều nhà cung cấp');

  const QuoteRequestType(this.wire, this.label);

  final String wire;
  final String label;

  static QuoteRequestType fromWire(Object? value) =>
      value == 'DIRECT' ? QuoteRequestType.direct : QuoteRequestType.open;
}

enum QuoteRequestStatus {
  open('OPEN', 'Đang nhận báo giá'),
  awarded('AWARDED', 'Đã chọn báo giá'),
  closed('CLOSED', 'Đã đóng'),
  expired('EXPIRED', 'Đã hết hạn');

  const QuoteRequestStatus(this.wire, this.label);

  final String wire;
  final String label;

  static QuoteRequestStatus fromWire(Object? value) => switch (value) {
    'AWARDED' => QuoteRequestStatus.awarded,
    'CLOSED' => QuoteRequestStatus.closed,
    'EXPIRED' => QuoteRequestStatus.expired,
    _ => QuoteRequestStatus.open,
  };
}

enum CustomType {
  bag('BAG', 'Túi'),
  card('CARD', 'Thiệp'),
  sticker('STICKER', 'Nhãn dán'),
  templateBox('TEMPLATE_BOX', 'Hộp theo mẫu');

  const CustomType(this.wire, this.label);

  final String wire;
  final String label;

  static CustomType? fromWire(Object? value) {
    for (final type in values) {
      if (type.wire == value) return type;
    }
    return null;
  }
}

final class Supplier {
  const Supplier({
    required this.id,
    required this.businessName,
    required this.ordersOnly,
    required this.supplySource,
    required this.minQuantity,
    required this.leadTimeDays,
    required this.customCapabilities,
    required this.deliveryAreas,
    required this.earlyBirdOffer,
    required this.isOwn,
  });

  factory Supplier.fromJson(Map<String, Object?> json) => Supplier(
    id: _string(json, 'vendorId'),
    businessName: _string(json, 'businessName'),
    ordersOnly: json['ordersOnly'] == true,
    supplySource: _string(json, 'supplySource'),
    minQuantity: _nullableInt(json['minQty']),
    leadTimeDays: _nullableInt(json['leadTimeDays']),
    customCapabilities: _strings(json['customCapabilities']),
    deliveryAreas: _strings(json['deliveryAreas']),
    earlyBirdOffer: _string(json, 'earlyBirdOffer'),
    isOwn: json['isOwn'] == true,
  );

  final String id;
  final String businessName;
  final bool ordersOnly;
  final String supplySource;
  final int? minQuantity;
  final int? leadTimeDays;
  final List<String> customCapabilities;
  final List<String> deliveryAreas;
  final String earlyBirdOffer;
  final bool isOwn;
}

final class QuoteDelivery {
  const QuoteDelivery({
    required this.recipientName,
    required this.recipientPhone,
    required this.provinceCode,
    required this.addressDetail,
  });

  factory QuoteDelivery.fromJson(Map<String, Object?> json) => QuoteDelivery(
    recipientName: _string(json, 'recipientName'),
    recipientPhone: _string(json, 'recipientPhone'),
    provinceCode: _string(json, 'provinceCode'),
    addressDetail: _string(json, 'addressDetail'),
  );

  final String recipientName;
  final String recipientPhone;
  final String provinceCode;
  final String addressDetail;

  Map<String, Object?> toJson() => {
    'recipientName': recipientName,
    'recipientPhone': recipientPhone,
    'provinceCode': provinceCode,
    'addressDetail': addressDetail,
  };
}

final class BuyerQuoteRequest {
  const BuyerQuoteRequest({
    required this.id,
    required this.type,
    required this.targetVendorId,
    required this.productId,
    required this.quantity,
    required this.budget,
    required this.customTypes,
    required this.customSpec,
    required this.deliveryDeadline,
    required this.delivery,
    required this.status,
    required this.invitedCount,
    required this.quoteCount,
    required this.createdAt,
  });

  factory BuyerQuoteRequest.fromJson(Map<String, Object?> json) => BuyerQuoteRequest(
    id: _string(json, 'id'),
    type: QuoteRequestType.fromWire(json['type']),
    targetVendorId: _string(json, 'targetVendorId'),
    productId: _string(json, 'productId'),
    quantity: _int(json['quantity']),
    budget: _nullableInt(json['budget']),
    customTypes: json['customTypes'] is List
        ? (json['customTypes']! as List)
              .map(CustomType.fromWire)
              .whereType<CustomType>()
              .toList(growable: false)
        : const [],
    customSpec: _string(json, 'customSpec'),
    deliveryDeadline: _date(json['deliveryDeadline']),
    delivery: QuoteDelivery.fromJson(_map(json['delivery'])),
    status: QuoteRequestStatus.fromWire(json['status']),
    invitedCount: _int(json['invitedCount']),
    quoteCount: _int(json['quoteCount']),
    createdAt: _dateTime(json['createdAt']),
  );

  final String id;
  final QuoteRequestType type;
  final String targetVendorId;
  final String productId;
  final int quantity;
  final int? budget;
  final List<CustomType> customTypes;
  final String customSpec;
  final DateTime? deliveryDeadline;
  final QuoteDelivery delivery;
  final QuoteRequestStatus status;
  final int invitedCount;
  final int quoteCount;
  final DateTime? createdAt;
}

final class QuoteRequestDraft {
  const QuoteRequestDraft({
    required this.type,
    required this.targetVendorId,
    required this.quantity,
    required this.budget,
    required this.customTypes,
    required this.customSpec,
    required this.deliveryDeadline,
    required this.delivery,
    this.productId,
  });

  final QuoteRequestType type;
  final String? targetVendorId;
  final String? productId;
  final int quantity;
  final int? budget;
  final Set<CustomType> customTypes;
  final String customSpec;
  final DateTime deliveryDeadline;
  final QuoteDelivery delivery;

  Map<String, Object?> toJson() => {
    'type': type.wire,
    if (type == QuoteRequestType.direct) 'targetVendorId': targetVendorId,
    if (productId?.isNotEmpty == true) 'productId': productId,
    'quantity': quantity,
    if (budget != null) 'budget': budget,
    'customTypes': customTypes.map((type) => type.wire).toList(growable: false),
    'customSpec': customSpec.trim(),
    'deliveryDeadline': _dateWire(deliveryDeadline),
    'delivery': delivery.toJson(),
  };
}

final class QuoteInvitation {
  const QuoteInvitation({
    required this.vendorId,
    required this.vendorName,
    required this.status,
    required this.declineReason,
  });

  factory QuoteInvitation.fromJson(Map<String, Object?> json) => QuoteInvitation(
    vendorId: _string(json, 'vendorId'),
    vendorName: _string(json, 'vendorName'),
    status: _string(json, 'status'),
    declineReason: _string(json, 'declineReason'),
  );

  final String vendorId;
  final String vendorName;
  final String status;
  final String declineReason;
}

final class VendorQuote {
  const VendorQuote({
    required this.id,
    required this.vendorId,
    required this.vendorName,
    required this.items,
    required this.itemsAmount,
    required this.customSurcharge,
    required this.shippingFee,
    required this.totalAmount,
    required this.depositAmount,
    required this.remainingAmount,
    required this.deliveryDate,
    required this.validUntil,
    required this.notes,
    required this.status,
    required this.acceptable,
  });

  factory VendorQuote.fromJson(Map<String, Object?> json) => VendorQuote(
    id: _string(json, 'id'),
    vendorId: _string(json, 'vendorId'),
    vendorName: _string(json, 'vendorName'),
    items: json['items'] is List
        ? (json['items']! as List)
              .map((item) => QuoteLine.fromJson(_map(item)))
              .toList(growable: false)
        : const [],
    itemsAmount: _int(json['itemsAmount']),
    customSurcharge: _int(json['customSurcharge']),
    shippingFee: _int(json['shippingFee']),
    totalAmount: _int(json['totalAmount']),
    depositAmount: _int(json['depositAmount']),
    remainingAmount: _int(json['remainingAmount']),
    deliveryDate: _date(json['deliveryDate']),
    validUntil: _dateTime(json['validUntil']),
    notes: _string(json, 'notes'),
    status: _string(json, 'status'),
    acceptable: json['acceptable'] == true,
  );

  final String id;
  final String vendorId;
  final String vendorName;
  final List<QuoteLine> items;
  final int itemsAmount;
  final int customSurcharge;
  final int shippingFee;
  final int totalAmount;
  final int depositAmount;
  final int remainingAmount;
  final DateTime? deliveryDate;
  final DateTime? validUntil;
  final String notes;
  final String status;
  final bool acceptable;
}

final class QuoteLine {
  const QuoteLine({
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.amount,
  });

  factory QuoteLine.fromJson(Map<String, Object?> json) => QuoteLine(
    description: _string(json, 'description'),
    quantity: _int(json['quantity']),
    unitPrice: _int(json['unitPrice']),
    amount: _int(json['amount']),
  );

  final String description;
  final int quantity;
  final int unitPrice;
  final int amount;
}

final class QuoteAcceptance {
  const QuoteAcceptance({
    required this.id,
    required this.status,
    required this.depositAmount,
    required this.paymentId,
    required this.paymentUrl,
  });

  factory QuoteAcceptance.fromJson(Map<String, Object?> json) => QuoteAcceptance(
    id: _string(json, 'acceptanceId'),
    status: _string(json, 'status'),
    depositAmount: _int(json['depositAmount']),
    paymentId: _string(json, 'paymentId'),
    paymentUrl: _string(json, 'paymentUrl'),
  );

  final String id;
  final String status;
  final int depositAmount;
  final String paymentId;
  final String paymentUrl;
}

Map<String, Object?> _map(Object? value) {
  if (value is! Map) return const {};
  return value.map((key, item) => MapEntry(key.toString(), item));
}

String _string(Map<String, Object?> json, String key) =>
    json[key] is String ? json[key]! as String : '';
int _int(Object? value) => value is num ? value.toInt() : 0;
int? _nullableInt(Object? value) => value is num ? value.toInt() : null;
List<String> _strings(Object? value) =>
    value is List ? value.whereType<String>().toList(growable: false) : const [];
DateTime? _date(Object? value) => value is String ? DateTime.tryParse(value) : null;
DateTime? _dateTime(Object? value) => value is String ? DateTime.tryParse(value)?.toLocal() : null;
String _dateWire(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
