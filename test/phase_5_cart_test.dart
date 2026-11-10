import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moonkage_verify/core/network/api_endpoints.dart';
import 'package:moonkage_verify/features/cart/data/cart_api.dart';

import 'helpers/fake_http_adapter.dart';

Map<String, Object?> cartLineJson({int quantity = 2}) => {
  'itemId': 'item-1',
  'productId': 'product-1',
  'productName': 'Bánh nướng thập cẩm',
  'unitPrice': 185000,
  'quantity': quantity,
  'available': true,
};

void main() {
  test('đọc giỏ hàng theo tỉnh và parse nhóm shop', () async {
    final adapter = FakeHttpAdapter(
      body: {
        'data': {
          'provinceCode': '79',
          'groups': [
            {
              'vendorId': 'vendor-1',
              'vendorName': 'Nguyệt Viên',
              'deliverable': true,
              'interprovince': true,
              'shippingFee': 45000,
              'subtotal': 370000,
              'items': [cartLineJson()],
            },
          ],
          'totalAmount': 415000,
        },
      },
    );
    final dio = Dio(BaseOptions(baseUrl: 'http://mock'))..httpClientAdapter = adapter;

    final cart = await CartApi(dio).getMine('79');

    expect(adapter.lastRequest?.path, ApiEndpoints.cart);
    expect(adapter.lastRequest?.queryParameters['provinceCode'], '79');
    expect(cart.groups.single.vendorName, 'Nguyệt Viên');
    expect(cart.groups.single.shippingFee, 45000);
    expect(cart.itemCount, 2);
    expect(cart.totalAmount, 415000);
  });

  test('thêm sản phẩm gửi đúng productId và số lượng', () async {
    final adapter = FakeHttpAdapter(body: {'data': cartLineJson(quantity: 3)});
    final dio = Dio(BaseOptions(baseUrl: 'http://mock'))..httpClientAdapter = adapter;

    final line = await CartApi(dio).addItem(productId: 'product-1', quantity: 3);

    expect(adapter.lastRequest?.method, 'POST');
    expect(adapter.lastRequest?.path, ApiEndpoints.cartItems);
    expect(adapter.lastRequest?.data, {'productId': 'product-1', 'quantity': 3});
    expect(line.quantity, 3);
    expect(line.lineTotal, 555000);
  });

  test('cập nhật số lượng sử dụng PATCH với số lượng tuyệt đối', () async {
    final adapter = FakeHttpAdapter(body: {'data': cartLineJson(quantity: 4)});
    final dio = Dio(BaseOptions(baseUrl: 'http://mock'))..httpClientAdapter = adapter;

    final line = await CartApi(dio).updateItem('item-1', 4);

    expect(adapter.lastRequest?.method, 'PATCH');
    expect(adapter.lastRequest?.path, ApiEndpoints.cartItem('item-1'));
    expect(adapter.lastRequest?.data, {'quantity': 4});
    expect(line.quantity, 4);
  });

  test('xóa sản phẩm sử dụng đúng endpoint item', () async {
    final adapter = FakeHttpAdapter(statusCode: 204);
    final dio = Dio(BaseOptions(baseUrl: 'http://mock'))..httpClientAdapter = adapter;

    await CartApi(dio).removeItem('item-1');

    expect(adapter.lastRequest?.method, 'DELETE');
    expect(adapter.lastRequest?.path, ApiEndpoints.cartItem('item-1'));
  });
}
