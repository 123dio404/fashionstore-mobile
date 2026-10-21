import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../features/app_repository.dart';
import '../../features/auth/data/models/auth_models.dart';
import '../../features/catalog/data/catalog_repository.dart';
import '../../features/catalog/data/models/catalog_models.dart';
import '../../features/commerce/data/commerce_repository.dart';
import '../data/mock_data.dart';
import '../models/fashion_models.dart';
import '../services/sync_manager.dart';

/// Estado global de la app móvil (espejo de `App.tsx` del prototipo).
class AppState extends ChangeNotifier {
  AppPhase phase = AppPhase.splash;
  AppTab tab = AppTab.home;
  OverlayScreen overlay = OverlayScreen.none;

  final SyncManager syncManager = SyncManager.instance;
  final AppRepository _appRepo = AppRepository();

  final List<CartItem> _cart = [];
  final List<int> _favs = [];
  List<Reservation> _reservations = List.of(kInitialReservations);
  final List<Purchase> _purchases = List.of(kInitialPurchases);
  final List<NotificationItem> _notifications = [
    NotificationItem(
      id: 'NOTIF-INIT-1',
      title: '¡Bienvenido a FashionStore!',
      message: 'Explora nuestra nueva colección y prueba tus prendas favoritas con el Vestidor Virtual AR.',
      date: 'Hoy',
      type: 'info',
      isRead: false,
    ),
  ];
  List<Product> _products = List.of(kProducts);
  UserPreferences _prefs = kDefaultPrefs;
  Purchase? _lastPurchase;
  Product? _arProduct;
  UserResponse? _currentUser;
  String _searchQuery = '';
  bool _stockLoaded = false;
  bool _isOffline = false;
  String? _toast;
  Timer? _toastTimer;

  AppState() {
    syncManager.isOnline.addListener(() {
      _isOffline = !syncManager.isOnline.value;
      notifyListeners();
    });
    syncManager.pendingCount.addListener(notifyListeners);
    syncManager.isSyncing.addListener(notifyListeners);
  }

  @override
  void dispose() {
    _toastTimer?.cancel();
    syncManager.isOnline.removeListener(notifyListeners);
    syncManager.pendingCount.removeListener(notifyListeners);
    syncManager.isSyncing.removeListener(notifyListeners);
    super.dispose();
  }

  List<Product> get products => List.unmodifiable(_products);
  List<CartItem> get cart => List.unmodifiable(_cart);
  List<int> get favs => List.unmodifiable(_favs);
  List<Reservation> get reservations => List.unmodifiable(_reservations);
  List<Purchase> get purchases => List.unmodifiable(_purchases);
  List<NotificationItem> get notifications => List.unmodifiable(_notifications);
  int get unreadNotificationsCount => _notifications.where((n) => !n.isRead).length;
  UserPreferences get prefs => _prefs;
  Purchase? get lastPurchase => _lastPurchase;
  Product? get arProduct => _arProduct;
  UserResponse? get currentUser => _currentUser;
  String get searchQuery => _searchQuery;
  bool get stockLoaded => _stockLoaded;
  bool get isOffline => _isOffline;
  String? get toast => _toast;

  int get cartCount => _cart.fold(0, (sum, i) => sum + i.qty);
  int get reservCount =>
      _reservations.where((r) => r.status == 'confirmada').length;
  int get favCount => _favs.length;

  void setCurrentUser(UserResponse? user) {
    _currentUser = user;
    notifyListeners();
  }

  void setSearchQuery(String q) {
    _searchQuery = q;
    notifyListeners();
  }

