// Mock server cho GĐ 1: thay identity-service khi web và đăng nhập chưa xong.
//
// Chạy:  dart run tool/mock_server.dart
// Mở http://localhost:8090 trên PC để lấy QR; app build với env/mock.json.
//
// Tài khoản: demo@moonkage.vn / 123456 và other@moonkage.vn / 123456.
//
// Giả lập (trạng thái giữ trong bộ nhớ, mất khi tắt):
// - POST /api/auth/register                 → tạo tài khoản, OTP luôn là 123456
// - POST /api/auth/verify-account           → kích hoạt tài khoản
// - POST /api/auth/login                    → LoginResponse
// - POST /api/auth/refresh-token            → đổi cặp access/refresh token
// - POST /api/auth/send-reset-password-otp  → OTP luôn là 123456
// - POST /api/auth/reset-password           → đặt mật khẩu mới
// - GET/PATCH /api/accounts/me[/profile]    → xem/sửa tên hồ sơ
// - GET/POST/PUT/DELETE /api/addresses/**   → sổ địa chỉ giao hàng
// - GET /api/products[/facets|/{id}]        → catalog, filter và chi tiết
// - GET /api/products/{id}/reviews          → đánh giá sản phẩm
// - GET /api/cake-attributes                → nhãn vỏ và nhân bánh
// - GET/POST/PATCH/DELETE /api/carts/me/**  → giỏ hàng lưu theo tài khoản
// - POST/GET /api/checkouts/**              → giữ hàng, link thanh toán và trạng thái
// - GET/PATCH /api/orders/**                → danh sách, chi tiết, tiến trình, xác nhận nhận
// - GET  /api/nfc/sessions/{id}             → {sessionId, status: PENDING|VERIFIED, expiresAt}
// - POST /api/nfc/sessions/{id}/card        → VERIFIED hoặc REJECTED (gửi một lần, D-20)
// Từ chối: SESSION_EXPIRED (quá 5 phút), SESSION_USED, SESSION_NOT_OWNED, LOCKED,
// BAD_FORMAT và ID_ALREADY_LINKED (tính một lần thử; 5 lần → khóa 15 phút).
// Không in nội dung thẻ ra console.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:jose/jose.dart';
import 'package:moonkage_verify/core/network/api_endpoints.dart';
import 'package:moonkage_verify/features/verify/data/demo_nfc_key.dart';

const _port = 8090;
const _maxAttempts = 5;
const _sessionTtl = Duration(minutes: 5);
const _lockDuration = Duration(minutes: 15);
const _api = ApiEndpoints.apiRoot;

final _sessionPath = RegExp('^$_api/nfc/sessions/([A-Za-z0-9_-]+)/card\$');
final _random = Random.secure();

final class _User {
  _User(this.email, this.phone, this.fullName, {String? password, this.verified = true})
    : password = password ?? _password;

  final String email;
  final String phone;
  String fullName;
  final String accountId = _randomHex(8);
  String password;
  bool verified;
  String otp = '123456';
  var failedAttempts = 0;
  DateTime? lockedUntil;
}

final class _Session {
  _Session(this.owner, this.createdAt);

  final _User owner;
  final DateTime createdAt;
  Map<String, Object?>? pendingCard;
  var used = false;

  DateTime get expiresAt => createdAt.add(_sessionTtl);
}

final class _MockAddress {
  _MockAddress.fromBody(Map<String, Object?> body)
    : id = _randomHex(8),
      recipientName = body['recipientName']! as String,
      recipientPhone = body['recipientPhone']! as String,
      provinceCode = body['provinceCode']! as String,
      provinceName = body['provinceName']! as String,
      wardName = body['wardName']! as String,
      detail = body['detail']! as String,
      label = body['label'] is String ? body['label']! as String : '',
      isDefault = body['isDefault'] == true;

  final String id;
  String recipientName;
  String recipientPhone;
  String provinceCode;
  String provinceName;
  String wardName;
  String detail;
  String label;
  bool isDefault;

  void update(Map<String, Object?> body) {
    recipientName = body['recipientName']! as String;
    recipientPhone = body['recipientPhone']! as String;
    provinceCode = body['provinceCode']! as String;
    provinceName = body['provinceName']! as String;
    wardName = body['wardName']! as String;
    detail = body['detail']! as String;
    label = body['label'] is String ? body['label']! as String : '';
    if (body['isDefault'] is bool) isDefault = body['isDefault']! as bool;
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'recipientName': recipientName,
    'recipientPhone': recipientPhone,
    'provinceCode': provinceCode,
    'provinceName': provinceName,
    'wardName': wardName,
    'detail': detail,
    'fullAddress': '$detail, $wardName, $provinceName',
    'areaCode': provinceCode,
    'label': label,
    'isDefault': isDefault,
    'createdAt': DateTime.now().toUtc().toIso8601String(),
    'updatedAt': DateTime.now().toUtc().toIso8601String(),
  };
}

final class _MockCartItem {
  _MockCartItem({required this.productId, required this.quantity}) : id = _randomHex(8);

  final String id;
  final String productId;
  int quantity;
}

final class _MockCheckout {
  _MockCheckout({
    required this.owner,
    required this.totalAmount,
    required this.delivery,
  }) : id = _randomHex(8),
       paymentId = _randomHex(8),
       expiresAt = DateTime.now().add(const Duration(minutes: 10));

  final String id;
  final String paymentId;
  final _User owner;
  final int totalAmount;
  final Map<String, Object?> delivery;
  final DateTime expiresAt;
  String status = 'PENDING_PAYMENT';
  List<String> orderIds = const [];
}

final class _MockOrder {
  _MockOrder({required this.owner, required this.data, required this.progress});

  final _User owner;
  final Map<String, Object?> data;
  final List<Map<String, Object?>> progress;

  String get id => data['id']! as String;
  String get status => data['status']! as String;
}

final class _MockQuoteRequest {
  _MockQuoteRequest({
    required this.owner,
    required this.data,
    required this.invitations,
    required this.quotes,
  });

  final _User owner;
  final Map<String, Object?> data;
  final List<Map<String, Object?>> invitations;
  final List<Map<String, Object?>> quotes;

  String get id => data['id']! as String;
}

final class _MockConversation {
  _MockConversation({
    required this.id,
    required this.buyer,
    required this.vendorId,
    required this.vendorName,
  });

  final String id;
  final _User buyer;
  final String vendorId;
  final String vendorName;
  final List<Map<String, Object?>> messages = [];
  var buyerReadSequence = 0;
}

final _users = [
  _User('demo@moonkage.vn', '0900000001', 'Nguyen Van Demo'),
  _User('other@moonkage.vn', '0900000002', 'Tran Thi Khac'),
];
const _password = '123456';

final _tokens = <String, _User>{};
final _refreshTokens = <String, _User>{};
final _sessions = <String, _Session>{};
final _linkedIds = <String, _User>{};
final _addresses = <String, List<_MockAddress>>{};
final _carts = <String, List<_MockCartItem>>{};
final _checkouts = <String, _MockCheckout>{};
final _orders = <String, _MockOrder>{};
final _orderReviews = <String, List<Map<String, Object?>>>{};
final _quoteRequests = <String, _MockQuoteRequest>{};
final _notifications = <String, List<Map<String, Object?>>>{};
final _conversations = <String, _MockConversation>{};
final _suppliers = <Map<String, Object?>>[
  {
    'vendorId': 'vendor-nguyet-vien',
    'businessName': 'Nguyệt Viên Hoàng Gia',
    'ordersOnly': false,
    'supplySource': 'Xưởng bánh thủ công Hà Nội',
    'minQty': 30,
    'leadTimeDays': 10,
    'customCapabilities': ['BAG', 'CARD', 'STICKER', 'TEMPLATE_BOX'],
    'deliveryAreas': ['01', '79'],
    'earlyBirdOffer': 'Giảm 5% cho đơn trước 30 ngày',
    'refPriceTiers': null,
    'isOwn': false,
  },
  {
    'vendorId': 'vendor-trang-thu',
    'businessName': 'Trăng Thu An Nhiên',
    'ordersOnly': false,
    'supplySource': 'Nguyên liệu Việt Nam',
    'minQty': 50,
    'leadTimeDays': 14,
    'customCapabilities': ['BAG', 'CARD', 'STICKER'],
    'deliveryAreas': ['01', '48', '79'],
    'earlyBirdOffer': '',
    'refPriceTiers': null,
    'isOwn': false,
  },
];
final _products = <Map<String, Object?>>[
  _mockProduct(
    id: 'banh-thap-cam',
    name: 'Bánh Nướng Thập Cẩm Hoàng Gia',
    brand: 'Nguyệt Viên',
    price: 185000,
    crust: 'vo-nuong',
    filling: 'thap-cam',
    rating: 4.9,
    reviews: 128,
  ),
  _mockProduct(
    id: 'banh-dau-xanh',
    name: 'Bánh Nướng Đậu Xanh Trứng Muối',
    brand: 'Nguyệt Viên',
    price: 145000,
    crust: 'vo-nuong',
    filling: 'dau-xanh',
    rating: 4.8,
    reviews: 96,
  ),
  _mockProduct(
    id: 'banh-deo-sen',
    name: 'Bánh Dẻo Hạt Sen Thanh Nhã',
    brand: 'Trăng Thu',
    price: 125000,
    crust: 'vo-deo',
    filling: 'hat-sen',
    rating: 4.7,
    reviews: 54,
  ),
  _mockProduct(
    id: 'banh-tra-xanh',
    name: 'Bánh Lạnh Trà Xanh Mochi',
    brand: 'Lam Nguyệt',
    price: 165000,
    crust: 'vo-lanh',
    filling: 'tra-xanh',
    rating: 4.6,
    reviews: 43,
  ),
  _mockProduct(
    id: 'banh-sau-rieng',
    name: 'Bánh Nướng Sầu Riêng Hạt Sen',
    brand: 'Phúc Nguyệt',
    price: 195000,
    crust: 'vo-nuong',
    filling: 'sau-rieng',
    rating: 4.5,
    reviews: 31,
  ),
  _mockProduct(
    id: 'hop-tu-quy',
    name: 'Hộp Quà Tứ Quý Đoàn Viên',
    brand: 'Nguyệt Viên',
    price: 720000,
    crust: 'vo-nuong',
    filling: 'thap-cam',
    rating: 5,
    reviews: 22,
    pieces: 4,
  ),
];

