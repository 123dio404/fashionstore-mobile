import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'buttons.dart';

/// Estado vacío del prototipo (icono en círculo + título + subtítulo + CTA).
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.inbox_outlined,
    this.iconSize = 32,
    this.cta,
    this.onCta,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final double iconSize;
  final String? cta;
  final VoidCallback? onCta;

  @override
  Widget build(BuildContext context) => _StateShell(
        circleColor: AppColors.borderLight,
        icon: Icon(icon, size: iconSize, color: AppColors.mutedLight),
        title: title,
        subtitle: subtitle,
        cta: cta,
        onCta: onCta,
        tone: DButtonTone.dark,
      );
}

/// Estado de error con reintento.
class ErrorState extends StatelessWidget {
  const ErrorState({super.key, this.message, this.onRetry});

  final String? message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => _StateShell(
        circleColor: AppColors.dangerBg,
        icon: const Icon(
          Icons.error_outline,
          size: 32,
          color: AppColors.accent,
        ),
        title: 'Ups, hubo un error',
        subtitle: message ?? 'No pudimos completar la operación.',
        cta: onRetry == null ? null : 'Intentar de nuevo',
        onCta: onRetry,
        ctaIcon: Icons.refresh,
        tone: DButtonTone.accent,
      );
}

/// Estado sin conexión con reintento.
class OfflineState extends StatelessWidget {
  const OfflineState({super.key, this.onRetry});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => _StateShell(
        circleColor: const Color(0xFFF1F5F9),
        icon: const Icon(
          Icons.wifi_off,
          size: 32,
          color: AppColors.mutedLight,
        ),
        title: 'Sin conexión',
        subtitle: 'Revisa tu conexión a internet y vuelve a intentarlo.',
        cta: onRetry == null ? null : 'Reintentar',
        onCta: onRetry,
        ctaIcon: Icons.refresh,
        tone: DButtonTone.dark,
      );
}

class _StateShell extends StatelessWidget {
  const _StateShell({
    required this.circleColor,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.cta,
    this.onCta,
    this.ctaIcon,
    required this.tone,
  });

  final Color circleColor;
  final Widget icon;
  final String title;
  final String subtitle;
  final String? cta;
  final VoidCallback? onCta;
  final IconData? ctaIcon;
  final DButtonTone tone;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxl,
          vertical: 56,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: circleColor,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: icon,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySize(17, weight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySize(
                13,
                color: AppColors.muted,
                height: 1.6,
              ),
            ),
            if (cta != null && onCta != null) ...[
              const SizedBox(height: AppSpacing.lg),
              DButton(
                label: cta!,
                tone: tone,
                icon: ctaIcon,
                size: DButtonSize.lg,
                onPressed: onCta,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
