import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moonkage_verify/core/errors/app_failure.dart';
import 'package:moonkage_verify/core/platform/external_url_launcher.dart';
import 'package:moonkage_verify/core/strings.dart';
import 'package:moonkage_verify/core/theme/moonkage_colors.dart';
import 'package:moonkage_verify/core/widgets/content_state.dart';
import 'package:moonkage_verify/features/b2b/data/quotation_api.dart';
import 'package:moonkage_verify/features/b2b/domain/quotation.dart';
import 'package:moonkage_verify/features/catalog/domain/product.dart';

class QuoteRequestDetailScreen extends ConsumerStatefulWidget {
  const QuoteRequestDetailScreen({required this.requestId, super.key});

  final String requestId;

  @override
  ConsumerState<QuoteRequestDetailScreen> createState() => _QuoteRequestDetailScreenState();
}

class _QuoteRequestDetailScreenState extends ConsumerState<QuoteRequestDetailScreen> {
  String? _acceptingQuoteId;

  void _refresh() {
    ref
      ..invalidate(quoteRequestProvider(widget.requestId))
      ..invalidate(quoteInvitationsProvider(widget.requestId))
      ..invalidate(vendorQuotesProvider(widget.requestId))
      ..invalidate(quoteRequestsProvider);
  }

  Future<void> _accept(VendorQuote quote) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chấp nhận báo giá?'),
        content: Text(
          'Bạn sẽ chọn ${quote.vendorName} và chuyển sang thanh toán tiền cọc ${formatVnd(quote.depositAmount)}.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Để sau')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Chấp nhận'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _acceptingQuoteId = quote.id);
    try {
      final acceptance = await ref.read(quotationApiProvider).accept(widget.requestId, quote.id);
      _refresh();
      final opened = await ref.read(externalUrlLauncherProvider).open(acceptance.paymentUrl);
      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể mở trang thanh toán tiền cọc.')),
        );
      }
    } on AppFailure catch (failure) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(Strings.failure(failure))),
        );
      }
    } finally {
      if (mounted) setState(() => _acceptingQuoteId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = ref.watch(quoteRequestProvider(widget.requestId));
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết yêu cầu')),
      body: request.when(
        loading: () => const LoadingState(message: 'Đang tải yêu cầu…'),
        error: (error, _) => ErrorState(
          message: error is AppFailure ? Strings.failure(error) : 'Không thể tải yêu cầu.',
          onRetry: _refresh,
        ),
        data: (value) => RefreshIndicator(
          onRefresh: () async => _refresh(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              _RequestOverview(request: value),
              const SizedBox(height: 14),
              _InvitationCard(requestId: value.id),
              const SizedBox(height: 14),
              _QuotesCard(
                request: value,
                acceptingQuoteId: _acceptingQuoteId,
                onAccept: _accept,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RequestOverview extends StatelessWidget {
  const _RequestOverview({required this.request});

  final BuyerQuoteRequest request;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(request.type.label, style: Theme.of(context).textTheme.titleLarge),
              ),
              Chip(label: Text(request.status.label)),
            ],
          ),
          const SizedBox(height: 12),
          _InfoRow(label: 'Số lượng', value: '${request.quantity} sản phẩm'),
          if (request.budget != null)
            _InfoRow(label: 'Ngân sách', value: formatVnd(request.budget!)),
          _InfoRow(
            label: 'Tùy chỉnh',
            value: request.customTypes.isEmpty
                ? 'Không có'
                : request.customTypes.map((type) => type.label).join(', '),
          ),
          if (request.customSpec.isNotEmpty) _InfoRow(label: 'Yêu cầu', value: request.customSpec),
          _InfoRow(
            label: 'Hạn giao',
            value: request.deliveryDeadline == null ? '—' : _formatDate(request.deliveryDeadline!),
          ),
          const Divider(height: 24),
          Text(
            'Giao đến ${request.delivery.recipientName}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 5),
          Text(request.delivery.recipientPhone),
          Text(request.delivery.addressDetail),
        ],
      ),
    ),
  );
}