Future<void> main() async {
  final server = await HttpServer.bind(InternetAddress.anyIPv4, _port);
  stdout
    ..writeln('Mock server đang chạy ở cổng $_port.')
    ..writeln('Mở http://localhost:$_port trên PC để lấy QR.')
    ..writeln('Tài khoản: ${_users.map((u) => u.email).join(', ')} — mật khẩu $_password');
  await for (final request in server) {
    try {
      await _handle(request);
    } on Exception catch (e) {
      stderr.writeln('Lỗi xử lý ${request.method} ${request.uri.path}: ${e.runtimeType}');
      await _error(request, HttpStatus.internalServerError, 'Lỗi mock server');
    }
  }
}

Future<void> _handle(HttpRequest request) async {
  final path = request.uri.path;
  final method = request.method;

  if (path.startsWith('/mock-pay/')) return _handleMockPayment(request);
  if (path.startsWith('/mock-quote-pay/')) return _handleMockQuotePayment(request);
  if (method == 'GET' && path == '/') {
    return _send(request, HttpStatus.ok, ContentType.html, _page());
  }
  if (method == 'POST' && path == '/reset') {
    _reset();
    request.response
      ..statusCode = HttpStatus.seeOther
      ..headers.set(HttpHeaders.locationHeader, '/');
    return request.response.close();
  }
  if (method == 'POST' && path == '/advance-orders') {
    _advanceOrders();
    request.response
      ..statusCode = HttpStatus.seeOther
      ..headers.set(HttpHeaders.locationHeader, '/');
    return request.response.close();
  }
  if (method == 'POST' && path == ApiEndpoints.login) return _login(request);
  if (method == 'POST' && path == ApiEndpoints.register) return _register(request);
  if (method == 'POST' && path == ApiEndpoints.refreshToken) return _refresh(request);
  if (method == 'POST' && path == ApiEndpoints.sendVerifyAccountOtp) {
    return _sendOtp(request);
  }
  if (method == 'POST' && path == ApiEndpoints.verifyAccount) return _verifyAccount(request);
  if (method == 'POST' && path == ApiEndpoints.sendResetPasswordOtp) {
    return _sendOtp(request);
  }
  if (method == 'POST' && path == ApiEndpoints.resetPassword) return _resetPassword(request);

  if (path == ApiEndpoints.accountMe || path == ApiEndpoints.accountProfile) {
    return _handleAccount(request);
  }
  if (path == ApiEndpoints.addresses || path.startsWith('${ApiEndpoints.addresses}/')) {
    return _handleAddresses(request);
  }
  if (path == ApiEndpoints.cart ||
      path == ApiEndpoints.cartItems ||
      path.startsWith('${ApiEndpoints.cartItems}/')) {
    return _handleCart(request);
  }
  if (path == ApiEndpoints.checkouts || path.startsWith('${ApiEndpoints.checkouts}/')) {
    return _handleCheckout(request);
  }
  if (path == ApiEndpoints.orders || path.startsWith('${ApiEndpoints.orders}/')) {
    return _handleOrders(request);
  }
  if (path == ApiEndpoints.suppliers || path.startsWith('${ApiEndpoints.suppliers}/')) {
    return _handleSuppliers(request);
  }
  if (path == ApiEndpoints.quoteRequests || path.startsWith('${ApiEndpoints.quoteRequests}/')) {
    return _handleQuoteRequests(request);
  }
  if (path == ApiEndpoints.notifications || path.startsWith('${ApiEndpoints.notifications}/')) {
    return _handleNotifications(request);
  }
  if (path == ApiEndpoints.conversations || path.startsWith('${ApiEndpoints.conversations}/')) {
    return _handleChat(request);
  }
  if (method == 'GET' && path == ApiEndpoints.cakeAttributes) {
    return _json(request, _cakeAttributes);
  }
  if (method == 'GET' && path == ApiEndpoints.productFacets) {
    return _catalogFacets(request);
  }
  if (method == 'GET' && path == ApiEndpoints.products) return _catalogSearch(request);
  if (method == 'GET' && path.startsWith('${ApiEndpoints.products}/')) {
    return _catalogDetail(request);
  }

  final getSessionMatch = RegExp('^$_api/nfc/sessions/([A-Za-z0-9_-]+)\$').firstMatch(path);
  if (method == 'GET' && getSessionMatch != null) {
    final user = _authenticate(request);
    if (user == null) return _error(request, HttpStatus.unauthorized, 'Token thiếu hoặc hết hạn');
    final sessionId = getSessionMatch.group(1)!;
    final session = _sessions[sessionId];
    if (session == null || DateTime.now().isAfter(session.expiresAt)) {
      return _error(request, HttpStatus.gone, 'Phiên không tồn tại hoặc đã hết hạn');
    }
    if (session.owner.accountId != user.accountId) {
      return _error(request, HttpStatus.forbidden, 'Phiên thuộc tài khoản khác');
    }
    return _send(
      request,
      HttpStatus.ok,
      ContentType.json,
      jsonEncode({
        'sessionId': sessionId,
        // giống identity-service: phiên đã dùng vẫn đọc được, trả VERIFIED
        'status': session.used ? 'VERIFIED' : 'PENDING',
        'expiresAt': session.expiresAt.toIso8601String(),
      }),
    );
  }

  final match = _sessionPath.firstMatch(path);
  if (match == null) return _error(request, HttpStatus.notFound, 'Không tìm thấy đường dẫn');

  final user = _authenticate(request);
  if (user == null) return _error(request, HttpStatus.unauthorized, 'Token thiếu hoặc hết hạn');
  final sessionId = match.group(1)!;
  if (method != 'POST') {
    return _error(request, HttpStatus.methodNotAllowed, 'Không hỗ trợ $method');
  }
  final result = await _submitCard(user, sessionId, await _readJson(request));
  _log(sessionId, 'card → ${result['status']} ${result['reasonCode'] ?? ''}');
  return _send(request, HttpStatus.ok, ContentType.json, jsonEncode(result));
}

Future<void> _login(HttpRequest request) async {
  final body = await _readJson(request);
  final username = body?['username'];
  final password = body?['password'];
  final user = _users.where((u) => u.email == username || u.phone == username).firstOrNull;
  if (user == null || password != user.password) {
    return _error(request, HttpStatus.unauthorized, 'Thông tin đăng nhập không đúng');
  }
  if (!user.verified) {
    return _error(request, HttpStatus.forbidden, 'Tài khoản chưa được kích hoạt.');
  }
  return _sendLoginResponse(request, user);
}

Future<void> _sendLoginResponse(HttpRequest request, _User user) async {
  final token = _randomHex(24);
  final refreshToken = _randomHex(24);
  _tokens[token] = user;
  _refreshTokens[refreshToken] = user;
  stdout.writeln('[${_time()}] đăng nhập: ${user.email}');
  return _send(
    request,
    HttpStatus.ok,
    ContentType.json,
    jsonEncode({
      'token': token,
      'refreshToken': refreshToken,
      'accountId': user.accountId,
      'userId': user.accountId,
      'email': user.email,
      'phoneNumber': user.phone,
      'fullName': user.fullName,
      'role': 'MEMBER',
      'vendorStatus': 'NONE',
      'vendorId': null,
    }),
  );
}

Future<void> _register(HttpRequest request) async {
  final body = await _readJson(request);
  final email = body?['email'];
  final fullName = body?['fullName'];
  final password = body?['password'];
  final phone = body?['phoneNumber'];
  if (email is! String || fullName is! String || password is! String || password.length < 8) {
    return _error(request, HttpStatus.badRequest, 'Thông tin đăng ký không hợp lệ');
  }
  if (_users.any((user) => user.email.toLowerCase() == email.toLowerCase())) {
    return _error(request, HttpStatus.conflict, 'Email đã được sử dụng');
  }
  final user = _User(
    email.trim().toLowerCase(),
    phone is String ? phone.trim() : '',
    fullName.trim(),
    password: password,
    verified: false,
  );
  _users.add(user);
  stdout.writeln('[${_time()}] OTP mock cho ${user.email}: ${user.otp}');
  return _json(request, {
    'id': user.accountId,
    'email': user.email,
    'phoneNumber': user.phone,
    'verified': false,
    'otpSent': true,
  });
}

Future<void> _refresh(HttpRequest request) async {
  final body = await _readJson(request);
  final refreshToken = body?['refreshToken'];
  final user = refreshToken is String ? _refreshTokens.remove(refreshToken) : null;
  if (user == null) {
    return _error(request, HttpStatus.unauthorized, 'Refresh token không hợp lệ');
  }
  return _sendLoginResponse(request, user);
}

Future<void> _sendOtp(HttpRequest request) async {
  final body = await _readJson(request);
  final email = body?['email'];
  final user = email is String
      ? _users.where((candidate) => candidate.email == email.trim().toLowerCase()).firstOrNull
      : null;
  if (user != null) stdout.writeln('[${_time()}] OTP mock cho ${user.email}: ${user.otp}');
  return _json(request, null);
}

Future<void> _verifyAccount(HttpRequest request) async {
  final body = await _readJson(request);
  final email = body?['email'];
  final otp = body?['otp'];
  final user = email is String
      ? _users.where((candidate) => candidate.email == email.trim().toLowerCase()).firstOrNull
      : null;
  if (user == null || otp != user.otp) {
    return _error(request, HttpStatus.badRequest, 'Mã OTP không đúng hoặc đã hết hạn');
  }
  user.verified = true;
  return _json(request, {
    'id': user.accountId,
    'email': user.email,
    'phoneNumber': user.phone,
    'verified': true,
  });
}

Future<void> _resetPassword(HttpRequest request) async {
  final body = await _readJson(request);
  final email = body?['email'];
  final otp = body?['otp'];
  final password = body?['newPassword'];
  final user = email is String
      ? _users.where((candidate) => candidate.email == email.trim().toLowerCase()).firstOrNull
      : null;
  if (user == null || otp != user.otp || password is! String || password.length < 8) {
    return _error(request, HttpStatus.badRequest, 'OTP hoặc mật khẩu mới không hợp lệ');
  }
  user.password = password;
  return _json(request, null);
}