  /// Sincroniza el inventario real por sucursal contra la base de datos de la API
  /// (`GET /inventory/stock`), idéntico al cálculo de la versión Web (`CatalogStore`).
  Future<void> refreshStockFromRemote({CatalogRepository? catalogRepo}) async {
    try {
      final repo = catalogRepo ?? CatalogRepository();
      final branches = await repo.branches();
      final apiProducts = await repo.products();
      final stocks = await repo.inventoryStock();

      _products = _products.map((p) {
        final apiProd = apiProducts.cast<ProductResponse?>().firstWhere(
              (ap) =>
                  ap != null &&
                  (ap.name.trim().toLowerCase() == p.name.trim().toLowerCase() ||
                      ap.id == p.id),
              orElse: () => null,
            );
        if (apiProd == null) return p;

        final variantIds = apiProd.variants.map((v) => v.id).toSet();
        final newStockMap = Map<String, int>.from(p.stock);

        for (final branch in branches) {
          final bKey = branch.name
              .replaceFirst(RegExp(r'^Sucursal\s+', caseSensitive: false), '')
              .trim();
          final branchTotal = stocks
              .where((s) =>
                  (s['branch_id'] == branch.id) &&
                  variantIds.contains(s['variant_id']))
              .fold<int>(0, (sum, s) {
            final avail = (s['available_stock'] as num?)?.toInt() ?? 0;
            return sum + (avail > 0 ? avail : 0);
          });

          newStockMap[bKey] = branchTotal;
          final capitalized = bKey.isNotEmpty
              ? bKey[0].toUpperCase() + bKey.substring(1).toLowerCase()
              : bKey;
          newStockMap[capitalized] = branchTotal;
        }

        return p.copyWith(stock: newStockMap);
      }).toList();

      _stockLoaded = true;
      notifyListeners();
    } catch (_) {
      _stockLoaded = true;
    }
  }

