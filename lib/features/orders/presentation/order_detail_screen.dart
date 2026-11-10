import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moonkage_verify/core/errors/app_failure.dart';
import 'package:moonkage_verify/core/platform/external_url_launcher.dart';
import 'package:moonkage_verify/core/strings.dart';
import 'package:moonkage_verify/core/theme/moonkage_colors.dart';
import 'package:moonkage_verify/core/widgets/content_state.dart';
import 'package:moonkage_verify/features/catalog/data/catalog_api.dart';
import 'package:moonkage_verify/features/catalog/domain/product.dart';
import 'package:moonkage_verify/features/catalog/presentation/widgets/product_image.dart';
import 'package:moonkage_verify/features/orders/data/order_api.dart';
import 'package:moonkage_verify/features/orders/domain/order.dart';

class OrderDetailScreen extends ConsumerStatefulWidget {
  const OrderDetailScreen({required this.orderId, super.key});

  final String orderId;

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> with WidgetsBindingObserver {
  var _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  void _refresh() {
    ref
      ..invalidate(orderDetailProvider(widget.orderId))
      ..invalidate(orderProgressProvider(widget.orderId))
      ..invalidate(orderReviewsProvider(widget.orderId))
      ..invalidate(ordersProvider);
  }

  Future<void> _confirmReceived() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận đã nhận hàng?'),
        content: const Text(
          'Chỉ xác nhận khi bạn đã nhận và kiểm tra hàng. Thao tác này không thể hoàn tác.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Để sau')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref.read(orderApiProvider).confirmReceived(widget.orderId);
      _refresh();
    } on AppFailure catch (failure) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(Strings.failure(failure))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _payRemainder() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final payment = await ref.read(orderApiProvider).payRemainder(widget.orderId);
      final opened = await ref.read(externalUrlLauncherProvider).open(payment.paymentUrl);
      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể mở trang thanh toán VNPay.')),
        );
      }
    } on AppFailure catch (failure) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(Strings.failure(failure))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = ref.watch(orderDetailProvider(widget.orderId));
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết đơn hàng')),
      body: order.when(
        loading: () => const LoadingState(message: 'Đang tải chi tiết đơn…'),
        error: (error, _) => ErrorState(
          message: error is AppFailure ? Strings.failure(error) : 'Không thể tải đơn hàng.',
          onRetry: _refresh,
        ),
        data: (value) => RefreshIndicator(
          onRefresh: () async => _refresh(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              _OrderHeader(order: value),
              const SizedBox(height: 14),
              _ItemsCard(order: value),
              const SizedBox(height: 14),
              _DeliveryCard(order: value),
              const SizedBox(height: 14),
              _MoneyCard(order: value),
              const SizedBox(height: 14),
              _ProgressCard(orderId: value.id),
              if (value.kind == OrderKind.buyNow &&
                  (value.status == OrderStatus.delivered ||
                      value.status == OrderStatus.completed)) ...[
                const SizedBox(height: 14),
                _OrderReviewsCard(order: value),
              ],
              if (value.invoiceInfo != null) ...[
                const SizedBox(height: 14),
                _InvoiceCard(invoice: value.invoiceInfo!),
              ],
              if (value.disputeOpen) ...[
                const SizedBox(height: 14),
                Card(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: const ListTile(
                    leading: Icon(Icons.gavel_outlined),
                    title: Text('Đơn hàng đang có khiếu nại'),
                    subtitle: Text('Hệ thống tạm giữ thanh toán cho tới khi có quyết định.'),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              if (value.status == OrderStatus.delivered && value.receivedConfirmedAt == null)
                FilledButton.icon(
                  onPressed: _busy ? null : _confirmReceived,
                  icon: const Icon(Icons.inventory_2_outlined),
                  label: const Text('Tôi đã nhận hàng'),
                ),
              if (value.kind == OrderKind.customOrder &&
                  value.status == OrderStatus.delivered &&
                  value.receivedConfirmedAt != null &&
                  (value.remainingAmount ?? 0) > 0)
                FilledButton.icon(
                  onPressed: _busy ? null : _payRemainder,
                  icon: const Icon(Icons.payment_rounded),
                  label: Text('Thanh toán phần còn lại ${formatVnd(value.remainingAmount!)}'),
                ),
              if (_busy) ...[
                const SizedBox(height: 12),
                const Center(child: CircularProgressIndicator()),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderHeader extends StatelessWidget {
  const _OrderHeader({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            order.vendorName.isEmpty ? 'Hiệu bánh' : order.vendorName,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: order.status == OrderStatus.completed
                  ? MoonkageColors.paleJade
                  : MoonkageColors.paleGold,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(order.status.label, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 12),
          Text('Mã đơn: ${order.id}', style: const TextStyle(color: MoonkageColors.mutedInk)),
          if (order.createdAt != null) ...[
            const SizedBox(height: 5),
            Text(
              'Đặt lúc ${_formatDate(order.createdAt!)}',
              style: const TextStyle(color: MoonkageColors.mutedInk),
            ),
          ],
        ],
      ),
    ),
  );
}

class _ItemsCard extends StatelessWidget {
  const _ItemsCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sản phẩm', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          if (order.items.isEmpty)
            const Text('Danh sách sản phẩm không có trong dữ liệu đơn này.')
          else
            for (var index = 0; index < order.items.length; index++) ...[
              _OrderLineRow(line: order.items[index]),
              if (index + 1 < order.items.length) const Divider(height: 24),
            ],
        ],
      ),
    ),
  );
}

class _OrderLineRow extends StatelessWidget {
  const _OrderLineRow({required this.line});

  final OrderLine line;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(width: 64, height: 64, child: ProductImage(imageUrl: line.imageUrl)),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(line.productName, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 5),
            Text('${formatVnd(line.unitPrice)} × ${line.quantity}'),
          ],
        ),
      ),
      Text(formatVnd(line.subtotal), style: const TextStyle(fontWeight: FontWeight.w700)),
    ],
  );
}

