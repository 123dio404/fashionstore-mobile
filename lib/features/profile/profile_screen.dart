import 'package:flutter/material.dart';

import '../../core/models/fashion_models.dart';
import '../../core/state/app_scope.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/kit/buttons.dart';
import '../../shared/kit/cart_widgets.dart';
import '../../shared/kit/chips.dart';
import '../../shared/kit/nav.dart';
import '../../shared/kit/states.dart';

/// Perfil: identidad, métricas, accesos rápidos, modo demo y logout.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _showDemo = false;
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    if (s.isOffline) {
      return Column(
        children: [
          const AppTopBar(title: 'Mi Perfil', subtitle: 'FashionStore'),
          OfflineState(onRetry: () => s.setOffline(false)),
        ],
      );
    }
    return Column(
      children: [
        AppTopBar(
          title: 'Mi Perfil',
          subtitle: 'FashionStore',
          right: _iconBtn(
            Icons.settings_outlined,
            () => s.openOverlay(OverlayScreen.settings),
          ),
        ),
        Expanded(
          child: _error
              ? ErrorState(onRetry: _load)
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  children: [
                    _identity(s),
                    const SizedBox(height: 20),
                    _stats(s),
                    const SizedBox(height: 20),
                    _menu(s),
                    const SizedBox(height: 20),
                    _demoPanel(s),
                    const SizedBox(height: 20),
                    _logout(s),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) => Material(
        color: AppColors.surface,
        shape: const CircleBorder(),
        elevation: 1.5,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 36,
            height: 36,
            child: Icon(icon, size: 17, color: AppColors.dark),
          ),
        ),
      );

  Widget _identity(AppState s) => Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: AppColors.dark,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              'AL',
              style: AppTextStyles.bodySize(
                24,
                color: Colors.white,
                weight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: _loading
                ? const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBox(height: 16, width: 150),
                      SizedBox(height: 8),
                      SkeletonBox(height: 12, width: 190),
                      SizedBox(height: 8),
                      SkeletonBox(height: 10, width: 110),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ana López', style: AppTextStyles.displaySize(20)),
                      const SizedBox(height: 2),
                      Text('cliente@fashionstore.com',
                          style: AppTextStyles.bodySize(12,
                              color: AppColors.muted)),
                      const SizedBox(height: 6),
                      const ToneBadge(label: 'Cliente', tone: BadgeTone.accent),
                    ],
                  ),
          ),
        ],
      );

  Widget _stats(AppState s) => Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Row(
          children: [
            _stat('${s.favCount}', 'Favoritos'),
            _divider(),
            _stat('${s.cartCount}', 'Carrito'),
            _divider(),
            _stat('${s.reservCount}', 'Reservas'),
            _divider(),
            _stat('${s.purchases.length}', 'Compras'),
          ],
        ),
      );

  Widget _stat(String value, String label) => Expanded(
        child: Column(
          children: [
            Text(value,
                style: AppTextStyles.bodySize(20, weight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(label,
                style: AppTextStyles.bodySize(11, color: AppColors.muted)),
          ],
        ),
      );

  Widget _divider() =>
      Container(width: 1, height: 32, color: AppColors.borderLight);

  Widget _menu(AppState s) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            _menuItem(Icons.inventory_2_outlined, 'Mis compras',
                'Historial de pedidos', () => s.openOverlay(OverlayScreen.purchases)),
            _menuItem(Icons.tune, 'Preferencias',
                'Marcas, colores y tallas', () => s.openOverlay(OverlayScreen.preferences)),
            _menuItem(Icons.settings_outlined, 'Configuración',
                'Tema, idioma y cuenta', () => s.openOverlay(OverlayScreen.settings)),
            _menuItem(Icons.auto_awesome, 'Recomendaciones IA',
                'Sugerencias según tu estilo', () => s.openOverlay(OverlayScreen.aiRecs)),
            _menuItem(Icons.chat_bubble_outline, 'Asistente FashionStore',
                'Resuelve tus dudas', () => s.openOverlay(OverlayScreen.chatbot)),
            _menuItem(Icons.mic_none, 'Búsqueda por voz',
                'Busca hablando', () => s.openOverlay(OverlayScreen.voice)),
            _menuItem(Icons.help_outline, 'Ayuda y soporte', 'Preguntas frecuentes',
                () => s.openOverlay(OverlayScreen.support)),
            _menuItem(Icons.layers_outlined, 'Pantallas de estado',
                'Demo de errores', () => s.openOverlay(OverlayScreen.stateDemo),
                last: true),
          ],
        ),
      );

  Widget _menuItem(
    IconData icon,
    String label,
    String sub,
    VoidCallback onTap, {
    bool last = false,
  }) =>
      InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: last
                ? null
                : const Border(
                    bottom: BorderSide(color: AppColors.borderLight),
                  ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.borderLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 18, color: AppColors.dark),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: AppTextStyles.bodySize(13,
                            weight: FontWeight.w600)),
                    Text(sub,
                        style: AppTextStyles.bodySize(11,
                            color: AppColors.muted)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  size: 18, color: AppColors.mutedLight),
            ],
          ),
        ),
      );

  Widget _demoPanel(AppState s) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            InkWell(
              onTap: () => setState(() => _showDemo = !_showDemo),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('⚙️ Modo Demo',
                          style: AppTextStyles.bodySize(13,
                              color: AppColors.muted,
                              weight: FontWeight.w700)),
                    ),
                    Icon(
                      _showDemo ? Icons.expand_less : Icons.expand_more,
                      size: 18,
                      color: AppColors.muted,
                    ),
                  ],
                ),
              ),
            ),
            if (_showDemo)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        PillChip(
                          label: s.isOffline ? 'Online' : 'Offline',
                          selected: s.isOffline,
                          onTap: () {
                            s.setOffline(!s.isOffline);
                            s.setToast(s.isOffline
                                ? 'Modo offline activado'
                                : 'Conexión restaurada');
                          },
                        ),
                        PillChip(
                          label: 'Error',
                          onTap: () => setState(() => _error = true),
                        ),
                        PillChip(label: '↻ Skeleton', onTap: _load),
                        PillChip(
                          label: 'Pantallas de estado',
                          onTap: () => s.openOverlay(OverlayScreen.stateDemo),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Código de descuento: FASHION10',
                      style: AppTextStyles.bodySize(10,
                          color: AppColors.mutedLight),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );

  Widget _logout(AppState s) => DButton(
        label: 'Cerrar sesión',
        icon: Icons.logout,
        tone: DButtonTone.outline,
        expanded: true,
        onPressed: () {
          s.setToast('Sesión cerrada');
          s.goTo(AppPhase.login);
        },
      );
}
