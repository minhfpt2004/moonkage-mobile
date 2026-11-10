import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moonkage_verify/core/errors/app_failure.dart';
import 'package:moonkage_verify/core/platform/external_url_launcher.dart';
import 'package:moonkage_verify/core/strings.dart';
import 'package:moonkage_verify/core/theme/moonkage_colors.dart';
import 'package:moonkage_verify/core/widgets/content_state.dart';
import 'package:moonkage_verify/features/communication/data/communication_api.dart';
import 'package:moonkage_verify/features/communication/domain/communication.dart';

class ChatThreadScreen extends ConsumerStatefulWidget {
  const ChatThreadScreen({required this.conversationId, required this.vendorName, super.key});

  final String conversationId;
  final String vendorName;

  @override
  ConsumerState<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends ConsumerState<ChatThreadScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _pollTimer;
  DateTime? _lastTypingSentAt;
  var _sending = false;
  var _lastMarkedSequence = 0;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_onTyping);
    _pollTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => ref.invalidate(chatThreadProvider(widget.conversationId)),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _messageController
      ..removeListener(_onTyping)
      ..dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTyping() {
    if (_messageController.text.trim().isEmpty) return;
    final now = DateTime.now();
    if (_lastTypingSentAt != null && now.difference(_lastTypingSentAt!).inSeconds < 3) return;
    _lastTypingSentAt = now;
    unawaited(ref.read(communicationApiProvider).typing(widget.conversationId).catchError((_) {}));
  }

  Future<void> _send() async {
    final body = _messageController.text.trim();
    if (body.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await ref.read(communicationApiProvider).sendMessage(widget.conversationId, body);
      _messageController.clear();
      ref
        ..invalidate(chatThreadProvider(widget.conversationId))
        ..invalidate(conversationsProvider);
    } on AppFailure catch (failure) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(Strings.failure(failure))),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _afterLoaded(ChatThread thread) {
    if (thread.messages.isEmpty) return;
    final newestSequence = thread.messages.last.sequence;
    if (newestSequence > _lastMarkedSequence) {
      _lastMarkedSequence = newestSequence;
      unawaited(
        ref
            .read(communicationApiProvider)
            .markConversationRead(widget.conversationId, newestSequence)
            .then((_) => ref.invalidate(conversationsProvider))
            .catchError((_) {}),
      );
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final thread = ref.watch(chatThreadProvider(widget.conversationId));
    return Scaffold(
      appBar: AppBar(title: Text(widget.vendorName.isEmpty ? 'Cửa hàng' : widget.vendorName)),
      body: Column(
        children: [
          Expanded(
            child: thread.when(
              loading: () => const LoadingState(message: 'Đang tải tin nhắn…'),
              error: (error, _) => ErrorState(
                message: error is AppFailure ? Strings.failure(error) : 'Không thể tải hội thoại.',
                onRetry: () => ref.invalidate(chatThreadProvider(widget.conversationId)),
              ),
              data: (value) {
                _afterLoaded(value);
                if (value.messages.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        'Hãy gửi lời chào hoặc câu hỏi đầu tiên cho cửa hàng.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),
                  itemCount: value.messages.length,
                  itemBuilder: (_, index) => _MessageBubble(
                    message: value.messages[index],
                    mine: value.messages[index].senderParty == value.myParty,
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Material(
              elevation: 10,
              color: Theme.of(context).colorScheme.surface,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 9, 8, 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        enabled: !_sending,
                        minLines: 1,
                        maxLines: 5,
                        maxLength: 2000,
                        buildCounter: (
                          _, {
                          required currentLength,
                          required isFocused,
                          maxLength,
                        }) => null,
                        decoration: const InputDecoration(
                          hintText: 'Nhập tin nhắn…',
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton.filled(
                      tooltip: 'Gửi',
                      onPressed: _sending ? null : _send,
                      icon: _sending
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send_rounded),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends ConsumerWidget {
  const _MessageBubble({required this.message, required this.mine});

  final ChatMessage message;
  final bool mine;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Align(
    alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
    child: Container(
      constraints: const BoxConstraints(maxWidth: 310),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
      decoration: BoxDecoration(
        color: mine ? MoonkageColors.royalRed : MoonkageColors.surfaceContainer,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(mine ? 18 : 4),
          bottomRight: Radius.circular(mine ? 4 : 18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.body.isNotEmpty)
            Text(message.body, style: TextStyle(color: mine ? Colors.white : MoonkageColors.ink)),
          if (message.attachmentUrl.isNotEmpty)
            TextButton.icon(
              onPressed: () => ref.read(externalUrlLauncherProvider).open(message.attachmentUrl),
              icon: const Icon(Icons.attach_file_rounded),
              label: Text(message.attachmentName.isEmpty ? 'Tệp đính kèm' : message.attachmentName),
            ),
          if (message.createdAt != null) ...[
            const SizedBox(height: 4),
            Text(
              _messageTime(message.createdAt!),
              style: TextStyle(
                fontSize: 10,
                color: mine ? Colors.white70 : MoonkageColors.mutedInk,
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

String _messageTime(DateTime value) =>
    '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