class _DeliveryCard extends StatelessWidget {
  const _DeliveryCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Giao hàng', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          _InfoRow(label: 'Người nhận', value: order.recipientName),
          _InfoRow(label: 'Điện thoại', value: order.recipientPhone),
          _InfoRow(label: 'Địa chỉ', value: order.addressDetail),
          if (order.trackingCode.isNotEmpty)
            _InfoRow(label: 'Mã vận đơn', value: order.trackingCode),
          if (order.deliveryDate.isNotEmpty)
            _InfoRow(label: 'Ngày giao', value: order.deliveryDate),
          if (order.receivedConfirmedAt != null)
            _InfoRow(label: 'Đã xác nhận nhận', value: _formatDate(order.receivedConfirmedAt!)),
        ],
      ),
    ),
  );
}

class _MoneyCard extends StatelessWidget {
  const _MoneyCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _InfoRow(label: 'Tiền bánh', value: formatVnd(order.itemsAmount)),
          _InfoRow(label: 'Phí giao hàng', value: formatVnd(order.shippingFee)),
          if (order.discountAmount > 0)
            _InfoRow(label: 'Giảm giá', value: '-${formatVnd(order.discountAmount)}'),
          if (order.depositAmount != null)
            _InfoRow(label: 'Đã đặt cọc', value: formatVnd(order.depositAmount!)),
          if ((order.remainingAmount ?? 0) > 0)
            _InfoRow(label: 'Còn lại', value: formatVnd(order.remainingAmount!)),
          const Divider(height: 24),
          _InfoRow(label: 'Tổng đơn', value: formatVnd(order.totalAmount), emphasized: true),
        ],
      ),
    ),
  );
}

