import 'package:moonkage_verify/core/auth/auth_session.dart';
import 'package:moonkage_verify/core/errors/app_failure.dart';
import 'package:moonkage_verify/core/network/api_payload.dart';

AuthSession parseAuthSession(Object? body, {String fallbackName = ''}) {
  final map = payloadMap(body);
  final token = map?['token'] ?? map?['accessToken'];
  if (token is! String || token.trim().isEmpty) {
    throw const InvalidResponseFailure();
  }
  String value(String key) => map?[key] is String ? (map![key]! as String).trim() : '';
  final fullName = value('fullName').isNotEmpty
      ? value('fullName')
      : value('name').isNotEmpty
      ? value('name')
      : fallbackName;
  return AuthSession(
    token: token.trim(),
    refreshToken: value('refreshToken'),
    accountId: value('accountId'),
    email: value('email'),
    phoneNumber: value('phoneNumber'),
    fullName: fullName,
    role: value('role'),
  );
}

Map<String, Object?>? payloadMap(Object? body) {
  final payload = apiPayload(body);
  if (payload is Map<String, Object?>) return payload;
  if (payload is Map) return payload.map((key, value) => MapEntry(key.toString(), value));
  return null;
}
