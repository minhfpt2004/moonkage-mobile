import 'package:flutter_test/flutter_test.dart';
import 'package:moonkage_verify/features/verify/domain/card_parser.dart';
import 'package:moonkage_verify/nfc/mock_nfc_reader.dart';
import 'package:moonkage_verify/nfc/nfc_reader.dart';

void main() {
  test('báo NFC bật và trả về CCCD mẫu hợp lệ', () async {
    final reader = MockNfcReader(readDelay: Duration.zero);

    expect(await reader.checkStatus(), NfcStatus.enabled);
    final records = await reader.readTextRecords();
    expect(records, hasLength(1));
    expect(parseCardText(records.single), isNotNull);
  });

  test('cancel hủy lần đọc đang chờ', () async {
    final reader = MockNfcReader(readDelay: const Duration(seconds: 1));
    final read = reader.readTextRecords();
    final expectation = expectLater(read, throwsA(isA<NfcReadCancelled>()));

    await reader.cancel();

    await expectation;
  });
}
