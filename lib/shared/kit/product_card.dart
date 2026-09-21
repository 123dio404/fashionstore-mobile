import 'package:flutter/material.dart';

import '../../core/models/fashion_models.dart';
import '../../core/theme/app_theme.dart';
import 'buttons.dart';
import 'net_image.dart';

/// Tarjeta de producto del catálogo (grid 2 columnas).
class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onAddToCart,
    this.isFav = false,
    this.onToggleFav,
  });

  final Product product;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;
  final bool isFav;
  final VoidCallback? onToggleFav;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              aspectRatio: 3 / 4,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  NetImage(url: product.image),
                  Positioned(top: 10, left: 10, child: _discountTag()),
                  if (product.isNew)
                    Positioned(top: 34, left: 10, child: _newTag()),
                  if (onToggleFav != null)
                    Positioned(top: 8, right: 8, child: _favButton()),
                  if (onAddToCart != null)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: AddChipButton(onPressed: onAddToCart!),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    product.brand.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySize(
                      10,
                      color: AppColors.muted,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySize(
                      13,
                      weight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 11, color: Color(0xFFF59E0B)),
                      const SizedBox(width: 4),
                      Text(
                        '${product.rating} (${product.reviews})',
                        style: AppTextStyles.bodySize(11, color: AppColors.muted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  PriceRow(product: product),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _discountTag() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          '-${product.discount}%',
          style: AppTextStyles.bodySize(
            10,
            color: Colors.white,
            weight: FontWeight.w700,
          ),
        ),
      );

  Widget _newTag() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.dark,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(
          'NUEVO',
          style: AppTextStyles.bodySize(
            9,
            color: Colors.white,
            weight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
      );

  Widget _favButton() => Material(
        color: AppColors.surface,
        shape: const CircleBorder(),
        elevation: 1.5,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onToggleFav,
          child: SizedBox(
            width: 30,
            height: 30,
            child: Icon(
              isFav ? Icons.favorite : Icons.favorite_border,
              size: 15,
              color: isFav ? AppColors.accent : AppColors.mutedLight,
            ),
          ),
        ),
      );
}

/// Precio actual + precio tachado.
class PriceRow extends StatelessWidget {
  const PriceRow({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '\$${product.price.toStringAsFixed(2)}',
          style: AppTextStyles.bodySize(14, weight: FontWeight.w700),
        ),
        const SizedBox(width: 6),
        Text(
          '\$${product.oldPrice.toStringAsFixed(2)}',
          style: AppTextStyles.bodySize(11, color: AppColors.mutedLight)
              .copyWith(decoration: TextDecoration.lineThrough),
        ),
      ],
    );
  }
}