Future<void> _json(
  HttpRequest request,
  Object? data, {
  int status = HttpStatus.ok,
}) => _send(request, status, ContentType.json, jsonEncode({'data': data}));

Map<String, Object?> _mockProduct({
  required String id,
  required String name,
  required String brand,
  required int price,
  required String crust,
  required String filling,
  required double rating,
  required int reviews,
  int pieces = 1,
}) => {
  'id': id,
  'vendorId': 'vendor-nguyet-vien',
  'vendorName': 'Tiệm bánh Nguyệt Viên',
  'provinceCode': '01',
  'name': name,
  'description': 'Bánh trung thu được tuyển chọn từ nguyên liệu chất lượng, vị ngọt thanh và đóng gói trang trọng.',
  'crustCodes': [crust],
  'fillingCodes': [filling],
  'brand': brand,
  'origin': 'Việt Nam',
  'piecesPerBox': pieces,
  'listPrice': price,
  'stock': 80,
  'inStock': true,
  'expiryDate': '2027-12-31',
  'deliveryLabel': 'NATIONWIDE',
  'quoteThreshold': 50,
  'status': 'ON_SALE',
  'imageKeys': <String>[],
  'imageUrls': <String>[],
  'priceTiers': null,
  'ratingAvg': rating,
  'ratingCount': reviews,
  'vendorAcceptsOrders': true,
  'isOwn': false,
  'updatedAt': DateTime.now().toUtc().toIso8601String(),
};

const _cakeAttributes = <Map<String, Object?>>[
  {
    'id': 'c1',
    'group': 'CRUST',
    'code': 'vo-nuong',
    'label': 'Vỏ nướng',
    'sortOrder': 1,
    'active': true,
  },
  {
    'id': 'c2',
    'group': 'CRUST',
    'code': 'vo-deo',
    'label': 'Vỏ dẻo',
    'sortOrder': 2,
    'active': true,
  },
  {
    'id': 'c3',
    'group': 'CRUST',
    'code': 'vo-lanh',
    'label': 'Vỏ lạnh',
    'sortOrder': 3,
    'active': true,
  },
  {
    'id': 'f1',
    'group': 'FILLING',
    'code': 'thap-cam',
    'label': 'Thập cẩm',
    'sortOrder': 1,
    'active': true,
  },
  {
    'id': 'f2',
    'group': 'FILLING',
    'code': 'dau-xanh',
    'label': 'Đậu xanh',
    'sortOrder': 2,
    'active': true,
  },
  {
    'id': 'f3',
    'group': 'FILLING',
    'code': 'hat-sen',
    'label': 'Hạt sen',
    'sortOrder': 3,
    'active': true,
  },
  {
    'id': 'f4',
    'group': 'FILLING',
    'code': 'tra-xanh',
    'label': 'Trà xanh',
    'sortOrder': 4,
    'active': true,
  },
  {
    'id': 'f5',
    'group': 'FILLING',
    'code': 'sau-rieng',
    'label': 'Sầu riêng',
    'sortOrder': 5,
    'active': true,
  },
];

Future<void> _catalogSearch(HttpRequest request) async {
  final query = request.uri.queryParameters;
  var products = _catalogBase(request);
  final brands = _multiQuery(request, 'brand');
  final crusts = _multiQuery(request, 'crust');
  final fillings = _multiQuery(request, 'filling');
  final priceMin = int.tryParse(query['priceMin'] ?? '');
  final priceMax = int.tryParse(query['priceMax'] ?? '');
  if (brands.isNotEmpty)
    products = products.where((item) => brands.contains(item['brand'])).toList();
  if (crusts.isNotEmpty) {
    products = products
        .where((item) => (item['crustCodes']! as List).any(crusts.contains))
        .toList();
  }
  if (fillings.isNotEmpty) {
    products = products
        .where((item) => (item['fillingCodes']! as List).any(fillings.contains))
        .toList();
  }
  if (priceMin != null) {
    products = products.where((item) => (item['listPrice']! as int) >= priceMin).toList();
  }
  if (priceMax != null) {
    products = products.where((item) => (item['listPrice']! as int) <= priceMax).toList();
  }
  switch (query['sort']) {
    case 'price-asc':
      products.sort((a, b) => (a['listPrice']! as int).compareTo(b['listPrice']! as int));
    case 'price-desc':
      products.sort((a, b) => (b['listPrice']! as int).compareTo(a['listPrice']! as int));
    case 'newest':
      products = products.reversed.toList();
    default:
      products.sort((a, b) => (b['ratingAvg']! as double).compareTo(a['ratingAvg']! as double));
  }
  final page = int.tryParse(query['page'] ?? '') ?? 0;
  final size = int.tryParse(query['size'] ?? '') ?? 20;
  final start = page * size;
  final content = start >= products.length
      ? <Map<String, Object?>>[]
      : products.sublist(start, min(start + size, products.length));
  return _json(request, {
    'content': content,
    'page': page,
    'size': size,
    'totalElements': products.length,
    'totalPages': products.isEmpty ? 0 : (products.length / size).ceil(),
  });
}

Future<void> _catalogFacets(HttpRequest request) async {
  final products = _catalogBase(request);
  List<Map<String, Object?>> counts(String field) {
    final values = <String, int>{};
    for (final product in products) {
      final raw = product[field];
      final items = raw is List ? raw.whereType<String>() : [raw].whereType<String>();
      for (final item in items) {
        values[item] = (values[item] ?? 0) + 1;
      }
    }
    return [
      for (final entry in values.entries) {'value': entry.key, 'count': entry.value},
    ];
  }

  final prices = products.map((item) => item['listPrice']! as int).toList();
  return _json(request, {
    'crusts': counts('crustCodes'),
    'fillings': counts('fillingCodes'),
    'brands': counts('brand'),
    'vendors': [
      {
        'vendorId': 'vendor-nguyet-vien',
        'vendorName': 'Tiệm bánh Nguyệt Viên',
        'count': products.length,
      },
    ],
    'priceMin': prices.isEmpty ? null : prices.reduce(min),
    'priceMax': prices.isEmpty ? null : prices.reduce(max),
  });
}

List<Map<String, Object?>> _catalogBase(HttpRequest request) {
  final text = (request.uri.queryParameters['q'] ?? '').trim().toLowerCase();
  return _products
      .where((product) {
        if (text.isEmpty) return true;
        return '${product['name']} ${product['brand']} ${product['description']}'
            .toLowerCase()
            .contains(text);
      })
      .map((item) => Map<String, Object?>.from(item))
      .toList();
}

Set<String> _multiQuery(HttpRequest request, String key) =>
    request.uri.queryParametersAll[key]
        ?.expand((value) => value.split(','))
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet() ??
    {};

Future<void> _catalogDetail(HttpRequest request) async {
  final reviewMatch = RegExp('^${ApiEndpoints.products}/([^/]+)/reviews\$')
      .firstMatch(request.uri.path);
  if (reviewMatch != null) {
    final productId = reviewMatch.group(1)!;
    final product = _products.where((item) => item['id'] == productId).firstOrNull;
    if (product == null) return _error(request, HttpStatus.notFound, 'Không tìm thấy sản phẩm');
    return _json(request, {
      'content': [
        {
          'reviewId': 'review-$productId-1',
          'rating': 5,
          'content': 'Bánh ngon, hộp đẹp và giao hàng cẩn thận.',
          'createdAt': DateTime.now().subtract(const Duration(days: 3)).toUtc().toIso8601String(),
        },
      ],
      'page': 0,
      'size': 20,
      'totalElements': 1,
      'totalPages': 1,
    });
  }
  final detailMatch = RegExp('^${ApiEndpoints.products}/([^/]+)\$').firstMatch(request.uri.path);
  final productId = detailMatch?.group(1);
  final product = _products.where((item) => item['id'] == productId).firstOrNull;
  if (product == null) return _error(request, HttpStatus.notFound, 'Không tìm thấy sản phẩm');
  return _json(request, product);
}

Future<void> _handleCart(HttpRequest request) async {
  final user = _authenticate(request);
  if (user == null) return _error(request, HttpStatus.unauthorized, 'Token không hợp lệ');
  final items = _carts.putIfAbsent(user.accountId, () => []);
  final path = request.uri.path;

  if (path == ApiEndpoints.cart && request.method == 'GET') {
    final provinceCode = request.uri.queryParameters['provinceCode'];
    if (provinceCode == null || provinceCode.trim().isEmpty) {
      return _error(request, HttpStatus.badRequest, 'Thiếu mã tỉnh giao hàng');
    }
    return _json(request, _cartJson(items, provinceCode));
  }

  if (path == ApiEndpoints.cartItems && request.method == 'POST') {
    final body = await _readJson(request);
    final productId = body?['productId'];
    final quantity = body?['quantity'];
    if (productId is! String || quantity is! int || quantity < 1) {
      return _error(request, HttpStatus.badRequest, 'Sản phẩm hoặc số lượng không hợp lệ');
    }
    final product = _findProduct(productId);
    if (product == null) {
      return _error(request, HttpStatus.notFound, 'Không tìm thấy sản phẩm');
    }
    final existing = items.where((item) => item.productId == productId).firstOrNull;
    final nextQuantity = (existing?.quantity ?? 0) + quantity;
    if (!_validCartQuantity(product, nextQuantity)) {
      return _error(request, HttpStatus.conflict, 'Số lượng vượt tồn kho hoặc cần yêu cầu báo giá');
    }
    final item = existing ?? _MockCartItem(productId: productId, quantity: 0);
    if (existing == null) items.add(item);
    item.quantity = nextQuantity;
    return _json(request, _cartLineJson(item, product));
  }

  final match = RegExp('^${ApiEndpoints.cartItems}/([^/]+)\$').firstMatch(path);
  final itemId = match?.group(1);
  final index = items.indexWhere((item) => item.id == itemId);
  if (index < 0) return _error(request, HttpStatus.notFound, 'Không tìm thấy sản phẩm trong giỏ');
  final item = items[index];
  final product = _findProduct(item.productId);

  if (request.method == 'PATCH') {
    final body = await _readJson(request);
    final quantity = body?['quantity'];
    if (product == null || quantity is! int || !_validCartQuantity(product, quantity)) {
      return _error(request, HttpStatus.conflict, 'Số lượng vượt tồn kho hoặc cần yêu cầu báo giá');
    }
    item.quantity = quantity;
    return _json(request, _cartLineJson(item, product));
  }
  if (request.method == 'DELETE') {
    items.removeAt(index);
    request.response.statusCode = HttpStatus.noContent;
    return request.response.close();
  }
  return _error(request, HttpStatus.methodNotAllowed, 'Không hỗ trợ phương thức');
}

