# Phase 5 - Giỏ hàng

## Phạm vi

Thay màn giỏ hàng placeholder bằng giỏ hàng phía server, dùng tỉnh giao hàng mặc định từ Phase 3 và sản phẩm từ Phase 4. Checkout chưa nằm trong phase này.

## Contract đã dùng

| Chức năng | Endpoint | Ý nghĩa số lượng |
| --- | --- | --- |
| Đọc giỏ hàng | `GET /api/carts/me?provinceCode={code}` | Backend tính lại khả năng giao và phí ship |
| Thêm sản phẩm | `POST /api/carts/me/items` | Cộng thêm vào số lượng hiện có |
| Đổi số lượng | `PATCH /api/carts/me/items/{itemId}` | Số lượng tuyệt đối mới |
| Xóa sản phẩm | `DELETE /api/carts/me/items/{itemId}` | Xóa một dòng giỏ hàng |

Giỏ hàng là dữ liệu phía server theo tài khoản. App không tự lưu một bản cart khác trong local storage để tránh lệch tồn kho, giá và phí giao hàng.

## Đã triển khai

- Thêm sản phẩm thật từ màn chi tiết, có bộ chọn số lượng.
- Giới hạn số lượng theo tồn kho và thấp hơn `quoteThreshold`; đơn lớn chuyển sang luồng báo giá ở phase sau.
- Không cho người bán tự mua sản phẩm của chính mình.
- Badge tổng số hộp trong giỏ trên thanh điều hướng.
- Giỏ hàng chia theo shop như response backend.
- Hiển thị tạm tính, phí giao từng shop và tổng thanh toán từ backend.
- Tăng, giảm và xóa sản phẩm; refresh lại toàn bộ cart sau mutation.
- Cảnh báo sản phẩm không còn khả dụng hoặc shop không giao được tới tỉnh đã chọn.
- Loading, empty, error và pull-to-refresh.
- Mock server lưu giỏ riêng theo tài khoản và kiểm tra tồn kho/ngưỡng báo giá.
- Bốn test contract cho GET, POST, PATCH và DELETE.

## Cách test với mock server

Khởi động lại mock server để nhận endpoint Phase 5:

```powershell
dart run tool/mock_server.dart
```

Ở terminal khác, chạy app:

```powershell
flutter run --dart-define-from-file=env/mock.json
```

Sau khi đăng nhập bằng `demo@moonkage.vn` / `123456`:

1. Mở `Danh mục`, chọn một sản phẩm.
2. Chọn số lượng rồi nhấn `Thêm vào giỏ hàng`.
3. Kiểm tra badge ở tab `Giỏ hàng`.
4. Mở giỏ, thử tăng/giảm số lượng và kéo xuống để refresh.
5. Xóa sản phẩm và xác nhận empty state xuất hiện.

Nút `Tiến hành thanh toán` hiện chỉ đánh dấu ranh giới sang Phase 6; chưa tạo checkout hoặc order.

## Tiêu chí hoàn thành

- [x] Cart luôn gửi `provinceCode` hiện tại.
- [x] POST dùng số lượng cộng thêm; PATCH dùng số lượng tuyệt đối.
- [x] Giá, phí ship và tổng tiền lấy từ response backend.
- [x] Cart được nhóm theo vendor và chặn checkout khi có nhóm không giao được/item không khả dụng.
- [x] Badge cập nhật sau khi thêm, sửa hoặc xóa.
- [x] Mock server hỗ trợ test thủ công đầy đủ CRUD cart.
- [x] Test API contract riêng cho Phase 5.
- [ ] Chạy `flutter analyze` và toàn bộ `flutter test` sau khi giải phóng Flutter SDK lock.
