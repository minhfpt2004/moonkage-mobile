import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moonkage_verify/core/errors/app_failure.dart';
import 'package:moonkage_verify/core/network/api_endpoints.dart';
import 'package:moonkage_verify/core/network/api_payload.dart';
import 'package:moonkage_verify/core/network/dio_failure.dart';
import 'package:moonkage_verify/core/network/dio_provider.dart';
import 'package:moonkage_verify/features/catalog/domain/catalog_filter.dart';
import 'package:moonkage_verify/features/catalog/domain/product.dart';

final catalogApiProvider = Provider<CatalogApi>((ref) => CatalogApi(ref.watch(dioProvider)));

final productDetailProvider = FutureProvider.autoDispose
    .family<Product, ({String id, String provinceCode})>(
      (ref, argument) =>
          ref.watch(catalogApiProvider).getProduct(argument.id, argument.provinceCode),
    );

final productReviewsProvider = FutureProvider.autoDispose.family<List<ProductReview>, String>(
  (ref, productId) => ref.watch(catalogApiProvider).getReviews(productId),
);

final cakeAttributesProvider = FutureProvider.autoDispose<List<CakeAttribute>>(
  (ref) => ref.watch(catalogApiProvider).getCakeAttributes(),
);

final featuredProductsProvider = FutureProvider.autoDispose.family<List<Product>, String>(
  (ref, provinceCode) async {
    final page = await ref
        .watch(catalogApiProvider)
        .search(CatalogFilter(provinceCode: provinceCode));
    return page.content.take(6).toList(growable: false);
  },
);

class CatalogApi {
  CatalogApi(this._dio);

  final Dio _dio;

  Future<ProductPage> search(CatalogFilter filter, {int page = 0}) async {
    try {
      final response = await _dio.get<Object?>(
        ApiEndpoints.products,
        queryParameters: filter.toQueryParameters(page: page),
        options: Options(listFormat: ListFormat.multi),
      );
      return _parseProductPage(apiPayload(response.data));
    } on DioException catch (error) {
      throw failureFromDio(error);
    }
  }

  Future<ProductFacets> getFacets(String provinceCode, {String query = ''}) async {
    try {
      final response = await _dio.get<Object?>(
        ApiEndpoints.productFacets,
        queryParameters: {
          'provinceCode': provinceCode,
          if (query.trim().isNotEmpty) 'q': query.trim(),
        },
      );
      final payload = _map(apiPayload(response.data));
      return ProductFacets(
        crusts: _facetValues(payload['crusts']),
        fillings: _facetValues(payload['fillings']),
        brands: _facetValues(payload['brands']),
        vendors: _vendorValues(payload['vendors']),
        priceMin: _nullableInt(payload['priceMin']),
        priceMax: _nullableInt(payload['priceMax']),
      );
    } on DioException catch (error) {
      throw failureFromDio(error);
    }
  }

  Future<Product> getProduct(String productId, String provinceCode) async {
    try {
      final response = await _dio.get<Object?>(
        ApiEndpoints.product(productId),
        queryParameters: {'provinceCode': provinceCode},
      );
      return Product.fromJson(_map(apiPayload(response.data)));
    } on DioException catch (error) {
      throw failureFromDio(error);
    }
  }

  Future<List<ProductReview>> getReviews(String productId) async {
    try {
      final response = await _dio.get<Object?>(ApiEndpoints.productReviews(productId));
      final page = _map(apiPayload(response.data));
      final content = page['content'];
      if (content is! List) throw const InvalidResponseFailure();
      return content.map((item) => ProductReview.fromJson(_map(item))).toList(growable: false);
    } on DioException catch (error) {
      throw failureFromDio(error);
    }
  }

  Future<List<CakeAttribute>> getCakeAttributes() async {
    try {
      final response = await _dio.get<Object?>(ApiEndpoints.cakeAttributes);
      final payload = apiPayload(response.data);
      if (payload is! List) throw const InvalidResponseFailure();
      return payload
          .map((item) {
            final map = _map(item);
            return CakeAttribute(
              code: map['code'] is String ? map['code']! as String : '',
              label: map['label'] is String ? map['label']! as String : '',
              group: map['group'] is String ? map['group']! as String : '',
              active: map['active'] == true,
            );
          })
          .toList(growable: false);
    } on DioException catch (error) {
      throw failureFromDio(error);
    }
  }

  ProductPage _parseProductPage(Object? payload) {
    final map = _map(payload);
    final content = map['content'];
    if (content is! List) throw const InvalidResponseFailure();
    return ProductPage(
      content: content.map((item) => Product.fromJson(_map(item))).toList(growable: false),
      page: _integer(map['page']),
      size: _integer(map['size']),
      totalElements: _integer(map['totalElements']),
      totalPages: _integer(map['totalPages']),
    );
  }

  static Map<String, Object?> _map(Object? value) {
    if (value is! Map) throw const InvalidResponseFailure();
    return value.map((key, item) => MapEntry(key.toString(), item));
  }

  static List<FacetValue> _facetValues(Object? value) => value is List
      ? value
            .map((item) {
              final map = _map(item);
              return FacetValue(
                value: map['value'] is String ? map['value']! as String : '',
                count: _integer(map['count']),
              );
            })
            .toList(growable: false)
      : const [];

  static List<FacetValue> _vendorValues(Object? value) => value is List
      ? value
            .map((item) {
              final map = _map(item);
              return FacetValue(
                value: map['vendorId'] is String ? map['vendorId']! as String : '',
                label: map['vendorName'] is String ? map['vendorName']! as String : '',
                count: _integer(map['count']),
              );
            })
            .toList(growable: false)
      : const [];

  static int _integer(Object? value) => value is num ? value.toInt() : 0;
  static int? _nullableInt(Object? value) => value is num ? value.toInt() : null;
}
