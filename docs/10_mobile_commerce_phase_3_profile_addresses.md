# Phase 3 - Hồ sơ và sổ địa chỉ

## Phạm vi

Kết nối khu vực Tài khoản với API thật của identity-service, gồm hồ sơ người dùng và CRUD địa chỉ giao hàng.

## Contract đã dùng

| Chức năng | Endpoint |
| --- | --- |
| Đọc hồ sơ | `GET /api/accounts/me` |
| Sửa tên hiển thị | `PATCH /api/accounts/me/profile` |
| Danh sách địa chỉ | `GET /api/addresses` |
| Thêm địa chỉ | `POST /api/addresses` |
| Thay thế địa chỉ | `PUT /api/addresses/{addressId}` |
| Xóa địa chỉ | `DELETE /api/addresses/{addressId}` |

Hồ sơ chỉ cho phép sửa `fullName`. Email, số điện thoại và role được hiển thị dạng chỉ đọc, đúng với contract backend.

## Địa chỉ giao hàng

Form mobile gửi đúng `AddAddressRequest`:

- `recipientName`
- `recipientPhone`
- `provinceCode` và `provinceName`
- `wardName`
- `detail`
- `label` không bắt buộc
- `isDefault`

Ứng dụng dùng cùng danh mục 34 tỉnh/thành và mã hành chính hai chữ số như web/backend. Việt Nam sau tháng 7/2025
không còn trường quận/huyện trong contract này; người dùng nhập phường/xã trực tiếp.

## Đã triển khai

- Header Tài khoản đọc profile mới nhất từ backend.
- Màn Hồ sơ cá nhân:
  - sửa tên hiển thị;
  - xem email, số điện thoại và loại tài khoản;
  - đồng bộ tên mới vào session và secure storage.
- Màn Sổ địa chỉ:
  - loading, empty, error và pull-to-refresh;
  - hiển thị địa chỉ mặc định;
  - thêm, sửa và xác nhận trước khi xóa.
- Form địa chỉ validation theo giới hạn backend.
- `deliveryProvinceProvider` lấy tỉnh từ địa chỉ mặc định, sau đó địa chỉ đầu tiên, cuối cùng là Hà Nội. Provider này là
  đầu vào dùng chung cho catalog/cart từ Phase 4 trở đi.
- Mock server hỗ trợ profile và toàn bộ CRUD address.
- Test contract cho profile, address payload/response và danh mục tỉnh.

## Route mobile

- `/account/profile`
- `/account/addresses`
- `/account/addresses/form`

Các route nằm trong nhánh Tài khoản của app shell nên vẫn giữ thanh điều hướng dưới.

## Cách test với mock server

Khởi động lại mock server để nhận các endpoint mới:

```powershell
dart run tool/mock_server.dart
```

Chạy app:

```powershell
flutter run --dart-define-from-file=env/mock.json
```

Sau khi đăng nhập:

1. Mở `Tài khoản -> Hồ sơ cá nhân`, đổi tên và lưu.
2. Mở `Tài khoản -> Sổ địa chỉ`.
3. Thêm một địa chỉ, chọn tỉnh/thành và bật địa chỉ mặc định.
4. Thử chỉnh sửa và xóa địa chỉ.

## Tiêu chí hoàn thành

- [x] Profile dùng API thật, không dùng dữ liệu UI giả.
- [x] Tên mới đồng bộ session/secure storage.
- [x] CRUD address đúng DTO backend.
- [x] Danh mục 34 tỉnh/thành đồng bộ với web/backend.
- [x] Có nguồn tỉnh giao hàng mặc định cho catalog/cart.
- [x] Mock server hỗ trợ test thủ công Phase 3.
- [ ] Chạy `flutter analyze` và toàn bộ `flutter test` sau khi giải phóng Flutter SDK lock.
