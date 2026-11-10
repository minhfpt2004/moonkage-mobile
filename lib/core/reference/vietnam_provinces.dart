final class VietnamProvince {
  const VietnamProvince(this.code, this.name);

  final String code;
  final String name;
}

/// 34 đơn vị hành chính cấp tỉnh theo cùng danh mục backend/web đang dùng.
const vietnamProvinces = <VietnamProvince>[
  VietnamProvince('01', 'Hà Nội'),
  VietnamProvince('04', 'Cao Bằng'),
  VietnamProvince('08', 'Tuyên Quang'),
  VietnamProvince('11', 'Điện Biên'),
  VietnamProvince('12', 'Lai Châu'),
  VietnamProvince('14', 'Sơn La'),
  VietnamProvince('15', 'Lào Cai'),
  VietnamProvince('19', 'Thái Nguyên'),
  VietnamProvince('20', 'Lạng Sơn'),
  VietnamProvince('22', 'Quảng Ninh'),
  VietnamProvince('24', 'Bắc Ninh'),
  VietnamProvince('25', 'Phú Thọ'),
  VietnamProvince('31', 'Hải Phòng'),
  VietnamProvince('33', 'Hưng Yên'),
  VietnamProvince('37', 'Ninh Bình'),
  VietnamProvince('38', 'Thanh Hóa'),
  VietnamProvince('40', 'Nghệ An'),
  VietnamProvince('42', 'Hà Tĩnh'),
  VietnamProvince('44', 'Quảng Trị'),
  VietnamProvince('46', 'Huế'),
  VietnamProvince('48', 'Đà Nẵng'),
  VietnamProvince('51', 'Quảng Ngãi'),
  VietnamProvince('52', 'Gia Lai'),
  VietnamProvince('56', 'Khánh Hòa'),
  VietnamProvince('66', 'Đắk Lắk'),
  VietnamProvince('68', 'Lâm Đồng'),
  VietnamProvince('75', 'Đồng Nai'),
  VietnamProvince('79', 'TP Hồ Chí Minh'),
  VietnamProvince('80', 'Tây Ninh'),
  VietnamProvince('82', 'Đồng Tháp'),
  VietnamProvince('86', 'Vĩnh Long'),
  VietnamProvince('91', 'An Giang'),
  VietnamProvince('92', 'Cần Thơ'),
  VietnamProvince('96', 'Cà Mau'),
];

VietnamProvince provinceByCode(String code) => vietnamProvinces.firstWhere(
  (province) => province.code == code,
  orElse: () => vietnamProvinces.first,
);