Map<String, Object?> _cartJson(List<_MockCartItem> items, String provinceCode) {
  final byVendor = <String, List<_MockCartItem>>{};
  for (final item in items) {
    final product = _findProduct(item.productId);
    final vendorId = product?['vendorId'] as String? ?? 'unavailable';
    byVendor.putIfAbsent(vendorId, () => []).add(item);
  }
  final groups = <Map<String, Object?>>[];
  var totalAmount = 0;
  for (final entry in byVendor.entries) {
    final product = _findProduct(entry.value.first.productId);
    final lines = entry.value.map((item) {
      final current = _findProduct(item.productId);
      return _cartLineJson(item, current);
    }).toList();
    final subtotal = lines.fold<int>(
      0,
      (sum, line) => sum + (line['unitPrice']! as int) * (line['quantity']! as int),
    );
    final local = provinceCode == (product?['provinceCode'] as String? ?? '');
    final shippingFee = local ? 25000 : 45000;
    totalAmount += subtotal + shippingFee;
    groups.add({
      'vendorId': entry.key,
      'vendorName': product?['vendorName'] as String? ?? 'Hiệu bánh không còn hoạt động',
      'deliverable': true,
      'interprovince': !local,
      'shippingFee': shippingFee,
      'subtotal': subtotal,
      'items': lines,
    });
  }
  return {'provinceCode': provinceCode, 'groups': groups, 'totalAmount': totalAmount};
}

Map<String, Object?> _cartLineJson(
  _MockCartItem item,
  Map<String, Object?>? product,
) => {
  'itemId': item.id,
  'productId': item.productId,
  'productName': product?['name'] as String? ?? '',
  'unitPrice': product?['listPrice'] as int? ?? 0,
  'quantity': item.quantity,
  'available': product != null && product['inStock'] == true,
};

Map<String, Object?>? _findProduct(String productId) =>
    _products.where((product) => product['id'] == productId).firstOrNull;

bool _validCartQuantity(Map<String, Object?> product, int quantity) {
  final stock = product['stock']! as int;
  final quoteThreshold = product['quoteThreshold'] as int?;
  return quantity > 0 && quantity <= stock && (quoteThreshold == null || quantity < quoteThreshold);
}

Future<void> _handleCheckout(HttpRequest request) async {
  final user = _authenticate(request);
  if (user == null) return _error(request, HttpStatus.unauthorized, 'Token không hợp lệ');
  final path = request.uri.path;

  if (path == ApiEndpoints.checkouts && request.method == 'POST') {
    final body = await _readJson(request);
    if (!_validCheckoutBody(body)) {
      return _error(request, HttpStatus.badRequest, 'Thông tin nhận hàng không hợp lệ');
    }
    final items = _carts[user.accountId] ?? const <_MockCartItem>[];
    if (items.isEmpty) return _error(request, HttpStatus.conflict, 'Giỏ hàng đang trống');
    final provinceCode = body!['provinceCode']! as String;
    final cart = _cartJson(items, provinceCode);
    final checkout = _MockCheckout(
      owner: user,
      totalAmount: cart['totalAmount']! as int,
      delivery: Map<String, Object?>.from(body),
    );
    _checkouts[checkout.id] = checkout;
    return _json(request, {
      'checkoutId': checkout.id,
      'paymentId': checkout.paymentId,
      'paymentUrl': 'http://10.0.2.2:$_port/mock-pay/${checkout.id}',
      'totalAmount': checkout.totalAmount,
      'expiresAt': checkout.expiresAt.toUtc().toIso8601String(),
    });
  }

  final match = RegExp('^${ApiEndpoints.checkouts}/([^/]+)\$').firstMatch(path);
  final checkout = _checkouts[match?.group(1)];
  if (checkout == null || checkout.owner != user) {
    return _error(request, HttpStatus.notFound, 'Không tìm thấy checkout');
  }
  if (request.method != 'GET') {
    return _error(request, HttpStatus.methodNotAllowed, 'Không hỗ trợ phương thức');
  }
  if (checkout.status == 'PENDING_PAYMENT' && DateTime.now().isAfter(checkout.expiresAt)) {
    checkout.status = 'EXPIRED';
  }
  return _json(request, _checkoutJson(checkout));
}

Future<void> _handleMockPayment(HttpRequest request) async {
  final match = RegExp(r'^/mock-pay/([^/]+)(?:/(success|failed))?$').firstMatch(request.uri.path);
  final checkout = _checkouts[match?.group(1)];
  if (checkout == null) {
    return _error(request, HttpStatus.notFound, 'Không tìm thấy phiên thanh toán');
  }
  final action = match?.group(2);
  if (request.method == 'POST' && action != null && checkout.status == 'PENDING_PAYMENT') {
    if (action == 'success') {
      checkout
        ..status = 'SUCCEEDED'
        ..orderIds = _createOrders(checkout);
      _carts[checkout.owner.accountId]?.clear();
    } else {
      checkout.status = 'FAILED';
    }
  } else if (request.method != 'GET') {
    return _error(request, HttpStatus.methodNotAllowed, 'Không hỗ trợ phương thức');
  }
  return _send(request, HttpStatus.ok, ContentType.html, _mockPaymentPage(checkout));
}

bool _validCheckoutBody(Map<String, Object?>? body) {
  if (body == null) return false;
  final name = body['recipientName'];
  final phone = body['recipientPhone'];
  final province = body['provinceCode'];
  final address = body['addressDetail'];
  if (name is! String || name.trim().isEmpty || name.length > 100) return false;
  if (phone is! String || !RegExp(r'^0\d{9}$').hasMatch(phone)) return false;
  if (province is! String || !RegExp(r'^\d{2}$').hasMatch(province)) return false;
  if (address is! String || address.trim().isEmpty || address.length > 255) return false;
  final invoice = body['invoiceInfo'];
  if (invoice == null) return true;
  if (invoice is! Map) return false;
  final values = invoice.map((key, value) => MapEntry(key.toString(), value));
  final taxCode = values['taxCode'];
  final email = values['email'];
  return values['name'] is String &&
      (values['name']! as String).trim().isNotEmpty &&
      taxCode is String &&
      RegExp(r'^(\d{10}(-\d{3})?|\d{12})$').hasMatch(taxCode) &&
      values['address'] is String &&
      (values['address']! as String).trim().isNotEmpty &&
      email is String &&
      email.contains('@');
}

Map<String, Object?> _checkoutJson(_MockCheckout checkout) => {
  'checkoutId': checkout.id,
  'status': checkout.status,
  'totalAmount': checkout.totalAmount,
  'paymentId': checkout.paymentId,
  'expiresAt': checkout.expiresAt.toUtc().toIso8601String(),
  'orderIds': checkout.orderIds,
};

List<String> _createOrders(_MockCheckout checkout) {
  final items = _carts[checkout.owner.accountId] ?? const <_MockCartItem>[];
  final provinceCode = checkout.delivery['provinceCode']! as String;
  final cart = _cartJson(items, provinceCode);
  final groups = cart['groups']! as List<Map<String, Object?>>;
  final created = <String>[];
  for (var index = 0; index < groups.length; index++) {
    final group = groups[index];
    final id = 'order-${checkout.id}-${index + 1}';
    final now = DateTime.now().toUtc();
    final lines = (group['items']! as List<Map<String, Object?>>)
        .map(
          (line) => {
            'productId': line['productId'],
            'productName': line['productName'],
            'imageUrl': null,
            'unitPrice': line['unitPrice'],
            'quantity': line['quantity'],
            'subtotal': (line['unitPrice']! as int) * (line['quantity']! as int),
          },
        )
        .toList();
    final order = _MockOrder(
      owner: checkout.owner,
      data: {
        'id': id,
        'kind': 'BUY_NOW',
        'status': 'PAID',
        'buyerAccountId': checkout.owner.accountId,
        'vendorId': group['vendorId'],
        'vendorName': group['vendorName'],
        'paymentGroupId': checkout.id,
        'quoteId': null,
        'itemsAmount': group['subtotal'],
        'shippingFee': group['shippingFee'],
        'discountAmount': 0,
        'totalAmount': (group['subtotal']! as int) + (group['shippingFee']! as int),
        'depositAmount': null,
        'remainingAmount': null,
        'interprovince': group['interprovince'],
        'hasCustom': false,
        'recipientName': checkout.delivery['recipientName'],
        'recipientPhone': checkout.delivery['recipientPhone'],
        'provinceCode': provinceCode,
        'addressDetail': checkout.delivery['addressDetail'],
        'deliveryDate': null,
        'deliveryMethod': group['interprovince'] == true ? 'STANDARD' : 'LOCAL',
        'trackingCode': null,
        'invoiceInfo': checkout.delivery['invoiceInfo'],
        'hasInvoiceFile': false,
        'deliveredAt': null,
        'receivedConfirmedAt': null,
        'complaintDeadline': null,
        'disputeOpen': false,
        'createdAt': now.toIso8601String(),
        'items': lines,
      },
      progress: [
        {
          'milestone': 'PAID',
          'note': 'Thanh toán đã được xác nhận.',
          'photoKeys': <String>[],
          'createdAt': now.toIso8601String(),
        },
      ],
    );
    _orders[id] = order;
    created.add(id);
  }
  return created;
}

