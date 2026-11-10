import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moonkage_verify/core/errors/app_failure.dart';
import 'package:moonkage_verify/core/network/api_endpoints.dart';
import 'package:moonkage_verify/core/network/api_payload.dart';
import 'package:moonkage_verify/core/network/dio_failure.dart';
import 'package:moonkage_verify/core/network/dio_provider.dart';
import 'package:moonkage_verify/features/orders/domain/order.dart';

final orderApiProvider = Provider<OrderApi>((ref) => OrderApi(ref.watch(dioProvider)));

final ordersProvider = FutureProvider.autoDispose.family<OrderPage, OrderStatus?>(
  (ref, status) => ref.watch(orderApiProvider).list(status: status),
);

final orderDetailProvider = FutureProvider.autoDispose.family<Order, String>(
  (ref, orderId) => ref.watch(orderApiProvider).get(orderId),
);

final orderProgressProvider = FutureProvider.autoDispose.family<List<OrderProgress>, String>(
  (ref, orderId) => ref.watch(orderApiProvider).progress(orderId),
);

final orderReviewsProvider = FutureProvider.autoDispose.family<List<OrderReview>, String>(
  (ref, orderId) => ref.watch(orderApiProvider).reviews(orderId),
);

class OrderApi {
  OrderApi(this._dio);

  final Dio _dio;

  Future<OrderPage> list({OrderStatus? status, int page = 0}) async {
    try {
      final response = await _dio.get<Object?>(
        ApiEndpoints.orders,
        queryParameters: {
          if (status != null) 'status': status.wire,
          'page': page,
          'size': 50,
        },
      );
      final payload = _map(apiPayload(response.data));
      final content = payload['content'];
      if (content is! List) throw const InvalidResponseFailure();
      return OrderPage(
        content: content.map((item) => Order.fromJson(_map(item))).toList(growable: false),
        page: _integer(payload['page']),
        totalElements: _integer(payload['totalElements']),
        totalPages: _integer(payload['totalPages']),
      );
    } on DioException catch (error) {
      throw failureFromDio(error);
    }
  }

  Future<Order> get(String orderId) async {
    try {
      final response = await _dio.get<Object?>(ApiEndpoints.order(orderId));
      return Order.fromJson(_map(apiPayload(response.data)));
    } on DioException catch (error) {
      throw failureFromDio(error);
    }
  }

  Future<List<OrderProgress>> progress(String orderId) async {
    try {
      final response = await _dio.get<Object?>(ApiEndpoints.orderProgress(orderId));
      final payload = apiPayload(response.data);
      if (payload is! List) throw const InvalidResponseFailure();
      return payload.map((item) => OrderProgress.fromJson(_map(item))).toList(growable: false);
    } on DioException catch (error) {
      throw failureFromDio(error);
    }
  }

  Future<List<OrderReview>> reviews(String orderId) async {
    try {
      final response = await _dio.get<Object?>(ApiEndpoints.orderReviews(orderId));
      final payload = apiPayload(response.data);
      if (payload is! List) throw const InvalidResponseFailure();
      return payload.map((item) => OrderReview.fromJson(_map(item))).toList(growable: false);
    } on DioException catch (error) {
      throw failureFromDio(error);
    }
  }

  Future<OrderReview> createReview(String orderId, OrderReviewDraft draft) async {
    try {
      final response = await _dio.post<Object?>(
        ApiEndpoints.orderReviews(orderId),
        data: draft.toJson(),
      );
      return OrderReview.fromJson(_map(apiPayload(response.data)));
    } on DioException catch (error) {
      throw failureFromDio(error);
    }
  }

  Future<Order> confirmReceived(String orderId) async {
    try {
      final response = await _dio.patch<Object?>(
        ApiEndpoints.order(orderId),
        data: {'receivedConfirmed': true},
      );
      return Order.fromJson(_map(apiPayload(response.data)));
    } on DioException catch (error) {
      throw failureFromDio(error);
    }
  }

  Future<PaymentLink> payRemainder(String orderId) async {
    try {
      final response = await _dio.post<Object?>(ApiEndpoints.orderPayments(orderId));
      final payload = _map(apiPayload(response.data));
      final link = PaymentLink(
        paymentId: payload['paymentId'] is String ? payload['paymentId']! as String : '',
        paymentUrl: payload['paymentUrl'] is String ? payload['paymentUrl']! as String : '',
      );
      if (link.paymentId.isEmpty || link.paymentUrl.isEmpty) {
        throw const InvalidResponseFailure();
      }
      return link;
    } on DioException catch (error) {
      throw failureFromDio(error);
    }
  }

  static Map<String, Object?> _map(Object? value) {
    if (value is! Map) throw const InvalidResponseFailure();
    return value.map((key, item) => MapEntry(key.toString(), item));
  }

  static int _integer(Object? value) => value is num ? value.toInt() : 0;
}
