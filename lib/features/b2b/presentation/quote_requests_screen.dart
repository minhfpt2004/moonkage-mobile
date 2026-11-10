import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:moonkage_verify/core/errors/app_failure.dart';
import 'package:moonkage_verify/core/strings.dart';
import 'package:moonkage_verify/core/theme/moonkage_colors.dart';
import 'package:moonkage_verify/core/widgets/content_state.dart';
import 'package:moonkage_verify/features/b2b/data/quotation_api.dart';
import 'package:moonkage_verify/features/b2b/domain/quotation.dart';
import 'package:moonkage_verify/features/catalog/domain/product.dart';
import 'package:moonkage_verify/router.dart';

class QuoteRequestsScreen extends ConsumerWidget {
  const QuoteRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(quoteRequestsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yêu cầu báo giá'),
        actions: [
          IconButton(
            tooltip: 'Nhà cung cấp',
            onPressed: () => context.push(AppRoutes.suppliers),
            icon: const Icon(Icons.storefront_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.newQuoteRequest),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tạo yêu cầu'),
      ),
      body: requests.when(
        loading: () => const LoadingState(message: 'Đang tải yêu cầu báo giá…'),
        error: (error, _) => ErrorState(
          message: error is AppFailure ? Strings.failure(error) : 'Không thể tải yêu cầu báo giá.',
          onRetry: () => ref.invalidate(quoteRequestsProvider),
        ),
        data: (items) => RefreshIndicator(
          onRefresh: () => ref.refresh(quoteRequestsProvider.future).then<void>((_) {}),
          child: items.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  children: const [
                    SizedBox(height: 100),
                    Icon(Icons.request_quote_outlined, size: 64, color: MoonkageColors.mutedInk),
                    SizedBox(height: 16),
                    Text(
                      'Bạn chưa có yêu cầu báo giá.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Tạo yêu cầu cho đơn số lượng lớn hoặc bao bì tùy chỉnh.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, index) => _RequestCard(request: items[index]),
                ),
        ),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request});

  final BuyerQuoteRequest request;

  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => context.push(AppRoutes.quoteRequest(request.id)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    request.type.label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _StatusPill(status: request.status),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '${request.quantity} sản phẩm · ${request.customTypes.map((e) => e.label).join(', ')}',
            ),
            if (request.budget != null) ...[
              const SizedBox(height: 5),
              Text('Ngân sách ${formatVnd(request.budget!)}'),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.storefront_outlined, size: 18),
                const SizedBox(width: 5),
                Text('${request.invitedCount} nhà cung cấp'),
                const SizedBox(width: 18),
                const Icon(Icons.description_outlined, size: 18),
                const SizedBox(width: 5),
                Text('${request.quoteCount} báo giá'),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final QuoteRequestStatus status;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: status == QuoteRequestStatus.open ? MoonkageColors.paleJade : MoonkageColors.paleGold,
      borderRadius: BorderRadius.circular(99),
    ),
    child: Text(status.label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
  );
}
