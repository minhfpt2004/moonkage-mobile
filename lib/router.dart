import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:moonkage_verify/core/auth/session_notifier.dart';
import 'package:moonkage_verify/features/account/domain/delivery_address.dart';
import 'package:moonkage_verify/features/account/presentation/address_form_screen.dart';
import 'package:moonkage_verify/features/account/presentation/addresses_screen.dart';
import 'package:moonkage_verify/features/account/presentation/profile_screen.dart';
import 'package:moonkage_verify/features/auth/presentation/login_screen.dart';
import 'package:moonkage_verify/features/auth/presentation/register_screen.dart';
import 'package:moonkage_verify/features/auth/presentation/reset_password_screen.dart';
import 'package:moonkage_verify/features/auth/presentation/verify_account_screen.dart';
import 'package:moonkage_verify/features/b2b/presentation/quote_request_detail_screen.dart';
import 'package:moonkage_verify/features/b2b/presentation/quote_request_form_screen.dart';
import 'package:moonkage_verify/features/b2b/presentation/quote_requests_screen.dart';
import 'package:moonkage_verify/features/b2b/presentation/suppliers_screen.dart';
import 'package:moonkage_verify/features/cart/presentation/cart_screen.dart';
import 'package:moonkage_verify/features/catalog/presentation/catalog_screen.dart';
import 'package:moonkage_verify/features/catalog/presentation/product_detail_screen.dart';
import 'package:moonkage_verify/features/checkout/domain/checkout.dart';
import 'package:moonkage_verify/features/checkout/presentation/checkout_screen.dart';
import 'package:moonkage_verify/features/checkout/presentation/checkout_status_screen.dart';
import 'package:moonkage_verify/features/commerce/presentation/screens/account_screen.dart';
import 'package:moonkage_verify/features/commerce/presentation/screens/commerce_home_screen.dart';
import 'package:moonkage_verify/features/communication/presentation/chat_thread_screen.dart';
import 'package:moonkage_verify/features/communication/presentation/conversations_screen.dart';
import 'package:moonkage_verify/features/communication/presentation/notifications_screen.dart';
import 'package:moonkage_verify/features/orders/presentation/order_detail_screen.dart';
import 'package:moonkage_verify/features/orders/presentation/orders_screen.dart';
import 'package:moonkage_verify/features/verify/presentation/screens/confirm_screen.dart';
import 'package:moonkage_verify/features/verify/presentation/screens/home_screen.dart' as verify;
import 'package:moonkage_verify/features/verify/presentation/screens/result_screen.dart';
import 'package:moonkage_verify/features/verify/presentation/screens/scan_qr_screen.dart';
import 'package:moonkage_verify/features/verify/presentation/screens/tap_card_screen.dart';
import 'package:moonkage_verify/shell/app_shell.dart';

/// Route của ứng dụng. Dữ liệu nhạy cảm của thẻ không được truyền qua URL.
abstract final class AppRoutes {
  static const login = '/login';
  static const register = '/register';
  static const verifyAccount = '/verify-account';
  static const resetPassword = '/reset-password';

  static const home = '/';
  static const catalog = '/catalog';
  static String product(String productId) => '$catalog/${Uri.encodeComponent(productId)}';
  static const cart = '/cart';
  static const checkout = '$cart/checkout';
  static String checkoutStatus(String checkoutId) => '$checkout/${Uri.encodeComponent(checkoutId)}';
  static const orders = '/orders';
  static String order(String orderId) => '$orders/${Uri.encodeComponent(orderId)}';
  static const account = '/account';
  static const profile = '$account/profile';
  static const addresses = '$account/addresses';
  static const addressForm = '$addresses/form';
  static const quoteRequests = '$account/quote-requests';
  static const newQuoteRequest = '$quoteRequests/new';
  static const suppliers = '$quoteRequests/suppliers';
  static String quoteRequest(String requestId) =>
      '$quoteRequests/${Uri.encodeComponent(requestId)}';
  static const notifications = '$account/notifications';
  static const conversations = '$account/messages';
  static String conversation(String conversationId) =>
      '$conversations/${Uri.encodeComponent(conversationId)}';

  static const verification = '/verification';
  static const scanQr = '/verification/scan-qr';
  static const tapCard = '/verification/tap-card';
  static const confirm = '/verification/confirm';
  static const result = '/verification/result';
}