Future<void> _handleNotifications(HttpRequest request) async {
  final user = _authenticate(request);
  if (user == null) {
    return _error(request, HttpStatus.unauthorized, 'Token thiếu hoặc hết hạn');
  }
  final items = _notifications.putIfAbsent(user.accountId, () => _seedNotifications());
  final path = request.uri.path;
  if (path == ApiEndpoints.notifications && request.method == 'GET') {
    final page = int.tryParse(request.uri.queryParameters['page'] ?? '') ?? 0;
    final size = int.tryParse(request.uri.queryParameters['size'] ?? '') ?? 20;
    final start = page * size;
    final content = start >= items.length
        ? <Map<String, Object?>>[]
        : items.sublist(start, min(start + size, items.length));
    return _json(request, {
      'content': content,
      'page': page,
      'size': size,
      'totalElements': items.length,
      'totalPages': items.isEmpty ? 0 : (items.length / size).ceil(),
      'unread': items.where((item) => item['read'] != true).length,
    });
  }
  if (path == ApiEndpoints.notificationsReadAll && request.method == 'POST') {
    final unread = items.where((item) => item['read'] != true).length;
    for (final item in items) {
      item['read'] = true;
    }
    return _json(request, unread);
  }
  final readMatch = RegExp(
    '^${ApiEndpoints.notifications}/([^/]+)/read\$',
  ).firstMatch(path);
  if (readMatch != null && request.method == 'POST') {
    final item = items.where((value) => value['id'] == readMatch.group(1)).firstOrNull;
    if (item == null) {
      return _error(request, HttpStatus.notFound, 'Không tìm thấy thông báo');
    }
    item['read'] = true;
    return _json(request, item);
  }
  return _error(request, HttpStatus.methodNotAllowed, 'Không hỗ trợ phương thức');
}

List<Map<String, Object?>> _seedNotifications() {
  final now = DateTime.now();
  return [
    {
      'id': _randomHex(8),
      'type': 'ORDER_STATUS',
      'title': 'Chào mừng đến MoonKage',
      'content': 'Theo dõi đơn hàng, báo giá và tin nhắn mới tại đây.',
      'targetUrl': null,
      'read': false,
      'createdAt': now.toUtc().toIso8601String(),
    },
    {
      'id': _randomHex(8),
      'type': 'QUOTE_RECEIVED',
      'title': 'Tính năng báo giá đã sẵn sàng',
      'content': 'Bạn có thể gửi yêu cầu cho các nhà cung cấp B2B.',
      'targetUrl': null,
      'read': false,
      'createdAt': now.subtract(const Duration(minutes: 12)).toUtc().toIso8601String(),
    },
  ];
}

Future<void> _handleChat(HttpRequest request) async {
  final user = _authenticate(request);
  if (user == null) {
    return _error(request, HttpStatus.unauthorized, 'Token thiếu hoặc hết hạn');
  }
  final path = request.uri.path;
  if (path == ApiEndpoints.conversations && request.method == 'GET') {
    final items =
        _conversations.values
            .where((conversation) => conversation.buyer == user)
            .map(_conversationJson)
            .toList(growable: false)
          ..sort((a, b) {
            final left = a['lastMessageAt'] as String? ?? '';
            final right = b['lastMessageAt'] as String? ?? '';
            return right.compareTo(left);
          });
    return _json(request, items);
  }
  if (path == ApiEndpoints.conversations && request.method == 'POST') {
    final body = await _readJson(request);
    final vendorId = body?['vendorId'];
    final selectedVendorId = vendorId is String ? vendorId : '';
    final supplier = vendorId is String
        ? _suppliers.where((item) => item['vendorId'] == vendorId).firstOrNull
        : null;
    if (supplier == null) {
      return _error(request, HttpStatus.badRequest, 'Nhà cung cấp không hợp lệ');
    }
    var conversation = _conversations.values
        .where((item) => item.buyer == user && item.vendorId == selectedVendorId)
        .firstOrNull;
    if (conversation == null) {
      conversation = _MockConversation(
        id: _randomHex(8),
        buyer: user,
        vendorId: selectedVendorId,
        vendorName: supplier['businessName']! as String,
      );
      _conversations[conversation.id] = conversation;
      conversation.messages.add(
        _mockMessage(
          conversation: conversation,
          senderParty: 'VENDOR',
          body: 'Xin chào! Cửa hàng có thể hỗ trợ bạn về sản phẩm nào?',
        ),
      );
    }
    return _json(request, _conversationJson(conversation));
  }

  final messagesMatch = RegExp(
    '^${ApiEndpoints.conversations}/([^/]+)/messages\$',
  ).firstMatch(path);
  if (messagesMatch != null && request.method == 'POST') {
    final conversation = _conversations[messagesMatch.group(1)];
    if (conversation == null || conversation.buyer != user) {
      return _error(request, HttpStatus.notFound, 'Không tìm thấy hội thoại');
    }
    final body = await _readJson(request);
    final text = body?['body'];
    if (text is! String || text.trim().isEmpty || text.length > 2000) {
      return _error(request, HttpStatus.badRequest, 'Tin nhắn không hợp lệ');
    }
    final message = _mockMessage(
      conversation: conversation,
      senderParty: 'BUYER',
      body: text.trim(),
    );
    conversation.messages.add(message);
    conversation.messages.add(
      _mockMessage(
        conversation: conversation,
        senderParty: 'VENDOR',
        body: 'Cửa hàng đã nhận được tin nhắn và sẽ phản hồi chi tiết ngay.',
      ),
    );
    return _json(request, message, status: HttpStatus.created);
  }

  final readMatch = RegExp(
    '^${ApiEndpoints.conversations}/([^/]+)/read\$',
  ).firstMatch(path);
  if (readMatch != null && request.method == 'POST') {
    final conversation = _conversations[readMatch.group(1)];
    final body = await _readJson(request);
    if (conversation == null || conversation.buyer != user || body?['upToSeq'] is! int) {
      return _error(request, HttpStatus.badRequest, 'Không thể đánh dấu đã đọc');
    }
    conversation.buyerReadSequence = body!['upToSeq']! as int;
    request.response.statusCode = HttpStatus.noContent;
    return request.response.close();
  }

  final typingMatch = RegExp(
    '^${ApiEndpoints.conversations}/([^/]+)/typing\$',
  ).firstMatch(path);
  if (typingMatch != null && request.method == 'POST') {
    final conversation = _conversations[typingMatch.group(1)];
    if (conversation == null || conversation.buyer != user) {
      return _error(request, HttpStatus.notFound, 'Không tìm thấy hội thoại');
    }
    request.response.statusCode = HttpStatus.noContent;
    return request.response.close();
  }

  final threadMatch = RegExp('^${ApiEndpoints.conversations}/([^/]+)\$').firstMatch(path);
  if (threadMatch != null && request.method == 'GET') {
    final conversation = _conversations[threadMatch.group(1)];
    if (conversation == null || conversation.buyer != user) {
      return _error(request, HttpStatus.notFound, 'Không tìm thấy hội thoại');
    }
    final size = int.tryParse(request.uri.queryParameters['size'] ?? '') ?? 30;
    final start = max(0, conversation.messages.length - size);
    return _json(request, {
      'conversationId': conversation.id,
      'myParty': 'BUYER',
      'messages': conversation.messages.sublist(start),
      'buyerReadSeq': conversation.buyerReadSequence,
      'vendorReadSeq': conversation.messages
          .where((message) => message['senderParty'] == 'BUYER')
          .map((message) => message['seq']! as int)
          .fold<int>(0, max),
      'hasMore': start > 0,
    });
  }
  return _error(request, HttpStatus.methodNotAllowed, 'Không hỗ trợ phương thức');
}

Map<String, Object?> _conversationJson(_MockConversation conversation) {
  final last = conversation.messages.lastOrNull;
  final unread = conversation.messages
      .where(
        (message) =>
            message['senderParty'] == 'VENDOR' &&
            (message['seq']! as int) > conversation.buyerReadSequence,
      )
      .length;
  return {
    'id': conversation.id,
    'vendorId': conversation.vendorId,
    'vendorName': conversation.vendorName,
    'buyerAccountId': conversation.buyer.accountId,
    'buyerName': conversation.buyer.fullName,
    'myParty': 'BUYER',
    'lastMessage': last,
    'lastMessageAt': last?['createdAt'],
    'unreadCount': unread,
  };
}

Map<String, Object?> _mockMessage({
  required _MockConversation conversation,
  required String senderParty,
  required String body,
}) => {
  'id': _randomHex(8),
  'seq': conversation.messages.length + 1,
  'conversationId': conversation.id,
  'senderAccountId': senderParty == 'BUYER'
      ? conversation.buyer.accountId
      : 'owner-${conversation.vendorId}',
  'senderParty': senderParty,
  'body': body,
  'attachmentName': null,
  'attachmentContentType': null,
  'attachmentUrl': null,
  'createdAt': DateTime.now().toUtc().toIso8601String(),
};

Future<void> _handleSuppliers(HttpRequest request) async {
  final path = request.uri.path;
  if (request.method != 'GET') {
    return _error(request, HttpStatus.methodNotAllowed, 'Không hỗ trợ phương thức');
  }
  if (path == ApiEndpoints.suppliers) {
    final query = request.uri.queryParameters['q']?.toLowerCase();
    final customType = request.uri.queryParameters['customType'];
    final minQty = int.tryParse(request.uri.queryParameters['minQty'] ?? '');
    final province = request.uri.queryParameters['provinceCode'];
    final items = _suppliers
        .where((supplier) {
          final name = supplier['businessName']! as String;
          final capabilities = supplier['customCapabilities']! as List<String>;
          final areas = supplier['deliveryAreas']! as List<String>;
          final supplierMin = supplier['minQty']! as int;
          return (query == null || name.toLowerCase().contains(query)) &&
              (customType == null || capabilities.contains(customType)) &&
              (minQty == null || supplierMin <= minQty) &&
              (province == null || areas.contains(province));
        })
        .toList(growable: false);
    return _json(request, items);
  }
  final match = RegExp('^${ApiEndpoints.suppliers}/([^/]+)\$').firstMatch(path);
  final supplier = match == null
      ? null
      : _suppliers.where((item) => item['vendorId'] == match.group(1)).firstOrNull;
  if (supplier == null) {
    return _error(request, HttpStatus.notFound, 'Không tìm thấy nhà cung cấp');
  }
  return _json(request, supplier);
}

