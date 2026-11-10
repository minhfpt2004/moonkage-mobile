import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:moonkage_verify/core/errors/app_failure.dart';
import 'package:moonkage_verify/core/strings.dart';
import 'package:moonkage_verify/features/auth/presentation/login_notifier.dart';
import 'package:moonkage_verify/features/auth/presentation/widgets/auth_form_support.dart';
import 'package:moonkage_verify/router.dart';

/// Đăng nhập bằng tài khoản Moonkage (email hoặc số điện thoại).
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = true;

  @override
  void initState() {
    super.initState();
    _username.addListener(_onTextChanged);
    _password.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    ref.read(loginProvider.notifier).clearError();
  }

  @override
  void dispose() {
    _username.removeListener(_onTextChanged);
    _password.removeListener(_onTextChanged);
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    unawaited(
      ref
          .read(loginProvider.notifier)
          .login(
            username: _username.text,
            password: _password.text,
            rememberMe: _rememberMe,
          ),
    );
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? Strings.requiredField : null;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(loginProvider);
    final failure = state.failure;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text(Strings.loginTitle)),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const AuthBrandHeader(
                title: 'Chào mừng trở lại',
                subtitle: 'Đăng nhập để tiếp tục hành trình thưởng nguyệt cùng MoonKage.',
              ),
              const SizedBox(height: 28),
              TextFormField(
                controller: _username,
                enabled: !state.submitting,
                decoration: const InputDecoration(labelText: Strings.usernameLabel),
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                textInputAction: TextInputAction.next,
                validator: _required,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _password,
                enabled: !state.submitting,
                decoration: InputDecoration(
                  labelText: Strings.passwordLabel,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    tooltip: _obscurePassword ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
                  ),
                ),
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                validator: _required,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: Checkbox(
                      value: _rememberMe,
                      onChanged: state.submitting
                          ? null
                          : (value) => setState(() => _rememberMe = value ?? true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: state.submitting
                        ? null
                        : () => setState(() => _rememberMe = !_rememberMe),
                    child: const Text(Strings.rememberMe),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: state.submitting ? null : () => context.go(AppRoutes.resetPassword),
                    child: const Text('Quên mật khẩu?'),
                  ),
                ],
              ),
              if (failure != null) ...[
                const SizedBox(height: 16),
                Text(
                  failure is UnauthorizedFailure
                      ? Strings.invalidCredentials
                      : Strings.failure(failure),
                  style: TextStyle(color: colors.error),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: state.submitting ? null : _submit,
                child: state.submitting
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(Strings.login),
              ),
              TextButton(
                onPressed: state.submitting ? null : () => context.go(AppRoutes.register),
                child: const Text('Chưa có tài khoản? Đăng ký'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
