# Phase 9 - B2B và yêu cầu báo giá

## Phạm vi buyer mobile

- Xem danh sách nhà cung cấp đang nhận đơn tùy chỉnh.
- Tạo yêu cầu `DIRECT` cho một nhà cung cấp hoặc `OPEN` cho nhiều nhà cung cấp phù hợp.
- Chọn số lượng, ngân sách, loại tùy chỉnh, mô tả, hạn giao và địa chỉ nhận hàng.
- Theo dõi lời mời, so sánh các báo giá theo tổng tiền, tiền cọc, ngày giao và ghi chú.
- Chấp nhận một báo giá và mở link thanh toán tiền cọc.

Các thao tác gửi, sửa hoặc thu hồi báo giá thuộc vai trò shop và không nằm trong app buyer.

## API backend

- `GET /api/suppliers`
- `GET /api/quote-requests`
- `POST /api/quote-requests`
- `GET /api/quote-requests/{requestId}`
- `GET /api/quote-requests/{requestId}/invitations`
- `GET /api/quote-requests/{requestId}/quotes`
- `POST /api/quote-requests/{requestId}/quotes/{quoteId}/acceptance`

Backend thật yêu cầu tài khoản đã xác minh NFC trước khi tạo yêu cầu hoặc chấp nhận báo giá.

## Kiểm thử mock

1. Dừng và chạy lại `dart run tool/mock_server.dart`.
2. Chạy app bằng `flutter run --dart-define-from-file=env/mock.json`.
3. Vào **Tài khoản > Yêu cầu báo giá B2B**.
4. Tạo yêu cầu công khai để mock server sinh hai báo giá cho màn hình so sánh.
5. Chọn một báo giá để mở trang đặt cọc giả lập.
