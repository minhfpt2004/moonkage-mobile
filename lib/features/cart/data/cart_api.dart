import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moonkage_verify/core/errors/app_failure.dart';
import 'package:moonkage_verify/core/network/api_endpoints.dart';
import 'package:moonkage_verify/core/network/api_payload.dart';
import 'package:moonkage_verify/core/network/dio_failure.dart';
import 'package:moonkage_verify/core/network/dio_provider.dart';
import 'package:moonkage_verify/features/cart/domain/cart.dart';

final cartApiProvider = Provider<CartApi>((ref) => CartApi(ref.watch(dioProvider)));

final cartProvider = FutureProvider.autoDispose.family<Cart, String>(
  (ref, provinceCode) => ref.watch(cartApiProvider).getMine(provinceCode),
);

class CartApi {
  CartApi(this._dio);

  final Dio _dio;

  Future<Cart> getMine(String provinceCode) async {
    try {
      final response = await _dio.get<Object?>(
        ApiEndpoints.cart,
        queryParameters: {'provinceCode': provinceCode},
      );
      final payload = apiPayload(response.data);
      if (payload is! Map) throw const InvalidResponseFailure();
      return Cart.fromJson(_map(payload));
    } on DioException catch (error) {
      throw failureFromDio(error);
    }
  }

  Future<CartLine> addItem({required String productId, required int quantity}) async {
    try {
      final response = await _dio.post<Object?>(
        ApiEndpoints.cartItems,
        data: {'productId': productId, 'quantity': quantity},
      );
      return _line(response.data);
    } on DioException catch (error) {
      throw failureFromDio(error);
    }
  }

  Future<CartLine> updateItem(String itemId, int quantity) async {
    try {
      final response = await _dio.patch<Object?>(
        ApiEndpoints.cartItem(itemId),
        data: {'quantity': quantity},
      );
      return _line(response.data);
    } on DioException catch (error) {
      throw failureFromDio(error);
    }
  }

  Future<void> removeItem(String itemId) async {
    try {
      await _dio.delete<void>(ApiEndpoints.cartItem(itemId));
    } on DioException catch (error) {
      throw failureFromDio(error);
    }
  }

  CartLine _line(Object? body) {
    final payload = apiPayload(body);
    if (payload is! Map) throw const InvalidResponseFailure();
    return CartLine.fromJson(_map(payload));
  }

  static Map<String, Object?> _map(Map<dynamic, dynamic> value) =>
      value.map((key, item) => MapEntry(key.toString(), item));
}
