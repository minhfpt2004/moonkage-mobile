import 'package:flutter_test/flutter_test.dart';
import 'package:moonkage_verify/core/network/api_payload.dart';

void main() {
  test('unwraps object, list, primitive and null data', () {
    expect(
      apiPayload({
        'data': {'id': '1'},
      }),
      {'id': '1'},
    );
    expect(
      apiPayload({
        'data': [1, 2],
      }),
      [1, 2],
    );
    expect(apiPayload({'data': 3}), 3);
    expect(apiPayload({'data': null}), isNull);
  });

  test('keeps legacy unwrapped body unchanged', () {
    final body = {'status': 'VERIFIED'};
    expect(apiPayload(body), same(body));
  });
}
