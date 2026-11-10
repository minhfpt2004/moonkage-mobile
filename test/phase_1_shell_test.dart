import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moonkage_verify/app.dart';
import 'package:moonkage_verify/core/auth/auth_session.dart';
import 'package:moonkage_verify/core/auth/session_notifier.dart';
import 'package:moonkage_verify/features/commerce/presentation/screens/account_screen.dart';
import 'package:moonkage_verify/features/commerce/presentation/screens/commerce_home_screen.dart';
import 'package:moonkage_verify/features/verify/presentation/screens/home_screen.dart' as verify;
import 'package:moonkage_verify/nfc/nfc_reader.dart';

class _MockNfcReader extends Mock implements NfcReader {}

void main() {
  testWidgets('người dùng đã đăng nhập thấy app shell và mở được xác minh NFC', (tester) async {
    final nfcReader = _MockNfcReader();
    when(
      () => nfcReader.ensureSessionStarted(force: any(named: 'force')),
    ).thenAnswer((_) async {});
    when(nfcReader.stop).thenAnswer((_) async {});
    when(nfcReader.checkStatus).thenAnswer((_) async => NfcStatus.enabled);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          nfcReaderProvider.overrideWithValue(nfcReader),
          initialSessionProvider.overrideWithValue(
            const AuthSession(token: 'test-token', fullName: 'Nguyễn Văn Demo'),
          ),
        ],
        child: const MoonkageVerifyApp(configValid: true),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CommerceHomeScreen), findsOneWidget);
    expect(find.text('Trang chủ'), findsOneWidget);
    expect(find.text('Danh mục'), findsOneWidget);
    expect(find.text('Giỏ hàng'), findsOneWidget);
    expect(find.text('Đơn hàng'), findsOneWidget);
    expect(find.text('Tài khoản'), findsOneWidget);

    await tester.tap(find.text('Tài khoản'));
    await tester.pumpAndSettle();
    expect(find.byType(AccountScreen), findsOneWidget);

    await tester.tap(find.text('Xác minh danh tính NFC'));
    await tester.pumpAndSettle();
    expect(find.byType(verify.HomeScreen), findsOneWidget);
  });
}