/// Người chưa đăng nhập được đưa về màn đăng nhập. Sau khi đăng nhập, năm tab
/// thương mại giữ state độc lập nhờ [StatefulShellRoute.indexedStack].
final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: AppRoutes.home,
    redirect: (_, state) {
      final signedIn = ref.read(sessionProvider) != null;
      final publicAuthRoutes = {
        AppRoutes.login,
        AppRoutes.register,
        AppRoutes.verifyAccount,
        AppRoutes.resetPassword,
      };
      final atPublicAuth = publicAuthRoutes.contains(state.matchedLocation);
      if (!signedIn) return atPublicAuth ? null : AppRoutes.login;
      return atPublicAuth ? AppRoutes.home : null;
    },
    routes: [
      GoRoute(path: AppRoutes.login, builder: (_, _) => const LoginScreen()),
      GoRoute(path: AppRoutes.register, builder: (_, _) => const RegisterScreen()),
      GoRoute(
        path: AppRoutes.verifyAccount,
        builder: (_, state) => VerifyAccountScreen(
          initialEmail: state.uri.queryParameters['email'] ?? '',
          otpSent: state.uri.queryParameters['sent'] != '0',
        ),
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        builder: (_, _) => const ResetPasswordScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, navigationShell) => AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: AppRoutes.home, builder: (_, _) => const CommerceHomeScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.catalog,
                builder: (_, _) => const CatalogScreen(),
                routes: [
                  GoRoute(
                    path: ':productId',
                    builder: (_, state) => ProductDetailScreen(
                      productId: state.pathParameters['productId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.cart,
                builder: (_, _) => const CartScreen(),
                routes: [
                  GoRoute(
                    path: 'checkout',
                    builder: (_, _) => const CheckoutScreen(),
                    routes: [
                      GoRoute(
                        path: ':checkoutId',
                        builder: (_, state) => CheckoutStatusScreen(
                          checkoutId: state.pathParameters['checkoutId']!,
                          created: state.extra is CheckoutCreated
                              ? state.extra! as CheckoutCreated
                              : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.orders,
                builder: (_, _) => const OrdersScreen(),
                routes: [
                  GoRoute(
                    path: ':orderId',
                    builder: (_, state) => OrderDetailScreen(
                      orderId: state.pathParameters['orderId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.account,
                builder: (_, _) => const AccountScreen(),
                routes: [
                  GoRoute(path: 'profile', builder: (_, _) => const ProfileScreen()),
                  GoRoute(
                    path: 'addresses',
                    builder: (_, _) => const AddressesScreen(),
                    routes: [
                      GoRoute(
                        path: 'form',
                        builder: (_, state) => AddressFormScreen(
                          address: state.extra is DeliveryAddress
                              ? state.extra! as DeliveryAddress
                              : null,
                        ),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'quote-requests',
                    builder: (_, _) => const QuoteRequestsScreen(),
                    routes: [
                      GoRoute(
                        path: 'new',
                        builder: (_, state) => QuoteRequestFormScreen(
                          initialVendorId: state.uri.queryParameters['vendorId'],
                        ),
                      ),
                      GoRoute(path: 'suppliers', builder: (_, _) => const SuppliersScreen()),
                      GoRoute(
                        path: ':requestId',
                        builder: (_, state) => QuoteRequestDetailScreen(
                          requestId: state.pathParameters['requestId']!,
                        ),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'notifications',
                    builder: (_, _) => const NotificationsScreen(),
                  ),
                  GoRoute(
                    path: 'messages',
                    builder: (_, _) => const ConversationsScreen(),
                    routes: [
                      GoRoute(
                        path: ':conversationId',
                        builder: (_, state) => ChatThreadScreen(
                          conversationId: state.pathParameters['conversationId']!,
                          vendorName: state.uri.queryParameters['name'] ?? '',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.verification,
        builder: (_, _) => const verify.HomeScreen(),
      ),
      GoRoute(path: AppRoutes.scanQr, builder: (_, _) => const ScanQrScreen()),
      GoRoute(path: AppRoutes.tapCard, builder: (_, _) => const TapCardScreen()),
      GoRoute(path: AppRoutes.confirm, builder: (_, _) => const ConfirmScreen()),
      GoRoute(path: AppRoutes.result, builder: (_, _) => const ResultScreen()),
    ],
  );
  ref
    ..listen(sessionProvider, (_, _) => router.refresh())
    ..onDispose(router.dispose);
  return router;
});
