import 'package:flutter/material.dart';

import '../../core/models/fashion_models.dart';
import '../../core/theme/app_theme.dart';
import 'net_image.dart';

/// Control de cantidad (− qty +) del prototipo.
class QtyControl extends StatelessWidget {
  const QtyControl({
    super.key,
    required this.qty,
    required this.onInc,
    required this.onDec,
  });

  final int qty;
  final VoidCallback onInc;
  final VoidCallback onDec;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _box(Icons.remove, onDec),
        SizedBox(
          width: 30,
          child: Text(
            '$qty',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySize(14, weight: FontWeight.w700),
          ),
        ),
        _box(Icons.add, onInc),
      ],
    );
  }

  Widget _box(IconData icon, VoidCallback onTap) => Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          onTap: onTap,
          child: Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: AppColors.border, width: 1.5),
            ),
            child: Icon(icon, size: 13, color: AppColors.dark),
          ),
        ),
      );
}

/// Fila de artículo del carrito.
class CartRow extends StatelessWidget {
  const CartRow({
    super.key,
    required this.item,
    required this.onInc,
    required this.onDec,
    required this.onRemove,
  });

  final CartItem item;
  final VoidCallback onInc;
  final VoidCallback onDec;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NetImage(
            url: item.image,
            width: 80,
            height: 96,
            radius: BorderRadius.circular(AppRadius.md),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.brand.toUpperCase(),
                  style: AppTextStyles.bodySize(
                    10,
                    color: AppColors.muted,
                    letterSpacing: 0.6,
                  ),
                ),
                Text(
                  item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySize(
                    13,
                    weight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Talla ${item.size} · ${item.color}',
                  style: AppTextStyles.bodySize(11, color: AppColors.mutedLight),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Text(
                      '\$${(item.price * item.qty).toStringAsFixed(2)}',
                      style: AppTextStyles.bodySize(15, weight: FontWeight.w700),
                    ),
                    const Spacer(),
                    QtyControl(qty: item.qty, onInc: onInc, onDec: onDec),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          InkWell(
            onTap: onRemove,
            child: const Padding(
              padding: EdgeInsets.all(2),
              child: Icon(
                Icons.delete_outline,
                size: 16,
                color: AppColors.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bloque skeleton con pulso (estados de carga).
class SkeletonBox extends StatefulWidget {
  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.radius = 8,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: AppColors.borderLight.withValues(alpha: 0.6 + _c.value * 0.4),
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}
