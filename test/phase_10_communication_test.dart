import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moonkage_verify/core/network/api_endpoints.dart';
import 'package:moonkage_verify/features/communication/data/communication_api.dart';

import 'helpers/fake_http_adapter.dart';

void main() {
  test('danh sách thông báo parse phân trang và số chưa đọc', () async {
    final adapter = FakeHttpAdapter(
      body: {
        'data': {
          'content': [
            {
              'id': 'notification-1',
              'type': 'ORDER_STATUS',
              'title': 'Đơn đang giao',
              'content': 'Đơn hàng đang trên đường giao đến bạn.',
              'targetUrl': '/orders/order-1',
              'read': false,
              'createdAt': '2026-11-10T09:00:00Z',
            },
          ],
          'page': 0,
          'size': 50,
          'totalElements': 1,
          'totalPages': 1,
          'unread': 1,
        },
      },
    );
    final dio = Dio(BaseOptions(baseUrl: 'http://mock'))..httpClientAdapter = adapter;

    final page = await CommunicationApi(dio).notifications();

    expect(adapter.lastRequest?.path, ApiEndpoints.notifications);
    expect(adapter.lastRequest?.queryParameters, {'page': 0, 'size': 50});
    expect(page.unread, 1);
    expect(page.content.single.type, 'ORDER_STATUS');
  });

  test('bắt đầu hội thoại gửi đúng vendorId', () async {
    final adapter = FakeHttpAdapter(body: {'data': _conversationJson()});
    final dio = Dio(BaseOptions(baseUrl: 'http://mock'))..httpClientAdapter = adapter;

    final conversation = await CommunicationApi(dio).startConversation('vendor-1');

    expect(adapter.lastRequest?.method, 'POST');
    expect(adapter.lastRequest?.path, ApiEndpoints.conversations);
    expect(adapter.lastRequest?.data, {'vendorId': 'vendor-1'});
    expect(conversation.id, 'conversation-1');
  });

  test('gửi tin nhắn đúng endpoint và body đã trim', () async {
    final adapter = FakeHttpAdapter(
      body: {
        'data': {
          'id': 'message-1',
          'seq': 1,
          'conversationId': 'conversation-1',
          'senderAccountId': 'buyer-1',
          'senderParty': 'BUYER',
          'body': 'Shop còn bánh không?',
          'attachmentName': null,
          'attachmentContentType': null,
          'attachmentUrl': null,
          'createdAt': '2026-11-10T09:00:00Z',
        },
      },
    );
    final dio = Dio(BaseOptions(baseUrl: 'http://mock'))..httpClientAdapter = adapter;

    final message = await CommunicationApi(dio).sendMessage(
      'conversation-1',
      '  Shop còn bánh không?  ',
    );

    expect(adapter.lastRequest?.method, 'POST');
    expect(
      adapter.lastRequest?.path,
      ApiEndpoints.conversationMessages('conversation-1'),
    );
    expect(adapter.lastRequest?.data, {'body': 'Shop còn bánh không?'});
    expect(message.sequence, 1);
  });

  test('đánh dấu hội thoại đã đọc gửi upToSeq', () async {
    final adapter = FakeHttpAdapter(body: null, statusCode: 204);
    final dio = Dio(BaseOptions(baseUrl: 'http://mock'))..httpClientAdapter = adapter;

    await CommunicationApi(dio).markConversationRead('conversation-1', 12);

    expect(adapter.lastRequest?.path, ApiEndpoints.conversationRead('conversation-1'));
    expect(adapter.lastRequest?.data, {'upToSeq': 12});
  });
}

Map<String, Object?> _conversationJson() => {
  'id': 'conversation-1',
  'vendorId': 'vendor-1',
  'vendorName': 'Nguyệt Viên',
  'buyerAccountId': 'buyer-1',
  'buyerName': 'Nguyễn Văn Demo',
  'myParty': 'BUYER',
  'lastMessage': null,
  'lastMessageAt': null,
  'unreadCount': 0,
};
