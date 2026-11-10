import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:moonkage_verify/core/errors/app_failure.dart';
import 'package:moonkage_verify/core/strings.dart';
import 'package:moonkage_verify/core/theme/moonkage_colors.dart';
import 'package:moonkage_verify/core/widgets/content_state.dart';
import 'package:moonkage_verify/features/account/domain/delivery_region_provider.dart';
import 'package:moonkage_verify/features/cart/data/cart_api.dart';
import 'package:moonkage_verify/features/catalog/data/catalog_api.dart';
import 'package:moonkage_verify/features/catalog/domain/product.dart';
import 'package:moonkage_verify/features/catalog/presentation/widgets/product_image.dart';
import 'package:moonkage_verify/features/communication/data/communication_api.dart';
import 'package:moonkage_verify/router.dart';

class ProductDetailScreen extends ConsumerWidget {
  const ProductDetailScreen({required this.productId, super.key});

  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final province = ref.watch(deliveryProvinceProvider);
    final product = ref.watch(
      productDetailProvider((id: productId, provinceCode: province.code)),
    );
    return Scaffold(
      appBar: product.hasValue ? null : AppBar(),
      body: product.when(
        loading: () => const LoadingState(message: 'Đang tải thông tin sản phẩm…'),
        error: (error, _) => SafeArea(
          child: ErrorState(
            message: error is AppFailure ? Strings.failure(error) : 'Không thể tải sản phẩm.',
            onRetry: () => ref.invalidate(
              productDetailProvider((id: productId, provinceCode: province.code)),
            ),
          ),
        ),
        data: (value) => _ProductContent(product: value),
      ),
      bottomNavigationBar: product.hasValue
          ? _AddToCartBar(product: product.requireValue, provinceCode: province.code)
          : null,
    );
  }
}

class _AddToCartBar extends ConsumerStatefulWidget {
  const _AddToCartBar({required this.product, required this.provinceCode});

  final Product product;
  final String provinceCode;

  @override
  ConsumerState<_AddToCartBar> createState() => _AddToCartBarState();
}

class _AddToCartBarState extends ConsumerState<_AddToCartBar> {
  var _quantity = 1;
  var _adding = false;
  var _chatting = false;

  int get _maximum {
    final quoteLimit = widget.product.quoteThreshold;
    final maximum = quoteLimit == null
        ? widget.product.stock
        : (widget.product.stock < quoteLimit - 1 ? widget.product.stock : quoteLimit - 1);
    return maximum < 0 ? 0 : maximum;
  }

  bool get _canAdd => widget.product.inStock && !widget.product.isOwn && _maximum > 0 && !_adding;

