import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:moonkage_verify/core/errors/app_failure.dart';
import 'package:moonkage_verify/core/strings.dart';
import 'package:moonkage_verify/core/theme/moonkage_colors.dart';
import 'package:moonkage_verify/core/widgets/content_state.dart';
import 'package:moonkage_verify/features/account/data/address_api.dart';
import 'package:moonkage_verify/features/account/domain/delivery_address.dart';
import 'package:moonkage_verify/features/cart/data/cart_api.dart';
import 'package:moonkage_verify/features/cart/domain/cart.dart';
import 'package:moonkage_verify/features/catalog/domain/product.dart';
import 'package:moonkage_verify/features/checkout/data/checkout_api.dart';
import 'package:moonkage_verify/features/checkout/domain/checkout.dart';
import 'package:moonkage_verify/router.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyName = TextEditingController();
  final _taxCode = TextEditingController();
  final _companyAddress = TextEditingController();
  final _companyEmail = TextEditingController();
  String? _selectedAddressId;
  var _needInvoice = false;
  var _submitting = false;

  @override
  void dispose() {
    _companyName.dispose();
    _taxCode.dispose();
    _companyAddress.dispose();
    _companyEmail.dispose();
    super.dispose();
  }

  DeliveryAddress _selectedAddress(List<DeliveryAddress> addresses) {
    final selected = addresses.where((item) => item.id == _selectedAddressId).firstOrNull;
    return selected ?? addresses.where((item) => item.isDefault).firstOrNull ?? addresses.first;
  }

  Future<void> _submit(DeliveryAddress address) async {
    if (_submitting || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);
    try {
      final detail = address.wardName.trim().isEmpty
          ? address.detail.trim()
          : '${address.detail.trim()}, ${address.wardName.trim()}';
      final created = await ref
          .read(checkoutApiProvider)
          .create(
            CheckoutDraft(
              recipientName: address.recipientName.trim(),
              recipientPhone: _nationalPhone(address.recipientPhone),
              provinceCode: address.provinceCode,
              addressDetail: detail,
              invoiceInfo: _needInvoice
                  ? InvoiceInfo(
                      name: _companyName.text.trim(),
                      taxCode: _taxCode.text.trim(),
                      address: _companyAddress.text.trim(),
                      email: _companyEmail.text.trim(),
                    )
                  : null,
            ),
          );
      if (mounted) {
        context.pushReplacement(
          AppRoutes.checkoutStatus(created.checkoutId),
          extra: created,
        );
      }
    } on AppFailure catch (failure) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(Strings.failure(failure))),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final addresses = ref.watch(addressesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Xác nhận thanh toán')),
      body: addresses.when(
        loading: () => const LoadingState(message: 'Đang tải địa chỉ nhận hàng…'),
        error: (error, _) => ErrorState(
          message: error is AppFailure ? Strings.failure(error) : 'Không thể tải địa chỉ.',
          onRetry: () => ref.invalidate(addressesProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return EmptyState(
              icon: Icons.location_on_outlined,
              title: 'Bạn chưa có địa chỉ nhận hàng',
              message: 'Hãy thêm địa chỉ trước khi tạo phiên thanh toán VNPay.',
              actionLabel: 'Thêm địa chỉ',
              onAction: () => context.push(AppRoutes.addressForm),
            );
          }
          final selected = _selectedAddress(items);
          final cart = ref.watch(cartProvider(selected.provinceCode));
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                _SectionTitle(
                  title: 'Địa chỉ nhận hàng',
                  action: TextButton.icon(
                    onPressed: _submitting ? null : () => context.push(AppRoutes.addressForm),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Thêm'),
                  ),
                ),
                for (final address in items)
                  _AddressChoice(
                    address: address,
                    selected: address.id == selected.id,
                    onTap: _submitting
                        ? null
                        : () => setState(() => _selectedAddressId = address.id),
                  ),
                const SizedBox(height: 18),
                Text('Hóa đơn', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: [
                      SwitchListTile(
                        value: _needInvoice,
                        onChanged: _submitting
                            ? null
                            : (value) => setState(() => _needInvoice = value),
                        title: const Text('Xuất hóa đơn doanh nghiệp'),
                        subtitle: const Text('Áp dụng chung cho các đơn của mọi shop.'),
                      ),
                      if (_needInvoice)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _companyName,
                                enabled: !_submitting,
                                decoration: const InputDecoration(labelText: 'Tên đơn vị *'),
                                validator: _required,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _taxCode,
                                enabled: !_submitting,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: 'Mã số thuế *'),
                                validator: _taxCodeValidator,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _companyAddress,
                                enabled: !_submitting,
                                decoration: const InputDecoration(labelText: 'Địa chỉ đơn vị *'),
                                validator: _required,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _companyEmail,
                                enabled: !_submitting,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(
                                  labelText: 'Email nhận hóa đơn *',
                                ),
                                validator: _emailValidator,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Text('Phương thức thanh toán', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                const Card(
                  child: ListTile(
                    leading: Icon(Icons.account_balance_outlined, color: MoonkageColors.royalRed),
                    title: Text('VNPay'),
                    subtitle: Text('Thanh toán an toàn trên trang của VNPay.'),
                    trailing: Icon(Icons.check_circle_rounded, color: MoonkageColors.jade),
                  ),
                ),
                const SizedBox(height: 18),
                cart.when(
                  loading: () => const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
                  error: (error, _) => ErrorState(
                    message: error is AppFailure
                        ? Strings.failure(error)
                        : 'Không thể tính lại giỏ hàng.',
                    onRetry: () => ref.invalidate(cartProvider(selected.provinceCode)),
                  ),
                  data: (value) => _CheckoutSummary(
                    cart: value,
                    submitting: _submitting,
                    onSubmit: () => _submit(selected),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  static String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Thông tin này không được để trống.' : null;

  static String? _taxCodeValidator(String? value) {
    final input = value?.trim() ?? '';
    return RegExp(r'^(\d{10}(-\d{3})?|\d{12})$').hasMatch(input)
        ? null
        : 'Mã số thuế gồm 10, 12 hoặc 10-3 chữ số.';
  }

  static String? _emailValidator(String? value) {
    final input = value?.trim() ?? '';
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(input) ? null : 'Email không hợp lệ.';
  }

  static String _nationalPhone(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('84') && digits.length == 11) return '0${digits.substring(2)}';
    if (digits.length == 9) return '0$digits';
    return digits;
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.action});

  final String title;
  final Widget action;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
      action,
    ],
  );
}

class _AddressChoice extends StatelessWidget {
  const _AddressChoice({required this.address, required this.selected, required this.onTap});

  final DeliveryAddress address;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Card(
    color: selected ? MoonkageColors.paleGold : null,
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? MoonkageColors.royalRed : MoonkageColors.mutedInk,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          address.recipientName,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Text(address.recipientPhone),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(address.fullAddress.isEmpty ? address.detail : address.fullAddress),
                  if (address.isDefault) ...[
                    const SizedBox(height: 6),
                    const Text('Mặc định', style: TextStyle(color: MoonkageColors.royalRed)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _CheckoutSummary extends StatelessWidget {
  const _CheckoutSummary({
    required this.cart,
    required this.submitting,
    required this.onSubmit,
  });

  final Cart cart;
  final bool submitting;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final subtotal = cart.groups.fold(0, (sum, group) => sum + group.subtotal);
    final shipping = cart.groups.fold(0, (sum, group) => sum + (group.shippingFee ?? 0));
    final canSubmit =
        !cart.isEmpty &&
        cart.groups.every(
          (group) => group.deliverable && group.items.every((item) => item.available),
        );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Tóm tắt thanh toán', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 14),
            _MoneyRow(label: 'Tiền bánh', value: formatVnd(subtotal)),
            const SizedBox(height: 8),
            _MoneyRow(label: 'Phí giao hàng', value: formatVnd(shipping)),
            const Divider(height: 28),
            _MoneyRow(label: 'Tổng cộng', value: formatVnd(cart.totalAmount), emphasized: true),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: canSubmit && !submitting ? onSubmit : null,
              icon: submitting
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.lock_outline_rounded),
              label: Text(submitting ? 'Đang giữ hàng…' : 'Thanh toán qua VNPay'),
            ),
            const SizedBox(height: 8),
            const Text(
              'Bạn sẽ được chuyển sang trình duyệt để thanh toán. Đơn chỉ được tạo sau khi backend nhận xác nhận từ VNPay.',
              textAlign: TextAlign.center,
              style: TextStyle(color: MoonkageColors.mutedInk, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoneyRow extends StatelessWidget {
  const _MoneyRow({required this.label, required this.value, this.emphasized = false});

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Text(label)),
      Text(
        value,
        style: TextStyle(
          fontWeight: emphasized ? FontWeight.w800 : FontWeight.w600,
          fontSize: emphasized ? 18 : null,
          color: emphasized ? MoonkageColors.royalRed : null,
        ),
      ),
    ],
  );
}
