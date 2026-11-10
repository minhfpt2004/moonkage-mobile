import 'package:moonkage_verify/core/config/app_config.dart';

/// Public contract exposed by Moonkage API Gateway.
///
/// Mobile clients always call canonical aggregate-root paths under `/api`.
/// Service-name paths such as `/identity-service/api/**` are legacy and must
/// not be used by new code. Internal `/internal/**` paths are never available
/// through the gateway.
abstract final class ApiEndpoints {
  static const apiRoot = '/api';

  // Authentication and account.
  static const auth = '$apiRoot/auth';
  static const register = '$auth/register';
  static const login = '$auth/login';
  static const refreshToken = '$auth/refresh-token';
  static const verifyAccount = '$auth/verify-account';
  static const sendVerifyAccountOtp = '$auth/send-verify-account-otp';
  static const resetPassword = '$auth/reset-password';
  static const sendResetPasswordOtp = '$auth/send-reset-password-otp';
  static const accountMe = '$apiRoot/accounts/me';
  static const accountProfile = '$accountMe/profile';
  static const addresses = '$apiRoot/addresses';
  static String address(String addressId) => '$addresses/${_segment(addressId)}';

  // NFC verification.
  static const nfcSessions = '$apiRoot/nfc/sessions';
  static String nfcSession(String sessionId) => '$nfcSessions/${_segment(sessionId)}';
  static String nfcSessionCard(String sessionId) => '${nfcSession(sessionId)}/card';
  static const nfcStatus = '$apiRoot/nfc/status';

  // Buyer catalog.
  static const products = '$apiRoot/products';
  static const productFacets = '$products/facets';
  static String product(String productId) => '$products/${_segment(productId)}';
  static String productReviews(String productId) => '${product(productId)}/reviews';
  static const cakeAttributes = '$apiRoot/cake-attributes';
  static const interprovinceFees = '$apiRoot/interprovince-fees';

  // Cart and checkout.
  static const cart = '$apiRoot/carts/me';
  static const cartItems = '$cart/items';
  static String cartItem(String itemId) => '$cartItems/${_segment(itemId)}';
  static const checkouts = '$apiRoot/checkouts';
  static String checkout(String checkoutId) => '$checkouts/${_segment(checkoutId)}';

  // Orders and after-sales.
  static const orders = '$apiRoot/orders';
  static const orderUploads = '$orders/uploads';
  static String order(String orderId) => '$orders/${_segment(orderId)}';
  static String orderProgress(String orderId) => '${order(orderId)}/progress-updates';
  static String orderPayments(String orderId) => '${order(orderId)}/payments';
  static String orderReviews(String orderId) => '${order(orderId)}/reviews';
  static String orderDispute(String orderId) => '${order(orderId)}/dispute';
  static String orderDisputeEvidences(String orderId) => '${orderDispute(orderId)}/evidences';
  static String orderMockups(String orderId) => '${order(orderId)}/mockups';
  static String orderMockup(String orderId, int versionNo) => '${orderMockups(orderId)}/$versionNo';
  static String orderInvoice(String orderId) => '${order(orderId)}/invoice';

  // B2B suppliers and quotations.
  static const suppliers = '$apiRoot/suppliers';
  static String supplier(String vendorId) => '$suppliers/${_segment(vendorId)}';
  static const quoteRequests = '$apiRoot/quote-requests';
  static String quoteRequest(String requestId) => '$quoteRequests/${_segment(requestId)}';
  static String quoteInvitations(String requestId) => '${quoteRequest(requestId)}/invitations';
  static String quoteInvitation(String requestId, String vendorId) =>
      '${quoteInvitations(requestId)}/${_segment(vendorId)}';
  static String quotes(String requestId) => '${quoteRequest(requestId)}/quotes';
  static String quote(String requestId, String quoteId) =>
      '${quotes(requestId)}/${_segment(quoteId)}';
  static String quoteAcceptance(String requestId, String quoteId) =>
      '${quote(requestId, quoteId)}/acceptance';

  // Chat and notifications.
  static const conversations = '$apiRoot/chat/conversations';
  static String conversation(String conversationId) => '$conversations/${_segment(conversationId)}';
  static String conversationMessages(String conversationId) =>
      '${conversation(conversationId)}/messages';
  static String conversationRead(String conversationId) => '${conversation(conversationId)}/read';
  static String conversationTyping(String conversationId) =>
      '${conversation(conversationId)}/typing';
  static const notifications = '$apiRoot/notifications';
  static String notificationRead(String notificationId) =>
      '$notifications/${_segment(notificationId)}/read';
  static const notificationsReadAll = '$notifications/read-all';

  static String _segment(String value) => Uri.encodeComponent(value);

  /// Resolves a public path against [AppConfig.apiBaseUrl].
  static Uri resolve(String path) => Uri.parse(AppConfig.apiBaseUrl).resolve(path);
}
