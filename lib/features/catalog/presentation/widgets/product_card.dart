import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:moonkage_verify/core/theme/moonkage_colors.dart';
import 'package:moonkage_verify/features/catalog/domain/product.dart';
import 'package:moonkage_verify/features/catalog/presentation/widgets/product_image.dart';
import 'package:moonkage_verify/router.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({required this.product, super.key});

  final Product product;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: () => context.push(AppRoutes.product(product.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                ProductImage(imageUrl: product.imageUrls.firstOrNull ?? ''),
                if (!product.inStock)
                  const ColoredBox(
                    color: Color(0x66000000),
                    child: Center(
                      child: Text(
                        'Tạm hết hàng',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.brand.isEmpty ? product.vendorName : product.brand,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: MoonkageColors.royalRed,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700, height: 1.25),
                ),
                const SizedBox(height: 8),
                Text(
                  formatVnd(product.listPrice),
                  style: const TextStyle(
                    color: MoonkageColors.imperialRed,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    if (product.ratingCount > 0) ...[
                      const Icon(Icons.star_rounded, size: 16, color: Color(0xFFE49B0F)),
                      Text('${product.ratingAvg.toStringAsFixed(1)} (${product.ratingCount})'),
                    ] else
                      const Text(
                        'Chưa có đánh giá',
                        style: TextStyle(color: MoonkageColors.mutedInk),
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
