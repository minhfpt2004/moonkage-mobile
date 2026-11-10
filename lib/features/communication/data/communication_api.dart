import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moonkage_verify/core/errors/app_failure.dart';
import 'package:moonkage_verify/core/network/api_endpoints.dart';
import 'package:moonkage_verify/core/network/api_payload.dart';
import 'package:moonkage_verify/core/network/dio_failure.dart';
import 'package:moonkage_verify/core/network/dio_provider.dart';
import 'package:moonkage_verify/features/communication/domain/communication.dart';

final communicationApiProvider = Provider<CommunicationApi>(
  (ref) => CommunicationApi(ref.watch(dioProvider)),
);

final notificationsProvider = FutureProvider.autoDispose<NotificationPage>(
  (ref) => ref.watch(communicationApiProvider).notifications(),
);

final conversationsProvider = FutureProvider.autoDispose<List<ChatConversation>>(
  (ref) => ref.watch(communicationApiProvider).conversations(),
);

final chatThreadProvider = FutureProvider.autoDispose.family<ChatThread, String>(
  (ref, conversationId) => ref.watch(communicationApiProvider).thread(conversationId),
);

class CommunicationApi {
  CommunicationApi(this._dio);

  final Dio _dio;

  Future<NotificationPage> notifications({int page = 0, int size = 50}) async {
    try {
      final response = await _dio.get<Object?>(
        ApiEndpoints.notifications,
        queryParameters: {'page': page, 'size': size},
      );
      return NotificationPage.fromJson(_map(apiPayload(response.data)));
    } on DioException catch (error) {
      throw failureFromDio(error);
    }
  }

  Future<AppNotification> markNotificationRead(String notificationId) async {
    try {
      final response = await _dio.post<Object?>(ApiEndpoints.notificationRead(notificationId));
      return AppNotification.fromJson(_map(apiPayload(response.data)));
    } on DioException catch (error) {
      throw failureFromDio(error);
    }
  }

  Future<int> markAllNotificationsRead() async {
    try {
      final response = await _dio.post<Object?>(ApiEndpoints.notificationsReadAll);
      final payload = apiPayload(response.data);
      if (payload is! num) throw const InvalidResponseFailure();
      return payload.toInt();
    } on DioException catch (error) {
      throw failureFromDio(error);
    }
  }

  Future<List<ChatConversation>> conversations() async {
    try {
      final response = await _dio.get<Object?>(
        ApiEndpoints.conversations,
        queryParameters: {'as': 'BUYER'},
      );
      final payload = apiPayload(response.data);
      if (payload is! List) throw const InvalidResponseFailure();
      return payload.map((item) => ChatConversation.fromJson(_map(item))).toList(growable: false);
    } on DioException catch (error) {
      throw failureFromDio(error);
    }
  }

  Future<ChatConversation> startConversation(String vendorId) async {
    try {
      final response = await _dio.post<Object?>(
        ApiEndpoints.conversations,
        data: {'vendorId': vendorId},
      );
      return ChatConversation.fromJson(_map(apiPayload(response.data)));
    } on DioException catch (error) {
      throw failureFromDio(error);
    }
  }

  Future<ChatThread> thread(String conversationId, {int size = 100}) async {
    try {
      final response = await _dio.get<Object?>(
        ApiEndpoints.conversation(conversationId),
        queryParameters: {'size': size},
      );
      return ChatThread.fromJson(_map(apiPayload(response.data)));
    } on DioException catch (error) {
      throw failureFromDio(error);
    }
  }

  Future<ChatMessage> sendMessage(String conversationId, String body) async {
    try {
      final response = await _dio.post<Object?>(
        ApiEndpoints.conversationMessages(conversationId),
        data: {'body': body.trim()},
      );
      return ChatMessage.fromJson(_map(apiPayload(response.data)));
    } on DioException catch (error) {
      throw failureFromDio(error);
    }
  }

  Future<void> markConversationRead(String conversationId, int upToSequence) async {
    try {
      await _dio.post<void>(
        ApiEndpoints.conversationRead(conversationId),
        data: {'upToSeq': upToSequence},
      );
    } on DioException catch (error) {
      throw failureFromDio(error);
    }
  }

  Future<void> typing(String conversationId) async {
    try {
      await _dio.post<void>(ApiEndpoints.conversationTyping(conversationId));
    } on DioException catch (error) {
      throw failureFromDio(error);
    }
  }

  static Map<String, Object?> _map(Object? value) {
    if (value is! Map) throw const InvalidResponseFailure();
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
}
