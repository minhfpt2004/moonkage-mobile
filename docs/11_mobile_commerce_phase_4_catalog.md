# Phase 4 - Catalog sản phẩm

## Phạm vi

Thay màn danh mục placeholder bằng catalog thật từ catalog-service, dùng tỉnh giao hàng mặc định của Phase 3.

## Contract đã dùng

| Chức năng | Endpoint |
| --- | --- |
| Tìm kiếm và lọc | `GET /api/products` |
| Giá trị bộ lọc | `GET /api/products/facets` |
| Chi tiết sản phẩm | `GET /api/products/{productId}` |
| Đánh giá sản phẩm | `GET /api/products/{productId}/reviews` |
| Nhãn vỏ và nhân bánh | `GET /api/cake-attributes` |

`provinceCode` luôn được gửi khi lấy danh sách/chi tiết. App không dùng tên tỉnh thay cho mã hai chữ số.

## Đã triển khai

- Danh sách sản phẩm dạng grid mobile với:
  - ảnh hoặc placeholder khi backend không có ảnh;
  - thương hiệu, tên, giá, rating và trạng thái kho;
  - điều hướng sang chi tiết sản phẩm.
- Tìm kiếm debounce 450ms, không gọi API sau từng phím ngay lập tức.
- Facets động từ backend:
  - vỏ bánh;
  - vị nhân;
  - thương hiệu;
  - khoảng giá.
- Sắp xếp đúng contract: `rating`, `newest`, `price-asc`, `price-desc`.
- Phân trang bằng nút `Xem thêm sản phẩm`.
- Pull-to-refresh, loading, empty và error state.
- Chi tiết sản phẩm gồm giá, shop, giao hàng, tồn kho, quy cách, taxonomy, hạn dùng, mô tả và ngưỡng B2B.
- Danh sách đánh giá đọc từ catalog-service.
- Nút thêm giỏ hiện giữ điểm vào UI; ghi giỏ thật thuộc Phase 5.
- Mock server có sáu sản phẩm, facets, taxonomy và review để test độc lập.
- Test contract cho query, PageResponse, detail, facets và định dạng VND.

## Route mobile

- `/catalog`
- `/catalog/{productId}`

Route chi tiết nằm trong nhánh Danh mục nên vẫn giữ app shell.

## Cách test với mock server

Khởi động lại mock server:

```powershell
dart run tool/mock_server.dart
```

Chạy app:

```powershell
flutter run --dart-define-from-file=env/mock.json
```

Sau khi đăng nhập:

1. Mở tab `Danh mục`.
2. Tìm kiếm `thập cẩm` hoặc `đậu xanh`.
3. Mở bộ lọc và chọn vỏ/nhân/thương hiệu/khoảng giá.
4. Thay đổi cách sắp xếp.
5. Mở một sản phẩm để xem chi tiết và đánh giá.

## Tiêu chí hoàn thành

- [x] Catalog gửi `provinceCode` bắt buộc.
- [x] Mapping đúng `listPrice`, `crustCodes`, `fillingCodes`, `imageUrls` và rating.
- [x] Filter/sort/search chạy phía backend.
- [x] Detail parse một object, không parse nhầm thành list.
- [x] Reviews parse `PageResponse`.
- [x] Không hiển thị số lượng đã bán vì backend không cung cấp.
- [x] Mock server hỗ trợ test thủ công Phase 4.
- [ ] Chạy `flutter analyze` và toàn bộ `flutter test` sau khi giải phóng Flutter SDK lock.
