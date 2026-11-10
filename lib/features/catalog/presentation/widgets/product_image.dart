import 'package:flutter/material.dart';
import 'package:moonkage_verify/core/theme/moonkage_colors.dart';

class ProductImage extends StatelessWidget {
  const ProductImage({required this.imageUrl, this.fit = BoxFit.cover, super.key});

  final String imageUrl;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) return const _Fallback();
    return Image.network(
      imageUrl,
      fit: fit,
      width: double.infinity,
      errorBuilder: (_, _, _) => const _Fallback(),
      loadingBuilder: (context, child, progress) => progress == null
          ? child
          : const ColoredBox(
              color: MoonkageColors.surfaceContainer,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
    );
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback();

  @override
  Widget build(BuildContext context) => const ColoredBox(
    color: MoonkageColors.surfaceContainer,
    child: Center(
      child: Icon(Icons.bakery_dining_rounded, size: 56, color: MoonkageColors.royalRed),
    ),
  );
}
