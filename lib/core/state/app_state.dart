import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../features/app_repository.dart';
import '../../features/auth/data/models/auth_models.dart';
import '../../features/catalog/data/catalog_repository.dart';
import '../../features/catalog/data/models/catalog_models.dart';
import '../../features/commerce/data/commerce_repository.dart';
import '../data/mock_data.dart';
import '../models/fashion_models.dart';
import '../services/sync_manager.dart';
import '../storage/local_database.dart';

/// Estado global de la app móvil (espejo de `App.tsx` del prototipo).
class AppState extends ChangeNotifier {
  AppPhase phase = AppPhase.splash;
  AppTab tab = AppTab.home;
  OverlayScreen overlay = OverlayScreen.none;

  final SyncManager syncManager = SyncManager.instance;
  final AppRepository _appRepo = AppRepository();
  final CatalogRepository _catalogRepo = CatalogRepository();
  final CommerceRepository _commerceRepo = CommerceRepository();
  final LocalDatabase _db = LocalDatabase.instance;

  /// Relaciones del backend necesarias para convertir una prenda demo en la
  /// fila real de inventario (`stock_id`) de una operación offline.
  List<BranchResponse> _branches = const [];
  List<Map<String, dynamic>> _apiStocks = const [];
  List<Map<String, dynamic>> _variants = const [];

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
  bool _remoteCatalogLoaded = false;
  bool _isOffline = false;
  String? _toast;
  Timer? _toastTimer;

  AppState() {
    syncManager.isOnline.addListener(_handleOnlineChanged);
    syncManager.pendingCount.addListener(notifyListeners);
    syncManager.isSyncing.addListener(notifyListeners);
    unawaited(_loadCachedCatalog());
  }

  void _handleOnlineChanged() {
    _isOffline = !syncManager.isOnline.value;
    notifyListeners();
  }

  @override
  void dispose() {
    _toastTimer?.cancel();
    syncManager.isOnline.removeListener(_handleOnlineChanged);
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
    syncManager.setActiveTenantId(user?.tenantId);
    notifyListeners();
  }

  void setSearchQuery(String q) {
    _searchQuery = q;
    notifyListeners();
  }

  /// Sincroniza el inventario real por sucursal contra la base de datos de la API
  /// (`GET /inventory/stock`), idéntico al cálculo de la versión Web (`CatalogStore`).
  ///
  /// Además guarda una instantánea en SQLite para que catálogo, carrito, ventas y
  /// reservas sigan operando sin conexión (CU-09, CU-12, CU-15).
  Future<void> refreshStockFromRemote({CatalogRepository? catalogRepo}) async {
    final repo = catalogRepo ?? _catalogRepo;
    try {
      final branches = await repo.branches();
      final apiProducts = await repo.products();
      final stocks = await repo.inventoryStock();
      List<Map<String, dynamic>> sizes = const [];
      try {
        sizes = await repo.sizes();
      } catch (_) {}

      _branches = branches;
      _apiStocks = stocks;
      _variants = _buildVariants(apiProducts, sizes);

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

      await _persistCatalog(branches, stocks);
      _remoteCatalogLoaded = true;
      syncManager.setOnlineStatus(true);
      _stockLoaded = true;
      notifyListeners();
    } on DioException catch (e) {
      if (_isConnectionError(e)) syncManager.setOnlineStatus(false);
      _stockLoaded = true;
      await _loadCachedCatalog();
    } catch (_) {
      _stockLoaded = true;
      await _loadCachedCatalog();
    }
  }

  Future<void> _persistCatalog(
    List<BranchResponse> branches,
    List<Map<String, dynamic>> stocks,
  ) async {
    try {
      await _db.cacheProducts(_products);
      await _db.cacheStock(stocks);
      await _db.cacheVariants(_variants);
      await _db.cacheBranches(branches
          .map((b) => {'id': b.id, 'name': b.name, 'address': b.address})
          .toList());
    } catch (_) {
      // La falta de almacenamiento local no debe romper la sesión online.
    }
  }

