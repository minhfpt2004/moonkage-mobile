import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moonkage_verify/core/auth/auth_session.dart';
import 'package:moonkage_verify/core/auth/auth_session_parser.dart';
import 'package:moonkage_verify/core/config/app_config.dart';
import 'package:moonkage_verify/core/network/api_endpoints.dart';

final refreshTokenClientProvider = Provider<RefreshTokenClient>((ref) {
  final client = RefreshTokenClient(
    Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        contentType: Headers.jsonContentType,
        responseType: ResponseType.json,
      ),
    ),
  );
  ref.onDispose(client.close);
  return client;
});

/// Client riêng không gắn AuthInterceptor, tránh vòng lặp 401 khi refresh thất bại.
class RefreshTokenClient {
  RefreshTokenClient(this._dio);

  final Dio _dio;

  Future<AuthSession> refresh(String refreshToken) async {
    final response = await _dio.post<Object?>(
      ApiEndpoints.refreshToken,
      data: {'refreshToken': refreshToken},
    );
    return parseAuthSession(response.data);
  }

  void close() => _dio.close();
}
