# Phase 7 - Theo dõi và quản lý đơn hàng

## Phạm vi

Phase này đưa các đơn được tạo sau checkout vào mobile app. Người mua có thể lọc danh sách, xem đầy đủ chi tiết và tiến độ, xác nhận đã nhận hàng, đồng thời tiếp tục thanh toán phần còn lại của đơn đặt làm khi backend cho phép.

## Contract đã dùng

| Chức năng | Endpoint |
| --- | --- |
| Danh sách đơn và lọc trạng thái | `GET /api/orders?status=&page=0&size=50` |
| Chi tiết đơn | `GET /api/orders/{orderId}` |
| Timeline tiến độ | `GET /api/orders/{orderId}/progress-updates` |
| Xác nhận đã nhận hàng | `PATCH /api/orders/{orderId}` |
| Thanh toán phần còn lại | `POST /api/orders/{orderId}/payments` |

Body xác nhận nhận hàng:

```json
{
  "receivedConfirmed": true
}
```

Backend quyết định khi nào được xác nhận hoặc thanh toán. Mobile chỉ hiển thị hành động phù hợp với loại và trạng thái đơn, không tự chuyển trạng thái ở phía client.

## Vòng đời hiển thị

- Đơn mua ngay: `PAID → CONFIRMED → SHIPPING → DELIVERED → COMPLETED`.
- Đơn đặt làm: `DEPOSITED → AWAITING_MOCKUP_APPROVAL → IN_PRODUCTION → READY_TO_SHIP → DELIVERED → COMPLETED`.
- Trạng thái mới chưa biết được ánh xạ thành `Đang cập nhật` để app không bị lỗi parse.

## Đã triển khai

- Màn danh sách đơn với chip lọc trạng thái và kéo để tải lại.
- Màn chi tiết gồm sản phẩm, shop, địa chỉ giao hàng, mã vận đơn và tổng tiền.
- Timeline tiến độ lấy độc lập từ backend.
- Hiển thị thông tin hóa đơn và cảnh báo khi đơn đang có khiếu nại.
- Xác nhận đã nhận hàng sau hộp thoại xác nhận; làm mới danh sách và chi tiết sau thành công.
- Mở URL thanh toán phần còn lại bằng trình duyệt ngoài cho đơn đặt làm.
- Tự làm mới chi tiết khi app quay lại từ trình duyệt thanh toán.
- Mock server tạo đơn sau khi giả lập VNPay thành công và hỗ trợ đẩy trạng thái để test.
- Unit test các API contract, parser và toàn bộ status hiện có.

## Cách test với mock server

Terminal 1:

```powershell
dart run tool/mock_server.dart
```

Terminal 2:

```powershell
flutter run --dart-define-from-file=env/mock.json
```

Luồng test:

1. Đăng nhập `demo@moonkage.vn` / `123456`.
2. Thêm sản phẩm, checkout và chọn `Giả lập thành công` trên trang Mock VNPay.
3. Quay lại app, mở mục `Đơn hàng`; đơn mới có trạng thái `Đã thanh toán`.
4. Trên máy tính mở `http://localhost:8090` và bấm `Đẩy đơn mock sang bước tiếp theo`.
5. Kéo để tải lại trong app. Mỗi lần bấm sẽ chuyển `PAID → CONFIRMED → SHIPPING → DELIVERED`.
6. Ở trạng thái `DELIVERED`, mở chi tiết và chọn `Tôi đã nhận hàng`; đơn chuyển sang `COMPLETED`.

Nút đẩy trạng thái chỉ tồn tại trong mock server để kiểm thử. Khi dùng backend thật, vendor và hệ thống vận chuyển cập nhật tiến độ.

## Tiêu chí hoàn thành

- [x] Danh sách và bộ lọc dùng đúng contract backend.
- [x] Chi tiết hiển thị items mà API danh sách cố ý lược bỏ.
- [x] Timeline hỗ trợ milestone và danh sách ảnh tiến độ.
- [x] Xác nhận nhận hàng chỉ xuất hiện với đơn đã giao.
- [x] Thanh toán phần còn lại chỉ xuất hiện đúng ngữ cảnh đơn đặt làm.
- [x] App không tự suy diễn kết quả thanh toán hay cập nhật trạng thái client-side.
- [x] Mock server có luồng tạo và đẩy trạng thái đơn mua ngay.
- [x] Có test contract riêng cho Phase 7.
- [ ] Review, dispute, mockup approval và tải hóa đơn được triển khai ở phase tiếp theo.
