/// Phiên đăng nhập người dùng. Giữ trong bộ nhớ và có thể lưu an toàn qua
/// [TokenStorage] nếu người dùng bật Ghi nhớ đăng nhập.
final class AuthSession {
  const AuthSession({
    required this.token,
    required this.fullName,
    this.refreshToken = '',
    this.accountId = '',
    this.email = '',
    this.phoneNumber = '',
    this.role = '',
    this.rememberMe = false,
  });

  /// Access token (JWT) của identity-service.
  final String token;
  final String fullName;
  final String refreshToken;
  final String accountId;
  final String email;
  final String phoneNumber;
  final String role;

  /// Chỉ phiên có bật ghi nhớ mới được ghi lại sau khi access token được làm mới.
  final bool rememberMe;

  AuthSession copyWith({
    String? token,
    String? refreshToken,
    String? accountId,
    String? email,
    String? phoneNumber,
    String? fullName,
    String? role,
    bool? rememberMe,
  }) => AuthSession(
    token: token ?? this.token,
    refreshToken: refreshToken ?? this.refreshToken,
    accountId: accountId ?? this.accountId,
    email: email ?? this.email,
    phoneNumber: phoneNumber ?? this.phoneNumber,
    fullName: fullName ?? this.fullName,
    role: role ?? this.role,
    rememberMe: rememberMe ?? this.rememberMe,
  );
}
