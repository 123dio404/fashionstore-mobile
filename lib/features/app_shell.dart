import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/models/fashion_models.dart';
import '../core/state/app_scope.dart';
import '../core/state/app_state.dart';
import '../core/theme/app_theme.dart';
import '../shared/kit/bottom_nav.dart';
import '../shared/kit/nav.dart';
import 'admin/admin_dashboard_screen.dart';
import 'ai/ai_recommendations_screen.dart';
import 'ar/ar_fitter_screen.dart';
import 'auth/data/models/auth_models.dart';
import 'cart/cart_screen.dart';
import 'catalog/presentation/catalog_screen.dart';
import 'catalog/presentation/product_detail_screen.dart';
import 'chatbot/chatbot_screen.dart';
import 'checkout/checkout_screen.dart';
import 'checkout/purchase_success_screen.dart';
import 'home/home_screen.dart';
import 'notifications/notifications_screen.dart';
import 'preferences/preferences_screen.dart';
import 'profile/profile_screen.dart';
import 'purchases/purchases_screen.dart';
import 'reports/ai_report_screen.dart';
import 'reservations/reservations_screen.dart';
import 'settings/settings_screen.dart';
import 'state_demo/state_demo_screen.dart';
import 'support/support_screen.dart';
import 'sync/sync_queue_screen.dart';
import 'voice/voice_screen.dart';

/// Contenedor principal: pestañas + overlays + detalle de producto.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  Product? _detail;
  DateTime? _lastBackPress;

  void _openProduct(Product p) => setState(() => _detail = p);

  void _openProductFromOverlay(Product p) {
    AppScope.read(context).closeOverlay();
    setState(() => _detail = p);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final showNav = _detail == null && s.overlay == OverlayScreen.none;
    final role = s.currentUser?.role;

    final Widget body;
    if (_detail != null) {
      final currentProd = s.products.firstWhere(
        (p) => p.id == _detail!.id,
        orElse: () => _detail!,
      );
      body = ProductDetailScreen(
        product: currentProd,
        onBack: () => setState(() => _detail = null),
      );
    } else if (role == Role.administrador) {
      body = switch (s.tab) {
        AppTab.home => AdminDashboardScreen(onOpenProduct: _openProduct),
        AppTab.catalog => CatalogScreen(onOpenProduct: _openProduct),
        AppTab.reservations => const ReservationsScreen(),
        AppTab.cart => const AiReportScreen(),
        AppTab.profile => const ProfileScreen(),
      };
    } else if (role == Role.cajero) {
      body = switch (s.tab) {
        AppTab.home || AppTab.catalog => CatalogScreen(onOpenProduct: _openProduct),
        AppTab.reservations => const ReservationsScreen(),
        AppTab.cart => const SyncQueueScreen(),
        AppTab.profile => const ProfileScreen(),
      };
    } else {
      body = switch (s.tab) {
        AppTab.home => HomeScreen(onOpenProduct: _openProduct),
        AppTab.catalog => CatalogScreen(onOpenProduct: _openProduct),
        AppTab.reservations => const ReservationsScreen(),
        AppTab.cart => const CartScreen(),
        AppTab.profile => const ProfileScreen(),
      };
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // 1. Si hay un overlay abierto (Vestidor AR, Ajustes, Chatbot, etc.), cerrarlo
        if (s.overlay != OverlayScreen.none) {
          s.closeOverlay();
          return;
        }
        // 2. Si está en detalle de producto, volver al catálogo/home
        if (_detail != null) {
          setState(() => _detail = null);
          return;
        }
        // 3. Si está en otra pestaña, volver a Inicio
        if (s.tab != AppTab.home) {
          s.setTab(AppTab.home);
          return;
        }
        // 4. Si está en Inicio sin overlays ni detalle: doble toque para salir
        final now = DateTime.now();
        if (_lastBackPress == null ||
            now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
          _lastBackPress = now;
          s.setToast('Presiona atrás de nuevo para salir');
          return;
        }
        SystemNavigator.pop();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            Column(
              children: [
                if (s.isOffline) const OfflineBanner(),
                Expanded(child: body),
                if (showNav)
                  BottomNav(
                    active: s.tab,
                    onTab: s.setTab,
                    cartCount: s.cartCount,
                    reservCount: s.reservCount,
                    role: role,
                  ),
              ],
            ),
            if (s.overlay != OverlayScreen.none)
              Positioned.fill(
                child: ColoredBox(color: AppColors.background, child: _overlay(s)),
              ),
            if (s.activePushBanner != null)
              Positioned(
                top: MediaQuery.paddingOf(context).top + 8,
                left: 14,
                right: 14,
                child: _pushBanner(context, s, s.activePushBanner!),
              ),
            if (s.toast != null)
              Positioned(
                left: 16,
                right: 16,
                bottom: s.overlay != OverlayScreen.none ? 24 : 92,
                child: SuccessToast(
                  message: s.toast!,
                  onDismiss: () => s.setToast(null),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _overlay(AppState s) => switch (s.overlay) {
        OverlayScreen.checkout => const CheckoutScreen(),
        OverlayScreen.purchaseSuccess => const PurchaseSuccessScreen(),
        OverlayScreen.purchases => const PurchasesScreen(),
        OverlayScreen.notifications => const NotificationsScreen(),
        OverlayScreen.arFitter => ArFitterScreen(
            initialProduct: s.arProduct,
          ),
        OverlayScreen.aiRecs => AiRecommendationsScreen(
            onOpenProduct: _openProductFromOverlay,
          ),
        OverlayScreen.chatbot => const ChatbotScreen(),
        OverlayScreen.voice => const VoiceScreen(),
        OverlayScreen.preferences => const PreferencesScreen(),
        OverlayScreen.settings => const SettingsScreen(),
        OverlayScreen.aiReport => const AiReportScreen(),
        OverlayScreen.syncQueue => const SyncQueueScreen(),
        OverlayScreen.support => const SupportScreen(),
        OverlayScreen.stateDemo => const StateDemoScreen(),
        OverlayScreen.none => const SizedBox.shrink(),
      };

  Widget _pushBanner(BuildContext context, AppState s, NotificationItem item) {
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: () {
          s.dismissPushBanner();
          s.openOverlay(OverlayScreen.notifications);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.dark,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.accent.withValues(alpha: 0.6), width: 1.5),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.notifications_active, color: AppColors.accent, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          'NOTIFICACIÓN PUSH',
                          style: AppTextStyles.bodySize(
                            10,
                            color: AppColors.accent,
                            weight: FontWeight.w800,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Ahora',
                          style: AppTextStyles.bodySize(
                            10,
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.title,
                      style: AppTextStyles.bodySize(
                        13,
                        color: Colors.white,
                        weight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      item.message,
                      style: AppTextStyles.bodySize(
                        11,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: s.dismissPushBanner,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 16, color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pantalla demo de estados (se abre desde Perfil).
class StateDemoOverlay extends StatelessWidget {
  const StateDemoOverlay({super.key});

  @override
  Widget build(BuildContext context) => const StateDemoScreen();
}
