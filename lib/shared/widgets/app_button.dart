import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Figma — Button: primary / secondary / brand / danger / ghost (+ loading).
enum AppButtonVariant { primary, secondary, brand, danger, ghost }

enum AppButtonSize { sm, md, lg }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.md,
    this.icon,
    this.loading = false,
    this.expanded = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? icon;
  final bool loading;
  final bool expanded;

  bool get _enabled => onPressed != null && !loading;

  @override
  Widget build(BuildContext context) {
    final button = _build();
    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }

  Widget _build() {
    final padding = switch (size) {
      AppButtonSize.sm => const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      AppButtonSize.lg => const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.md,
      ),
      AppButtonSize.md => const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm + 2,
      ),
    };

    final radius = BorderRadius.circular(
      size == AppButtonSize.sm ? AppRadius.sm : AppRadius.md,
    );

    final child = loading
        ? const SizedBox(
            height: 16,
            width: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: _foreground),
                const SizedBox(width: AppSpacing.sm),
              ],
              Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: _foreground)),
            ],
          );

    return Opacity(
      opacity: _enabled ? 1 : 0.55,
      child: Material(
        color: _background,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: _enabled ? onPressed : null,
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: _borderColor),
            ),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }

  Color get _background => switch (variant) {
    AppButtonVariant.primary => AppColors.brand,
    AppButtonVariant.secondary => AppColors.brandSoft,
    AppButtonVariant.brand => AppColors.brandDark,
    AppButtonVariant.danger => AppColors.danger,
    AppButtonVariant.ghost => Colors.transparent,
  };

  Color get _borderColor => switch (variant) {
    AppButtonVariant.secondary => AppColors.brandSoft,
    AppButtonVariant.ghost => Colors.transparent,
    _ => Colors.transparent,
  };

  Color get _foreground => switch (variant) {
    AppButtonVariant.primary || AppButtonVariant.brand || AppButtonVariant.danger => Colors.white,
    AppButtonVariant.secondary || AppButtonVariant.ghost => AppColors.brandDark,
  };
}

/// Figma — Badge: chips de estado.
enum AppBadgeTone { neutral, success, warning, danger, info, brand }

class AppBadge extends StatelessWidget {
  const AppBadge({super.key, required this.label, this.tone = AppBadgeTone.neutral});

  final String label;
  final AppBadgeTone tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _foreground),
      ),
    );
  }

  Color get _background => switch (tone) {
    AppBadgeTone.neutral => AppColors.surface2,
    AppBadgeTone.success => AppColors.successSoft,
    AppBadgeTone.warning => AppColors.warningSoft,
    AppBadgeTone.danger => AppColors.dangerSoft,
    AppBadgeTone.info => AppColors.infoSoft,
    AppBadgeTone.brand => AppColors.brandSoft,
  };

  Color get _foreground => switch (tone) {
    AppBadgeTone.neutral => AppColors.muted,
    AppBadgeTone.success => const Color(0xFF14603F),
    AppBadgeTone.warning => AppColors.warning,
    AppBadgeTone.danger => const Color(0xFF8F2F34),
    AppBadgeTone.info => const Color(0xFF2B3F9E),
    AppBadgeTone.brand => AppColors.brandDark,
  };
}
