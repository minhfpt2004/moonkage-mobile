import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moonkage_verify/core/reference/vietnam_provinces.dart';
import 'package:moonkage_verify/features/account/data/address_api.dart';

/// Khu vực giao hàng dùng chung cho catalog/cart ở các phase sau.
/// Ưu tiên địa chỉ mặc định, rồi địa chỉ đầu tiên, cuối cùng là Hà Nội.
final deliveryProvinceProvider = Provider<VietnamProvince>((ref) {
  final addresses = ref.watch(addressesProvider);
  if (!addresses.hasValue || addresses.requireValue.isEmpty) return vietnamProvinces.first;
  final items = addresses.requireValue;
  final selected = items.where((address) => address.isDefault).firstOrNull ?? items.first;
  return provinceByCode(selected.provinceCode);
});
