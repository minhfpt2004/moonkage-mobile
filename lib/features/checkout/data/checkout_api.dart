import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moonkage_verify/core/errors/app_failure.dart';
import 'package:moonkage_verify/core/network/api_endpoints.dart';
import 'package:moonkage_verify/core/network/api_payload.dart';
import 'package:moonkage_verify/core/network/dio_failure.dart';
import 'package:moonkage_verify/core/network/dio_provider.dart';
import 'package:moonkage_verify/features/checkout/domain/checkout.dart';

final checkoutApiProvider = Provider<CheckoutApi>((ref) => CheckoutApi(ref.watch(dioProvider)));

class CheckoutApi {
  CheckoutApi(this._dio);

  final Dio _dio;

  Future<CheckoutCreated> create(CheckoutDraft draft) async {
    try {
      final response = await _dio.post<Object?>(ApiEndpoints.checkouts, data: draft.toJson());
      final payload = _mapPayload(response.data);
      final checkout = CheckoutCreated.fromJson(payload);
      if (checkout.checkoutId.isEmpty || checkout.paymentUrl.isEmpty) {
        throw const InvalidResponseFailure();
      }
      return checkout;
    } on DioException catch (error) {
      throw failureFromDio(error);
    }
  }

  Future<CheckoutResult> get(String checkoutId) async {
    try {
      final response = await _dio.get<Object?>(ApiEndpoints.checkout(checkoutId));
      final checkout = CheckoutResult.fromJson(_mapPayload(response.data));
      if (checkout.checkoutId.isEmpty) throw const InvalidResponseFailure();
      return checkout;
    } on DioException catch (error) {
      throw failureFromDio(error);
    }
  }

  Map<String, Object?> _mapPayload(Object? body) {
    final payload = apiPayload(body);
    if (payload is! Map) throw const InvalidResponseFailure();
    return payload.map((key, value) => MapEntry(key.toString(), value));
  }
}
