# Phase 8 - Đánh giá sau khi mua

## Phạm vi

- Hiển thị đánh giá đã gửi theo từng sản phẩm trong chi tiết đơn hàng.
- Cho phép chọn từ 1 đến 5 sao và nhập nhận xét tối đa 2.000 ký tự.
- Sau khi gửi, cập nhật cả đánh giá của đơn hàng và danh sách đánh giá ở chi tiết sản phẩm.

## Quy tắc backend

- Chỉ áp dụng cho đơn `BUY_NOW`.
- Đơn phải ở trạng thái `DELIVERED` hoặc `COMPLETED`.
- Sản phẩm phải thuộc đơn hàng.
- Mỗi sản phẩm trong một đơn chỉ được đánh giá một lần.
- API: `GET /api/orders/{orderId}/reviews` và `POST /api/orders/{orderId}/reviews`.

## Cách kiểm thử với mock server

1. Chạy `dart run tool/mock_server.dart`.
2. Chạy app với `flutter run --dart-define-from-file=env/mock.json`.
3. Tạo đơn mua ngay và dùng trang điều khiển mock để chuyển đơn tới `DELIVERED`.
4. Mở **Đơn hàng > Chi tiết đơn > Đánh giá sản phẩm**.
5. Chọn số sao, nhập nhận xét và gửi. Nút gửi sẽ được thay bằng nội dung đánh giá.

Nếu mock server đã chạy trước khi phase này được thêm, cần dừng và chạy lại server để nạp route đánh giá mới.
