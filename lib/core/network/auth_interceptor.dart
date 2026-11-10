import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moonkage_verify/core/auth/auth_session.dart';
import 'package:moonkage_verify/core/auth/refresh_token_client.dart';
import 'package:moonkage_verify/core/auth/session_notifier.dart';

/// Gắn Bearer token, refresh một lần khi gặp 401 rồi phát lại request ban đầu.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._ref, this._dio);

  static const _retriedKey = 'authRetried';

  final Ref _ref;
  final Dio _dio;
  Future<AuthSession?>? _refreshing;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _ref.read(sessionProvider)?.token;
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final request = err.requestOptions;
    final sentToken = request.headers.containsKey('Authorization');
    if (!sentToken || err.response?.statusCode != 401) {
      handler.next(err);
      return;
    }

    final current = _ref.read(sessionProvider);
    if (current == null || current.refreshToken.isEmpty || request.extra[_retriedKey] == true) {
      _ref.read(sessionProvider.notifier).signOut();
      handler.next(err);
      return;
    }

    try {
      final refreshed = await _refreshOnce(current);
      if (refreshed == null) {
        _ref.read(sessionProvider.notifier).signOut();
        handler.next(err);
        return;
      }
      _ref.read(sessionProvider.notifier).replaceSession(refreshed);
      request
        ..headers['Authorization'] = 'Bearer ${refreshed.token}'
        ..extra[_retriedKey] = true;
      final response = await _dio.fetch<Object?>(request);
      handler.resolve(response);
    } on Object catch (_) {
      _ref.read(sessionProvider.notifier).signOut();
      handler.next(err);
    }
  }

  Future<AuthSession?> _refreshOnce(AuthSession current) {
    final active = _refreshing;
    if (active != null) return active;
    final future = _refresh(current);
    _refreshing = future;
    return future.whenComplete(() {
      if (identical(_refreshing, future)) _refreshing = null;
    });
  }

  Future<AuthSession?> _refresh(AuthSession current) async {
    final fresh = await _ref.read(refreshTokenClientProvider).refresh(current.refreshToken);
    final active = _ref.read(sessionProvider);
    if (active == null || active.refreshToken != current.refreshToken) return null;
    return fresh.copyWith(
      refreshToken: fresh.refreshToken.isEmpty ? current.refreshToken : fresh.refreshToken,
      accountId: fresh.accountId.isEmpty ? current.accountId : fresh.accountId,
      email: fresh.email.isEmpty ? current.email : fresh.email,
      phoneNumber: fresh.phoneNumber.isEmpty ? current.phoneNumber : fresh.phoneNumber,
      fullName: fresh.fullName.isEmpty ? current.fullName : fresh.fullName,
      role: fresh.role.isEmpty ? current.role : fresh.role,
      rememberMe: current.rememberMe,
    );
  }
}
