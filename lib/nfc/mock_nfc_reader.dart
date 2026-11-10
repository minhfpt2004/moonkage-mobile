import 'dart:async';
import 'dart:convert';

import 'package:moonkage_verify/nfc/nfc_reader.dart';

/// NFC giả lập dành riêng cho emulator khi build với `NFC_MOCK_MODE=true`.
///
/// Sau một khoảng trễ ngắn, reader trả về một NDEF Text record chứa CCCD mẫu.
/// Không sử dụng dữ liệu người thật và không truy cập phần cứng NFC.
final class MockNfcReader implements NfcReader {
  MockNfcReader({this.readDelay = const Duration(milliseconds: 900)});

  final Duration readDelay;
  Completer<List<String>>? _pending;
  Timer? _timer;

  @override
  Future<NfcStatus> checkStatus() async => NfcStatus.enabled;

  @override
  Future<void> ensureSessionStarted({bool force = false}) async {}

  @override
  Future<List<String>> readTextRecords() {
    _cancelPending();

    final completer = Completer<List<String>>();
    _pending = completer;
    _timer = Timer(readDelay, () {
      if (!identical(_pending, completer) || completer.isCompleted) return;
      _pending = null;
      _timer = null;
      completer.complete([jsonEncode(_sampleCard)]);
    });
    return completer.future;
  }

  @override
  Future<void> cancel() async => _cancelPending();

  @override
  Future<void> stop() async => _cancelPending();

  void _cancelPending() {
    _timer?.cancel();
    _timer = null;
    final pending = _pending;
    _pending = null;
    if (pending != null && !pending.isCompleted) {
      pending.completeError(const NfcReadCancelled());
    }
  }
}

const _sampleCard = <String, String>{
  'id_number': '000000000001',
  'full_name': 'NGUYEN VAN AN',
  'date_of_birth': '1990-01-01',
  'gender': 'Nam',
  'nationality': 'Viet Nam',
  'place_of_birth': 'Tinh Lam Dong',
  'place_of_residence': 'So 1 Duong Thu Nghiem, Phuong Sai Gon, TP Lam Dong',
  'date_of_issue': '2024-01-01',
  'date_of_expiry': '2035-01-01',
};
