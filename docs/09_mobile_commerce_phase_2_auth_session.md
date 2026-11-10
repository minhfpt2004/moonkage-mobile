# Phase 2 - Authentication và session

## Phạm vi

Triển khai luồng tài khoản người mua theo contract công khai của identity-service. Mọi endpoint đi qua API Gateway
với prefix `/api/auth/**`.

## Contract đã dùng

| Chức năng | Endpoint | Payload chính |
| --- | --- | --- |
| Đăng ký | `POST /api/auth/register` | `email`, `phoneNumber`, `fullName`, `password` |
| Gửi OTP kích hoạt | `POST /api/auth/send-verify-account-otp` | `email` |
| Kích hoạt | `POST /api/auth/verify-account` | `email`, `otp` |
| Đăng nhập | `POST /api/auth/login` | `username`, `password` |
| Làm mới phiên | `POST /api/auth/refresh-token` | `refreshToken` |
| Gửi OTP reset | `POST /api/auth/send-reset-password-otp` | `email` |
| Đổi mật khẩu | `POST /api/auth/reset-password` | `email`, `otp`, `newPassword` |

## Đã triển khai

- Màn đăng ký với validation tương ứng backend:
  - email bắt buộc;
  - số điện thoại Việt Nam không bắt buộc;
  - mật khẩu từ 8 đến 72 ký tự.
- Luồng đăng ký chuyển thẳng sang nhập OTP và hỗ trợ gửi lại OTP.
- Luồng quên mật khẩu gồm gửi OTP, nhập OTP và đặt mật khẩu mới.
- Login parse đầy đủ `token`, `refreshToken`, account/profile và role.
- Secure storage lưu đầy đủ phiên khi người dùng bật `Ghi nhớ đăng nhập`.
- Interceptor xử lý 401 theo cơ chế single-flight:
  1. chỉ gửi một request refresh khi nhiều request cùng hết hạn;
  2. cập nhật secure storage;
  3. phát lại request ban đầu một lần;
  4. đăng xuất nếu refresh thất bại hoặc request phát lại vẫn nhận 401.
- Các route đăng ký, OTP và reset được phép truy cập khi chưa đăng nhập.
- Mock server hỗ trợ toàn bộ flow Phase 2; OTP mock cố định là `123456`.
- Test bổ sung cho parser phiên, secure storage, refresh/retry và validator.

## Route mobile

- `/login`
- `/register`
- `/verify-account?email=...&sent=1`
- `/reset-password`

Email được phép nằm trong query để prefill form; mật khẩu, OTP và token không được đưa vào URL.

## Cách test với mock server

Terminal 1:

```powershell
dart run tool/mock_server.dart
```

Terminal 2:

```powershell
flutter run --dart-define-from-file=env/mock.json
```

Luồng đăng ký:

1. Chọn `Chưa có tài khoản? Đăng ký`.
2. Nhập email mới và mật khẩu tối thiểu 8 ký tự.
3. Nhập OTP `123456`.
4. Quay lại đăng nhập bằng tài khoản vừa tạo.

Tài khoản demo cũ vẫn dùng mật khẩu `123456`.

## Tiêu chí hoàn thành

- [x] Register và verify-account đúng DTO backend.
- [x] Forgot/reset password đúng DTO backend.
- [x] Lưu refresh token bằng secure storage.
- [x] Refresh token single-flight và retry request đúng một lần.
- [x] Không đưa token, password hoặc OTP vào URL/log.
- [x] Mock server hỗ trợ test thủ công Phase 2.
- [ ] Chạy `flutter analyze` và toàn bộ `flutter test` sau khi giải phóng Flutter SDK lock.
