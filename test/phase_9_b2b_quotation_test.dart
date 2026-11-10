import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moonkage_verify/core/network/api_endpoints.dart';
import 'package:moonkage_verify/features/b2b/data/quotation_api.dart';
import 'package:moonkage_verify/features/b2b/domain/quotation.dart';

import 'helpers/fake_http_adapter.dart';

void main() {
  test('đọc danh sách nhà cung cấp theo contract backend', () async {
    final adapter = FakeHttpAdapter(
      body: {
        'data': [
          {
            'vendorId': 'vendor-1',
            'businessName': 'Nguyệt Viên',
            'ordersOnly': false,
            'supplySource': 'Xưởng Hà Nội',
            'minQty': 30,
            'leadTimeDays': 10,
            'customCapabilities': ['BAG', 'CARD'],
            'deliveryAreas': ['01', '79'],
            'earlyBirdOffer': 'Giảm 5%',
            'refPriceTiers': null,
            'isOwn': false,
          },
        ],
      },
    );
    final dio = Dio(BaseOptions(baseUrl: 'http://mock'))..httpClientAdapter = adapter;

    final suppliers = await QuotationApi(dio).suppliers();

    expect(adapter.lastRequest?.method, 'GET');
    expect(adapter.lastRequest?.path, ApiEndpoints.suppliers);
    expect(suppliers.single.businessName, 'Nguyệt Viên');
    expect(suppliers.single.customCapabilities, ['BAG', 'CARD']);
  });

  test('tạo yêu cầu trực tiếp gửi đúng payload', () async {
    final adapter = FakeHttpAdapter(body: {'data': _requestJson()});
    final dio = Dio(BaseOptions(baseUrl: 'http://mock'))..httpClientAdapter = adapter;

    final request = await QuotationApi(dio).create(
      QuoteRequestDraft(
        type: QuoteRequestType.direct,
        targetVendorId: 'vendor-1',
        quantity: 100,
        budget: 20000000,
        customTypes: const {CustomType.bag, CustomType.card},
        customSpec: '  In logo doanh nghiệp  ',
        deliveryDeadline: DateTime(2026, 12, 20),
        delivery: const QuoteDelivery(
          recipientName: 'Nguyễn Văn Demo',
          recipientPhone: '0900000001',
          provinceCode: '79',
          addressDetail: '12 Lê Lợi, TP.HCM',
        ),
      ),
    );

    expect(adapter.lastRequest?.method, 'POST');
    expect(adapter.lastRequest?.path, ApiEndpoints.quoteRequests);
    expect(adapter.lastRequest?.data, {
      'type': 'DIRECT',
      'targetVendorId': 'vendor-1',
      'quantity': 100,
      'budget': 20000000,
      'customTypes': ['BAG', 'CARD'],
      'customSpec': 'In logo doanh nghiệp',
      'deliveryDeadline': '2026-12-20',
      'delivery': {
        'recipientName': 'Nguyễn Văn Demo',
        'recipientPhone': '0900000001',
        'provinceCode': '79',
        'addressDetail': '12 Lê Lợi, TP.HCM',
      },
    });
    expect(request.id, 'request-1');
  });

  test('chấp nhận báo giá gọi đúng endpoint và đọc link đặt cọc', () async {
    final adapter = FakeHttpAdapter(
      body: {
        'data': {
          'acceptanceId': 'acceptance-1',
          'status': 'PENDING_PAYMENT',
          'depositAmount': 4500000,
          'paymentId': 'payment-1',
          'paymentUrl': 'https://sandbox.vnpay.vn/deposit',
          'paymentExpiresAt': '2026-11-10T10:15:00Z',
        },
      },
    );
    final dio = Dio(BaseOptions(baseUrl: 'http://mock'))..httpClientAdapter = adapter;

    final acceptance = await QuotationApi(dio).accept('request-1', 'quote-1');

    expect(adapter.lastRequest?.method, 'POST');
    expect(
      adapter.lastRequest?.path,
      ApiEndpoints.quoteAcceptance('request-1', 'quote-1'),
    );
    expect(adapter.lastRequest?.data, <String, Object?>{});
    expect(acceptance.depositAmount, 4500000);
    expect(acceptance.paymentUrl, contains('vnpay.vn'));
  });
}

Map<String, Object?> _requestJson() => {
  'id': 'request-1',
  'type': 'DIRECT',
  'buyerAccountId': 'buyer-1',
  'targetVendorId': 'vendor-1',
  'productId': null,
  'quantity': 100,
  'budget': 20000000,
  'customTypes': ['BAG', 'CARD'],
  'customSpec': 'In logo doanh nghiệp',
  'deliveryDeadline': '2026-12-20',
  'delivery': {
    'recipientName': 'Nguyễn Văn Demo',
    'recipientPhone': '0900000001',
    'provinceCode': '79',
    'addressDetail': '12 Lê Lợi, TP.HCM',
  },
  'status': 'OPEN',
  'invitedCount': 1,
  'quoteCount': 0,
  'suggestedUnitPrice': null,
  'createdAt': '2026-11-10T09:00:00Z',
};