  Future<void> _chat() async {
    if (_chatting || widget.product.vendorId.isEmpty || widget.product.isOwn) return;
    setState(() => _chatting = true);
    try {
      final conversation = await ref
          .read(communicationApiProvider)
          .startConversation(widget.product.vendorId);
      ref.invalidate(conversationsProvider);
      if (mounted) {
        unawaited(
          context.push(
            '${AppRoutes.conversation(conversation.id)}?name=${Uri.encodeQueryComponent(conversation.vendorName)}',
          ),
        );
      }
    } on AppFailure catch (failure) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(Strings.failure(failure))),
        );
      }
    } finally {
      if (mounted) setState(() => _chatting = false);
    }
  }

  Future<void> _add() async {
    if (!_canAdd) return;
    setState(() => _adding = true);
    try {
      await ref
          .read(cartApiProvider)
          .addItem(
            productId: widget.product.id,
            quantity: _quantity,
          );
      ref.invalidate(cartProvider(widget.provinceCode));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã thêm $_quantity hộp vào giỏ hàng.')),
        );
      }
    } on AppFailure catch (failure) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(Strings.failure(failure))),
        );
      }
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final unavailableLabel = widget.product.isOwn
        ? 'Không thể mua sản phẩm của bạn'
        : 'Tạm hết hàng';
    return Material(
      elevation: 12,
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Row(
            children: [
              IconButton.outlined(
                tooltip: 'Nhắn cửa hàng',
                onPressed: _chatting || widget.product.isOwn ? null : _chat,
                icon: _chatting
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.chat_bubble_outline_rounded),
              ),
              const SizedBox(width: 8),
              IconButton.outlined(
                onPressed: _adding || _quantity <= 1 ? null : () => setState(() => _quantity--),
                icon: const Icon(Icons.remove_rounded),
              ),
              SizedBox(
                width: 42,
                child: Text(
                  '$_quantity',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              IconButton.outlined(
                onPressed: _adding || _quantity >= _maximum
                    ? null
                    : () => setState(() => _quantity++),
                icon: const Icon(Icons.add_rounded),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _canAdd ? _add : null,
                  icon: _adding
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.shopping_bag_outlined),
                  label: Text(_canAdd || _adding ? 'Thêm vào giỏ hàng' : unavailableLabel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductContent extends ConsumerWidget {
  const _ProductContent({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attributes = ref.watch(cakeAttributesProvider);
    String label(String code) {
      if (!attributes.hasValue) return code;
      return attributes.requireValue
              .where((attribute) => attribute.code == code)
              .map((attribute) => attribute.label)
              .firstOrNull ??
          code;
    }

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: 320,
          flexibleSpace: FlexibleSpaceBar(
            background: ProductImage(imageUrl: product.imageUrls.firstOrNull ?? ''),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          sliver: SliverList.list(
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (product.brand.isNotEmpty)
                    Chip(label: Text(product.brand), backgroundColor: MoonkageColors.paleGold),
                  Chip(
                    avatar: const Icon(Icons.local_shipping_outlined, size: 17),
                    label: Text(
                      product.deliveryLabel == 'LOCAL' ? 'Giao nội tỉnh' : 'Giao toàn quốc',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(product.name, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              if (product.vendorName.isNotEmpty)
                Row(
                  children: [
                    const Icon(Icons.storefront_outlined, size: 18),
                    const SizedBox(width: 6),
                    Expanded(child: Text(product.vendorName)),
                  ],
                ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      formatVnd(product.listPrice),
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: MoonkageColors.royalRed,
                      ),
                    ),
                  ),
                  if (product.ratingCount > 0)
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: Color(0xFFE49B0F)),
                        Text('${product.ratingAvg.toStringAsFixed(1)} (${product.ratingCount})'),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _SpecRow(
                        label: 'Tình trạng',
                        value: product.inStock ? 'Còn ${product.stock} hộp' : 'Tạm hết hàng',
                      ),
                      if (product.piecesPerBox > 0)
                        _SpecRow(label: 'Quy cách', value: '${product.piecesPerBox} bánh / hộp'),
                      if (product.crustCodes.isNotEmpty)
                        _SpecRow(
                          label: 'Vỏ bánh',
                          value: product.crustCodes.map(label).join(', '),
                        ),
                      if (product.fillingCodes.isNotEmpty)
                        _SpecRow(
                          label: 'Vị nhân',
                          value: product.fillingCodes.map(label).join(', '),
                        ),
                      if (product.expiryDate.isNotEmpty)
                        _SpecRow(label: 'Hạn sử dụng', value: _displayDate(product.expiryDate)),
                      if (product.origin.isNotEmpty)
                        _SpecRow(label: 'Xuất xứ', value: product.origin),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text('Mô tả sản phẩm', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                product.description.isEmpty ? 'Sản phẩm chưa có mô tả.' : product.description,
              ),
              const SizedBox(height: 28),
              Text('Đánh giá từ khách mua', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              _Reviews(productId: product.id),
            ],
          ),
        ),
      ],
    );
  }

  String _displayDate(String value) {
    final date = DateTime.tryParse(value);
    if (date == null) return value;
    String two(int number) => number.toString().padLeft(2, '0');
    return '${two(date.day)}/${two(date.month)}/${date.year}';
  }
}

class _SpecRow extends StatelessWidget {
  const _SpecRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 105,
          child: Text(label, style: const TextStyle(color: MoonkageColors.mutedInk)),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    ),
  );
}

class _Reviews extends ConsumerWidget {
  const _Reviews({required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviews = ref.watch(productReviewsProvider(productId));
    return reviews.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => OutlinedButton(
        onPressed: () => ref.invalidate(productReviewsProvider(productId)),
        child: const Text('Tải lại đánh giá'),
      ),
      data: (items) {
        if (items.isEmpty) {
          return const Text(
            'Sản phẩm chưa có đánh giá.',
            style: TextStyle(color: MoonkageColors.mutedInk),
          );
        }
        return Column(
          children: [
            for (final review in items)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          for (var index = 0; index < 5; index++)
                            Icon(
                              index < review.rating
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              size: 18,
                              color: const Color(0xFFE49B0F),
                            ),
                        ],
                      ),
                      if (review.content.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(review.content),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
