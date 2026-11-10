final class RegisterResult {
  const RegisterResult({
    required this.id,
    required this.email,
    required this.phoneNumber,
    required this.verified,
    required this.otpSent,
  });

  final String id;
  final String email;
  final String phoneNumber;
  final bool verified;
  final bool otpSent;
}
