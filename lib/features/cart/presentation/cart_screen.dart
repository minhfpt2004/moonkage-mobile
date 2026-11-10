import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:moonkage_verify/core/errors/app_failure.dart';
import 'package:moonkage_verify/core/strings.dart';
import 'package:moonkage_verify/core/theme/moonkage_colors.dart';
import 'package:moonkage_verify/core/widgets/content_state.dart';
import 'package:moonkage_verify/features/account/domain/delivery_region_provider.dart';
import 'package:moonkage_verify/features/cart/data/cart_api.dart';
import 'package:moonkage_verify/features/cart/domain/cart.dart';
import 'package:moonkage_verify/features/catalog/domain/product.dart';
import 'package:moonkage_verify/router.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final province = ref.watch(deliveryProvinceProvider);
    final asyncCart = ref.watch(cartProvider(province.code));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Giỏ hàng'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Chip(
              avatar: const Icon(Icons.location_on_outlined, size: 17),
              label: Text(province.name),
            ),
          ),
        ],
      ),
      body: asyncCart.when(
        loading: () => const LoadingState(message: 'Đang tải giỏ hàng…'),
        error: (error, _) => ErrorState(
          message: error is AppFailure ? Strings.failure(error) : 'Không thể tải giỏ hàng.',
          onRetry: () => ref.invalidate(cartProvider(province.code)),
        ),
        data: (cart) => cart.isEmpty
            ? EmptyState(
                icon: Icons.shopping_bag_outlined,
                title: 'Giỏ hàng đang trống',
                message: 'Hãy chọn những chiếc bánh và hộp quà dành cho mùa đoàn viên.',
                actionLabel: 'Khám phá sản phẩm',
                onAction: () => context.go(AppRoutes.catalog),
              )
            : _CartContent(cart: cart, provinceCode: province.code),
      ),
    );
  }
}

class _CartContent extends ConsumerStatefulWidget {
  const _CartContent({required this.cart, required this.provinceCode});

  final Cart cart;
  final String provinceCode;

  @override
  ConsumerState<_CartContent> createState() => _CartContentState();
}

class _CartContentState extends ConsumerState<_CartContent> {
  final _busyItems = <String>{};

  Future<void> _refresh() =>
      ref.refresh(cartProvider(widget.provinceCode).future).then<void>((_) {});

  Future<void> _change(CartLine line, int quantity) async {
    if (quantity < 1 || _busyItems.contains(line.itemId)) return;
    setState(() => _busyItems.add(line.itemId));
    try {
      await ref.read(cartApiProvider).updateItem(line.itemId, quantity);
      await _refresh();
    } on AppFailure catch (failure) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(Strings.failure(failure))),
        );
      }
    } finally {
      if (mounted) setState(() => _busyItems.remove(line.itemId));
    }
  }

  Future<void> _remove(CartLine line) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa khỏi giỏ hàng?'),
        content: Text('Xóa “${line.productName}” khỏi giỏ hàng của bạn?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xóa')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busyItems.add(line.itemId));
    try {
      await ref.read(cartApiProvider).removeItem(line.itemId);
      await _refresh();
    } on AppFailure catch (failure) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(Strings.failure(failure))),
        );
      }
    } finally {
      if (mounted) setState(() => _busyItems.remove(line.itemId));
    }
  }

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: _refresh,
    child: ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Text(
          'Đơn hàng được chia theo từng hiệu bánh và phí giao của mỗi shop.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: MoonkageColors.mutedInk),
        ),
        const SizedBox(height: 16),
        for (final group in widget.cart.groups) ...[
          _ShopGroupCard(
            group: group,
            busyItems: _busyItems,
            onChange: _change,
            onRemove: _remove,
          ),
          const SizedBox(height: 14),
        ],
        _SummaryCard(cart: widget.cart),
      ],
    ),
  );
}

class _ShopGroupCard extends StatelessWidget {
  const _ShopGroupCard({
    required this.group,
    required this.busyItems,
    required this.onChange,
    required this.onRemove,
  });

