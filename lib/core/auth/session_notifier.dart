import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moonkage_verify/core/auth/auth_session.dart';
import 'package:moonkage_verify/core/auth/token_storage.dart';

final initialSessionProvider = Provider<AuthSession?>((ref) => null);

/// `null` khi chưa đăng nhập. Router và interceptor của Dio đọc provider này.
final sessionProvider = NotifierProvider<SessionNotifier, AuthSession?>(SessionNotifier.new);

class SessionNotifier extends Notifier<AuthSession?> {
  @override
  AuthSession? build() => ref.watch(initialSessionProvider);

  void signIn(AuthSession session, {bool rememberMe = true}) {
    final activeSession = session.copyWith(rememberMe: rememberMe);
    state = activeSession;
    final storage = ref.read(tokenStorageProvider);
    if (rememberMe) {
      if (storage is FullSessionStorage) {
        unawaited(storage.saveFullSession(activeSession));
      } else {
        unawaited(storage.saveSession(token: session.token, fullName: session.fullName));
      }
    } else {
      unawaited(storage.clearSession());
    }
  }

  /// Thay access token sau refresh nhưng giữ đúng lựa chọn "Ghi nhớ đăng nhập".
  void replaceSession(AuthSession session) {
    final current = state;
    if (current == null) return;
    final activeSession = session.copyWith(rememberMe: current.rememberMe);
    state = activeSession;
    final storage = ref.read(tokenStorageProvider);
    if (!activeSession.rememberMe) return;
    if (storage is FullSessionStorage) {
      unawaited(storage.saveFullSession(activeSession));
    } else {
      unawaited(storage.saveSession(token: session.token, fullName: session.fullName));
    }
  }

  /// Đồng bộ tên hiển thị sau khi PATCH hồ sơ thành công.
  void updateFullName(String fullName) {
    final current = state;
    if (current == null) return;
    replaceSession(current.copyWith(fullName: fullName));
  }

  void signOut() {
    state = null;
    unawaited(ref.read(tokenStorageProvider).clearSession());
  }
}
