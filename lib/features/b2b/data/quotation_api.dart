import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moonkage_verify/core/errors/app_failure.dart';
import 'package:moonkage_verify/core/network/api_endpoints.dart';
import 'package:moonkage_verify/core/network/api_payload.dart';
import 'package:moonkage_verify/core/network/dio_failure.dart';
import 'package:moonkage_verify/core/network/dio_provider.dart';
import 'package:moonkage_verify/features/b2b/domain/quotation.dart';

final quotationApiProvider = Provider<QuotationApi>((ref) => QuotationApi(ref.watch(dioProvider)));

final suppliersProvider = FutureProvider.autoDispose<List<Supplier>>(
  (ref) => ref.watch(quotationApiProvider).suppliers(),
);

final quoteRequestsProvider = FutureProvider.autoDispose<List<BuyerQuoteRequest>>(
  (ref) => ref.watch(quotationApiProvider).requests(),
);

final quoteRequestProvider = FutureProvider.autoDispose.family<BuyerQuoteRequest, String>(
  (ref, requestId) => ref.watch(quotationApiProvider).request(requestId),
);

final quoteInvitationsProvider = FutureProvider.autoDispose.family<List<QuoteInvitation>, String>(
  (ref, requestId) => ref.watch(quotationApiProvider).invitations(requestId),
);

final vendorQuotesProvider = FutureProvider.autoDispose.family<List<VendorQuote>, String>(
  (ref, requestId) => ref.watch(quotationApiProvider).quotes(requestId),
);

class QuotationApi {
  QuotationApi(this._dio);

  final Dio _dio;

  Future<List<Supplier>> suppliers() => _list(
    () => _dio.get<Object?>(ApiEndpoints.suppliers),
    Supplier.fromJson,
  );

  Future<List<BuyerQuoteRequest>> requests() => _list(
    () => _dio.get<Object?>(ApiEndpoints.quoteRequests),
    BuyerQuoteRequest.fromJson,
  );

  Future<BuyerQuoteRequest> request(String requestId) => _one(
    () => _dio.get<Object?>(ApiEndpoints.quoteRequest(requestId)),
    BuyerQuoteRequest.fromJson,
  );

  Future<List<QuoteInvitation>> invitations(String requestId) => _list(
    () => _dio.get<Object?>(ApiEndpoints.quoteInvitations(requestId)),
    QuoteInvitation.fromJson,
  );

  Future<List<VendorQuote>> quotes(String requestId) => _list(
    () => _dio.get<Object?>(ApiEndpoints.quotes(requestId)),
    VendorQuote.fromJson,
  );

  Future<BuyerQuoteRequest> create(QuoteRequestDraft draft) => _one(
    () => _dio.post<Object?>(ApiEndpoints.quoteRequests, data: draft.toJson()),
    BuyerQuoteRequest.fromJson,
  );

  Future<QuoteAcceptance> accept(String requestId, String quoteId) => _one(
    () => _dio.post<Object?>(
      ApiEndpoints.quoteAcceptance(requestId, quoteId),
      data: <String, Object?>{},
    ),
    QuoteAcceptance.fromJson,
  );

  Future<List<T>> _list<T>(
    Future<Response<Object?>> Function() request,
    T Function(Map<String, Object?>) parse,
  ) async {
    try {
      final response = await request();
      final payload = apiPayload(response.data);
      if (payload is! List) throw const InvalidResponseFailure();
      return payload.map((item) => parse(_map(item))).toList(growable: false);
    } on DioException catch (error) {
      throw failureFromDio(error);
    }
  }

  Future<T> _one<T>(
    Future<Response<Object?>> Function() request,
    T Function(Map<String, Object?>) parse,
  ) async {
    try {
      final response = await request();
      return parse(_map(apiPayload(response.data)));
    } on DioException catch (error) {
      throw failureFromDio(error);
    }
  }

  static Map<String, Object?> _map(Object? value) {
    if (value is! Map) throw const InvalidResponseFailure();
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
}
