import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:moonkage_verify/core/errors/app_failure.dart';
import 'package:moonkage_verify/core/strings.dart';
import 'package:moonkage_verify/core/theme/moonkage_colors.dart';
import 'package:moonkage_verify/features/auth/data/auth_api.dart';
import 'package:moonkage_verify/features/auth/presentation/widgets/auth_form_support.dart';
import 'package:moonkage_verify/router.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _otp = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _otpSent = false;
  bool _completed = false;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _otp.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (AuthValidators.email(_email.text) != null || _submitting) {
      _formKey.currentState?.validate();
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref.read(authApiProvider).sendResetPasswordOtp(_email.text.trim());
      if (mounted) setState(() => _otpSent = true);
    } on AppFailure catch (failure) {
      if (mounted) setState(() => _error = Strings.failure(failure));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _reset() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false) || _submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref
          .read(authApiProvider)
          .resetPassword(
            email: _email.text.trim(),
            otp: _otp.text,
            newPassword: _password.text,
          );
      if (mounted) setState(() => _completed = true);
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
      child: _completed
          ? _ResetSuccess(onLogin: () => context.go(AppRoutes.login))
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                children: [
                  AuthBrandHeader(
                    title: 'Đặt lại mật khẩu',
                    subtitle: _otpSent
                        ? 'Nhập OTP và chọn mật khẩu mới cho tài khoản.'
                        : 'Nhập email để nhận mã OTP đặt lại mật khẩu.',
                  ),
                  const SizedBox(height: 28),
                  TextFormField(
                    controller: _email,
                    enabled: !_submitting && !_otpSent,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: AuthValidators.email,
                  ),
                  if (_otpSent) ...[
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _otp,
                      enabled: !_submitting,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(labelText: 'Mã OTP'),
                      validator: AuthValidators.required,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _password,
                      enabled: !_submitting,
                      obscureText: true,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(labelText: 'Mật khẩu mới'),
                      validator: AuthValidators.password,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _confirmPassword,
                      enabled: !_submitting,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(labelText: 'Nhập lại mật khẩu mới'),
                      validator: (value) {
                        final requiredError = AuthValidators.required(value);
                        if (requiredError != null) return requiredError;
                        return value == _password.text ? null : 'Mật khẩu nhập lại không khớp.';
                      },
                      onFieldSubmitted: (_) => _reset(),
                    ),
                  ],
                  AuthFailureText(message: _error),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _submitting ? null : (_otpSent ? _reset : _sendOtp),
                    child: _submitting
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_otpSent ? 'Đổi mật khẩu' : 'Gửi mã OTP'),
                  ),
                  if (_otpSent)
                    TextButton(
                      onPressed: _submitting ? null : _sendOtp,
                      child: const Text('Gửi lại mã OTP'),
                    ),
                ],
              ),
            ),
    ),
  );
}

class _ResetSuccess extends StatelessWidget {
  const _ResetSuccess({required this.onLogin});

  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_reset_rounded, size: 72, color: MoonkageColors.jade),
          const SizedBox(height: 20),
          Text('Đã đổi mật khẩu', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          const Text('Hãy đăng nhập lại bằng mật khẩu mới.', textAlign: TextAlign.center),
          const SizedBox(height: 24),
          FilledButton(onPressed: onLogin, child: const Text('Đăng nhập')),
        ],
      ),
    ),
  );
}
