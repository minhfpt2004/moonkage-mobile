import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:moonkage_verify/core/errors/app_failure.dart';
import 'package:moonkage_verify/core/strings.dart';
import 'package:moonkage_verify/core/theme/moonkage_colors.dart';
import 'package:moonkage_verify/core/widgets/content_state.dart';
import 'package:moonkage_verify/features/communication/data/communication_api.dart';
import 'package:moonkage_verify/features/communication/domain/communication.dart';
import 'package:moonkage_verify/router.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  var _markingAll = false;

  Future<void> _markAll() async {
    if (_markingAll) return;
    setState(() => _markingAll = true);
    try {
      await ref.read(communicationApiProvider).markAllNotificationsRead();
      ref.invalidate(notificationsProvider);
    } on AppFailure catch (failure) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(Strings.failure(failure))),
        );
      }
    } finally {
      if (mounted) setState(() => _markingAll = false);
    }
  }

  Future<void> _open(AppNotification notification) async {
    if (!notification.read) {
      try {
        await ref.read(communicationApiProvider).markNotificationRead(notification.id);
        ref.invalidate(notificationsProvider);
      } on AppFailure catch (failure) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(Strings.failure(failure))),
          );
        }
        return;
      }
    }
    if (!mounted || notification.targetUrl.isEmpty) return;
    final route = _mobileRoute(notification.targetUrl);
    if (route != null) unawaited(context.push(route));
  }

  @override
  Widget build(BuildContext context) {
    final page = ref.watch(notificationsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        actions: [
          TextButton(
            onPressed: page.hasValue && page.requireValue.unread > 0 && !_markingAll
                ? _markAll
                : null,
            child: Text(_markingAll ? 'Đang đọc…' : 'Đọc tất cả'),
          ),
        ],
      ),
      body: page.when(
        loading: () => const LoadingState(message: 'Đang tải thông báo…'),
        error: (error, _) => ErrorState(
          message: error is AppFailure ? Strings.failure(error) : 'Không thể tải thông báo.',
          onRetry: () => ref.invalidate(notificationsProvider),
        ),
        data: (value) => RefreshIndicator(
          onRefresh: () => ref.refresh(notificationsProvider.future).then<void>((_) {}),
          child: value.content.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 140),
                    Icon(
                      Icons.notifications_none_rounded,
                      size: 68,
                      color: MoonkageColors.mutedInk,
                    ),
                    SizedBox(height: 14),
                    Text('Chưa có thông báo.', textAlign: TextAlign.center),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: value.content.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, index) {
                    final item = value.content[index];
                    return ListTile(
                      onTap: () => _open(item),
                      tileColor: item.read ? null : MoonkageColors.paleGold.withValues(alpha: 0.28),
                      leading: CircleAvatar(
                        backgroundColor: item.read
                            ? MoonkageColors.surfaceContainer
                            : MoonkageColors.paleGold,
                        child: Icon(_notificationIcon(item.type), color: MoonkageColors.royalRed),
                      ),
                      title: Text(
                        item.title,
                        style: TextStyle(fontWeight: item.read ? FontWeight.w600 : FontWeight.w800),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(item.content),
                          if (item.createdAt != null) ...[
                            const SizedBox(height: 5),
                            Text(
                              _formatDateTime(item.createdAt!),
                              style: const TextStyle(fontSize: 12, color: MoonkageColors.mutedInk),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}

String? _mobileRoute(String targetUrl) {
  final uri = Uri.tryParse(targetUrl);
  final path = uri?.path ?? targetUrl;
  final order = RegExp(r'/orders/([^/?]+)').firstMatch(path);
  if (order != null) return AppRoutes.order(Uri.decodeComponent(order.group(1)!));
  final quote = RegExp(r'/quote-requests/([^/?]+)').firstMatch(path);
  if (quote != null) return AppRoutes.quoteRequest(Uri.decodeComponent(quote.group(1)!));
  return null;
}

IconData _notificationIcon(String type) => switch (type) {
  'QUOTE_RECEIVED' => Icons.request_quote_outlined,
  'CHAT_MESSAGE' => Icons.chat_bubble_outline_rounded,
  'ORDER_STATUS' => Icons.local_shipping_outlined,
  _ => Icons.notifications_none_rounded,
};

String _formatDateTime(DateTime value) {
  String two(int number) => number.toString().padLeft(2, '0');
  return '${two(value.hour)}:${two(value.minute)} ${two(value.day)}/${two(value.month)}/${value.year}';
}