class _InvitationCard extends ConsumerWidget {
  const _InvitationCard({required this.requestId});

  final String requestId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invitations = ref.watch(quoteInvitationsProvider(requestId));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nhà cung cấp được mời', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            invitations.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => OutlinedButton(
                onPressed: () => ref.invalidate(quoteInvitationsProvider(requestId)),
                child: const Text('Tải lại lời mời'),
              ),
              data: (items) => items.isEmpty
                  ? const Text('Chưa có nhà cung cấp phù hợp được mời.')
                  : Column(
                      children: items
                          .map(
                            (item) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.storefront_outlined),
                              title: Text(item.vendorName),
                              subtitle: item.declineReason.isEmpty
                                  ? null
                                  : Text(item.declineReason),
                              trailing: Text(_invitationLabel(item.status)),
                            ),
                          )
                          .toList(growable: false),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuotesCard extends ConsumerWidget {
  const _QuotesCard({
    required this.request,
    required this.acceptingQuoteId,
    required this.onAccept,
  });

  final BuyerQuoteRequest request;
  final String? acceptingQuoteId;
  final ValueChanged<VendorQuote> onAccept;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quotes = ref.watch(vendorQuotesProvider(request.id));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text('Báo giá nhận được', style: Theme.of(context).textTheme.titleLarge),
        ),
        const SizedBox(height: 10),
        quotes.when(
          loading: () => const Card(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
          error: (_, _) => Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: OutlinedButton(
                onPressed: () => ref.invalidate(vendorQuotesProvider(request.id)),
                child: const Text('Tải lại báo giá'),
              ),
            ),
          ),
          data: (items) => items.isEmpty
              ? const Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Chưa có báo giá. Nhà cung cấp sẽ phản hồi tại đây.'),
                  ),
                )
              : Column(
                  children: items
                      .map(
                        (quote) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _QuoteCard(
                            quote: quote,
                            canAccept: request.status == QuoteRequestStatus.open,
                            accepting: acceptingQuoteId == quote.id,
                            onAccept: () => onAccept(quote),
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
        ),
      ],
    );
  }
}

class _QuoteCard extends StatelessWidget {
  const _QuoteCard({
    required this.quote,
    required this.canAccept,
    required this.accepting,
    required this.onAccept,
  });

  final VendorQuote quote;
  final bool canAccept;
  final bool accepting;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(quote.vendorName, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          for (final line in quote.items)
            _InfoRow(
              label: '${line.quantity} × ${line.description}',
              value: formatVnd(line.amount),
            ),
          if (quote.customSurcharge > 0)
            _InfoRow(label: 'Phí tùy chỉnh', value: formatVnd(quote.customSurcharge)),
          _InfoRow(label: 'Phí giao hàng', value: formatVnd(quote.shippingFee)),
          const Divider(height: 22),
          _InfoRow(label: 'Tổng báo giá', value: formatVnd(quote.totalAmount), emphasized: true),
          _InfoRow(label: 'Tiền cọc', value: formatVnd(quote.depositAmount)),
          _InfoRow(label: 'Còn lại', value: formatVnd(quote.remainingAmount)),
          if (quote.deliveryDate != null)
            _InfoRow(label: 'Ngày giao', value: _formatDate(quote.deliveryDate!)),
          if (quote.notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(quote.notes, style: const TextStyle(color: MoonkageColors.mutedInk)),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: canAccept && quote.acceptable && !accepting ? onAccept : null,
              child: accepting
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(quote.status == 'ACCEPTED' ? 'Đã chấp nhận' : 'Chọn báo giá này'),
            ),
          ),
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
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(color: MoonkageColors.mutedInk)),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(fontWeight: emphasized ? FontWeight.w800 : FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}

String _formatDate(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

String _invitationLabel(String value) => switch (value) {
  'ACCEPTED' => 'Đã nhận',
  'DECLINED' => 'Từ chối',
  _ => 'Đang chờ',
};
