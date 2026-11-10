# Phase 1 - UI foundation và app shell

## Mục tiêu

Tạo nền giao diện cho ứng dụng bán bánh trung thu MoonKage theo layout
"Nguyệt Viên - Hoàng Triều Mỹ Vị", đồng thời giữ nguyên luồng xác minh NFC hiện có.

## Đã triển khai

- Design tokens dùng chung: đỏ hoàng gia, vàng kim, xanh ngọc, màu nền và màu chữ.
- Material 3 theme cho typography, AppBar, Card, Button, Input và NavigationBar.
- App shell dạng `StatefulShellRoute.indexedStack`, giữ state độc lập cho 5 tab:
  - Trang chủ (`/`)
  - Danh mục (`/catalog`)
  - Giỏ hàng (`/cart`)
  - Đơn hàng (`/orders`)
  - Tài khoản (`/account`)
- Trang chủ thương mại theo ngôn ngữ thiết kế của prototype.
- Màn nền cho danh mục, giỏ hàng và đơn hàng; chưa dùng dữ liệu giả thay cho API.
- Bộ widget dùng chung cho loading, empty và error state.
- Chuyển điểm vào luồng NFC sang `Tài khoản -> Xác minh danh tính NFC`.
- Nhóm route NFC dưới `/verification/*` để tách khỏi route thương mại.
- Widget test kiểm tra app shell, điều hướng tab Tài khoản và điểm vào NFC.

## Chưa thuộc Phase 1

- Danh mục/sản phẩm thật từ API.
- Đồng bộ giỏ hàng và checkout.
- Lịch sử, chi tiết và tracking đơn hàng.
- Hồ sơ, địa chỉ và thông báo thật.
- B2B quote và custom gift box hoàn chỉnh.

Các phần trên được triển khai ở những phase tiếp theo theo tài liệu kế hoạch tổng.

## Cách chạy kiểm tra thủ công

```powershell
flutter run --dart-define-from-file=env/mock.json
```

Sau khi đăng nhập:

1. Kiểm tra đủ 5 tab ở thanh điều hướng dưới.
2. Chuyển qua lại giữa các tab.
3. Mở `Tài khoản`.
4. Chọn `Xác minh danh tính NFC` và kiểm tra luồng cũ vẫn hoạt động.

## Tiêu chí hoàn thành

- [x] Theme không còn dùng màu Indigo mặc định.
- [x] Có app shell 5 tab đúng layout mục tiêu.
- [x] Có reusable loading/empty/error state.
- [x] Luồng NFC không còn là trang chủ của app thương mại.
- [x] Router vẫn bảo vệ toàn bộ route khi chưa đăng nhập.
- [ ] `flutter analyze` và `flutter test` chạy thành công trong môi trường không bị Flutter SDK lock.
