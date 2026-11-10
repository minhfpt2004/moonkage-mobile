import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moonkage_verify/core/errors/app_failure.dart';
import 'package:moonkage_verify/core/network/api_endpoints.dart';
import 'package:moonkage_verify/core/network/api_payload.dart';
import 'package:moonkage_verify/core/network/dio_failure.dart';
import 'package:moonkage_verify/core/network/dio_provider.dart';
import 'package:moonkage_verify/features/account/domain/account_profile.dart';

final accountApiProvider = Provider<AccountApi>((ref) => AccountApi(ref.watch(dioProvider)));

final accountProfileProvider = FutureProvider.autoDispose<AccountProfile>((ref) {
  return ref.watch(accountApiProvider).getMyAccount();
});

class AccountApi {
  AccountApi(this._dio);

  final Dio _dio;

  Future<AccountProfile> getMyAccount() async {
    try {
      final response = await _dio.get<Object?>(ApiEndpoints.accountMe);
      return _parse(response.data);
    } on DioException catch (error) {
      throw failureFromDio(error);
    }
  }

  Future<AccountProfile> updateFullName(String fullName) async {
    try {
      final response = await _dio.patch<Object?>(
        ApiEndpoints.accountProfile,
        data: {'fullName': fullName},
      );
      return _parse(response.data);
    } on DioException catch (error) {
      throw failureFromDio(error);
    }
  }

  AccountProfile _parse(Object? body) {
    final payload = apiPayload(body);
    if (payload is! Map) throw const InvalidResponseFailure();
    final map = payload.map((key, value) => MapEntry(key.toString(), value));
    if (map['accountId'] is! String || map['email'] is! String) {
      throw const InvalidResponseFailure();
    }
    return AccountProfile.fromJson(map);
  }
}
