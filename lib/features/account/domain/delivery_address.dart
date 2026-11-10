final class DeliveryAddress {
  const DeliveryAddress({
    required this.id,
    required this.recipientName,
    required this.recipientPhone,
    required this.provinceCode,
    required this.provinceName,
    required this.wardName,
    required this.detail,
    required this.fullAddress,
    required this.areaCode,
    required this.label,
    required this.isDefault,
  });

  final String id;
  final String recipientName;
  final String recipientPhone;
  final String provinceCode;
  final String provinceName;
  final String wardName;
  final String detail;
  final String fullAddress;
  final String areaCode;
  final String label;
  final bool isDefault;

  factory DeliveryAddress.fromJson(Map<String, Object?> json) => DeliveryAddress(
    id: _string(json, 'id'),
    recipientName: _string(json, 'recipientName'),
    recipientPhone: _string(json, 'recipientPhone'),
    provinceCode: _string(json, 'provinceCode'),
    provinceName: _string(json, 'provinceName'),
    wardName: _string(json, 'wardName'),
    detail: _string(json, 'detail'),
    fullAddress: _string(json, 'fullAddress'),
    areaCode: _string(json, 'areaCode'),
    label: _string(json, 'label'),
    isDefault: json['isDefault'] == true,
  );

  static String _string(Map<String, Object?> json, String key) =>
      json[key] is String ? json[key]! as String : '';
}

final class AddressDraft {
  const AddressDraft({
    required this.recipientName,
    required this.recipientPhone,
    required this.provinceCode,
    required this.provinceName,
    required this.wardName,
    required this.detail,
    this.label,
    this.isDefault,
  });

  final String recipientName;
  final String recipientPhone;
  final String provinceCode;
  final String provinceName;
  final String wardName;
  final String detail;
  final String? label;
  final bool? isDefault;

  Map<String, Object?> toJson() => {
    'recipientName': recipientName,
    'recipientPhone': recipientPhone,
    'provinceCode': provinceCode,
    'provinceName': provinceName,
    'wardName': wardName,
    'detail': detail,
    'label': label,
    'isDefault': isDefault,
  };
}
