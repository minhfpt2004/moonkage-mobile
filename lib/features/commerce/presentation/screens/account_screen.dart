import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:moonkage_verify/core/auth/session_notifier.dart';
import 'package:moonkage_verify/core/theme/moonkage_colors.dart';
import 'package:moonkage_verify/features/account/data/account_api.dart';
import 'package:moonkage_verify/router.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final asyncProfile = ref.watch(accountProfileProvider);
    final profile = asyncProfile.hasValue ? asyncProfile.requireValue : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Tài khoản')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => context.push(AppRoutes.profile),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 28,
                      backgroundColor: MoonkageColors.paleGold,
                      foregroundColor: MoonkageColors.imperialRed,
                      child: Icon(Icons.person_rounded, size: 30),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile?.fullName ?? session?.fullName ?? 'Khách hàng MoonKage',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            profile?.email.isNotEmpty == true
                                ? profile!.email
                                : session?.email.isNotEmpty == true
                                ? session!.email
                                : 'Thành viên Nguyệt Viên',
                            style: const TextStyle(color: MoonkageColors.mutedInk),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.edit_outlined, color: MoonkageColors.mutedInk),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Tiện ích tài khoản', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                _AccountTile(
                  icon: Icons.manage_accounts_outlined,
                  title: 'Hồ sơ cá nhân',
                  subtitle: 'Tên hiển thị và thông tin tài khoản',
                  onTap: () => context.push(AppRoutes.profile),
                ),
                const Divider(height: 1, indent: 64),
                _AccountTile(
                  icon: Icons.verified_user_outlined,
                  title: 'Xác minh danh tính NFC',
                  subtitle: 'Quét QR và chạm thẻ căn cước',
                  onTap: () => context.push(AppRoutes.verification),
                ),
                const Divider(height: 1, indent: 64),
                _AccountTile(
                  icon: Icons.location_on_outlined,
                  title: 'Sổ địa chỉ',
                  subtitle: 'Quản lý địa chỉ nhận hàng',
                  onTap: () => context.push(AppRoutes.addresses),
                ),
                const Divider(height: 1, indent: 64),
                _AccountTile(
                  icon: Icons.request_quote_outlined,
                  title: 'Yêu cầu báo giá B2B',
                  subtitle: 'Đơn số lượng lớn và bao bì tùy chỉnh',
                  onTap: () => context.push(AppRoutes.quoteRequests),
                ),
                const Divider(height: 1, indent: 64),
                _AccountTile(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: 'Tin nhắn cửa hàng',
                  subtitle: 'Trao đổi trực tiếp với các shop',
                  onTap: () => context.push(AppRoutes.conversations),
                ),
                const Divider(height: 1, indent: 64),
                _AccountTile(
                  icon: Icons.notifications_none_rounded,
                  title: 'Thông báo',
                  subtitle: 'Đơn hàng, báo giá và tin nhắn mới',
                  onTap: () => context.push(AppRoutes.notifications),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => ref.read(sessionProvider.notifier).signOut(),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    onTap: onTap,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    leading: Icon(icon, color: MoonkageColors.royalRed),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
    subtitle: Text(subtitle),
    trailing: const Icon(Icons.chevron_right_rounded),
  );
}
