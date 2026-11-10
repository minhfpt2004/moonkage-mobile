import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moonkage_verify/core/network/api_endpoints.dart';
import 'package:moonkage_verify/core/reference/vietnam_provinces.dart';
import 'package:moonkage_verify/features/account/data/account_api.dart';
import 'package:moonkage_verify/features/account/data/address_api.dart';
import 'package:moonkage_verify/features/account/domain/delivery_address.dart';

import 'helpers/fake_http_adapter.dart';

void main() {
  test('parse hồ sơ từ envelope backend và chuẩn hóa số điện thoại hiển thị', () async {
    final adapter = FakeHttpAdapter(
      body: {
        'data': {
          'accountId': 'account-1',
          'email': 'an@example.com',
          'phoneNumber': '912345678',
          'fullName': 'Nguyễn Văn An',
          'role': 'MEMBER',
        },
      },
    );
    final dio = Dio(BaseOptions(baseUrl: 'http://mock'))..httpClientAdapter = adapter;

    final profile = await AccountApi(dio).getMyAccount();

    expect(adapter.lastRequest?.path, ApiEndpoints.accountMe);
    expect(profile.fullName, 'Nguyễn Văn An');
    expect(profile.displayPhone, '0912345678');
  });

  test('parse danh sách địa chỉ và giữ areaCode/fullAddress từ backend', () async {
    final adapter = FakeHttpAdapter(
      body: {
        'data': [
          {
            'id': 'address-1',
            'recipientName': 'Nguyễn Văn An',
            'recipientPhone': '0912345678',
            'provinceCode': '79',
            'provinceName': 'TP Hồ Chí Minh',
            'wardName': 'Phường Bến Nghé',
            'detail': '1 Đồng Khởi',
            'fullAddress': '1 Đồng Khởi, Phường Bến Nghé, TP Hồ Chí Minh',
            'areaCode': '79',
            'label': 'Nhà riêng',
            'isDefault': true,
          },
        ],
      },
    );
    final dio = Dio(BaseOptions(baseUrl: 'http://mock'))..httpClientAdapter = adapter;

    final addresses = await AddressApi(dio).list();

    expect(addresses, hasLength(1));
    expect(addresses.single.areaCode, '79');
    expect(addresses.single.isDefault, isTrue);
    expect(addresses.single.fullAddress, contains('Đồng Khởi'));
  });

  test('payload tạo địa chỉ đúng contract backend', () async {
    final adapter = FakeHttpAdapter(
      body: {
        'data': {
          'id': 'address-1',
          'recipientName': 'An',
          'recipientPhone': '0912345678',
          'provinceCode': '01',
          'provinceName': 'Hà Nội',
          'wardName': 'Ba Đình',
          'detail': '1 Kim Mã',
          'fullAddress': '1 Kim Mã, Ba Đình, Hà Nội',
          'areaCode': '01',
          'label': 'Nhà',
          'isDefault': true,
        },
      },
    );
    final dio = Dio(BaseOptions(baseUrl: 'http://mock'))..httpClientAdapter = adapter;
    const draft = AddressDraft(
      recipientName: 'An',
      recipientPhone: '0912345678',
      provinceCode: '01',
      provinceName: 'Hà Nội',
      wardName: 'Ba Đình',
      detail: '1 Kim Mã',
      label: 'Nhà',
      isDefault: true,
    );

    await AddressApi(dio).create(draft);

    expect(adapter.lastRequest?.method, 'POST');
    expect((adapter.lastRequest?.data as Map)['provinceCode'], '01');
    expect((adapter.lastRequest?.data as Map)['isDefault'], isTrue);
  });

  test('danh mục tỉnh đồng bộ 34 đơn vị và mã hai chữ số', () {
    expect(vietnamProvinces, hasLength(34));
    expect(
      vietnamProvinces.every((province) => RegExp(r'^\d{2}$').hasMatch(province.code)),
      isTrue,
    );
    expect(provinceByCode('79').name, 'TP Hồ Chí Minh');
  });
}
