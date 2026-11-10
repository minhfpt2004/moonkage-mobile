import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moonkage_verify/core/auth/auth_session.dart';
import 'package:moonkage_verify/core/auth/refresh_token_client.dart';
import 'package:moonkage_verify/core/auth/session_notifier.dart';
import 'package:moonkage_verify/core/auth/token_storage.dart';
import 'package:moonkage_verify/core/network/api_endpoints.dart';
import 'package:moonkage_verify/core/network/dio_provider.dart';
import 'package:moonkage_verify/features/auth/data/auth_api.dart';
import 'package:moonkage_verify/features/auth/presentation/widgets/auth_form_support.dart';

import 'helpers/fake_http_adapter.dart';

class _MockDio extends Mock implements Dio {}

class _MockRefreshTokenClient extends Mock implements RefreshTokenClient {}

class _MemoryFullSessionStorage implements FullSessionStorage {
  AuthSession? saved;

  @override
  Future<void> saveFullSession(AuthSession session) async => saved = session;

  @override
  Future<void> saveSession({required String token, required String fullName}) async {
    saved = AuthSession(token: token, fullName: fullName);
  }

  @override
  Future<AuthSession?> readSession() async => saved;

  @override
  Future<void> clearSession() async => saved = null;
}

void main() {
  test('login parse đầy đủ access token, refresh token và hồ sơ', () async {
    final dio = _MockDio();
    final api = AuthApi(dio);
    when(
      () => dio.post<Object?>(
        ApiEndpoints.login,
        data: {'username': 'an@example.com', 'password': '12345678'},
      ),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: ApiEndpoints.login),
        data: {
          'data': {
            'token': 'access',
            'refreshToken': 'refresh',
            'accountId': 'account-1',
            'email': 'an@example.com',
            'phoneNumber': '912345678',
            'fullName': 'Nguyễn Văn An',
            'role': 'MEMBER',
          },
        },
      ),
    );

    final session = await api.login(username: 'an@example.com', password: '12345678');

    expect(session.token, 'access');
    expect(session.refreshToken, 'refresh');
    expect(session.accountId, 'account-1');
    expect(session.email, 'an@example.com');
    expect(session.role, 'MEMBER');
  });

  test('phiên ghi nhớ lưu cả refresh token và được thay sau refresh', () async {
    final storage = _MemoryFullSessionStorage();
    final container = ProviderContainer(
      overrides: [tokenStorageProvider.overrideWithValue(storage)],
    );
    addTearDown(container.dispose);

    final notifier = container.read(sessionProvider.notifier);
    notifier.signIn(
      const AuthSession(token: 'old', refreshToken: 'refresh-old', fullName: 'An'),
      rememberMe: true,
    );
    notifier.replaceSession(
      const AuthSession(token: 'new', refreshToken: 'refresh-new', fullName: 'An'),
    );

    expect(storage.saved?.token, 'new');
    expect(storage.saved?.refreshToken, 'refresh-new');
    expect(storage.saved?.rememberMe, isTrue);
  });

  test('401 làm mới token một lần rồi phát lại request', () async {
    final refreshClient = _MockRefreshTokenClient();
    final container = ProviderContainer(
      overrides: [refreshTokenClientProvider.overrideWithValue(refreshClient)],
    );
    addTearDown(container.dispose);
    final adapter = FakeHttpAdapter(statusCode: 401, body: {'message': 'expired'});
    final dio = container.read(dioProvider)
      ..options.baseUrl = 'http://mock'
      ..httpClientAdapter = adapter;
    container
        .read(sessionProvider.notifier)
        .signIn(
          const AuthSession(
            token: 'access-old',
            refreshToken: 'refresh-1',
            fullName: 'An',
          ),
        );
    when(() => refreshClient.refresh('refresh-1')).thenAnswer((_) async {
      adapter.statusCode = 200;
      return const AuthSession(
        token: 'access-new',
        refreshToken: 'refresh-2',
        fullName: 'An',
      );
    });

    final response = await dio.get<Object?>('/protected');

    expect(response.statusCode, 200);
    expect(adapter.lastRequest?.headers['Authorization'], 'Bearer access-new');
    expect(container.read(sessionProvider)?.refreshToken, 'refresh-2');
    verify(() => refreshClient.refresh('refresh-1')).called(1);
  });

  test('validator khớp giới hạn backend', () {
    expect(AuthValidators.email('an@example.com'), isNull);
    expect(AuthValidators.email('email-sai'), isNotNull);
    expect(AuthValidators.phone('0912345678'), isNull);
    expect(AuthValidators.phone('0123'), isNotNull);
    expect(AuthValidators.password('1234567'), isNotNull);
    expect(AuthValidators.password('12345678'), isNull);
  });
}
