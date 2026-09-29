import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/models/fashion_models.dart';
import '../core/state/app_scope.dart';
import '../core/state/app_state.dart';
import '../core/theme/app_theme.dart';
import '../shared/kit/bottom_nav.dart';
import '../shared/kit/nav.dart';
import 'ai/ai_recommendations_screen.dart';
import 'ar/ar_fitter_screen.dart';
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
import 'reservations/reservations_screen.dart';
import 'settings/settings_screen.dart';
import 'state_demo/state_demo_screen.dart';
import 'support/support_screen.dart';
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
                  ),
              ],
            ),
            if (s.overlay != OverlayScreen.none)
              Positioned.fill(
                child: ColoredBox(color: AppColors.background, child: _overlay(s)),
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
        OverlayScreen.support => const SupportScreen(),
        OverlayScreen.stateDemo => const StateDemoScreen(),
        OverlayScreen.none => const SizedBox.shrink(),
      };
}

/// Pantalla demo de estados (se abre desde Perfil).
class StateDemoOverlay extends StatelessWidget {
  const StateDemoOverlay({super.key});

  @override
  Widget build(BuildContext context) => const StateDemoScreen();
}
