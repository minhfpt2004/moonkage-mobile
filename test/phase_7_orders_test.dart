import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moonkage_verify/core/network/api_endpoints.dart';
import 'package:moonkage_verify/features/orders/data/order_api.dart';
import 'package:moonkage_verify/features/orders/domain/order.dart';

import 'helpers/fake_http_adapter.dart';

void main() {
  test('danh sách đơn gửi bộ lọc trạng thái và phân trang đúng contract', () async {
    final adapter = FakeHttpAdapter(
      body: {
        'data': {
          'content': [_orderJson(items: const [])],
          'page': 0,
          'size': 50,
          'totalElements': 1,
          'totalPages': 1,
        },
      },
    );
    final dio = Dio(BaseOptions(baseUrl: 'http://mock'))..httpClientAdapter = adapter;

    final page = await OrderApi(dio).list(status: OrderStatus.shipping);

    expect(adapter.lastRequest?.method, 'GET');
    expect(adapter.lastRequest?.path, ApiEndpoints.orders);
    expect(adapter.lastRequest?.queryParameters, {
      'status': 'SHIPPING',
      'page': 0,
      'size': 50,
    });
    expect(page.totalElements, 1);
    expect(page.content.single.status, OrderStatus.shipping);
  });

  test('chi tiết đơn parse sản phẩm, tiền và thông tin giao hàng', () async {
    final adapter = FakeHttpAdapter(body: {'data': _orderJson()});
    final dio = Dio(BaseOptions(baseUrl: 'http://mock'))..httpClientAdapter = adapter;

    final order = await OrderApi(dio).get('order-1');

    expect(adapter.lastRequest?.path, ApiEndpoints.order('order-1'));
    expect(order.kind, OrderKind.buyNow);
    expect(order.totalAmount, 365000);
    expect(order.items.single.productName, 'Bánh trung thu thập cẩm');
    expect(order.items.single.quantity, 2);
    expect(order.recipientPhone, '0900000001');
  });

  test('timeline đơn parse milestone và ảnh tiến độ', () async {
    final adapter = FakeHttpAdapter(
      body: {
        'data': [
          {
            'milestone': 'SHIPPING',
            'note': 'Đơn hàng đang được vận chuyển.',
            'photoKeys': ['orders/order-1/shipping.jpg'],
            'createdAt': '2026-11-10T09:00:00Z',
          },
        ],
      },
    );
    final dio = Dio(BaseOptions(baseUrl: 'http://mock'))..httpClientAdapter = adapter;

    final progress = await OrderApi(dio).progress('order-1');

    expect(adapter.lastRequest?.path, ApiEndpoints.orderProgress('order-1'));
    expect(progress.single.milestone, OrderStatus.shipping);
    expect(progress.single.photoKeys, ['orders/order-1/shipping.jpg']);
  });

  test('xác nhận đã nhận hàng dùng PATCH với body chính xác', () async {
    final adapter = FakeHttpAdapter(
      body: {'data': _orderJson(status: 'COMPLETED', received: true)},
    );
    final dio = Dio(BaseOptions(baseUrl: 'http://mock'))..httpClientAdapter = adapter;

    final order = await OrderApi(dio).confirmReceived('order-1');

    expect(adapter.lastRequest?.method, 'PATCH');
    expect(adapter.lastRequest?.path, ApiEndpoints.order('order-1'));
    expect(adapter.lastRequest?.data, {'receivedConfirmed': true});
    expect(order.status, OrderStatus.completed);
    expect(order.receivedConfirmedAt, isNotNull);
  });

  test('thanh toán phần còn lại đọc payment URL từ backend', () async {
    final adapter = FakeHttpAdapter(
      body: {
        'data': {
          'paymentId': 'payment-remainder-1',
          'paymentUrl': 'https://sandbox.vnpay.vn/pay/remainder-1',
        },
      },
    );
    final dio = Dio(BaseOptions(baseUrl: 'http://mock'))..httpClientAdapter = adapter;

    final payment = await OrderApi(dio).payRemainder('order-custom-1');

    expect(adapter.lastRequest?.method, 'POST');
    expect(adapter.lastRequest?.path, ApiEndpoints.orderPayments('order-custom-1'));
    expect(payment.paymentId, 'payment-remainder-1');
    expect(payment.paymentUrl, contains('vnpay.vn'));
  });

  test('mapping đủ trạng thái đơn mua ngay và đơn đặt làm', () {
    expect(OrderStatus.fromWire('PAID'), OrderStatus.paid);
    expect(OrderStatus.fromWire('CONFIRMED'), OrderStatus.confirmed);
    expect(OrderStatus.fromWire('SHIPPING'), OrderStatus.shipping);
    expect(OrderStatus.fromWire('DEPOSITED'), OrderStatus.deposited);
    expect(
      OrderStatus.fromWire('AWAITING_MOCKUP_APPROVAL'),
      OrderStatus.awaitingMockupApproval,
    );
    expect(OrderStatus.fromWire('IN_PRODUCTION'), OrderStatus.inProduction);
    expect(OrderStatus.fromWire('READY_TO_SHIP'), OrderStatus.readyToShip);
    expect(OrderStatus.fromWire('DELIVERED'), OrderStatus.delivered);
    expect(OrderStatus.fromWire('COMPLETED'), OrderStatus.completed);
    expect(OrderStatus.fromWire('NEW_STATUS'), OrderStatus.unknown);
  });
}

Map<String, Object?> _orderJson({
  String status = 'SHIPPING',
  bool received = false,
  List<Map<String, Object?>>? items,
}) => {
  'id': 'order-1',
  'kind': 'BUY_NOW',
  'status': status,
  'buyerAccountId': 'buyer-1',
  'vendorId': 'vendor-1',
  'vendorName': 'Nguyệt Viên',
  'paymentGroupId': 'checkout-1',
  'quoteId': null,
  'itemsAmount': 350000,
  'shippingFee': 15000,
  'discountAmount': 0,
  'totalAmount': 365000,
  'depositAmount': null,
  'remainingAmount': null,
  'interprovince': false,
  'hasCustom': false,
  'recipientName': 'Nguyễn Văn Demo',
  'recipientPhone': '0900000001',
  'provinceCode': '79',
  'addressDetail': '12 Lê Lợi, Phường Bến Nghé',
  'deliveryDate': null,
  'deliveryMethod': 'LOCAL',
  'trackingCode': 'MK-ORDER-1',
  'invoiceInfo': null,
  'hasInvoiceFile': false,
  'deliveredAt': received ? '2026-11-10T10:00:00Z' : null,
  'receivedConfirmedAt': received ? '2026-11-10T11:00:00Z' : null,
  'complaintDeadline': null,
  'disputeOpen': false,
  'createdAt': '2026-11-10T08:00:00Z',
  'items':
      items ??
      [
        {
          'productId': 'product-1',
          'productName': 'Bánh trung thu thập cẩm',
          'imageUrl': 'https://cdn.example.com/product-1.jpg',
          'unitPrice': 175000,
          'quantity': 2,
          'subtotal': 350000,
        },
      ],
};
