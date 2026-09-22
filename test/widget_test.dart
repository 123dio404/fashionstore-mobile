import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:fashionstore_mobile/core/constants/ar_constants.dart';
import 'package:fashionstore_mobile/core/data/mock_data.dart';
import 'package:fashionstore_mobile/core/models/fashion_models.dart';
import 'package:fashionstore_mobile/core/services/ar_service.dart';
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
    // `AppTheme.light()` resuelve los estilos tipográficos de google_fonts y en las
    // pruebas no hay .ttf empaquetados (`allowRuntimeFetching = false`): la carga
    // fallida se propaga de forma asíncrona y ensucia el siguiente test. Se validan
    // el esquema (sin tipografías) y los tokens que alimentan ese tema.
    expect(AppTheme.scheme.primary, AppColors.accent);
    expect(AppTheme.scheme.surface, AppColors.surface);
    expect(AppTheme.scheme.onSurface, AppColors.dark);
  });

  // ------------------------------------------------------------------ CU17 --

  Product arProduct({String? modelUrl, String category = 'Mujer'}) => Product(
        id: 99,
        name: 'Zapatilla Demo',
        brand: 'Khronos',
        category: category,
        price: 10,
        oldPrice: 12,
        discount: 10,
        image: '',
        model3dUrl: modelUrl,
      );

  test('CU17: el vestidor usa el model_3d_url del producto cuando existe', () async {
    const url = 'https://cdn.fashionstore.test/models/zapatilla.glb';
    final resolved = await ArService().resolveModel(arProduct(modelUrl: url));
    expect(resolved.url, url);
    expect(resolved.source, ArModelSource.product);
    expect(resolved.label, contains('producto'));
  });

  test('CU17: sin model_3d_url usa el modelo de demostración de la categoría', () async {
    // Sin red (ni backend con modelos) el vestidor debe seguir siendo usable.
    final prenda = await ArService().resolveModel(arProduct());
    expect(prenda.url, ArConstants.clothModelUrl);
    expect(prenda.source, ArModelSource.category);
    expect(prenda.url, endsWith('SheenCloth.gltf'));
    expect(prenda.previewUrl, ArConstants.clothPreviewUrl);

    final calzado =
        await ArService().resolveModel(arProduct(category: 'Calzado'));
    expect(calzado.url, ArConstants.shoeModelUrl);
    expect(calzado.url, endsWith('MaterialsVariantsShoe.glb'));
    expect(calzado.previewUrl, endsWith('screenshot.jpg'));

    final accesorio =
        await ArService().resolveModel(arProduct(category: 'Accesorios'));
    expect(accesorio.url, ArConstants.sunglassesModelUrl);
    expect(accesorio.previewUrl, endsWith('SunglassesKhronos.png'));

    // Sin categoría queda el respaldo del prototipo (la zapatilla de Khronos).
    final sinCategoria = await ArService().resolveModel(arProduct(category: ''));
    expect(sinCategoria.url, ArConstants.fallbackModelUrl);
    expect(sinCategoria.source, ArModelSource.fallback);
  });

  test('CU17: el catálogo de demostración cubre prenda, calzado y accesorios', () {
    expect(ArConstants.modelForCategory('Mujer'), ArConstants.clothModelUrl);
    expect(ArConstants.modelForCategory('Hombre'), ArConstants.clothModelUrl);
    expect(ArConstants.modelForCategory('Calzado'), ArConstants.shoeModelUrl);
    expect(ArConstants.modelForCategory('Accesorios'),
        ArConstants.sunglassesModelUrl);
    expect(ArConstants.fallbackModelUrl, ArConstants.shoeModelUrl);
  });

  test('CU17: sin canal nativo el soporte AR se reporta como no disponible', () async {
    final availability = await ArService().availability();
    expect(availability.ready, isFalse);
    expect(availability.arCoreInstalled, isFalse);
    expect(availability.sceneViewerInstalled, isFalse);
    // Y abrir la sesión informa el motivo en vez de romper.
    final launch = await ArService().startSession(
      modelUrl: ArConstants.fallbackModelUrl,
      title: 'Zapatilla Demo',
    );
    expect(launch.launched, isFalse);
  });

  test('CU17: la captura del visor se decodifica desde data URL', () {
    final png = base64Encode(const [137, 80, 78, 71, 13, 10, 26, 10]);
    // webview_flutter puede devolver el literal JSON entre comillas.
    final quoted = ArService.decodeCapture('"data:image/png;base64,$png"');
    expect(quoted, isNotNull);
    expect(quoted, equals(const [137, 80, 78, 71, 13, 10, 26, 10]));
    // Y con escapes JSON (\u003d, \/) el PNG sigue siendo válido.
    final escaped =
        ArService.decodeCapture('"data:image\\/png;base64,${png.replaceAll('=', r'\u003d')}"');
    expect(escaped, equals(quoted));
    expect(ArService.decodeCapture('sin-imagen'), isNull);
    expect(ArService.decodeCapture(''), isNull);
  });

  test('CU17: solo se aceptan modelos glb/gltf', () {
    expect(ArService.isSupportedModel(ArConstants.fallbackModelUrl), isTrue);
    expect(
        ArService.isSupportedModel('https://cdn.test/prenda.gltf?v=2'), isTrue);
    expect(ArService.isSupportedModel('https://cdn.test/prenda.jpg'), isFalse);
  });
}
