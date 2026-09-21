import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:fashionstore_mobile/core/data/mock_data.dart';
import 'package:fashionstore_mobile/core/models/fashion_models.dart';
import 'package:fashionstore_mobile/core/state/app_state.dart';
import 'package:fashionstore_mobile/core/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  test('la app arranca en splash y avanza de fase', () {
    final state = AppState();
    expect(state.phase, AppPhase.splash);
    state.goTo(AppPhase.onboarding);
    expect(state.phase, AppPhase.onboarding);
    state.goTo(AppPhase.app);
    expect(state.phase, AppPhase.app);
    state.dispose();
  });

  test('carrito: agrega, incrementa, quita y calcula subtotal', () {
    final state = AppState();
    final p = kProducts.first;
    state.addToCart(p, size: 'M');
    expect(state.cartCount, 1);
    state.incQty(p.id);
    expect(state.cartCount, 2);
    expect(state.cartSubtotal, closeTo(p.price * 2, 0.001));
    state.removeFromCart(p.id);
    expect(state.cartCount, 0);
    expect(state.cartSubtotal, 0);
    state.dispose();
  });

  test('favoritos: alterna el estado por producto', () {
    final state = AppState();
    expect(state.isFav(1), isFalse);
    state.toggleFav(1);
    expect(state.isFav(1), isTrue);
    state.toggleFav(1);
    expect(state.isFav(1), isFalse);
    state.dispose();
  });

  test('reservas: crea y cancela', () {
    final state = AppState();
    final before = state.reservations.length;
    state.addReservation(const Reservation(
      id: 'RES-TEST',
      productId: 1,
      productName: 'Blazer Oversize Lana',
      productImage: '',
      brand: 'Massimo',
      size: 'M',
      color: 'Negro',
      date: '24 sep 2026',
      time: '15:30',
      store: 'Sucursal Centro',
      status: 'confirmada',
      code: 'FS-0001',
    ));
    expect(state.reservations.length, before + 1);
    state.cancelReservation('RES-TEST');
    expect(state.reservations.first.status, 'cancelada');
    state.dispose();
  });

  test('compra: completa el pedido y vacía el carrito', () {
    final state = AppState();
    state.addToCart(kProducts.first, size: 'M');
    expect(state.cartCount, 1);
    state.completePurchase(const Purchase(
      id: 'ORD-TEST',
      date: '20 sep 2026',
      status: 'procesando',
      total: 94.98,
      subtotal: 89.99,
      shipping: 4.99,
      paymentMethod: 'Visa •••• 4242',
      deliveryMethod: 'home',
    ));
    expect(state.cartCount, 0);
    expect(state.lastPurchase?.id, 'ORD-TEST');
    expect(state.purchases.first.id, 'ORD-TEST');
    state.dispose();
  });

  test('tema: expone el acento terracota del diseño', () {
    expect(AppColors.accent.toARGB32(), 0xFFE05A47);
    expect(AppColors.background.toARGB32(), 0xFFF8F9FA);
    expect(AppTheme.scheme.primary, AppColors.accent);
    expect(AppTheme.light().scaffoldBackgroundColor, AppColors.background);
  });
}
