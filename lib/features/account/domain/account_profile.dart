final class AccountProfile {
  const AccountProfile({
    required this.accountId,
    required this.email,
    required this.phoneNumber,
    required this.fullName,
    required this.role,
  });

  final String accountId;
  final String email;
  final String phoneNumber;
  final String fullName;
  final String role;

  String get displayPhone {
    final value = phoneNumber.trim();
    return RegExp(r'^[35789]\d{8}$').hasMatch(value) ? '0$value' : value;
  }

  factory AccountProfile.fromJson(Map<String, Object?> json) => AccountProfile(
    accountId: json['accountId'] is String ? json['accountId']! as String : '',
    email: json['email'] is String ? json['email']! as String : '',
    phoneNumber: json['phoneNumber'] is String ? json['phoneNumber']! as String : '',
    fullName: json['fullName'] is String ? json['fullName']! as String : '',
    role: json['role'] is String ? json['role']! as String : '',
  );
}
