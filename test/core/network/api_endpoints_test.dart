import 'package:flutter_test/flutter_test.dart';
import 'package:moonkage_verify/core/network/api_endpoints.dart';

void main() {
  const id = '3f2b8c1e-9a4d-4e7b-8c2a-1d5e6f7a8b9c';

  group('ApiEndpoints canonical gateway contract', () {
    test('uses aggregate-root /api paths instead of service-name paths', () {
      expect(ApiEndpoints.apiRoot, '/api');
      expect(ApiEndpoints.login, '/api/auth/login');
      expect(ApiEndpoints.accountMe, '/api/accounts/me');
      expect(ApiEndpoints.nfcSession(id), '/api/nfc/sessions/$id');
      expect(ApiEndpoints.nfcSessionCard(id), '/api/nfc/sessions/$id/card');
    });

    test('maps buyer commerce roots', () {
      expect(ApiEndpoints.products, '/api/products');
      expect(ApiEndpoints.productFacets, '/api/products/facets');
      expect(ApiEndpoints.cart, '/api/carts/me');
      expect(ApiEndpoints.checkouts, '/api/checkouts');
      expect(ApiEndpoints.orders, '/api/orders');
      expect(ApiEndpoints.suppliers, '/api/suppliers');
      expect(ApiEndpoints.quoteRequests, '/api/quote-requests');
    });

    test('encodes dynamic path segments', () {
      expect(
        ApiEndpoints.nfcSessionCard('session/with/slashes'),
        '/api/nfc/sessions/session%2Fwith%2Fslashes/card',
      );
      expect(ApiEndpoints.cartItem('item/1'), '/api/carts/me/items/item%2F1');
      expect(
        ApiEndpoints.quoteAcceptance('request/1', 'quote/1'),
        '/api/quote-requests/request%2F1/quotes/quote%2F1/acceptance',
      );
    });
  });
}
