# Phase 6 - Checkout và thanh toán VNPay

## Phạm vi

Phase này nối toàn bộ giỏ hàng phía server sang checkout, mở trang VNPay và theo dõi kết quả thanh toán. Danh sách và chi tiết đơn hàng thuộc Phase 7.

## Contract đã dùng

| Chức năng | Endpoint |
| --- | --- |
| Tạo checkout từ toàn bộ giỏ | `POST /api/checkouts` |
| Đọc trạng thái checkout | `GET /api/checkouts/{checkoutId}` |

Body tạo checkout:

```json
{
  "recipientName": "Nguyễn Văn Demo",
  "recipientPhone": "0900000001",
  "provinceCode": "79",
  "addressDetail": "12 Lê Lợi, Phường Bến Nghé",
  "invoiceInfo": {
    "name": "Công ty MoonKage",
    "taxCode": "0123456789",
    "address": "12 Lê Lợi, TP.HCM",
    "email": "invoice@moonkage.vn"
  }
}
```

`invoiceInfo` được bỏ hẳn khỏi JSON với hóa đơn cá nhân. Backend trả `paymentUrl`; mobile mở URL HTTP/HTTPS bằng Android Intent.

## Nguyên tắc xác nhận thanh toán

App không coi việc người dùng quay lại từ trình duyệt là thanh toán thành công. Màn kết quả poll `GET /api/checkouts/{id}` mỗi 2 giây và chỉ báo thành công khi backend trả `SUCCEEDED`, tức đã nhận xác nhận server-to-server từ VNPay và tạo `orderIds`.

Các trạng thái được hỗ trợ:

- `PENDING_PAYMENT`: đang chờ VNPay/IPN;
- `SUCCEEDED`: thanh toán thành công, đơn đã được tạo theo từng shop;
- `FAILED`: giao dịch bị từ chối, kho được trả lại;
- `EXPIRED`: hết thời gian giữ hàng;
- `REFUND_REQUESTED`: thanh toán đến muộn, backend đang xử lý hoàn tiền.

## Đã triển khai

- Chọn một địa chỉ giao hàng đã lưu; ưu tiên địa chỉ mặc định.
- Tính lại cart và phí giao theo tỉnh của địa chỉ được chọn.
- Form hóa đơn doanh nghiệp tùy chọn, validate mã số thuế và email.
- Phương thức thanh toán duy nhất là VNPay đúng contract hiện tại.
- Tạo checkout, hiển thị tổng tiền và hạn giữ hàng.
- Mở trình duyệt ngoài bằng MethodChannel Android, không thêm dependency ngoài.
- Poll trạng thái tối đa 30 lần, tự kiểm tra ngay khi app resume và hỗ trợ kéo để refresh.
- Xóa cache cart khi checkout thành công.
- Mock VNPay có hai nút giả lập thành công/thất bại.
- Test contract cho create, invoice tùy chọn, status và orderIds.

## Cách test với mock server

Khởi động lại mock server:

```powershell
dart run tool/mock_server.dart
```

Chạy app:

```powershell
flutter run --dart-define-from-file=env/mock.json
```

Luồng test:

1. Đăng nhập `demo@moonkage.vn` / `123456`.
2. Bảo đảm đã có địa chỉ và thêm sản phẩm vào giỏ.
3. Trong giỏ chọn `Tiến hành thanh toán`.
4. Chọn địa chỉ, tùy chọn nhập hóa đơn, rồi chọn `Thanh toán qua VNPay`.
5. Trình duyệt emulator mở trang Mock VNPay qua `10.0.2.2:8090`.
6. Chọn `Giả lập thành công` hoặc `Giả lập thất bại`, sau đó quay lại app.
7. App tự đọc trạng thái mới; thành công sẽ hiển thị số đơn đã tạo và giỏ hàng trở về rỗng.

## Tiêu chí hoàn thành

- [x] Checkout dùng toàn bộ cart, không có chọn một phần sản phẩm.
- [x] Dữ liệu địa chỉ khớp `CreateCheckoutRequest` của backend.
- [x] Invoice là tùy chọn và được validate theo backend.
- [x] Chỉ hỗ trợ VNPay; không hiển thị COD/MoMo/ZaloPay giả.
- [x] Không tin redirect trình duyệt để xác nhận thanh toán.
- [x] Hỗ trợ toàn bộ trạng thái checkout hiện tại.
- [x] Mock server hỗ trợ test thành công và thất bại.
- [x] Có test API contract riêng cho Phase 6.
- [ ] Chạy `flutter analyze` và toàn bộ `flutter test` sau khi giải phóng Flutter SDK lock.
