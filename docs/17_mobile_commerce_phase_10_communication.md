# Phase 10 - Thông báo và chat cửa hàng

## Thông báo

- Hiển thị danh sách mới nhất và badge số chưa đọc trên Trang chủ.
- Đánh dấu một thông báo hoặc tất cả thông báo là đã đọc.
- Điều hướng thông báo đơn hàng/báo giá sang màn hình mobile tương ứng khi `targetUrl` được hỗ trợ.
- API thật: `GET /api/notifications`, `POST /api/notifications/{id}/read`, `POST /api/notifications/read-all`.

## Chat buyer với cửa hàng

- Bắt đầu hội thoại từ nút chat trong trang chi tiết sản phẩm.
- Inbox hiển thị tin cuối và số chưa đọc.
- Thread hiển thị tin nhắn theo thứ tự cũ đến mới, gửi tin văn bản, đánh dấu đã đọc và gọi typing endpoint.
- Thread tự tải lại mỗi 5 giây. Backend vẫn có thể đẩy sự kiện STOMP; mobile có thể thay polling bằng WebSocket ở bước tối ưu sau mà không đổi contract REST.
- API thật: `POST/GET /api/chat/conversations`, `GET /{id}`, `POST /{id}/messages`, `POST /{id}/read`, `POST /{id}/typing`.

## Kiểm thử mock

1. Khởi động lại `dart run tool/mock_server.dart`.
2. Chạy app với `flutter run --dart-define-from-file=env/mock.json`.
3. Badge thông báo xuất hiện ở góc phải Trang chủ.
4. Mở một sản phẩm, nhấn biểu tượng chat cạnh bộ chọn số lượng.
5. Mock shop gửi lời chào và tự phản hồi sau mỗi tin nhắn để kiểm tra giao diện hai phía.
