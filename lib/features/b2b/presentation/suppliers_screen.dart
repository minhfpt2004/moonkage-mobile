import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:moonkage_verify/core/errors/app_failure.dart';
import 'package:moonkage_verify/core/strings.dart';
import 'package:moonkage_verify/core/theme/moonkage_colors.dart';
import 'package:moonkage_verify/core/widgets/content_state.dart';
import 'package:moonkage_verify/features/b2b/data/quotation_api.dart';
import 'package:moonkage_verify/features/b2b/domain/quotation.dart';
import 'package:moonkage_verify/router.dart';

class SuppliersScreen extends ConsumerStatefulWidget {
  const SuppliersScreen({super.key});

  @override
  ConsumerState<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends ConsumerState<SuppliersScreen> {
  var _query = '';

  @override
  Widget build(BuildContext context) {
    final suppliers = ref.watch(suppliersProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Nhà cung cấp B2B')),
      body: suppliers.when(
        loading: () => const LoadingState(message: 'Đang tìm nhà cung cấp…'),
        error: (error, _) => ErrorState(
          message: error is AppFailure ? Strings.failure(error) : 'Không thể tải nhà cung cấp.',
          onRetry: () => ref.invalidate(suppliersProvider),
        ),
        data: (items) {
          final filtered = items
              .where((item) => item.businessName.toLowerCase().contains(_query.toLowerCase()))
              .toList(growable: false);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [
              TextField(
                onChanged: (value) => setState(() => _query = value.trim()),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search_rounded),
                  hintText: 'Tìm theo tên nhà cung cấp',
                ),
              ),
              const SizedBox(height: 14),
              for (final supplier in filtered) ...[
                _SupplierCard(supplier: supplier),
                const SizedBox(height: 10),
              ],
              if (filtered.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 80),
                  child: Text('Không tìm thấy nhà cung cấp phù hợp.', textAlign: TextAlign.center),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _SupplierCard extends StatelessWidget {
  const _SupplierCard({required this.supplier});

  final Supplier supplier;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: MoonkageColors.paleGold,
                foregroundColor: MoonkageColors.royalRed,
                child: Icon(Icons.storefront_outlined),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  supplier.businessName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (supplier.supplySource.isNotEmpty) Text('Nguồn hàng: ${supplier.supplySource}'),
          Text('Số lượng tối thiểu: ${supplier.minQuantity ?? 'Liên hệ'}'),
          Text('Thời gian chuẩn bị: ${supplier.leadTimeDays ?? '—'} ngày'),
          if (supplier.customCapabilities.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: supplier.customCapabilities
                  .map((value) => Chip(label: Text(_customLabel(value))))
                  .toList(growable: false),
            ),
          ],
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: supplier.isOwn
                  ? null
                  : () => context.push(
                      '${AppRoutes.newQuoteRequest}?vendorId=${Uri.encodeQueryComponent(supplier.id)}',
                    ),
              icon: const Icon(Icons.request_quote_outlined),
              label: Text(supplier.isOwn ? 'Nhà cung cấp của bạn' : 'Yêu cầu báo giá'),
            ),
          ),
        ],
      ),
    ),
  );
}

String _customLabel(String value) => switch (value) {
  'BAG' => 'Túi',
  'CARD' => 'Thiệp',
  'STICKER' => 'Nhãn dán',
  'TEMPLATE_BOX' => 'Hộp theo mẫu',
  _ => value,
};
