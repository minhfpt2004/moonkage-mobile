import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:moonkage_verify/core/theme/moonkage_colors.dart';
import 'package:moonkage_verify/features/account/domain/delivery_region_provider.dart';
import 'package:moonkage_verify/features/catalog/data/catalog_api.dart';
import 'package:moonkage_verify/features/catalog/domain/product.dart';
import 'package:moonkage_verify/features/catalog/presentation/widgets/product_card.dart';
import 'package:moonkage_verify/features/communication/data/communication_api.dart';
import 'package:moonkage_verify/router.dart';

class CommerceHomeScreen extends ConsumerWidget {
  const CommerceHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final province = ref.watch(deliveryProvinceProvider);
    final featured = ref.watch(featuredProductsProvider(province.code));
    return Scaffold(
      appBar: AppBar(
        title: const _BrandTitle(),
        actions: const [_CommunicationActions()],
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.refresh(featuredProductsProvider(province.code).future).then<void>((_) {}),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              sliver: SliverList.list(
                children: [
                  const _HeroBanner(),
                  const SizedBox(height: 16),
                  const _B2bBanner(),
                  const SizedBox(height: 28),
                  _FeaturedHeader(provinceName: province.name),
                  const SizedBox(height: 12),
                  _FeaturedProducts(
                    products: featured,
                    onRetry: () => ref.invalidate(featuredProductsProvider(province.code)),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturedHeader extends StatelessWidget {
  const _FeaturedHeader({required this.provinceName});

  final String provinceName;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: Text('Sản phẩm nổi bật', style: Theme.of(context).textTheme.titleLarge),
          ),
          TextButton(
            onPressed: () => context.go(AppRoutes.catalog),
            child: const Text('Xem tất cả'),
          ),
        ],
      ),
      Row(
        children: [
          const Icon(Icons.location_on_outlined, size: 17, color: MoonkageColors.mutedInk),
          const SizedBox(width: 5),
          Text(
            'Có thể giao đến $provinceName',
            style: const TextStyle(color: MoonkageColors.mutedInk),
          ),
        ],
      ),
    ],
  );
}

class _CommunicationActions extends ConsumerWidget {
  const _CommunicationActions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);
    final unread = notifications.hasValue ? notifications.requireValue.unread : 0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Tin nhắn',
          onPressed: () => context.push(AppRoutes.conversations),
          icon: const Icon(Icons.chat_bubble_outline_rounded),
        ),
        IconButton(
          tooltip: 'Thông báo',
          onPressed: () => context.push(AppRoutes.notifications),
          icon: Badge(
            isLabelVisible: unread > 0,
            label: Text(unread > 99 ? '99+' : '$unread'),
            child: const Icon(Icons.notifications_none_rounded),
          ),
        ),
      ],
    );
  }
}

class _FeaturedProducts extends StatelessWidget {
  const _FeaturedProducts({required this.products, required this.onRetry});

  final AsyncValue<List<Product>> products;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => products.when(
    loading: () => const SizedBox(
      height: 286,
      child: Center(child: CircularProgressIndicator()),
    ),
    error: (_, _) => SizedBox(
      height: 180,
      child: Card(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, color: MoonkageColors.royalRed),
              const SizedBox(height: 8),
              const Text('Không thể tải sản phẩm nổi bật.'),
              TextButton(onPressed: onRetry, child: const Text('Thử lại')),
            ],
          ),
        ),
      ),
    ),
    data: (items) => items.isEmpty
        ? const SizedBox(
            height: 150,
            child: Card(
              child: Center(child: Text('Chưa có sản phẩm giao đến khu vực này.')),
            ),
          )
        : SizedBox(
            height: 286,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (_, index) => SizedBox(
                width: 178,
                child: ProductCard(product: items[index]),
              ),
            ),
          ),
  );
}

class _BrandTitle extends StatelessWidget {
  const _BrandTitle();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'MOONKAGE',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          letterSpacing: 2.2,
          fontSize: 18,
        ),
      ),
      Text(
        'NGUYỆT VIÊN',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: MoonkageColors.mutedInk,
          letterSpacing: 1.6,
        ),
      ),
    ],
  );
}

class _B2bBanner extends StatelessWidget {
  const _B2bBanner();

  @override
  Widget build(BuildContext context) => Card(
    color: MoonkageColors.paleJade,
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.corporate_fare_outlined, color: MoonkageColors.jade),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Quà tặng doanh nghiệp',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: MoonkageColors.jade,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Nhận và so sánh báo giá cho đơn số lượng lớn, túi, thiệp hoặc hộp theo mẫu.'),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: () => context.push(AppRoutes.newQuoteRequest),
                icon: const Icon(Icons.request_quote_outlined),
                label: const Text('Tạo yêu cầu'),
              ),
              TextButton(
                onPressed: () => context.push(AppRoutes.quoteRequests),
                child: const Text('Yêu cầu của tôi'),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(28),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [MoonkageColors.imperialRed, MoonkageColors.royalRed],
      ),
      boxShadow: const [
        BoxShadow(color: Color(0x33541212), blurRadius: 20, offset: Offset(0, 10)),
      ],
    ),
    child: Stack(
      children: [
        const Positioned(
          right: -4,
          top: -12,
          child: Icon(Icons.brightness_2_rounded, color: Color(0x33FED65B), size: 118),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'HOÀNG TRIỀU MỸ VỊ',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: MoonkageColors.gold,
                letterSpacing: 1.8,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Trọn vị đoàn viên\ntrong từng món quà',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Khám phá bánh trung thu và hộp quà mang dấu ấn riêng.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFFFFEDEA),
              ),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: () => context.go(AppRoutes.catalog),
              style: FilledButton.styleFrom(
                backgroundColor: MoonkageColors.gold,
                foregroundColor: MoonkageColors.ink,
              ),
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('Khám phá ngay'),
            ),
          ],
        ),
      ],
    ),
  );
}
