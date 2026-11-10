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

class VerifyAccountScreen extends ConsumerStatefulWidget {
  const VerifyAccountScreen({required this.initialEmail, required this.otpSent, super.key});

  final String initialEmail;
  final bool otpSent;

  @override
  ConsumerState<VerifyAccountScreen> createState() => _VerifyAccountScreenState();
}

class _VerifyAccountScreenState extends ConsumerState<VerifyAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _email;
  final _otp = TextEditingController();
  bool _submitting = false;
  bool _verified = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _email = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _email.dispose();
    _otp.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false) || _submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref.read(authApiProvider).verifyAccount(email: _email.text.trim(), otp: _otp.text);
      if (mounted) setState(() => _verified = true);
    } on AppFailure catch (failure) {
      if (mounted) setState(() => _error = Strings.failure(failure));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _resend() async {
    final emailError = AuthValidators.email(_email.text);
    if (emailError != null || _submitting) {
      _formKey.currentState?.validate();
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref.read(authApiProvider).sendVerifyAccountOtp(_email.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mã OTP đã được gửi lại. Vui lòng kiểm tra email.')),
        );
      }
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
      child: _verified
          ? _Success(onLogin: () => context.go(AppRoutes.login))
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                children: [
                  AuthBrandHeader(
                    title: 'Xác thực email',
                    subtitle: widget.otpSent
                        ? 'Nhập mã OTP đã gửi tới email của bạn.'
                        : 'Chưa gửi được OTP. Hãy yêu cầu gửi lại mã bên dưới.',
                  ),
                  const SizedBox(height: 28),
                  TextFormField(
                    controller: _email,
                    enabled: !_submitting,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: AuthValidators.email,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _otp,
                    enabled: !_submitting,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(labelText: 'Mã OTP'),
                    validator: AuthValidators.required,
                    onFieldSubmitted: (_) => _verify(),
                  ),
                  AuthFailureText(message: _error),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _submitting ? null : _verify,
                    child: _submitting
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Xác thực tài khoản'),
                  ),
                  TextButton(
                    onPressed: _submitting ? null : _resend,
                    child: const Text('Gửi lại mã OTP'),
                  ),
                ],
              ),
            ),
    ),
  );
}

class _Success extends StatelessWidget {
  const _Success({required this.onLogin});

  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified_rounded, size: 72, color: MoonkageColors.jade),
          const SizedBox(height: 20),
          Text('Email đã được xác thực', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          const Text('Bạn có thể đăng nhập và bắt đầu mua sắm.', textAlign: TextAlign.center),
          const SizedBox(height: 24),
          FilledButton(onPressed: onLogin, child: const Text('Đăng nhập')),
        ],
      ),
    ),
  );
}
