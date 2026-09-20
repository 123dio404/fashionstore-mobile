import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'app_button.dart';

/// Figma — Loading: skeleton animado.
class AppSkeleton extends StatefulWidget {
  const AppSkeleton({super.key, this.rows = 3, this.height = 16});

  final int rows;
  final double height;

  @override
  State<AppSkeleton> createState() => _AppSkeletonState();
}

class _AppSkeletonState extends State<AppSkeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final opacity = 0.45 + (_controller.value * 0.35);
        return Column(
          children: List.generate(
            widget.rows,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Container(
                height: widget.height,
                decoration: BoxDecoration(
                  color: AppColors.surface2.withValues(alpha: opacity),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Figma — Loading: fila con spinner y texto.
class AppLoadingRow extends StatelessWidget {
  const AppLoadingRow({super.key, this.label = 'Cargando…'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(
          height: 16,
          width: 16,
          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.brand),
        ),
        const SizedBox(width: AppSpacing.md),
        Text(label, style: const TextStyle(color: AppColors.muted)),
      ],
    );
  }
}

/// Base visual compartida por los estados.
class StateShell extends StatelessWidget {
  const StateShell({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.color,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Color color;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.xxl,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: color),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.text),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.muted),
          ),
          if (action != null) ...[
            const SizedBox(height: AppSpacing.lg),
            action!,
          ],
        ],
      ),
    );
  }
}

/// Figma — Empty: sin resultados o sin datos.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    this.icon = Icons.inbox_outlined,
    this.title = 'Sin resultados',
    this.message = 'No hay datos para mostrar.',
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) => StateShell(
    icon: icon,
    title: title,
    message: message,
    color: AppColors.border,
    action: action,
  );
}

/// Figma — Error: validación, red o servicio.
class AppErrorState extends StatelessWidget {
  const AppErrorState({
    super.key,
    this.title = 'Algo salió mal',
    this.message = 'No pudimos completar la operación.',
    this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => StateShell(
    icon: Icons.error_outline,
    title: title,
    message: message,
    color: AppColors.dangerSoft,
    action: onRetry == null ? null : AppButton(label: 'Reintentar', onPressed: onRetry),
  );
}

/// Figma — Offline: sin conexión, con reintento.
class AppOfflineState extends StatelessWidget {
  const AppOfflineState({super.key, this.onRetry});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => StateShell(
    icon: Icons.wifi_off_outlined,
    title: 'Sin conexión',
    message: 'No pudimos contactar al servidor. Revisa tu conexión e inténtalo de nuevo.',
    color: AppColors.warningSoft,
    action: onRetry == null ? null : AppButton(label: 'Reintentar', onPressed: onRetry),
  );
}

/// Figma — Service not configured: falta integración de IA, voz o pasarela.
class AppServiceUnavailable extends StatelessWidget {
  const AppServiceUnavailable({
    super.key,
    this.title = 'Servicio no configurado',
    this.message = 'Esta integración todavía no está habilitada.',
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => StateShell(
    icon: Icons.power_off_outlined,
    title: title,
    message: '$message Configúralo en el backend para habilitarlo.',
    color: AppColors.infoSoft,
  );
}

/// Banner de estado (success / error / info).
enum AppBannerTone { success, error, info }

class AppBanner extends StatelessWidget {
  const AppBanner({super.key, required this.message, this.tone = AppBannerTone.info});

  final String message;
  final AppBannerTone tone;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (tone) {
      AppBannerTone.success => (AppColors.successSoft, const Color(0xFF14603F)),
      AppBannerTone.error => (AppColors.dangerSoft, const Color(0xFF8F2F34)),
      AppBannerTone.info => (AppColors.infoSoft, const Color(0xFF2B3F9E)),
    };

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Text(message, style: TextStyle(color: foreground, fontSize: 13)),
    );
  }
}