  /// Carga la última instantánea guardada en SQLite (arranque sin conexión).
  Future<void> _loadCachedCatalog() async {
    if (_remoteCatalogLoaded) return;
    try {
      final cachedProducts = await _db.getCachedProducts();
      if (cachedProducts.isNotEmpty) _products = cachedProducts;

      final cachedStocks = await _db.getCachedStock();
      if (cachedStocks.isNotEmpty) {
        _apiStocks = cachedStocks.map((s) => Map<String, dynamic>.from(s)).toList();
      }

      final cachedBranches = await _db.getCachedBranches();
      if (cachedBranches.isNotEmpty) {
        _branches = cachedBranches
            .map((b) => BranchResponse(
                  id: (b['id'] as num?)?.toInt() ?? 0,
                  cityId: 0,
                  name: '${b['name'] ?? ''}',
                  address: '${b['address'] ?? ''}',
                  isActive: true,
                ))
            .toList();
      }

      final cachedVariants = await _db.getCachedVariants();
      if (cachedVariants.isNotEmpty) {
        _variants = cachedVariants.map((v) => Map<String, dynamic>.from(v)).toList();
      }

      notifyListeners();
    } catch (_) {}
  }

  List<Map<String, dynamic>> _buildVariants(
    List<ProductResponse> products,
    List<Map<String, dynamic>> sizes,
  ) {
    final sizeNames = <int, String>{};
    for (final s in sizes) {
      final id = (s['id'] as num?)?.toInt();
      final name = (s['name'] ?? s['value'] ?? '').toString();
      if (id != null && name.isNotEmpty) sizeNames[id] = name;
    }

    final result = <Map<String, dynamic>>[];
    for (final product in products) {
      for (final variant in product.variants) {
        final sizeId = variant.sizeId;
        result.add({
          'variant_id': variant.id,
          'product_id': product.id,
          'product_name': product.name,
          'size_id': sizeId,
          'size_name': sizeId != null ? (sizeNames[sizeId] ?? '$sizeId') : null,
          'price': product.price,
        });
      }
    }
    return result;
  }

  static bool _isConnectionError(DioException e) =>
      e.type == DioExceptionType.connectionError ||
      e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.sendTimeout ||
      e.type == DioExceptionType.receiveTimeout ||
      (e.type == DioExceptionType.unknown && e.response == null);