Future<void> _handleQuoteRequests(HttpRequest request) async {
  final user = _authenticate(request);
  if (user == null) {
    return _error(request, HttpStatus.unauthorized, 'Token thiếu hoặc hết hạn');
  }
  final path = request.uri.path;
  if (path == ApiEndpoints.quoteRequests && request.method == 'GET') {
    final items =
        _quoteRequests.values
            .where((item) => item.owner == user)
            .map((item) => item.data)
            .toList(growable: false)
          ..sort(
            (a, b) => (b['createdAt']! as String).compareTo(a['createdAt']! as String),
          );
    return _json(request, items);
  }
  if (path == ApiEndpoints.quoteRequests && request.method == 'POST') {
    final body = await _readJson(request);
    final type = body?['type'];
    final quantity = body?['quantity'];
    final delivery = body?['delivery'];
    final deadline = body?['deliveryDeadline'];
    if ((type != 'DIRECT' && type != 'OPEN') ||
        quantity is! int ||
        quantity <= 0 ||
        delivery is! Map ||
        deadline is! String) {
      return _error(request, HttpStatus.badRequest, 'Dữ liệu yêu cầu báo giá không hợp lệ');
    }
    final targetVendorId = body?['targetVendorId'];
    if (type == 'DIRECT' &&
        (targetVendorId is! String ||
            !_suppliers.any((item) => item['vendorId'] == targetVendorId))) {
      return _error(request, HttpStatus.badRequest, 'Nhà cung cấp không hợp lệ');
    }
    final invitedSuppliers = type == 'DIRECT'
        ? _suppliers.where((item) => item['vendorId'] == targetVendorId).toList()
        : _suppliers.toList();
    final id = _randomHex(8);
    final invitations = invitedSuppliers
        .map(
          (supplier) => <String, Object?>{
            'vendorId': supplier['vendorId'],
            'vendorName': supplier['businessName'],
            'status': 'ACCEPTED',
            'declineReason': null,
            'respondedAt': DateTime.now().toUtc().toIso8601String(),
          },
        )
        .toList(growable: false);
    final quotes = <Map<String, Object?>>[
      for (var index = 0; index < invitedSuppliers.length; index++)
        _mockVendorQuote(
          requestId: id,
          supplier: invitedSuppliers[index],
          quantity: quantity,
          index: index,
        ),
    ];
    final data = <String, Object?>{
      'id': id,
      'type': type,
      'buyerAccountId': user.accountId,
      'targetVendorId': targetVendorId,
      'productId': body?['productId'],
      'quantity': quantity,
      'budget': body?['budget'],
      'customTypes': body?['customTypes'] is List ? body!['customTypes'] : <Object?>[],
      'customSpec': body?['customSpec'] ?? '',
      'deliveryDeadline': deadline,
      'delivery': delivery.map((key, value) => MapEntry(key.toString(), value)),
      'status': 'OPEN',
      'invitedCount': invitations.length,
      'quoteCount': quotes.length,
      'suggestedUnitPrice': null,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    };
    _quoteRequests[id] = _MockQuoteRequest(
      owner: user,
      data: data,
      invitations: invitations,
      quotes: quotes,
    );
    return _json(request, data, status: HttpStatus.created);
  }

  final acceptanceMatch = RegExp(
    '^${ApiEndpoints.quoteRequests}/([^/]+)/quotes/([^/]+)/acceptance\$',
  ).firstMatch(path);
  if (acceptanceMatch != null && request.method == 'POST') {
    final quoteRequest = _quoteRequests[acceptanceMatch.group(1)];
    final quoteId = acceptanceMatch.group(2);
    final quote = quoteRequest?.quotes.where((item) => item['id'] == quoteId).firstOrNull;
    if (quoteRequest == null || quoteRequest.owner != user || quote == null) {
      return _error(request, HttpStatus.notFound, 'Không tìm thấy báo giá');
    }
    if (quoteRequest.data['status'] != 'OPEN' || quote['acceptable'] != true) {
      return _error(request, HttpStatus.conflict, 'Báo giá không còn có thể chấp nhận');
    }
    quoteRequest.data['status'] = 'AWARDED';
    for (final item in quoteRequest.quotes) {
      final accepted = identical(item, quote);
      item
        ..['status'] = accepted ? 'ACCEPTED' : 'REJECTED'
        ..['acceptable'] = false;
    }
    final acceptanceId = _randomHex(8);
    return _json(
      request,
      {
        'acceptanceId': acceptanceId,
        'status': 'PENDING_PAYMENT',
        'depositAmount': quote['depositAmount'],
        'paymentId': _randomHex(8),
        'paymentUrl': 'http://10.0.2.2:$_port/mock-quote-pay/$acceptanceId',
        'paymentExpiresAt': DateTime.now()
            .add(const Duration(minutes: 15))
            .toUtc()
            .toIso8601String(),
      },
      status: HttpStatus.created,
    );
  }

  final invitationsMatch = RegExp(
    '^${ApiEndpoints.quoteRequests}/([^/]+)/invitations\$',
  ).firstMatch(path);
  if (invitationsMatch != null && request.method == 'GET') {
    final quoteRequest = _quoteRequests[invitationsMatch.group(1)];
    if (quoteRequest == null || quoteRequest.owner != user) {
      return _error(request, HttpStatus.notFound, 'Không tìm thấy yêu cầu');
    }
    return _json(request, quoteRequest.invitations);
  }

  final quotesMatch = RegExp(
    '^${ApiEndpoints.quoteRequests}/([^/]+)/quotes\$',
  ).firstMatch(path);
  if (quotesMatch != null && request.method == 'GET') {
    final quoteRequest = _quoteRequests[quotesMatch.group(1)];
    if (quoteRequest == null || quoteRequest.owner != user) {
      return _error(request, HttpStatus.notFound, 'Không tìm thấy yêu cầu');
    }
    return _json(request, quoteRequest.quotes);
  }

  final requestMatch = RegExp('^${ApiEndpoints.quoteRequests}/([^/]+)\$').firstMatch(path);
  if (requestMatch != null && request.method == 'GET') {
    final quoteRequest = _quoteRequests[requestMatch.group(1)];
    if (quoteRequest == null || quoteRequest.owner != user) {
      return _error(request, HttpStatus.notFound, 'Không tìm thấy yêu cầu');
    }
    return _json(request, quoteRequest.data);
  }
  return _error(request, HttpStatus.methodNotAllowed, 'Không hỗ trợ phương thức');
}

Map<String, Object?> _mockVendorQuote({
  required String requestId,
  required Map<String, Object?> supplier,
  required int quantity,
  required int index,
}) {
  final unitPrice = 138000 - index * 5000;
  final itemsAmount = quantity * unitPrice;
  final customSurcharge = quantity * (index == 0 ? 8000 : 10000);
  final shippingFee = 30000 + index * 10000;
  final total = itemsAmount + customSurcharge + shippingFee;
  final deposit = (total * 0.3).round();
  return {
    'id': _randomHex(8),
    'requestId': requestId,
    'vendorId': supplier['vendorId'],
    'vendorName': supplier['businessName'],
    'revisionNo': 1,
    'supersedesQuoteId': null,
    'items': [
      {
        'lineNo': 1,
        'kind': 'PRODUCT',
        'description': 'Bánh trung thu doanh nghiệp',
        'productRef': null,
        'customType': null,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'amount': itemsAmount,
      },
    ],
    'itemsAmount': itemsAmount,
    'customSurcharge': customSurcharge,
    'shippingFee': shippingFee,
    'totalAmount': total,
    'depositRate': 0.3,
    'depositAmount': deposit,
    'remainingAmount': total - deposit,
    'deliveryDate': DateTime.now()
        .add(Duration(days: 12 + index * 2))
        .toIso8601String()
        .substring(0, 10),
    'deliveryMethod': 'LOCAL',
    'validUntil': DateTime.now().add(const Duration(days: 7)).toUtc().toIso8601String(),
    'notes': index == 0
        ? 'Đã gồm in logo một màu và đóng gói riêng.'
        : 'Miễn phí thiết kế thiệp cho đơn từ 100 sản phẩm.',
    'status': 'SUBMITTED',
    'acceptable': true,
    'submittedAt': DateTime.now().toUtc().toIso8601String(),
    'withdrawnAt': null,
  };
}

Future<void> _handleMockQuotePayment(HttpRequest request) => _send(
  request,
  HttpStatus.ok,
  ContentType.html,
  '''<!doctype html><html lang="vi"><meta charset="utf-8">
  <body style="font-family:system-ui;padding:32px"><h1>Thanh toán đặt cọc B2B</h1>
  <p>Đây là trang thanh toán giả lập. Báo giá đã được ghi nhận là đã chọn.</p></body></html>''',
);

