final class InvoiceInfo {
  const InvoiceInfo({
    required this.name,
    required this.taxCode,
    required this.address,
    required this.email,
  });

  final String name;
  final String taxCode;
  final String address;
  final String email;

  Map<String, Object?> toJson() => {
    'name': name,
    'taxCode': taxCode,
    'address': address,
    'email': email,
  };
}

final class CheckoutDraft {
  const CheckoutDraft({
    required this.recipientName,
    required this.recipientPhone,
    required this.provinceCode,
    required this.addressDetail,
    this.invoiceInfo,
  });

  final String recipientName;
  final String recipientPhone;
  final String provinceCode;
  final String addressDetail;
  final InvoiceInfo? invoiceInfo;

  Map<String, Object?> toJson() => {
    'recipientName': recipientName,
    'recipientPhone': recipientPhone,
    'provinceCode': provinceCode,
    'addressDetail': addressDetail,
    if (invoiceInfo != null) 'invoiceInfo': invoiceInfo!.toJson(),
  };
}

final class CheckoutCreated {
  const CheckoutCreated({
    required this.checkoutId,
    required this.paymentId,
    required this.paymentUrl,
    required this.totalAmount,
    required this.expiresAt,
  });

  factory CheckoutCreated.fromJson(Map<String, Object?> json) => CheckoutCreated(
    checkoutId: _string(json, 'checkoutId'),
    paymentId: _string(json, 'paymentId'),
    paymentUrl: _string(json, 'paymentUrl'),
    totalAmount: _integer(json['totalAmount']),
    expiresAt: _date(json['expiresAt']),
  );

  final String checkoutId;
  final String paymentId;
  final String paymentUrl;
  final int totalAmount;
  final DateTime? expiresAt;
}

enum CheckoutStatus {
  pendingPayment,
  succeeded,
  failed,
  expired,
  refundRequested,
  unknown;

  factory CheckoutStatus.fromWire(Object? value) => switch (value) {
    'PENDING_PAYMENT' => pendingPayment,
    'SUCCEEDED' => succeeded,
    'FAILED' => failed,
    'EXPIRED' => expired,
    'REFUND_REQUESTED' => refundRequested,
    _ => unknown,
  };

  bool get isFinal => this != pendingPayment && this != unknown;
}

final class CheckoutResult {
  const CheckoutResult({
    required this.checkoutId,
    required this.status,
    required this.totalAmount,
    required this.paymentId,
    required this.expiresAt,
    required this.orderIds,
  });

  factory CheckoutResult.fromJson(Map<String, Object?> json) => CheckoutResult(
    checkoutId: _string(json, 'checkoutId'),
    status: CheckoutStatus.fromWire(json['status']),
    totalAmount: _integer(json['totalAmount']),
    paymentId: _string(json, 'paymentId'),
    expiresAt: _date(json['expiresAt']),
    orderIds: json['orderIds'] is List
        ? (json['orderIds']! as List).whereType<String>().toList(growable: false)
        : const [],
  );

  final String checkoutId;
  final CheckoutStatus status;
  final int totalAmount;
  final String paymentId;
  final DateTime? expiresAt;
  final List<String> orderIds;
}

String _string(Map<String, Object?> json, String key) =>
    json[key] is String ? json[key]! as String : '';
int _integer(Object? value) => value is num ? value.toInt() : 0;
DateTime? _date(Object? value) => value is String ? DateTime.tryParse(value)?.toLocal() : null;
