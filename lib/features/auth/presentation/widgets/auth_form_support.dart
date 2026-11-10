import 'package:flutter/material.dart';
import 'package:moonkage_verify/core/strings.dart';
import 'package:moonkage_verify/core/theme/moonkage_colors.dart';

abstract final class AuthValidators {
  static final _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  static final _phone = RegExp(r'^(\+?84|0)[35789]\d{8}$');

  static String? required(String? value) =>
      value == null || value.trim().isEmpty ? Strings.requiredField : null;

  static String? email(String? value) {
    final requiredError = required(value);
    if (requiredError != null) return requiredError;
    return _email.hasMatch(value!.trim()) ? null : 'Email không đúng định dạng.';
  }

  static String? phone(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    return _phone.hasMatch(text) ? null : 'Số điện thoại Việt Nam không hợp lệ.';
  }

  static String? password(String? value) {
    final requiredError = required(value);
    if (requiredError != null) return requiredError;
    final length = value!.length;
    return length >= 8 && length <= 72 ? null : 'Mật khẩu phải có từ 8 đến 72 ký tự.';
  }

  const AuthValidators._();
}

class AuthBrandHeader extends StatelessWidget {
  const AuthBrandHeader({required this.title, required this.subtitle, super.key});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Icon(Icons.brightness_2_rounded, size: 42, color: MoonkageColors.gold),
      const SizedBox(height: 16),
      Text(title, style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 8),
      Text(
        subtitle,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: MoonkageColors.mutedInk),
      ),
    ],
  );
}

class AuthFailureText extends StatelessWidget {
  const AuthFailureText({required this.message, super.key});

  final String? message;

  @override
  Widget build(BuildContext context) {
    if (message == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Text(message!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
    );
  }
}