  /// Sincroniza compras remotas desde `GET /commerce/sales` para que
  /// compras hechas en Web se reflejen inmediatamente en las notificaciones del móvil.
  Future<void> syncRemoteSales({CommerceRepository? commerceRepo}) async {
    try {
      final repo = commerceRepo ?? CommerceRepository();
      final sales = await repo.listSales();
      var changed = false;
      for (final sale in sales) {
        final id = sale['id'];
        if (id == null) continue;
        final notifId = 'NOTIF-SALE-$id';
        final exists = _notifications.any((n) => n.id == notifId);
        if (!exists) {
          final total = (sale['total'] as num?)?.toDouble() ?? 0.0;
          _notifications.insert(
            0,
            NotificationItem(
              id: notifId,
              title: '¡Compra confirmada! Orden #ORD-$id',
              message:
                  'Tu compra por \$${total.toStringAsFixed(2)} fue registrada correctamente y el stock fue actualizado.',
              date: 'Hoy',
              type: 'purchase_success',
              isRead: false,
            ),
          );
          changed = true;
        }
      }
      if (changed) {
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> completePurchase(Purchase p, {int? branchId}) async {
    _purchases.insert(0, p);
    _cart.clear();
    _lastPurchase = p;

    // Descontar inventario de la sucursal de la que se compró
    final storeName = p.store ?? 'Sucursal Centro';
    final branchKey = _extractBranchKey(storeName);

    _products = _products.map((prod) {
      final matches = p.items.where((it) => it.productId == prod.id).toList();
      if (matches.isEmpty) return prod;
      final boughtQty = matches.fold<int>(0, (sum, it) => sum + it.qty);

      final newStock = Map<String, int>.from(prod.stock);
      final current = newStock[branchKey] ?? 0;
      newStock[branchKey] = (current - boughtQty).clamp(0, 9999);

      return prod.copyWith(stock: newStock);
    }).toList();

    final targetBranchId =
        branchId ?? (branchKey == 'Norte' ? 2 : (branchKey == 'Sur' ? 3 : 1));
    final saleItems = p.items
        .map((it) => {
              'stock_id': it.productId,
              'quantity': it.qty,
              'unit_price': it.price,
            })
        .toList();

    if (_isOffline) {
      final uuid = await syncManager.recordOfflineSale(
        branchId: targetBranchId,
        clientId: _currentUser?.id,
        items: saleItems,
        total: p.total,
      );
      setToast('Venta guardada offline (UUID: ${uuid.substring(0, 8)})');
    } else {
      unawaited(refreshStockFromRemote().catchError((_) {}));
      unawaited(syncRemoteSales().catchError((_) {}));
    }

    notifyListeners();
  }

  static String _extractBranchKey(String store) {
    final lower = store.toLowerCase();
    if (lower.contains('norte')) return 'Norte';
    if (lower.contains('sur')) return 'Sur';
    return 'Centro';
  }

  void addNotification(NotificationItem item) {
    _notifications.insert(0, item);
    notifyListeners();
  }

  void markNotificationsAsRead() {
    for (final n in _notifications) {
      n.isRead = true;
    }
    notifyListeners();
  }

  void clearNotifications() {
    _notifications.clear();
    notifyListeners();
  }

  Future<void> Function()? onLogout;

  void goTo(AppPhase p) {
    phase = p;
    notifyListeners();
  }

  Future<void> logout() async {
    if (onLogout != null) {
      await onLogout!();
    }
    goTo(AppPhase.login);
  }

  void setTab(AppTab t) {
    tab = t;
    notifyListeners();
  }

  void openOverlay(OverlayScreen o, {Product? product}) {
    if (product != null) _arProduct = product;
    overlay = o;
    notifyListeners();
  }

  void closeOverlay() {
    overlay = OverlayScreen.none;
    notifyListeners();
  }

  bool isFav(int id) => _favs.contains(id);

  void toggleFav(int id) {
    if (_favs.contains(id)) {
      _favs.remove(id);
    } else {
      _favs.add(id);
    }
    notifyListeners();
  }

  void addToCart(Product p, {String? size, String? color}) {
    final s = size ?? (p.sizes.isNotEmpty ? p.sizes.first : 'M');
    final c = color ?? (p.colors.isNotEmpty ? p.colors.first.name : '');
    final existing = _cart.where((i) => i.productId == p.id);
    if (existing.isNotEmpty) {
      existing.first.qty += 1;
    } else {
      _cart.add(CartItem(
        productId: p.id,
        name: p.name,
        brand: p.brand,
        price: p.price,
        image: p.image,
        size: s,
        color: c,
        qty: 1,
      ));
    }
    setToast('${p.name} agregado al carrito');
  }

  void incQty(int productId) {
    for (final i in _cart) {
      if (i.productId == productId) i.qty += 1;
    }
    notifyListeners();
  }

  void decQty(int productId) {
    for (final i in _cart) {
      if (i.productId == productId && i.qty > 1) i.qty -= 1;
    }
    notifyListeners();
  }

  void removeFromCart(int productId) {
    _cart.removeWhere((i) => i.productId == productId);
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    notifyListeners();
  }

  double get cartSubtotal => _cart.fold(0, (sum, i) => sum + i.price * i.qty);

  Future<void> addReservation(Reservation r, {int? branchId, int? variantId}) async {
    _reservations.insert(0, r);
    if (_isOffline) {
      final bId = branchId ?? 1;
      final vId = variantId ?? r.productId;
      final uuid = await syncManager.recordOfflineReservation(
        branchId: bId,
        variantId: vId,
        date: r.date,
        time: r.time,
      );
      setToast('Reserva guardada offline (UUID: ${uuid.substring(0, 8)})');
    }
    notifyListeners();
  }

  Future<void> cancelReservation(String id) async {
    _reservations = _reservations
        .map((r) => r.id == id ? r.copyWith(status: 'cancelada') : r)
        .toList();
    notifyListeners();

    final numStr = id.replaceAll(RegExp(r'[^0-9]'), '');
    final numId = int.tryParse(numStr);
    if (numId != null && !_isOffline) {
      try {
        await _appRepo.cancelReservation(numId);
      } catch (_) {}
    }
  }

  Future<Map<String, dynamic>> createExchange({
    required int branchId,
    required int originalSaleId,
    required int returnedVariantId,
    required int newVariantId,
    required String reason,
  }) async {
    final res = await _appRepo.createExchange(
      branchId: branchId,
      originalSaleId: originalSaleId,
      returnedVariantId: returnedVariantId,
      newVariantId: newVariantId,
      reason: reason,
    );
    final voucher = res['voucher_number'] ?? 'VOUCHER';
    final diff = res['price_difference'] ?? 0;
    addNotification(NotificationItem(
      id: 'exchange-${DateTime.now().millisecondsSinceEpoch}',
      title: '¡Cambio de prenda procesado!',
      message: 'Comprobante: $voucher. Diferencia ajustada: Bs. $diff (política máx. 30 días).',
      date: 'Hoy',
      type: 'purchase_success',
    ));
    setToast('Cambio procesado con éxito ($voucher)');
    notifyListeners();
    return res;
  }

  void updatePrefs(UserPreferences p) {
    _prefs = p;
    notifyListeners();
  }

  void setOffline(bool v) {
    _isOffline = v;
    notifyListeners();
  }

  void setToast(String? t) {
    _toast = t;
    _toastTimer?.cancel();
    if (t != null) {
      _toastTimer = Timer(const Duration(milliseconds: 2500), () {
        _toast = null;
        notifyListeners();
      });
    }
    notifyListeners();
  }
}
