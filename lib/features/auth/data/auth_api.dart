import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moonkage_verify/core/auth/auth_session.dart';
import 'package:moonkage_verify/core/auth/auth_session_parser.dart';
import 'package:moonkage_verify/core/errors/app_failure.dart';
import 'package:moonkage_verify/core/network/api_endpoints.dart';
import 'package:moonkage_verify/core/network/dio_failure.dart';
import 'package:moonkage_verify/core/network/dio_provider.dart';
import 'package:moonkage_verify/features/auth/data/register_result.dart';

final authApiProvider = Provider<AuthApi>((ref) => AuthApi(ref.watch(dioProvider)));

/// Public authentication contract of identity-service.
class AuthApi {
  AuthApi(this._dio);

  final Dio _dio;

  Future<AuthSession> login({required String username, required String password}) async {
    final body = await _post(
      ApiEndpoints.login,
      {'username': username, 'password': password},
    );
    return parseAuthSession(body, fallbackName: username);
  }

  Future<AuthSession> refresh(String refreshToken) async {
    final body = await _post(
      ApiEndpoints.refreshToken,
      {'refreshToken': refreshToken},
    );
    return parseAuthSession(body);
  }

  Future<RegisterResult> register({
    required String email,
    required String fullName,
    required String password,
    String? phoneNumber,
  }) async {
    final body = await _post(ApiEndpoints.register, {
      'email': email,
      'phoneNumber': phoneNumber ?? '',
      'fullName': fullName,
      'password': password,
    });
    final map = payloadMap(body);
    if (map == null || map['email'] is! String || map['id'] is! String) {
      throw const InvalidResponseFailure();
    }
    return RegisterResult(
      id: map['id']! as String,
      email: map['email']! as String,
      phoneNumber: map['phoneNumber'] is String ? map['phoneNumber']! as String : '',
      verified: map['verified'] == true,
      otpSent: map['otpSent'] == true,
    );
  }

  Future<void> sendVerifyAccountOtp(String email) =>
      _postVoid(ApiEndpoints.sendVerifyAccountOtp, {'email': email});

  Future<void> verifyAccount({required String email, required String otp}) =>
      _postVoid(ApiEndpoints.verifyAccount, {'email': email, 'otp': otp});

  Future<void> sendResetPasswordOtp(String email) =>
      _postVoid(ApiEndpoints.sendResetPasswordOtp, {'email': email});

  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) => _postVoid(ApiEndpoints.resetPassword, {
    'email': email,
    'otp': otp,
    'newPassword': newPassword,
  });

  Future<Object?> _post(String path, Map<String, Object?> data) async {
    try {
      final response = await _dio.post<Object?>(path, data: data);
      return response.data;
    } on DioException catch (error) {
      throw failureFromDio(error);
    }
  }

  Future<void> _postVoid(String path, Map<String, Object?> data) async {
    await _post(path, data);
  }
}
