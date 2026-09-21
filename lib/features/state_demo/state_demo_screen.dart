import 'package:flutter/material.dart';

import '../../core/state/app_scope.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/kit/buttons.dart';
import '../../shared/kit/nav.dart';
import '../../shared/kit/states.dart';

/// Demo de los cuatro estados de error del sistema.
class StateDemoScreen extends StatefulWidget {
  const StateDemoScreen({super.key});

  @override
  State<StateDemoScreen> createState() => _StateDemoScreenState();
}

class _StateDemoScreenState extends State<StateDemoScreen> {
  String _active = 'menu';

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return switch (_active) {
      'no-results' => _wrap(
          s,
          EmptyState(
            icon: Icons.search_off,
            title: 'Sin resultados',
            subtitle:
                'No encontramos productos que coincidan con tu búsqueda. Intenta con otros términos o ajusta los filtros.',
            cta: 'Limpiar filtros',
            onCta: _menu,
          ),
        ),
      'network' => _wrap(
          s,
          ErrorState(
            message:
                'No pudimos conectarnos con el servidor. Verifica tu conexión.',
            onRetry: _menu,
          ),
        ),
      'offline' => _wrap(s, OfflineState(onRetry: _menu)),
      'service' => _wrap(
          s,
          const EmptyState(
            icon: Icons.power_off_outlined,
            title: 'Servicio no disponible',
            subtitle:
                'Esta función todavía no está habilitada. Configúrala en el backend para usarla.',
          ),
        ),
      _ => _menuView(s),
    };
  }

  void _menu() => setState(() => _active = 'menu');

  Widget _wrap(AppState s, Widget child) => Column(
        children: [
          Padding(
            padding: EdgeInsets.only(
              top: MediaQuery.paddingOf(context).top + 12,
              left: 20,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _menu,
                icon: const Icon(Icons.chevron_left,
                    size: 18, color: AppColors.muted),
                label: Text('Volver',
                    style: AppTextStyles.bodySize(13,
                        color: AppColors.muted, weight: FontWeight.w600)),
              ),
            ),
          ),
          Expanded(child: child),
        ],
      );

  Widget _menuView(AppState s) {
    const screens = [
      ('no-results', 'Sin resultados', 'Búsqueda vacía', Icons.search_off),
      ('network', 'Error de red', 'Sin conexión', Icons.wifi_off),
      ('offline', 'Sin conexión', 'Modo offline', Icons.cloud_off),
      ('service', 'Servicio no disponible', 'Función deshabilitada',
          Icons.power_off_outlined),
    ];
    return Column(
      children: [
        AppTopBar(
          title: 'Pantallas de estado',
          subtitle: 'Demo de errores',
          onBack: s.closeOverlay,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Demo de los cuatro estados de error del sistema',
              style: AppTextStyles.bodySize(13, color: AppColors.muted),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: [
              for (final sc in screens)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: DButton(
                    label: '${sc.$2} · ${sc.$3}',
                    icon: sc.$4,
                    tone: DButtonTone.outline,
                    expanded: true,
                    size: DButtonSize.lg,
                    onPressed: () => setState(() => _active = sc.$1),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