Future<void> _handleOrders(HttpRequest request) async {
  final user = _authenticate(request);
  if (user == null) return _error(request, HttpStatus.unauthorized, 'Token không hợp lệ');
  final path = request.uri.path;

  if (path == ApiEndpoints.orders && request.method == 'GET') {
    final status = request.uri.queryParameters['status'];
    final page = int.tryParse(request.uri.queryParameters['page'] ?? '') ?? 0;
    final size = int.tryParse(request.uri.queryParameters['size'] ?? '') ?? 20;
    var items = _orders.values.where((order) => order.owner == user).toList()
      ..sort((a, b) => (b.data['createdAt']! as String).compareTo(a.data['createdAt']! as String));
    if (status != null) items = items.where((order) => order.status == status).toList();
    final start = page * size;
    final content = start >= items.length
        ? <Map<String, Object?>>[]
        : items.sublist(start, min(start + size, items.length)).map((order) {
            final data = Map<String, Object?>.from(order.data);
            data['items'] = <Object?>[];
            return data;
          }).toList();
    return _json(request, {
      'content': content,
      'page': page,
      'size': size,
      'totalElements': items.length,
      'totalPages': items.isEmpty ? 0 : (items.length / size).ceil(),
    });
  }

  final reviewsMatch = RegExp('^${ApiEndpoints.orders}/([^/]+)/reviews\$').firstMatch(path);
  if (reviewsMatch != null) {
    final orderId = reviewsMatch.group(1)!;
    final order = _orders[orderId];
    if (order == null || order.owner != user) {
      return _error(request, HttpStatus.notFound, 'Không tìm thấy đơn hàng');
    }
    final reviews = _orderReviews.putIfAbsent(orderId, () => []);
    if (request.method == 'GET') return _json(request, reviews);
    if (request.method == 'POST') {
      final body = await _readJson(request);
      final productId = body?['productId'];
      final rating = body?['rating'];
      final content = body?['content'];
      final lines = order.data['items'];
      final productInOrder =
          productId is String &&
          lines is List &&
          lines.whereType<Map<Object?, Object?>>().any((line) => line['productId'] == productId);
      final canReview =
          order.data['kind'] == 'BUY_NOW' &&
          (order.status == 'DELIVERED' || order.status == 'COMPLETED');
      if (!canReview || !productInOrder || rating is! int || rating < 1 || rating > 5) {
        return _error(request, HttpStatus.conflict, 'Không thể đánh giá sản phẩm này');
      }
      if (content is! String || content.length > 2000) {
        return _error(request, HttpStatus.badRequest, 'Nội dung đánh giá không hợp lệ');
      }
      if (reviews.any((review) => review['productId'] == productId)) {
        return _error(request, HttpStatus.conflict, 'Sản phẩm đã được đánh giá');
      }
      final review = <String, Object?>{
        'reviewId': _randomHex(8),
        'productId': productId,
        'rating': rating,
        'content': content.trim(),
        'createdAt': DateTime.now().toUtc().toIso8601String(),
      };
      reviews.add(review);
      return _json(request, review);
    }
    return _error(request, HttpStatus.methodNotAllowed, 'Không hỗ trợ phương thức');
  }

  final progressMatch = RegExp('^${ApiEndpoints.orders}/([^/]+)/progress-updates\$')
      .firstMatch(path);
  if (progressMatch != null && request.method == 'GET') {
    final order = _orders[progressMatch.group(1)];
    if (order == null || order.owner != user) {
      return _error(request, HttpStatus.notFound, 'Không tìm thấy đơn hàng');
    }
    return _json(request, order.progress);
  }

  final paymentMatch = RegExp('^${ApiEndpoints.orders}/([^/]+)/payments\$').firstMatch(path);
  if (paymentMatch != null && request.method == 'POST') {
    final order = _orders[paymentMatch.group(1)];
    if (order == null || order.owner != user) {
      return _error(request, HttpStatus.notFound, 'Không tìm thấy đơn hàng');
    }
    if (order.data['kind'] != 'CUSTOM_ORDER' || order.status != 'DELIVERED') {
      return _error(request, HttpStatus.conflict, 'Đơn chưa thể thanh toán phần còn lại');
    }
    return _json(request, {
      'paymentId': _randomHex(8),
      'paymentUrl': 'http://10.0.2.2:$_port/mock-order-pay/${order.id}',
    });
  }

  final match = RegExp('^${ApiEndpoints.orders}/([^/]+)\$').firstMatch(path);
  final order = _orders[match?.group(1)];
  if (order == null || order.owner != user) {
    return _error(request, HttpStatus.notFound, 'Không tìm thấy đơn hàng');
  }
  if (request.method == 'GET') return _json(request, order.data);
  if (request.method == 'PATCH') {
    final body = await _readJson(request);
    if (body?['receivedConfirmed'] != true || order.status != 'DELIVERED') {
      return _error(request, HttpStatus.conflict, 'Không thể xác nhận nhận hàng');
    }
    final now = DateTime.now().toUtc().toIso8601String();
    order.data['receivedConfirmedAt'] = now;
    if (order.data['kind'] == 'BUY_NOW') order.data['status'] = 'COMPLETED';
    order.progress.add({
      'milestone': order.data['status'],
      'note': 'Người mua đã xác nhận nhận hàng.',
      'photoKeys': <String>[],
      'createdAt': now,
    });
    return _json(request, order.data);
  }
  return _error(request, HttpStatus.methodNotAllowed, 'Không hỗ trợ phương thức');
}

void _advanceOrders() {
  const nextStatus = {
    'PAID': 'CONFIRMED',
    'CONFIRMED': 'SHIPPING',
    'SHIPPING': 'DELIVERED',
  };
  const notes = {
    'CONFIRMED': 'Shop đã xác nhận đơn hàng.',
    'SHIPPING': 'Đơn hàng đang được vận chuyển.',
    'DELIVERED': 'Đơn hàng đã được giao.',
  };
  final now = DateTime.now().toUtc();
  for (final order in _orders.values) {
    final next = nextStatus[order.status];
    if (next == null) continue;
    order.data['status'] = next;
    if (next == 'SHIPPING') order.data['trackingCode'] = 'MK-${order.id.toUpperCase()}';
    if (next == 'DELIVERED') {
      order.data['deliveredAt'] = now.toIso8601String();
      order.data['complaintDeadline'] = now.add(const Duration(days: 3)).toIso8601String();
    }
    order.progress.add({
      'milestone': next,
      'note': notes[next],
      'photoKeys': <String>[],
      'createdAt': now.toIso8601String(),
    });
  }
}

String _mockPaymentPage(_MockCheckout checkout) =>
    '''
<!doctype html>
<html lang="vi">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>MoonKage Mock VNPay</title>
  <style>
    body{font-family:Arial,sans-serif;background:#fff8f2;color:#2c201d;margin:0;padding:32px}
    main{max-width:520px;margin:40px auto;background:white;border-radius:24px;padding:28px;box-shadow:0 12px 40px #5f211522}
    h1{color:#8f241f}.amount{font-size:30px;font-weight:800;margin:24px 0}
    .actions{display:grid;gap:12px}button{width:100%;padding:14px;border:0;border-radius:12px;font-size:16px;font-weight:700}
    .ok{background:#186a4a;color:white}.fail{background:#f4ded9;color:#8f241f}.status{padding:12px;background:#fff2d4;border-radius:10px}
  </style>
</head>
<body><main>
  <p>MOCK VNPAY · Chỉ dùng khi phát triển</p>
  <h1>Thanh toán MoonKage</h1>
  <div class="amount">${checkout.totalAmount} VND</div>
  <p class="status">Trạng thái: ${checkout.status}</p>
  ${checkout.status == 'PENDING_PAYMENT' ? '''
  <div class="actions">
    <form method="post" action="/mock-pay/${checkout.id}/success"><button class="ok">Giả lập thành công</button></form>
    <form method="post" action="/mock-pay/${checkout.id}/failed"><button class="fail">Giả lập thất bại</button></form>
  </div>
  ''' : '<p>Đã cập nhật. Hãy quay lại ứng dụng MoonKage để xem kết quả.</p>'}
</main></body></html>
''';

Future<void> _handleAccount(HttpRequest request) async {
  final user = _authenticate(request);
  if (user == null) return _error(request, HttpStatus.unauthorized, 'Token không hợp lệ');
  if (request.method == 'PATCH' && request.uri.path == ApiEndpoints.accountProfile) {
    final body = await _readJson(request);
    final fullName = body?['fullName'];
    if (fullName is! String || fullName.trim().isEmpty || fullName.trim().length > 100) {
      return _error(request, HttpStatus.badRequest, 'Họ và tên không hợp lệ');
    }
    user.fullName = fullName.trim();
  } else if (request.method != 'GET' || request.uri.path != ApiEndpoints.accountMe) {
    return _error(request, HttpStatus.methodNotAllowed, 'Không hỗ trợ phương thức');
  }
  return _json(request, {
    'accountId': user.accountId,
    'email': user.email,
    'phoneNumber': user.phone.startsWith('0') ? user.phone.substring(1) : user.phone,
    'fullName': user.fullName,
    'role': 'MEMBER',
  });
}

Future<void> _handleAddresses(HttpRequest request) async {
  final user = _authenticate(request);
  if (user == null) return _error(request, HttpStatus.unauthorized, 'Token không hợp lệ');
  final items = _addresses.putIfAbsent(user.accountId, () => []);
  final path = request.uri.path;

  if (path == ApiEndpoints.addresses && request.method == 'GET') {
    return _json(request, items.map((address) => address.toJson()).toList());
  }
  if (path == ApiEndpoints.addresses && request.method == 'POST') {
    final body = await _validAddressBody(request);
    if (body == null) return;
    final address = _MockAddress.fromBody(body);
    if (items.isEmpty) address.isDefault = true;
    if (address.isDefault) _clearDefault(items);
    items.add(address);
    return _json(request, address.toJson());
  }

  final match = RegExp('^${ApiEndpoints.addresses}/([^/]+)\$').firstMatch(path);
  final addressId = match?.group(1);
  final index = items.indexWhere((address) => address.id == addressId);
  if (index < 0) return _error(request, HttpStatus.notFound, 'Không tìm thấy địa chỉ');
  final address = items[index];

  if (request.method == 'PUT') {
    final body = await _validAddressBody(request);
    if (body == null) return;
    address.update(body);
    if (address.isDefault) _clearDefault(items, except: address);
    return _json(request, address.toJson());
  }
  if (request.method == 'DELETE') {
    final wasDefault = address.isDefault;
    items.removeAt(index);
    if (wasDefault && items.isNotEmpty) items.first.isDefault = true;
    request.response.statusCode = HttpStatus.noContent;
    return request.response.close();
  }
  return _error(request, HttpStatus.methodNotAllowed, 'Không hỗ trợ phương thức');
}

Future<Map<String, Object?>?> _validAddressBody(HttpRequest request) async {
  final body = await _readJson(request);
  const requiredFields = [
    'recipientName',
    'recipientPhone',
    'provinceCode',
    'provinceName',
    'wardName',
    'detail',
  ];
  final valid =
      body != null &&
      requiredFields.every(
        (key) => body[key] is String && (body[key]! as String).trim().isNotEmpty,
      );
  if (!valid || !RegExp(r'^\d{2}$').hasMatch(body!['provinceCode']! as String)) {
    await _error(request, HttpStatus.badRequest, 'Địa chỉ không hợp lệ');
    return null;
  }
  return body;
}

void _clearDefault(List<_MockAddress> items, {_MockAddress? except}) {
  for (final address in items) {
    if (!identical(address, except)) address.isDefault = false;
  }
}

_User? _authenticate(HttpRequest request) {
  final header = request.headers.value(HttpHeaders.authorizationHeader) ?? '';
  return header.startsWith('Bearer ') ? _tokens[header.substring(7)] : null;
}