  final CartGroup group;
  final Set<String> busyItems;
  final void Function(CartLine line, int quantity) onChange;
  final ValueChanged<CartLine> onRemove;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: Column(
      children: [
        Container(
          color: MoonkageColors.surfaceContainer,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.storefront_outlined, color: MoonkageColors.royalRed),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  group.vendorName.isEmpty ? 'Hiệu bánh' : group.vendorName,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                group.shippingFee == null ? 'Không giao được' : formatVnd(group.shippingFee!),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: group.deliverable
                      ? MoonkageColors.ink
                      : Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ),
        ),
        if (!group.deliverable)
          Container(
            width: double.infinity,
            color: Theme.of(context).colorScheme.errorContainer,
            padding: const EdgeInsets.all(12),
            child: const Text('Shop này chưa giao tới tỉnh bạn đã chọn.'),
          ),
        for (var index = 0; index < group.items.length; index++) ...[
          _CartLineRow(
            line: group.items[index],
            busy: busyItems.contains(group.items[index].itemId),
            onChange: onChange,
            onRemove: onRemove,
          ),
          if (index + 1 < group.items.length) const Divider(height: 1, indent: 16, endIndent: 16),
        ],
        Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const Expanded(child: Text('Tổng của shop')),
              Text(formatVnd(group.total), style: const TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ],
    ),
  );
}

class _CartLineRow extends StatelessWidget {
  const _CartLineRow({
    required this.line,
    required this.busy,
    required this.onChange,
    required this.onRemove,
  });

  final CartLine line;
  final bool busy;
  final void Function(CartLine line, int quantity) onChange;
  final ValueChanged<CartLine> onRemove;

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: line.available ? 1 : 0.55,
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: MoonkageColors.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.bakery_dining_rounded, color: MoonkageColors.royalRed),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () => context.push(AppRoutes.product(line.productId)),
                  child: Text(
                    line.productName.isEmpty ? 'Sản phẩm không còn kinh doanh' : line.productName,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  formatVnd(line.unitPrice),
                  style: const TextStyle(color: MoonkageColors.royalRed),
                ),
                if (!line.available) ...[
                  const SizedBox(height: 5),
                  Text(
                    'Sản phẩm hiện không khả dụng',
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    IconButton.outlined(
                      onPressed: busy || line.quantity <= 1
                          ? null
                          : () => onChange(line, line.quantity - 1),
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.remove_rounded, size: 18),
                    ),
                    SizedBox(
                      width: 38,
                      child: busy
                          ? const Center(
                              child: SizedBox.square(
                                dimension: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : Text('${line.quantity}', textAlign: TextAlign.center),
                    ),
                    IconButton.outlined(
                      onPressed: busy || !line.available
                          ? null
                          : () => onChange(line, line.quantity + 1),
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.add_rounded, size: 18),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: busy ? null : () => onRemove(line),
                      tooltip: 'Xóa khỏi giỏ',
                      icon: const Icon(Icons.delete_outline_rounded),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.cart});

  final Cart cart;

  @override
  Widget build(BuildContext context) {
    final subtotal = cart.groups.fold(0, (sum, group) => sum + group.subtotal);
    final shipping = cart.groups.fold(
      0,
      (sum, group) => sum + (group.deliverable ? group.shippingFee ?? 0 : 0),
    );
    final canCheckout = cart.groups.every(
      (group) => group.deliverable && group.items.every((item) => item.available),
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Tóm tắt giỏ hàng', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            _SummaryRow(label: 'Tiền bánh (${cart.itemCount} hộp)', value: formatVnd(subtotal)),
            const SizedBox(height: 8),
            _SummaryRow(label: 'Phí giao hàng', value: formatVnd(shipping)),
            const Divider(height: 28),
            _SummaryRow(
              label: 'Tổng thanh toán',
              value: formatVnd(cart.totalAmount),
              emphasized: true,
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: canCheckout ? () => context.push(AppRoutes.checkout) : null,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('Tiến hành thanh toán'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value, this.emphasized = false});

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(label, style: emphasized ? const TextStyle(fontWeight: FontWeight.w700) : null),
      ),
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
