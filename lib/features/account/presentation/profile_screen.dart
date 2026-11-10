import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moonkage_verify/core/auth/session_notifier.dart';
import 'package:moonkage_verify/core/errors/app_failure.dart';
import 'package:moonkage_verify/core/strings.dart';
import 'package:moonkage_verify/core/widgets/content_state.dart';
import 'package:moonkage_verify/features/account/data/account_api.dart';
import 'package:moonkage_verify/features/account/domain/account_profile.dart';
import 'package:moonkage_verify/features/auth/presentation/widgets/auth_form_support.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  AccountProfile? _profile;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _fullName.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false) || _saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final profile = await ref.read(accountApiProvider).updateFullName(_fullName.text.trim());
      if (!mounted) return;
      ref.read(sessionProvider.notifier).updateFullName(profile.fullName);
      ref.invalidate(accountProfileProvider);
      setState(() => _profile = profile);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã cập nhật hồ sơ.')),
      );
    } on AppFailure catch (failure) {
      if (mounted) setState(() => _error = Strings.failure(failure));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncProfile = ref.watch(accountProfileProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Hồ sơ cá nhân')),
      body: asyncProfile.when(
        loading: () => const LoadingState(message: 'Đang tải hồ sơ…'),
        error: (error, _) => ErrorState(
          message: error is AppFailure ? Strings.failure(error) : 'Không thể tải hồ sơ.',
          onRetry: () => ref.invalidate(accountProfileProvider),
        ),
        data: (profile) {
          if (_profile?.accountId != profile.accountId) {
            _profile = profile;
            _fullName.text = profile.fullName;
          }
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                TextFormField(
                  controller: _fullName,
                  enabled: !_saving,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'Họ và tên hiển thị',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  validator: (value) {
                    final requiredError = AuthValidators.required(value);
                    if (requiredError != null) return requiredError;
                    return value!.trim().length <= 100
                        ? null
                        : 'Họ và tên không được vượt quá 100 ký tự.';
                  },
                  onFieldSubmitted: (_) => _save(),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ],
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: const Text('Lưu thay đổi'),
                ),
                const SizedBox(height: 28),
                Text('Thông tin tài khoản', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                Card(
                  child: Column(
                    children: [
                      _ReadOnlyInfo(
                        icon: Icons.email_outlined,
                        label: 'Email',
                        value: profile.email,
                      ),
                      const Divider(height: 1, indent: 64),
                      _ReadOnlyInfo(
                        icon: Icons.phone_outlined,
                        label: 'Số điện thoại',
                        value: profile.displayPhone.isEmpty
                            ? 'Chưa cập nhật'
                            : profile.displayPhone,
                      ),
                      const Divider(height: 1, indent: 64),
                      _ReadOnlyInfo(
                        icon: Icons.badge_outlined,
                        label: 'Loại tài khoản',
                        value: profile.role == 'MEMBER' ? 'Thành viên' : profile.role,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ReadOnlyInfo extends StatelessWidget {
  const _ReadOnlyInfo({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon),
    title: Text(label),
    subtitle: Text(value),
  );
}
