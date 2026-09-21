import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Cabecera de pantalla del prototipo (título serif + subtítulo + volver).
class AppTopBar extends StatelessWidget {
  const AppTopBar({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.right,
    this.transparent = false,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final Widget? right;
  final bool transparent;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: transparent ? Colors.transparent : AppColors.background,
      padding: EdgeInsets.only(
        top: MediaQuery.paddingOf(context).top + 12,
        left: 20,
        right: 20,
        bottom: 14,
      ),
      child: Row(
        children: [
          if (onBack != null) ...[
            _BackButton(onTap: onBack!),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (subtitle != null)
                  Text(
                    subtitle!.toUpperCase(),
                    style: AppTextStyles.bodySize(
                      11,
                      color: AppColors.muted,
                      letterSpacing: 0.9,
                    ),
                  ),
                Text(title, style: AppTextStyles.displaySize(onBack != null ? 20 : 24)),
              ],
            ),
          ),
          if (right != null) ...[const SizedBox(width: 8), right!],
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: const CircleBorder(),
      elevation: 1.5,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const SizedBox(
          width: 36,
          height: 36,
          child: Icon(Icons.chevron_left, size: 22, color: AppColors.dark),
        ),
      ),
    );
  }
}

/// Franja negra de modo offline.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.dark,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.wifi_off, size: 14, color: AppColors.mutedLight),
          const SizedBox(width: 8),
          Text(
            'Sin conexión — Mostrando datos guardados',
            style: AppTextStyles.bodySize(
              12,
              color: const Color(0xFFD1D5DB),
              weight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Toast flotante de éxito (agregado al carrito, reserva creada…).
class SuccessToast extends StatelessWidget {
  const SuccessToast({super.key, required this.message, this.onDismiss});

  final String message;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.dark,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Color(0x40000000), blurRadius: 24, offset: Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: AppColors.successBg,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.check, size: 15, color: AppColors.success),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySize(
                13,
                color: const Color(0xFFF9FAFB),
                weight: FontWeight.w500,
              ),
            ),
          ),
          if (onDismiss != null)
            InkWell(
              onTap: onDismiss,
              child: const Icon(Icons.close, size: 16, color: AppColors.mutedLight),
            ),
        ],
      ),
    );
  }
}
