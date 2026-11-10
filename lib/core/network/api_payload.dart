/// Gateway services bọc mọi response công khai trong `ApiResponse<T>`:
/// `{status, code, message, data, timestamp}` (Software Design 5.1 quy tắc 8).
/// Trả về `data` khi có; nếu body không bọc (mock server, bản backend cũ) thì trả nguyên body.
Object? apiPayload(Object? body) {
  if (body is Map<String, Object?> && body.containsKey('data')) {
    return body['data'];
  }
  return body;
}
