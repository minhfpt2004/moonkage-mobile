import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moonkage_verify/core/network/api_endpoints.dart';
import 'package:moonkage_verify/features/orders/data/order_api.dart';
import 'package:moonkage_verify/features/orders/domain/order.dart';

import 'helpers/fake_http_adapter.dart';

void main() {
  test('tải đánh giá của đơn hàng đúng endpoint và parse dữ liệu', () async {
    final adapter = FakeHttpAdapter(
      body: {
        'data': [
          {
            'reviewId': 'review-1',
            'productId': 'product-1',
            'rating': 5,
            'content': 'Bánh ngon và đóng gói đẹp.',
            'createdAt': '2026-11-10T09:00:00Z',
          },
        ],
      },
    );
    final dio = Dio(BaseOptions(baseUrl: 'http://mock'))..httpClientAdapter = adapter;

    final reviews = await OrderApi(dio).reviews('order-1');

    expect(adapter.lastRequest?.method, 'GET');
    expect(adapter.lastRequest?.path, ApiEndpoints.orderReviews('order-1'));
    expect(reviews.single.productId, 'product-1');
    expect(reviews.single.rating, 5);
    expect(reviews.single.content, 'Bánh ngon và đóng gói đẹp.');
    expect(reviews.single.createdAt, isNotNull);
  });

  test('gửi đánh giá dùng đúng body backend yêu cầu', () async {
    final adapter = FakeHttpAdapter(
      body: {
        'data': {
          'reviewId': 'review-2',
          'productId': 'product-2',
          'rating': 4,
          'content': 'Vị ngon.',
          'createdAt': '2026-11-10T10:00:00Z',
        },
      },
    );
    final dio = Dio(BaseOptions(baseUrl: 'http://mock'))..httpClientAdapter = adapter;

    final review = await OrderApi(dio).createReview(
      'order-2',
      const OrderReviewDraft(
        productId: 'product-2',
        rating: 4,
        content: '  Vị ngon.  ',
      ),
    );

    expect(adapter.lastRequest?.method, 'POST');
    expect(adapter.lastRequest?.path, ApiEndpoints.orderReviews('order-2'));
    expect(adapter.lastRequest?.data, {
      'productId': 'product-2',
      'rating': 4,
      'content': 'Vị ngon.',
    });
    expect(review.id, 'review-2');
  });
}
