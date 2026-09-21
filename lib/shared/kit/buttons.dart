import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

enum DButtonTone { dark, accent, outline, ghost }
enum DButtonSize { sm, md, lg }

/// Botón pill del prototipo (dark / terracota / outline / ghost).
class DButton extends StatelessWidget {
  const DButton({
    super.key,
    required this.label,
    this.onPressed,
    this.tone = DButtonTone.dark,
    this.icon,
    this.size = DButtonSize.md,
    this.expanded = false,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final DButtonTone tone;
  final IconData? icon;
  final DButtonSize size;
  final bool expanded;
  final bool loading;

  bool get _enabled => onPressed != null && !loading;

  @override
  Widget build(BuildContext context) {
    final (hPad, vPad, font) = switch (size) {
      DButtonSize.sm => (14.0, 8.0, 12.0),
      DButtonSize.md => (20.0, 12.0, 13.0),
      DButtonSize.lg => (26.0, 15.0, 15.0),
    };

    final radius = BorderRadius.circular(AppRadius.pill);
    final bg = switch (tone) {
      DButtonTone.dark => AppColors.dark,
      DButtonTone.accent => AppColors.accent,
      DButtonTone.outline => AppColors.surface,
      DButtonTone.ghost => Colors.transparent,
    };
    final fg = switch (tone) {
      DButtonTone.dark || DButtonTone.accent => Colors.white,
      DButtonTone.outline || DButtonTone.ghost => AppColors.dark,
    };

    final button = Opacity(
      opacity: _enabled ? 1 : 0.5,
      child: Material(
        color: bg,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: _enabled ? onPressed : null,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(
                color: tone == DButtonTone.outline
                    ? AppColors.border
                    : Colors.transparent,
              ),
            ),
            child: Center(
              widthFactor: 1,
              child: loading
                  ? SizedBox(
                      height: font + 3,
                      width: font + 3,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: fg,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, size: font + 4, color: fg),
                          const SizedBox(width: AppSpacing.sm),
                        ],
                        Text(
                          label,
                          style: AppTextStyles.bodySize(
                            font,
                            color: fg,
                            weight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );

    return expanded
        ? SizedBox(width: double.infinity, child: button)
        : button;
  }
}

/// Botón circular blanco con sombra (volver, favoritos, campana).
class IconCircleButton extends StatelessWidget {
  const IconCircleButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.size = 36,
    this.iconSize = 18,
    this.color = AppColors.dark,
    this.background = AppColors.surface,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final double iconSize;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      shape: const CircleBorder(),
      elevation: background == AppColors.surface ? 1.5 : 0,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, size: iconSize, color: color),
        ),
      ),
    );
  }
}

/// "+ Añadir" compacto sobre la tarjeta de producto.
class AddChipButton extends StatelessWidget {
  const AddChipButton({super.key, required this.onPressed, this.label = '+ Añadir'});

  final VoidCallback onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.dark,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          child: Text(
            label,
            style: AppTextStyles.bodySize(
              11,
              color: Colors.white,
              weight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
