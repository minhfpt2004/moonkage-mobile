import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:moonkage_verify/core/auth/auth_session.dart';

abstract interface class TokenStorage {
  Future<void> saveSession({required String token, required String fullName});
  Future<AuthSession?> readSession();
  Future<void> clearSession();
}

/// Khả năng lưu đầy đủ phiên mới. Interface riêng giữ tương thích với các adapter cũ.
abstract interface class FullSessionStorage implements TokenStorage {
  Future<void> saveFullSession(AuthSession session);
}

class SecureTokenStorage implements FullSessionStorage {
  const SecureTokenStorage(this._storage);

  final FlutterSecureStorage _storage;

  static const _tokenKey = 'auth_token';
  static const _refreshTokenKey = 'auth_refresh_token';
  static const _accountIdKey = 'auth_account_id';
  static const _emailKey = 'auth_email';
  static const _phoneKey = 'auth_phone';
  static const _fullNameKey = 'auth_full_name';
  static const _roleKey = 'auth_role';

  @override
  Future<void> saveSession({required String token, required String fullName}) async {
    await saveFullSession(AuthSession(token: token, fullName: fullName, rememberMe: true));
  }

  @override
  Future<void> saveFullSession(AuthSession session) async {
    try {
      await Future.wait([
        _storage.write(key: _tokenKey, value: session.token),
        _storage.write(key: _refreshTokenKey, value: session.refreshToken),
        _storage.write(key: _accountIdKey, value: session.accountId),
        _storage.write(key: _emailKey, value: session.email),
        _storage.write(key: _phoneKey, value: session.phoneNumber),
        _storage.write(key: _fullNameKey, value: session.fullName),
        _storage.write(key: _roleKey, value: session.role),
      ]);
    } on Object catch (_) {}
  }

  @override
  Future<AuthSession?> readSession() async {
    try {
      final token = await _storage.read(key: _tokenKey);
      if (token == null || token.trim().isEmpty) return null;
      final values = await Future.wait([
        _storage.read(key: _refreshTokenKey),
        _storage.read(key: _accountIdKey),
        _storage.read(key: _emailKey),
        _storage.read(key: _phoneKey),
        _storage.read(key: _fullNameKey),
        _storage.read(key: _roleKey),
      ]);
      return AuthSession(
        token: token,
        refreshToken: values[0] ?? '',
        accountId: values[1] ?? '',
        email: values[2] ?? '',
        phoneNumber: values[3] ?? '',
        fullName: values[4] ?? '',
        role: values[5] ?? '',
        rememberMe: true,
      );
    } on Object catch (_) {
      return null;
    }
  }

  @override
  Future<void> clearSession() async {
    try {
      await Future.wait([
        _storage.delete(key: _tokenKey),
        _storage.delete(key: _refreshTokenKey),
        _storage.delete(key: _accountIdKey),
        _storage.delete(key: _emailKey),
        _storage.delete(key: _phoneKey),
        _storage.delete(key: _fullNameKey),
        _storage.delete(key: _roleKey),
      ]);
    } on Object catch (_) {}
  }
}

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return const SecureTokenStorage(
    FlutterSecureStorage(
      aOptions: AndroidOptions.defaultOptions,
    ),
  );
});
