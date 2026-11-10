import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moonkage_verify/core/network/api_endpoints.dart';
import 'package:moonkage_verify/features/catalog/data/catalog_api.dart';
import 'package:moonkage_verify/features/catalog/domain/catalog_filter.dart';
import 'package:moonkage_verify/features/catalog/domain/product.dart';

import 'helpers/fake_http_adapter.dart';

Map<String, Object?> productJson({String id = 'product-1'}) => {
  'id': id,
  'vendorId': 'vendor-1',
  'vendorName': 'Nguyệt Viên',
  'provinceCode': '01',
  'name': 'Bánh nướng thập cẩm',
  'description': 'Mô tả',
  'crustCodes': ['vo-nuong'],
  'fillingCodes': ['thap-cam'],
  'brand': 'MoonKage',
  'origin': 'Việt Nam',
  'piecesPerBox': 1,
  'listPrice': 185000,
  'stock': 20,
  'inStock': true,
  'expiryDate': '2027-12-31',
  'deliveryLabel': 'NATIONWIDE',
  'quoteThreshold': 50,
  'imageUrls': <String>[],
  'ratingAvg': 4.8,
  'ratingCount': 12,
  'vendorAcceptsOrders': true,
  'isOwn': false,
};

void main() {
  test('search gửi province, filter, sort và parse PageResponse', () async {
    final adapter = FakeHttpAdapter(
      body: {
        'data': {
          'content': [productJson()],
          'page': 0,
          'size': 20,
          'totalElements': 1,
          'totalPages': 1,
        },
      },
    );
    final dio = Dio(BaseOptions(baseUrl: 'http://mock'))..httpClientAdapter = adapter;
    const filter = CatalogFilter(
      provinceCode: '79',
      query: 'thập cẩm',
      brands: {'MoonKage'},
      crusts: {'vo-nuong'},
      fillings: {'thap-cam'},
      sort: 'price-asc',
    );

    final page = await CatalogApi(dio).search(filter);

    expect(adapter.lastRequest?.path, ApiEndpoints.products);
    expect(adapter.lastRequest?.queryParameters['provinceCode'], '79');
    expect(adapter.lastRequest?.queryParameters['sort'], 'price-asc');
    expect(adapter.lastRequest?.queryParameters['brand'], ['MoonKage']);
    expect(page.content.single.name, 'Bánh nướng thập cẩm');
    expect(page.totalElements, 1);
  });

  test('chi tiết parse đúng listPrice, taxonomy và trạng thái kho', () async {
    final adapter = FakeHttpAdapter(body: {'data': productJson()});
    final dio = Dio(BaseOptions(baseUrl: 'http://mock'))..httpClientAdapter = adapter;

    final product = await CatalogApi(dio).getProduct('product-1', '01');

    expect(adapter.lastRequest?.path, ApiEndpoints.product('product-1'));
    expect(adapter.lastRequest?.queryParameters['provinceCode'], '01');
    expect(product.listPrice, 185000);
    expect(product.crustCodes, ['vo-nuong']);
    expect(product.inStock, isTrue);
  });

  test('facets parse code/count và khoảng giá', () async {
    final adapter = FakeHttpAdapter(
      body: {
        'data': {
          'crusts': [
            {'value': 'vo-nuong', 'count': 3},
          ],
          'fillings': <Object?>[],
          'brands': [
            {'value': 'MoonKage', 'count': 3},
          ],
          'vendors': [
            {'vendorId': 'vendor-1', 'vendorName': 'Nguyệt Viên', 'count': 3},
          ],
          'priceMin': 100000,
          'priceMax': 700000,
        },
      },
    );
    final dio = Dio(BaseOptions(baseUrl: 'http://mock'))..httpClientAdapter = adapter;

    final facets = await CatalogApi(dio).getFacets('01');

    expect(facets.crusts.single.value, 'vo-nuong');
    expect(facets.crusts.single.count, 3);
    expect(facets.vendors.single.label, 'Nguyệt Viên');
    expect(facets.priceMax, 700000);
  });

  test('format giá VND không cần dữ liệu UI giả', () {
    expect(formatVnd(185000), '185.000 ₫');
    expect(formatVnd(0), '0 ₫');
  });
}
