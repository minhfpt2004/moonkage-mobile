final class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.content,
    required this.targetUrl,
    required this.read,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, Object?> json) => AppNotification(
    id: _string(json, 'id'),
    type: _string(json, 'type'),
    title: _string(json, 'title'),
    content: _string(json, 'content'),
    targetUrl: _string(json, 'targetUrl'),
    read: json['read'] == true,
    createdAt: _date(json['createdAt']),
  );

  final String id;
  final String type;
  final String title;
  final String content;
  final String targetUrl;
  final bool read;
  final DateTime? createdAt;
}

final class NotificationPage {
  const NotificationPage({
    required this.content,
    required this.page,
    required this.totalElements,
    required this.totalPages,
    required this.unread,
  });

  factory NotificationPage.fromJson(Map<String, Object?> json) => NotificationPage(
    content: json['content'] is List
        ? (json['content']! as List)
              .map((item) => AppNotification.fromJson(_map(item)))
              .toList(growable: false)
        : const [],
    page: _int(json['page']),
    totalElements: _int(json['totalElements']),
    totalPages: _int(json['totalPages']),
    unread: _int(json['unread']),
  );

  final List<AppNotification> content;
  final int page;
  final int totalElements;
  final int totalPages;
  final int unread;
}

final class ChatConversation {
  const ChatConversation({
    required this.id,
    required this.vendorId,
    required this.vendorName,
    required this.buyerAccountId,
    required this.buyerName,
    required this.myParty,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.unreadCount,
  });

  factory ChatConversation.fromJson(Map<String, Object?> json) => ChatConversation(
    id: _string(json, 'id'),
    vendorId: _string(json, 'vendorId'),
    vendorName: _string(json, 'vendorName'),
    buyerAccountId: _string(json, 'buyerAccountId'),
    buyerName: _string(json, 'buyerName'),
    myParty: _string(json, 'myParty'),
    lastMessage: json['lastMessage'] is Map
        ? ChatMessage.fromJson(_map(json['lastMessage']))
        : null,
    lastMessageAt: _date(json['lastMessageAt']),
    unreadCount: _int(json['unreadCount']),
  );

  final String id;
  final String vendorId;
  final String vendorName;
  final String buyerAccountId;
  final String buyerName;
  final String myParty;
  final ChatMessage? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;
}

final class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.sequence,
    required this.conversationId,
    required this.senderAccountId,
    required this.senderParty,
    required this.body,
    required this.attachmentName,
    required this.attachmentUrl,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, Object?> json) => ChatMessage(
    id: _string(json, 'id'),
    sequence: _int(json['seq']),
    conversationId: _string(json, 'conversationId'),
    senderAccountId: _string(json, 'senderAccountId'),
    senderParty: _string(json, 'senderParty'),
    body: _string(json, 'body'),
    attachmentName: _string(json, 'attachmentName'),
    attachmentUrl: _string(json, 'attachmentUrl'),
    createdAt: _date(json['createdAt']),
  );

  final String id;
  final int sequence;
  final String conversationId;
  final String senderAccountId;
  final String senderParty;
  final String body;
  final String attachmentName;
  final String attachmentUrl;
  final DateTime? createdAt;
}

final class ChatThread {
  const ChatThread({
    required this.conversationId,
    required this.myParty,
    required this.messages,
    required this.buyerReadSequence,
    required this.vendorReadSequence,
    required this.hasMore,
  });

  factory ChatThread.fromJson(Map<String, Object?> json) => ChatThread(
    conversationId: _string(json, 'conversationId'),
    myParty: _string(json, 'myParty'),
    messages: json['messages'] is List
        ? (json['messages']! as List)
              .map((item) => ChatMessage.fromJson(_map(item)))
              .toList(growable: false)
        : const [],
    buyerReadSequence: _int(json['buyerReadSeq']),
    vendorReadSequence: _int(json['vendorReadSeq']),
    hasMore: json['hasMore'] == true,
  );

  final String conversationId;
  final String myParty;
  final List<ChatMessage> messages;
  final int buyerReadSequence;
  final int vendorReadSequence;
  final bool hasMore;
}

Map<String, Object?> _map(Object? value) {
  if (value is! Map) return const {};
  return value.map((key, item) => MapEntry(key.toString(), item));
}

String _string(Map<String, Object?> json, String key) =>
    json[key] is String ? json[key]! as String : '';
int _int(Object? value) => value is num ? value.toInt() : 0;
DateTime? _date(Object? value) => value is String ? DateTime.tryParse(value)?.toLocal() : null;