class _ProgressCard extends ConsumerWidget {
  const _ProgressCard({required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(orderProgressProvider(orderId));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tiến trình đơn hàng', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 14),
            progress.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => OutlinedButton(
                onPressed: () => ref.invalidate(orderProgressProvider(orderId)),
                child: const Text('Tải lại tiến trình'),
              ),
              data: (items) => items.isEmpty
                  ? const Text('Chưa có cập nhật tiến trình.')
                  : Column(
                      children: [
                        for (var index = 0; index < items.length; index++)
                          _ProgressRow(
                            item: items[index],
                            last: index + 1 == items.length,
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({required this.item, required this.last});

  final OrderProgress item;
  final bool last;

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 26,
          child: Column(
            children: [
              const Icon(Icons.circle, size: 14, color: MoonkageColors.royalRed),
              if (!last) Expanded(child: Container(width: 2, color: MoonkageColors.outline)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: last ? 0 : 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.milestone.label, style: const TextStyle(fontWeight: FontWeight.w700)),
                if (item.note.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(item.note),
                ],
                if (item.createdAt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(item.createdAt!),
                    style: const TextStyle(color: MoonkageColors.mutedInk, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _OrderReviewsCard extends ConsumerStatefulWidget {
  const _OrderReviewsCard({required this.order});

  final Order order;

  @override
  ConsumerState<_OrderReviewsCard> createState() => _OrderReviewsCardState();
}

class _OrderReviewsCardState extends ConsumerState<_OrderReviewsCard> {
  String? _submittingProductId;

  Future<void> _writeReview(OrderLine line) async {
    final draft = await showModalBottomSheet<OrderReviewDraft>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _ReviewSheet(line: line),
    );
    if (draft == null || !mounted) return;

    setState(() => _submittingProductId = line.productId);
    try {
      await ref.read(orderApiProvider).createReview(widget.order.id, draft);
      ref
        ..invalidate(orderReviewsProvider(widget.order.id))
        ..invalidate(productReviewsProvider(line.productId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã gửi đánh giá.')),
        );
      }
    } on AppFailure catch (failure) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(Strings.failure(failure))),
        );
      }
    } finally {
      if (mounted) setState(() => _submittingProductId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reviews = ref.watch(orderReviewsProvider(widget.order.id));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Đánh giá sản phẩm', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            const Text(
              'Chia sẻ trải nghiệm của bạn về sản phẩm trong đơn này.',
              style: TextStyle(color: MoonkageColors.mutedInk),
            ),
            const SizedBox(height: 14),
            reviews.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => OutlinedButton.icon(
                onPressed: () => ref.invalidate(orderReviewsProvider(widget.order.id)),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Tải lại đánh giá'),
              ),
              data: (items) {
                final byProduct = {for (final review in items) review.productId: review};
                return Column(
                  children: [
                    for (var index = 0; index < widget.order.items.length; index++) ...[
                      _ReviewProductRow(
                        line: widget.order.items[index],
                        review: byProduct[widget.order.items[index].productId],
                        submitting: _submittingProductId == widget.order.items[index].productId,
                        onWrite: () => _writeReview(widget.order.items[index]),
                      ),
                      if (index + 1 < widget.order.items.length) const Divider(height: 24),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewProductRow extends StatelessWidget {
  const _ReviewProductRow({
    required this.line,
    required this.review,
    required this.submitting,
    required this.onWrite,
  });

  final OrderLine line;
  final OrderReview? review;
  final bool submitting;
  final VoidCallback onWrite;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(width: 52, height: 52, child: ProductImage(imageUrl: line.imageUrl)),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(line.productName, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            if (review == null)
              OutlinedButton.icon(
                onPressed: submitting ? null : onWrite,
                icon: submitting
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.rate_review_outlined),
                label: Text(submitting ? 'Đang gửi…' : 'Viết đánh giá'),
              )
            else ...[
              Row(
                children: List.generate(
                  5,
                  (index) => Icon(
                    index < review!.rating ? Icons.star_rounded : Icons.star_border_rounded,
                    size: 20,
                    color: MoonkageColors.gold,
                  ),
                ),
              ),
              if (review!.content.isNotEmpty) ...[
                const SizedBox(height: 5),
                Text(review!.content),
              ],
              const SizedBox(height: 4),
              Text(
                review!.createdAt == null
                    ? 'Đã đánh giá'
                    : 'Đã đánh giá lúc ${_formatDate(review!.createdAt!)}',
                style: const TextStyle(color: MoonkageColors.mutedInk, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    ],
  );
}

class _ReviewSheet extends StatefulWidget {
  const _ReviewSheet({required this.line});

  final OrderLine line;

  @override
  State<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<_ReviewSheet> {
  final _contentController = TextEditingController();
  var _rating = 5;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.pop(
      context,
      OrderReviewDraft(
        productId: widget.line.productId,
        rating: _rating,
        content: _contentController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Đánh giá sản phẩm', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 6),
          Text(widget.line.productName, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 18),
          const Text('Mức độ hài lòng'),
          const SizedBox(height: 6),
          Row(
            children: List.generate(
              5,
              (index) => IconButton(
                tooltip: '${index + 1} sao',
                onPressed: () => setState(() => _rating = index + 1),
                icon: Icon(
                  index < _rating ? Icons.star_rounded : Icons.star_border_rounded,
                  size: 36,
                  color: MoonkageColors.gold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _contentController,
            maxLength: 2000,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Nhận xét (không bắt buộc)',
              hintText: 'Sản phẩm có đúng mô tả, hương vị thế nào?',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Mỗi sản phẩm trong đơn chỉ được đánh giá một lần.',
            style: TextStyle(color: MoonkageColors.mutedInk, fontSize: 12),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.send_rounded),
              label: Text('Gửi đánh giá $_rating sao'),
            ),
          ),
        ],
      ),
    ),
  );
}

class _InvoiceCard extends StatelessWidget {
  const _InvoiceCard({required this.invoice});

  final OrderInvoice invoice;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Thông tin hóa đơn', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          _InfoRow(label: 'Đơn vị', value: invoice.name),
          _InfoRow(label: 'Mã số thuế', value: invoice.taxCode),
          _InfoRow(label: 'Địa chỉ', value: invoice.address),
          _InfoRow(label: 'Email', value: invoice.email),
        ],
      ),
    ),
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.emphasized = false});

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 112,
          child: Text(label, style: const TextStyle(color: MoonkageColors.mutedInk)),
        ),
        Expanded(
          child: Text(
            value.isEmpty ? '—' : value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontWeight: emphasized ? FontWeight.w800 : FontWeight.w600,
              color: emphasized ? MoonkageColors.royalRed : null,
              fontSize: emphasized ? 18 : null,
            ),
          ),
        ),
      ],
    ),
  );
}

String _formatDate(DateTime value) {
  String two(int number) => number.toString().padLeft(2, '0');
  return '${two(value.hour)}:${two(value.minute)} ${two(value.day)}/${two(value.month)}/${value.year}';
}
