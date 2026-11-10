import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moonkage_verify/core/errors/app_failure.dart';
import 'package:moonkage_verify/core/network/api_endpoints.dart';
import 'package:moonkage_verify/core/network/api_payload.dart';
import 'package:moonkage_verify/core/network/dio_failure.dart';
import 'package:moonkage_verify/core/network/dio_provider.dart';
import 'package:moonkage_verify/features/account/domain/delivery_address.dart';

final addressApiProvider = Provider<AddressApi>((ref) => AddressApi(ref.watch(dioProvider)));

final addressesProvider = FutureProvider.autoDispose<List<DeliveryAddress>>((ref) {
  return ref.watch(addressApiProvider).list();
});

class AddressApi {
  AddressApi(this._dio);

  final Dio _dio;

  Future<List<DeliveryAddress>> list() async {
    try {
      final response = await _dio.get<Object?>(ApiEndpoints.addresses);
      final payload = apiPayload(response.data);
      if (payload is! List) throw const InvalidResponseFailure();
      return payload.map(_parse).toList(growable: false);
    } on DioException catch (error) {
      throw failureFromDio(error);
    }
  }

  Future<DeliveryAddress> create(AddressDraft draft) =>
      _write('POST', ApiEndpoints.addresses, draft);

  Future<DeliveryAddress> update(String addressId, AddressDraft draft) =>
      _write('PUT', ApiEndpoints.address(addressId), draft);

  Future<void> delete(String addressId) async {
    try {
      await _dio.delete<void>(ApiEndpoints.address(addressId));
    } on DioException catch (error) {
      throw failureFromDio(error);
    }
  }

  Future<DeliveryAddress> _write(String method, String path, AddressDraft draft) async {
    try {
      final response = await _dio.request<Object?>(
        path,
        data: draft.toJson(),
        options: Options(method: method),
      );
      return _parse(apiPayload(response.data));
    } on DioException catch (error) {
      throw failureFromDio(error);
    }
  }

  DeliveryAddress _parse(Object? value) {
    if (value is! Map) throw const InvalidResponseFailure();
    final map = value.map((key, item) => MapEntry(key.toString(), item));
    if (map['id'] is! String || map['recipientName'] is! String) {
      throw const InvalidResponseFailure();
    }
    return DeliveryAddress.fromJson(map);
  }
}
