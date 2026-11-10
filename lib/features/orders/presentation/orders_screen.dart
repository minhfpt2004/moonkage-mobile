import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:moonkage_verify/core/errors/app_failure.dart';
import 'package:moonkage_verify/core/strings.dart';
import 'package:moonkage_verify/core/theme/moonkage_colors.dart';
import 'package:moonkage_verify/core/widgets/content_state.dart';
import 'package:moonkage_verify/features/catalog/domain/product.dart';
import 'package:moonkage_verify/features/orders/data/order_api.dart';
import 'package:moonkage_verify/features/orders/domain/order.dart';
import 'package:moonkage_verify/router.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  OrderStatus? _status;

  Future<void> _refresh() => ref.refresh(ordersProvider(_status).future).then<void>((_) {});

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(ordersProvider(_status));
    return Scaffold(
      appBar: AppBar(title: const Text('Đơn hàng')),
      body: Column(
        children: [
          SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                ChoiceChip(
                  label: const Text('Tất cả'),
                  selected: _status == null,
                  onSelected: (_) => setState(() => _status = null),
                ),
                const SizedBox(width: 8),
                for (final status in _filterStatuses) ...[
                  ChoiceChip(
                    label: Text(status.label),
                    selected: _status == status,
                    onSelected: (_) => setState(() => _status = status),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          Expanded(
            child: orders.when(
              loading: () => const LoadingState(message: 'Đang tải đơn hàng…'),
              error: (error, _) => ErrorState(
                message: error is AppFailure ? Strings.failure(error) : 'Không thể tải đơn hàng.',
                onRetry: () => ref.invalidate(ordersProvider(_status)),
              ),
              data: (page) => page.content.isEmpty
                  ? EmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: _status == null ? 'Chưa có đơn hàng' : 'Không có đơn phù hợp',
                      message: _status == null
                          ? 'Đơn được tạo sau khi backend xác nhận thanh toán thành công.'
                          : 'Hãy chọn trạng thái khác để xem đơn hàng.',
                      actionLabel: _status == null ? 'Mua sắm ngay' : null,
                      onAction: _status == null ? () => context.go(AppRoutes.catalog) : null,
                    )
                  : RefreshIndicator(
                      onRefresh: _refresh,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                        itemCount: page.content.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (_, index) => _OrderCard(order: page.content[index]),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

const _filterStatuses = [
  OrderStatus.paid,
  OrderStatus.confirmed,
  OrderStatus.shipping,
  OrderStatus.deposited,
  OrderStatus.awaitingMockupApproval,
  OrderStatus.inProduction,
  OrderStatus.readyToShip,
  OrderStatus.delivered,
  OrderStatus.completed,
];

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => context.push(AppRoutes.order(order.id)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.storefront_outlined, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    order.vendorName.isEmpty ? 'Hiệu bánh' : order.vendorName,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                _StatusChip(status: order.status),
              ],
            ),
            const Divider(height: 26),
            Text(
              order.kind == OrderKind.customOrder ? 'Đơn đặt theo yêu cầu' : 'Đơn mua bánh',
              style: const TextStyle(color: MoonkageColors.mutedInk),
            ),
            const SizedBox(height: 7),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '#${_shortId(order.id)}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  formatVnd(order.totalAmount),
                  style: const TextStyle(
                    color: MoonkageColors.royalRed,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            if (order.createdAt != null) ...[
              const SizedBox(height: 6),
              Text(
                _formatDate(order.createdAt!),
                style: const TextStyle(color: MoonkageColors.mutedInk, fontSize: 12),
              ),
            ],
            if (order.disputeOpen) ...[
              const SizedBox(height: 10),
              const Row(
                children: [
                  Icon(Icons.gavel_outlined, size: 17, color: MoonkageColors.royalRed),
                  SizedBox(width: 6),
                  Text('Đang có khiếu nại', style: TextStyle(color: MoonkageColors.royalRed)),
                ],
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final completed = status == OrderStatus.completed;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: completed ? MoonkageColors.paleJade : MoonkageColors.paleGold,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: completed ? MoonkageColors.jade : const Color(0xFF795400),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

String _shortId(String value) => value.length <= 10 ? value : value.substring(0, 10);
String _formatDate(DateTime value) {
  String two(int number) => number.toString().padLeft(2, '0');
  return '${two(value.hour)}:${two(value.minute)} · ${two(value.day)}/${two(value.month)}/${value.year}';
}
