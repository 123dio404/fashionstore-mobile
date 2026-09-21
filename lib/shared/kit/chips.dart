import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Chip pill seleccionable (categorías, tallas, filtros).
class PillChip extends StatelessWidget {
  const PillChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.fontSize = 12,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.dark : AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: onTap,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: selected ? AppColors.dark : AppColors.border,
            ),
          ),
          child: Text(
            label,
            style: AppTextStyles.bodySize(
              fontSize,
              color: selected ? Colors.white : AppColors.muted,
              weight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

/// Chip cuadrado (tallas del detalle de producto).
class SizeChip extends StatelessWidget {
  const SizeChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.disabled = false,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: disabled ? 0.35 : 1,
      child: Material(
        color: selected ? AppColors.dark : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: disabled ? null : onTap,
          child: Container(
            width: 52,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: selected ? AppColors.dark : AppColors.border,
              ),
            ),
            child: Text(
              label,
              style: AppTextStyles.bodySize(
                13,
                color: selected ? Colors.white : AppColors.dark,
                weight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum BadgeTone { neutral, success, warning, danger, info, accent }

/// Etiqueta de estado (confirmada / pendiente / entregado…).
class ToneBadge extends StatelessWidget {
  const ToneBadge({super.key, required this.label, this.tone = BadgeTone.neutral});

  final String label;
  final BadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      BadgeTone.neutral => (AppColors.borderLight, AppColors.muted),
      BadgeTone.success => (AppColors.successBg, AppColors.success),
      BadgeTone.warning => (AppColors.warningBg, AppColors.warning),
      BadgeTone.danger => (AppColors.dangerBg, AppColors.danger),
      BadgeTone.info => (AppColors.infoBg, AppColors.info),
      BadgeTone.accent => (AppColors.accentSoft, AppColors.accent),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodySize(11, color: fg, weight: FontWeight.w600),
      ),
    );
  }
}

/// Mapea el estado de una reserva/compra a un [BadgeTone].
ToneBadge badgeForStatus(String status) {
  final tone = switch (status) {
    'confirmada' || 'entregado' => BadgeTone.success,
    'pendiente' || 'procesando' => BadgeTone.warning,
    'cancelada' || 'cancelado' => BadgeTone.danger,
    'en_camino' => BadgeTone.info,
    'completada' => BadgeTone.neutral,
    _ => BadgeTone.neutral,
  };
  final label = switch (status) {
    'en_camino' => 'En camino',
    _ => status[0].toUpperCase() + status.substring(1),
  };
  return ToneBadge(label: label, tone: tone);
}

/// Selector booleano tipo switch (preferencias).
class DSwitch extends StatelessWidget {
  const DSwitch({super.key, required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Switch.adaptive(
      value: value,
      onChanged: onChanged,
      activeThumbColor: Colors.white,
      activeTrackColor: AppColors.accent,
    );
  }
}

/// Encabezado de sección: título serif + acción terracota.
class SectionHead extends StatelessWidget {
  const SectionHead({
    super.key,
    required this.title,
    this.action,
    this.onAction,
  });

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: AppTextStyles.displaySize(18)),
        ),
        if (action != null)
          InkWell(
            onTap: onAction,
            child: Text(
              action!,
              style: AppTextStyles.bodySize(
                12,
                color: AppColors.accent,
                weight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}
