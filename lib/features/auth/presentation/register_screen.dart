import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:moonkage_verify/core/errors/app_failure.dart';
import 'package:moonkage_verify/core/strings.dart';
import 'package:moonkage_verify/features/auth/data/auth_api.dart';
import 'package:moonkage_verify/features/auth/presentation/widgets/auth_form_support.dart';
import 'package:moonkage_verify/router.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _submitting = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _fullName.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false) || _submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final result = await ref
          .read(authApiProvider)
          .register(
            email: _email.text.trim(),
            phoneNumber: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
            fullName: _fullName.text.trim(),
            password: _password.text,
          );
      if (!mounted) return;
      context.go(
        Uri(
          path: AppRoutes.verifyAccount,
          queryParameters: {'email': result.email, 'sent': result.otpSent ? '1' : '0'},
        ).toString(),
      );
    } on AppFailure catch (failure) {
      if (mounted) setState(() => _error = Strings.failure(failure));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(),
    body: SafeArea(
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          children: [
            const AuthBrandHeader(
              title: 'Tạo tài khoản',
              subtitle: 'Gia nhập Nguyệt Viên để lưu giỏ hàng và theo dõi đơn bánh.',
            ),
            const SizedBox(height: 28),
            TextFormField(
              controller: _fullName,
              enabled: !_submitting,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Họ và tên'),
              validator: AuthValidators.required,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _email,
              enabled: !_submitting,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autocorrect: false,
              decoration: const InputDecoration(labelText: 'Email'),
              validator: AuthValidators.email,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _phone,
              enabled: !_submitting,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Số điện thoại (không bắt buộc)'),
              validator: AuthValidators.phone,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _password,
              enabled: !_submitting,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Mật khẩu',
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  ),
                ),
              ),
              validator: AuthValidators.password,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _confirmPassword,
              enabled: !_submitting,
              obscureText: true,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              decoration: const InputDecoration(labelText: 'Nhập lại mật khẩu'),
              validator: (value) {
                final requiredError = AuthValidators.required(value);
                if (requiredError != null) return requiredError;
                return value == _password.text ? null : 'Mật khẩu nhập lại không khớp.';
              },
            ),
            AuthFailureText(message: _error),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Đăng ký'),
            ),
            TextButton(
              onPressed: _submitting ? null : () => context.go(AppRoutes.login),
              child: const Text('Đã có tài khoản? Đăng nhập'),
            ),
          ],
        ),
      ),
    ),
  );
}
