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

class ConversationsScreen extends ConsumerWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversations = ref.watch(conversationsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Tin nhắn cửa hàng')),
      body: conversations.when(
        loading: () => const LoadingState(message: 'Đang tải hội thoại…'),
        error: (error, _) => ErrorState(
          message: error is AppFailure ? Strings.failure(error) : 'Không thể tải tin nhắn.',
          onRetry: () => ref.invalidate(conversationsProvider),
        ),
        data: (items) => RefreshIndicator(
          onRefresh: () => ref.refresh(conversationsProvider.future).then<void>((_) {}),
          child: items.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 140),
                    Icon(Icons.forum_outlined, size: 68, color: MoonkageColors.mutedInk),
                    SizedBox(height: 14),
                    Text(
                      'Chưa có hội thoại. Bạn có thể nhắn shop từ trang sản phẩm.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const Divider(height: 1, indent: 76),
                  itemBuilder: (_, index) => _ConversationTile(conversation: items[index]),
                ),
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.conversation});

  final ChatConversation conversation;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    onTap: () => context.push(
      '${AppRoutes.conversation(conversation.id)}?name=${Uri.encodeQueryComponent(conversation.vendorName)}',
    ),
    leading: const CircleAvatar(
      backgroundColor: MoonkageColors.paleGold,
      foregroundColor: MoonkageColors.royalRed,
      child: Icon(Icons.storefront_outlined),
    ),
    title: Text(
      conversation.vendorName,
      style: TextStyle(
        fontWeight: conversation.unreadCount > 0 ? FontWeight.w800 : FontWeight.w600,
      ),
    ),
    subtitle: Text(
      conversation.lastMessage?.body.isNotEmpty == true
          ? conversation.lastMessage!.body
          : 'Bắt đầu trao đổi với cửa hàng',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    ),
    trailing: conversation.unreadCount > 0
        ? Badge(label: Text('${conversation.unreadCount}'))
        : conversation.lastMessageAt == null
        ? null
        : Text(
            _shortTime(conversation.lastMessageAt!),
            style: const TextStyle(fontSize: 12, color: MoonkageColors.mutedInk),
          ),
  );
}

String _shortTime(DateTime value) =>
    '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