/// Kiểm phiên chung cho bước gửi thẻ và xác nhận; null nghĩa là phiên hợp lệ.
Map<String, Object?>? _checkSession(_User user, _Session? session) {
  final now = DateTime.now();
  if (session == null || now.isAfter(session.expiresAt)) return _reject('SESSION_EXPIRED');
  if (session.owner != user) return _reject('SESSION_NOT_OWNED');
  if (session.used) return _reject('SESSION_USED');
  final lockedUntil = user.lockedUntil;
  if (lockedUntil != null && now.isBefore(lockedUntil)) {
    return _reject('LOCKED', lockedUntil: lockedUntil);
  }
  return null;
}

Future<Map<String, Object?>> _submitCard(
  _User user,
  String sessionId,
  Map<String, Object?>? body,
) async {
  final session = _sessions[sessionId];
  final rejected = _checkSession(user, session);
  if (rejected != null) return rejected;
  if (body == null) return _failAttempt(user, 'BAD_FORMAT');

  final mergedBody = Map<String, Object?>.from(body);
  final encryptedFields = body['encryptedFields'];
  if (encryptedFields is String && encryptedFields.isNotEmpty) {
    try {
      final jwe = JsonWebEncryption.fromCompactSerialization(encryptedFields);
      final store = JsonWebKeyStore()..addKey(JsonWebKey.fromJson(demoPrivateKeyJwk));
      final payload = await jwe.getPayload(store);
      final decrypted = payload.jsonContent;
      if (decrypted is Map<String, Object?>) {
        mergedBody.addAll(decrypted);
      } else {
        return _failAttempt(user, 'BAD_FORMAT');
      }
    } on Exception catch (_) {
      return _failAttempt(user, 'BAD_FORMAT');
    }
  }

  final card = _validCard(mergedBody);
  if (card == null) return _failAttempt(user, 'BAD_FORMAT');

  final expiry = DateTime.parse(card['dateOfExpiry']! as String);
  if (!expiry.isAfter(DateTime.now())) {
    return _failAttempt(user, 'CARD_EXPIRED');
  }

  final idNumber = card['idNumber']! as String;
  final linkedTo = _linkedIds[idNumber];
  if (linkedTo != null && linkedTo != user) return _failAttempt(user, 'ID_ALREADY_LINKED');

  session!
    ..used = true
    ..pendingCard = null;
  _linkedIds[idNumber] = user;
  user.failedAttempts = 0;
  return {'status': 'VERIFIED'};
}

final _idNumber = RegExp(r'^\d{12}$');
final _unaccentedName = RegExp(r'^[A-Z]+( [A-Z]+)*$');
const _textFields = ['nationality', 'placeOfBirth', 'placeOfResidence'];
const _dateFields = ['dateOfBirth', 'dateOfIssue', 'dateOfExpiry'];

/// Kiểm lại phía máy chủ, không tin kết quả kiểm ở app. Trả về bản đã chuẩn hóa hoặc null.
Map<String, Object?>? _validCard(Map<String, Object?> body) {
  final idNumber = body['idNumber'];
  final fullName = body['fullName'];
  final gender = body['gender'];
  if (idNumber is! String || !_idNumber.hasMatch(idNumber)) return null;
  if (fullName is! String || !_unaccentedName.hasMatch(fullName)) return null;
  if (gender != 'MALE' && gender != 'FEMALE') return null;

  final dates = <String, DateTime>{};
  for (final field in _dateFields) {
    final value = body[field];
    final parsed = value is String ? DateTime.tryParse(value) : null;
    if (parsed == null) return null;
    dates[field] = parsed;
  }
  if (dates['dateOfBirth']!.isAfter(dates['dateOfIssue']!)) return null;
  if (!dates['dateOfIssue']!.isBefore(dates['dateOfExpiry']!)) return null;

  for (final field in _textFields) {
    final value = body[field];
    if (value is! String || value.trim().isEmpty) return null;
  }

  return {
    'idNumber': idNumber,
    'fullName': fullName,
    for (final field in _dateFields) field: body[field],
    'gender': gender,
    for (final field in _textFields) field: (body[field]! as String).trim(),
  };
}

Map<String, Object?> _failAttempt(_User user, String reasonCode) {
  user.failedAttempts++;
  final attemptsLeft = _maxAttempts - user.failedAttempts;
  if (attemptsLeft > 0) return _reject(reasonCode, attemptsLeft: attemptsLeft);
  user.failedAttempts = 0;
  final lockedUntil = DateTime.now().add(_lockDuration);
  user.lockedUntil = lockedUntil;
  return _reject(reasonCode, attemptsLeft: 0, lockedUntil: lockedUntil);
}

Map<String, Object?> _reject(String reasonCode, {int? attemptsLeft, DateTime? lockedUntil}) => {
  'status': 'REJECTED',
  'reasonCode': reasonCode,
  'attemptsLeft': attemptsLeft,
  'lockedUntil': lockedUntil?.toUtc().toIso8601String(),
};

void _reset() {
  _sessions.clear();
  _linkedIds.clear();
  _tokens.clear();
  _refreshTokens.clear();
  _addresses.clear();
  _carts.clear();
  _checkouts.clear();
  _orders.clear();
  _orderReviews.clear();
  _quoteRequests.clear();
  _notifications.clear();
  _conversations.clear();
  for (final user in _users) {
    user
      ..failedAttempts = 0
      ..lockedUntil = null;
  }
  stdout.writeln('[${_time()}] đã xóa trạng thái');
}

String _newSession(_User owner, {DateTime? createdAt, String prefix = ''}) {
  final id = '$prefix${_randomHex(16)}';
  _sessions[id] = _Session(owner, createdAt ?? DateTime.now());
  return id;
}

String _page() {
  final demo = _users.first;
  final other = _users.last;
  final valid = _newSession(demo);
  final expired = _newSession(
    demo,
    createdAt: DateTime.now().subtract(_sessionTtl * 2),
    prefix: 'expired-',
  );
  final notOwned = _newSession(other);

  String userState(_User u) {
    final locked = u.lockedUntil;
    final lock = locked != null && DateTime.now().isBefore(locked)
        ? 'tạm khóa đến ${_time(locked)}'
        : 'không khóa';
    final linked = _linkedIds.values.where((owner) => owner == u).length;
    return '<li><b>${u.email}</b>: đã xác minh $linked CCCD · '
        'sai ${u.failedAttempts}/$_maxAttempts · $lock</li>';
  }

  String qr(String id, String title, String value, String note) =>
      '''
<div class="card"><h2>$title</h2><div id="$id" class="qr"></div>
<p class="note">$note</p><p><code>$value</code></p></div>
<script>new QRCode(document.getElementById('$id'), ${jsonEncode(value)});</script>''';

  return '''
<!doctype html>
<html lang="vi">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>MoonKage Mobile Mock</title>
<script src="https://cdnjs.cloudflare.com/ajax/libs/qrcodejs/1.0.0/qrcode.min.js"></script>
<style>
  body { font-family: system-ui, sans-serif; margin: 24px; background: #fff; color: #111; }
  .row { display: flex; gap: 40px; flex-wrap: wrap; }
  .card { max-width: 280px; }
  .qr { padding: 16px; background: #fff; display: inline-block; }
  .note { color: #555; }
  code { font-size: 11px; word-break: break-all; }
</style>
</head>
<body>
<h1>MoonKage Mobile — mock server</h1>
<p>Đăng nhập app bằng <b>${demo.email}</b> / $_password (tài khoản thứ hai: ${other.email}).</p>
<ul>${_users.map(userState).join()}</ul>
<div class="row">
${qr('ok', 'Phiên mới', 'moonkage-verify:v1:$valid', 'Của ${demo.email}, còn 5 phút.')}
${qr('expired', 'Phiên hết hạn', 'moonkage-verify:v1:$expired', '→ SESSION_EXPIRED')}
${qr('other', 'Phiên tài khoản khác', 'moonkage-verify:v1:$notOwned', 'Của ${other.email} → SESSION_NOT_OWNED khi app đăng nhập ${demo.email}.')}
${qr('bad', 'QR sai dạng', 'https://example.com/$valid', 'App báo lỗi, không gọi máy chủ.')}
</div>
<p><a href="/">Tạo phiên mới</a></p>
<form method="post" action="/advance-orders"><button>Đẩy đơn mock sang bước tiếp theo</button></form>
<form method="post" action="/reset"><button>Xóa trạng thái (phiên, CCCD đã gắn, lần thử, khóa)</button></form>
</body>
</html>
''';
}

Future<Map<String, Object?>?> _readJson(HttpRequest request) async {
  final body = await utf8.decoder.bind(request).join();
  try {
    final json = jsonDecode(body);
    return json is Map<String, Object?> ? json : null;
  } on FormatException {
    return null;
  }
}

/// Lỗi theo dạng chung của backend (docs/auth.md).
Future<void> _error(HttpRequest request, int status, String message) => _send(
  request,
  status,
  ContentType.json,
  jsonEncode({
    'status': status,
    'error': _reasonPhrase(status),
    'message': message,
    'path': request.uri.path,
    'timestamp': DateTime.now().toUtc().toIso8601String(),
  }),
);

String _reasonPhrase(int status) => switch (status) {
  HttpStatus.badRequest => 'Bad Request',
  HttpStatus.unauthorized => 'Unauthorized',
  HttpStatus.notFound => 'Not Found',
  HttpStatus.methodNotAllowed => 'Method Not Allowed',
  _ => 'Internal Server Error',
};

Future<void> _send(HttpRequest request, int status, ContentType type, String body) async {
  request.response
    ..statusCode = status
    ..headers.contentType = type
    ..write(body);
  await request.response.close();
}

void _log(String sessionId, String message) {
  final short = sessionId.length <= 14 ? sessionId : '${sessionId.substring(0, 14)}…';
  stdout.writeln('[${_time()}] phiên $short $message');
}

String _randomHex(int bytes) =>
    List.generate(bytes, (_) => _random.nextInt(256).toRadixString(16).padLeft(2, '0')).join();

String _time([DateTime? time]) {
  final t = (time ?? DateTime.now()).toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(t.hour)}:${two(t.minute)}:${two(t.second)}';
}
