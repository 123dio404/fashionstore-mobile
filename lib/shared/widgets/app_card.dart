import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'app_button.dart';

/// Figma — Card base (superficie blanca, borde suave, radio 14).
class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.padding, this.onTap});

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: content,
      ),
    );
  }
}

/// Figma — Stat card (KPI del dashboard).
class AppStatCard extends StatelessWidget {
  const AppStatCard({
    super.key,
    required this.label,
    required this.value,
    this.delta,
    this.deltaTone = AppBadgeTone.success,
  });

  final String label;
  final String value;
  final String? delta;
  final AppBadgeTone deltaTone;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.text),
          ),
          if (delta != null) ...[
            const SizedBox(height: AppSpacing.sm),
            AppBadge(label: delta!, tone: deltaTone),
          ],
        ],
      ),
    );
  }
}

/// Figma — Product card / table row.
class AppProductCard extends StatelessWidget {
  const AppProductCard({
    super.key,
    required this.title,
    required this.price,
    this.subtitle,
    this.badge,
    this.onTap,
  });

  final String title;
  final String price;
  final String? subtitle;
  final Widget? badge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 72,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.brandSoft,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Icon(Icons.checkroom, size: 36, color: AppColors.brand),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.text),
          ),
          if (subtitle != null)
            Text(subtitle!, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Text(price, style: const TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              if (badge != null) badge!,
            ],
          ),
        ],
      ),
    );
  }
}

/// Cabecera de card o de sección.
class AppCardHeader extends StatelessWidget {
  const AppCardHeader({super.key, required this.title, this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}