  /// Resuelve la sucursal del backend a partir del nombre demo usado por la app.
  int resolveBranchId(String storeName) {
    String norm(String value) => value
        .toLowerCase()
        .replaceAll('sucursal', '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    final wanted = norm(storeName);
    for (final branch in _branches) {
      final name = norm(branch.name);
      if (name == wanted || name.contains(wanted) || wanted.contains(name)) {
        return branch.id;
      }
    }
    for (final keyword in const ['norte', 'sur', 'centro']) {
      if (wanted.contains(keyword)) {
        for (final branch in _branches) {
          if (norm(branch.name).contains(keyword)) return branch.id;
        }
      }
    }
    if (_branches.isNotEmpty) return _branches.first.id;
    if (wanted.contains('norte')) return 2;
    if (wanted.contains('sur')) return 3;
    return 1;
  }

  Map<String, dynamic>? _findVariant(String productName, String? size) {
    final wanted = productName.trim().toLowerCase();
    var matches = _variants
        .where((v) => '${v['product_name'] ?? ''}'.trim().toLowerCase() == wanted)
        .toList();
    if (matches.isEmpty) {
      matches = _variants.where((v) {
        final name = '${v['product_name'] ?? ''}'.trim().toLowerCase();
        return name.isNotEmpty && (name.contains(wanted) || wanted.contains(name));
      }).toList();
    }
    if (matches.isEmpty) return null;

    final wantedSize = (size ?? '').trim().toLowerCase();
    if (wantedSize.isNotEmpty) {
      for (final variant in matches) {
        if ('${variant['size_name'] ?? ''}'.trim().toLowerCase() == wantedSize) {
          return variant;
        }
      }
    }
    return matches.first;
  }

  Map<String, dynamic>? _findStock(int variantId, int branchId, int quantity) {
    if (variantId <= 0) return null;
    final rows = _apiStocks
        .where((s) =>
            ((s['variant_id'] as num?)?.toInt() ?? 0) == variantId &&
            ((s['branch_id'] as num?)?.toInt() ?? 0) == branchId)
        .toList();
    for (final row in rows) {
      if (((row['available_stock'] as num?)?.toInt() ?? 0) >= quantity) return row;
    }
    for (final row in rows) {
      if (((row['available_stock'] as num?)?.toInt() ?? 0) > 0) return row;
    }
    // Si el inventario de la sucursal quedó desactualizado, usar otra fila del
    // mismo producto para no perder la operación.
    for (final row in _apiStocks.where(
        (s) => ((s['variant_id'] as num?)?.toInt() ?? 0) == variantId)) {
      if (((row['available_stock'] as num?)?.toInt() ?? 0) > 0) return row;
    }
    return null;
  }

  static int _stockRowId(Map<String, dynamic> stock) =>
      ((stock['stock_id'] ?? stock['id']) as num?)?.toInt() ?? 0;

  /// Resuelve la fila de inventario (`stock_id`) para una prenda/talla/sucursal.
  int? resolveStockId({
    required String productName,
    String? size,
    required int branchId,
    int quantity = 1,
  }) {
    final variant = _findVariant(productName, size);
    final variantId = (variant?['variant_id'] as num?)?.toInt() ?? 0;
    final stock = _findStock(variantId, branchId, quantity);
    if (stock == null) return null;
    final id = _stockRowId(stock);
    return id > 0 ? id : null;
  }

  /// Ítem listo para el contrato de `POST /sync/batch`.
  Map<String, dynamic>? resolveSaleItem({
    required String productName,
    String? size,
    required int branchId,
    required int quantity,
    required double fallbackPrice,
  }) {
    final variant = _findVariant(productName, size);
    if (variant == null) return null;
    final variantId = (variant['variant_id'] as num?)?.toInt() ?? 0;
    final stock = _findStock(variantId, branchId, quantity);
    if (stock == null) return null;
    final stockId = _stockRowId(stock);
    if (stockId <= 0) return null;
    return {
      'stock_id': stockId,
      'quantity': quantity,
      'unit_price': (variant['price'] as num?)?.toDouble() ?? fallbackPrice,
    };
  }

  /// Crea una reserva en el backend (`POST /commerce/reservations`).
  Future<Map<String, dynamic>?> createReservationRemote({
    required int branchId,
    required int stockId,
    required DateTime scheduledAt,
  }) async {
    try {
      final result = await _commerceRepo.createReservation(
        branchId: branchId,
        scheduledAt: scheduledAt,
        items: [
          {'stock_id': stockId, 'quantity': 1},
        ],
      );
      syncManager.setOnlineStatus(true);
      return result;
    } on DioException catch (e) {
      if (_isConnectionError(e)) syncManager.setOnlineStatus(false);
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Sincroniza compras remotas desde `GET /commerce/sales` para que
  /// compras hechas en Web se reflejen inmediatamente en las notificaciones del móvil.
  Future<void> syncRemoteSales({CommerceRepository? commerceRepo}) async {
    try {
      final repo = commerceRepo ?? _commerceRepo;
      final sales = await repo.listSales();
      syncManager.setOnlineStatus(true);
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

  /// Devuelve `true` si la compra quedó registrada localmente (online o en la
  /// cola offline). Devuelve `false` si no fue posible asociarla al inventario o
  /// guardarla, en cuyo caso el carrito se conserva.
  Future<bool> completePurchase(
    Purchase p, {
    int? branchId,
    List<Map<String, dynamic>>? saleItems,
    bool? remoteCompleted,
  }) async {
    final storeName = p.store ?? 'Sucursal Centro';
    final targetBranchId = branchId ?? resolveBranchId(storeName);

    // Se encola cuando la app está offline o cuando el checkout remoto falló
    // a mitad de camino: en ambos casos el backend aún no conoce la venta.
    final mustQueue = _isOffline || remoteCompleted == false;

    if (mustQueue) {
      final items = saleItems ?? _resolveSaleItems(p, targetBranchId);
      if (items.isEmpty) {
        // Sin stock_id la operación nunca podrá sincronizarse. No se registra
        // una compra fantasma: se conserva el carrito para que el cliente
        // reintente al recuperar la red.
        setToast(
          'No se pudo asociar la venta al inventario central. '
          'Tu carrito sigue intacto: reconecta y vuelve a intentar.',
        );
        notifyListeners();
        return false;
      }
      if ((_currentUser?.tenantId ?? 0) <= 0) {
        setToast('Inicia sesión en una empresa para guardar la venta offline.');
        notifyListeners();
        return false;
      }

      try {
        final uuid = await syncManager.recordOfflineSale(
          tenantId: _currentUser!.tenantId!,
          branchId: targetBranchId,
          clientId: _currentUser?.id,
          items: items,
          total: p.total,
          // RN-03: sin conexión solo se cobra en efectivo.
          paymentMethod: 'efectivo',
        );
        // Recién cuando la operación quedó en SQLite se registra la compra y se
        // descuenta el stock local: así no se pierde ni se duplica la venta.
        _registerCompletedPurchase(p, storeName);
        setToast('Venta guardada offline (UUID: ${uuid.substring(0, 8)})');
        return true;
      } catch (e) {
        setToast(
          'No se pudo guardar la venta offline: '
          '${e is ArgumentError ? e.message : 'error desconocido'}',
        );
        notifyListeners();
        return false;
      }
    }

    _registerCompletedPurchase(p, storeName);
    unawaited(refreshStockFromRemote().catchError((_) {}));
    unawaited(syncRemoteSales().catchError((_) {}));
    notifyListeners();
    return true;
  }

  /// Registra la compra confirmada, vacía el carrito y descuenta stock local.
  void _registerCompletedPurchase(Purchase p, String storeName) {
    _purchases.insert(0, p);
    _cart.clear();
    _lastPurchase = p;
    _decrementLocalStock(p, storeName);
    notifyListeners();
  }

  /// Descuenta del espejo local de inventario las unidades recién vendidas.
  void _decrementLocalStock(Purchase p, String storeName) {
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
  }

  List<Map<String, dynamic>> _resolveSaleItems(Purchase p, int branchId) {
    final items = <Map<String, dynamic>>[];
    for (final item in p.items) {
      final resolved = resolveSaleItem(
        productName: item.name,
        size: item.size,
        branchId: branchId,
        quantity: item.qty,
        fallbackPrice: item.price,
      );
      if (resolved != null) items.add(resolved);
    }
    return items;
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

  /// Registra una reserva local. Si no hay conexión, la encola para sincronizar
  /// con el `stock_id` real resuelto desde la instantánea de inventario.
  Future<void> addReservation(
    Reservation r, {
    int? branchId,
    int? stockId,
    double price = 0,
    DateTime? scheduledAt,
  }) async {
    _reservations.insert(0, r);

    if (_isOffline) {
      final targetBranchId = branchId ?? resolveBranchId(r.store);
      if ((_currentUser?.tenantId ?? 0) <= 0) {
        setToast('Inicia sesión en una empresa para guardar la reserva offline.');
      } else if (stockId != null && stockId > 0) {
        final uuid = await syncManager.recordOfflineReservation(
          tenantId: _currentUser!.tenantId!,
          branchId: targetBranchId,
          clientId: _currentUser?.id,
          items: [
            {'stock_id': stockId, 'quantity': 1, 'unit_price': price},
          ],
          scheduledAt: scheduledAt ?? _slotFromReservation(r),
        );
        setToast('Reserva guardada offline (UUID: ${uuid.substring(0, 8)})');
      } else {
        setToast(
          'Reserva guardada en el dispositivo; no se pudo asociar al inventario central.',
        );
      }
    }

    notifyListeners();
  }

  static const _monthNumbers = {
    'ene': 1,
    'feb': 2,
    'mar': 3,
    'abr': 4,
    'may': 5,
    'jun': 6,
    'jul': 7,
    'ago': 8,
    'sep': 9,
    'oct': 10,
    'nov': 11,
    'dic': 12,
  };

  /// Convierte la fecha/hora de la UI ("22 sep 2026" + "10:30") en [DateTime].
  static DateTime reservationSlot(String date, String time) {
    final parts = date.trim().toLowerCase().split(RegExp(r'\s+'));
    final day = parts.isNotEmpty ? int.tryParse(parts[0]) : null;
    final month = parts.length > 1 ? _monthNumbers[parts[1]] : null;
    final year = parts.length > 2 ? int.tryParse(parts[2]) : null;

    final timeParts = time.split(':');
    final hour = timeParts.isNotEmpty ? int.tryParse(timeParts[0]) : null;
    final minute = timeParts.length > 1 ? int.tryParse(timeParts[1]) : 0;

    if (day != null && month != null && year != null) {
      return DateTime(year, month, day, hour ?? 10, minute ?? 0);
    }
    return DateTime.now().add(const Duration(days: 1));
  }

  static DateTime _slotFromReservation(Reservation r) =>
      reservationSlot(r.date, r.time);

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

  /// CU20 — reporte analítico asistido por IA (texto o voz).
  ///
  /// La consulta viaja a `POST /ai-reports/query`, que interpreta el lenguaje
  /// natural, ejecuta el reporte y devuelve la síntesis ejecutiva junto a las
  /// filas y los datos del gráfico.
  Future<Map<String, dynamic>> generateAiReport(String query) =>
      _appRepo.generateAiReport(query);

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

  /// Cambia el modo offline manual (modo demo) delegando en [SyncManager].
  /// Al volver a online se intenta sincronizar automáticamente la cola.
  void setOffline(bool v) {
    syncManager.setOnlineStatus(!v);
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
