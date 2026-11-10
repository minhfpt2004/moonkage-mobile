import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moonkage_verify/core/network/api_endpoints.dart';
import 'package:moonkage_verify/features/checkout/data/checkout_api.dart';
import 'package:moonkage_verify/features/checkout/domain/checkout.dart';

import 'helpers/fake_http_adapter.dart';

void main() {
  test('tạo checkout gửi địa chỉ và hóa đơn đúng contract', () async {
    final adapter = FakeHttpAdapter(
      body: {
        'data': {
          'checkoutId': 'checkout-1',
          'paymentId': 'payment-1',
          'paymentUrl': 'https://sandbox.vnpay.vn/pay/1',
          'totalAmount': 415000,
          'expiresAt': '2026-11-10T08:30:00Z',
        },
      },
    );
    final dio = Dio(BaseOptions(baseUrl: 'http://mock'))..httpClientAdapter = adapter;
    const draft = CheckoutDraft(
      recipientName: 'Nguyễn Văn Demo',
      recipientPhone: '0900000001',
      provinceCode: '79',
      addressDetail: '12 Lê Lợi, Phường Bến Nghé',
      invoiceInfo: InvoiceInfo(
        name: 'Công ty MoonKage',
        taxCode: '0123456789',
        address: '12 Lê Lợi, TP.HCM',
        email: 'invoice@moonkage.vn',
      ),
    );

    final checkout = await CheckoutApi(dio).create(draft);

    expect(adapter.lastRequest?.method, 'POST');
    expect(adapter.lastRequest?.path, ApiEndpoints.checkouts);
    expect(adapter.lastRequest?.data, draft.toJson());
    expect(checkout.checkoutId, 'checkout-1');
    expect(checkout.paymentId, 'payment-1');
    expect(checkout.totalAmount, 415000);
    expect(checkout.expiresAt, isNotNull);
  });

  test('checkout cá nhân không gửi invoiceInfo null', () {
    const draft = CheckoutDraft(
      recipientName: 'Nguyễn Văn Demo',
      recipientPhone: '0900000001',
      provinceCode: '01',
      addressDetail: '1 Tràng Tiền, Hoàn Kiếm',
    );

    expect(draft.toJson().containsKey('invoiceInfo'), isFalse);
  });

  test('đọc trạng thái thành công và các orderIds do backend tạo', () async {
    final adapter = FakeHttpAdapter(
      body: {
        'data': {
          'checkoutId': 'checkout-1',
          'status': 'SUCCEEDED',
          'totalAmount': 415000,
          'paymentId': 'payment-1',
          'expiresAt': '2026-11-10T08:30:00Z',
          'orderIds': ['order-shop-1', 'order-shop-2'],
        },
      },
    );
    final dio = Dio(BaseOptions(baseUrl: 'http://mock'))..httpClientAdapter = adapter;

    final checkout = await CheckoutApi(dio).get('checkout-1');

    expect(adapter.lastRequest?.method, 'GET');
    expect(adapter.lastRequest?.path, ApiEndpoints.checkout('checkout-1'));
    expect(checkout.status, CheckoutStatus.succeeded);
    expect(checkout.status.isFinal, isTrue);
    expect(checkout.orderIds, ['order-shop-1', 'order-shop-2']);
  });

  test('mapping đủ vòng đời checkout backend', () {
    expect(CheckoutStatus.fromWire('PENDING_PAYMENT'), CheckoutStatus.pendingPayment);
    expect(CheckoutStatus.fromWire('FAILED'), CheckoutStatus.failed);
    expect(CheckoutStatus.fromWire('EXPIRED'), CheckoutStatus.expired);
    expect(CheckoutStatus.fromWire('REFUND_REQUESTED'), CheckoutStatus.refundRequested);
    expect(CheckoutStatus.fromWire('NEW_STATUS'), CheckoutStatus.unknown);
  });
}
