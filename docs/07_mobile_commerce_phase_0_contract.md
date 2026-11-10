# Phase 0 — Mobile commerce contract baseline

## Scope

The Android app targets the buyer experience for individual and B2B members. Seller and admin operations remain in
the web portal. The existing NFC flow is retained under Account verification.

All requests go through API Gateway using canonical `/api/**` aggregate-root paths. Mobile code must not call legacy
`/<service-name>/api/**` paths or any `/internal/**` endpoint.

## Layout-to-API map

| Mobile area | Public backend contract | Phase 0 decision |
| --- | --- | --- |
| Authentication | `/api/auth/**`, `/api/accounts/me` | Implement login, register, OTP, refresh and reset |
| Delivery region/address | `/api/addresses/**` | Province is shared input for catalog, cart and checkout |
| Home/catalog | `/api/products`, `/api/products/facets`, `/api/cake-attributes` | Replace all prototype mock products with catalog data |
| Product detail | `/api/products/{id}`, `/reviews`, `/api/carts/me/items` | One backend product is one SKU; no UI-only price variants |
| Cart | `/api/carts/me/**` | Checkout covers the whole server cart; no item-selection checkout |
| Checkout | `/api/checkouts`, `/api/checkouts/{id}` | VNPay only; open `paymentUrl`, then poll checkout status |
| Orders | `/api/orders/**` | Add list, detail, progress, receive confirmation and remainder payment |
| Reviews/disputes | `/api/orders/{id}/reviews`, `/dispute` | Implement after the order flow |
| Chat | `/api/chat/conversations/**` | Use real conversation and message APIs |
| B2B | `/api/suppliers/**`, `/api/quote-requests/**` | Direct/open request, compare quotes, acceptance and deposit |
| NFC | `/api/nfc/**` | Keep existing encrypted card submission under Account |
| Notifications | `/api/notifications/**` | Defer live UI until backend services emit notification events |

## Prototype gaps

The following prototype concepts have no current public backend contract and are excluded from the MVP:

- favorites, loyalty points and Net-30 credit;
- vouchers (database exists, public API does not);
- COD, MoMo, ZaloPay, direct VietQR and credit-card checkout;
- partial-cart checkout, checkout delivery scheduling and checkout notes;
- exact four-slot custom-box configuration, engraving and ribbon options;
- multi-branch company management and reusable logo library.

The custom-box entry point may create a B2B request only within supported custom types: `BAG`, `CARD`, `STICKER` and
`TEMPLATE_BOX`. Exact prototype behavior requires a separate backend contract before implementation.

## Phase 0 completion criteria

- [x] Canonical gateway paths are centralized in `ApiEndpoints`.
- [x] The local mock server uses the same auth/NFC paths as the real gateway.
- [x] API envelope parsing supports object, list, primitive and null payloads.
- [x] The buyer/B2B mobile scope and unsupported prototype features are recorded.
- [x] Root `.env` secrets are excluded from source control.
- [ ] Run format, analyze and the complete Flutter test suite.
