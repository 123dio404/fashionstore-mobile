import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/mock_data.dart';
import '../models/fashion_models.dart';

/// Estado global de la app móvil (espejo de `App.tsx` del prototipo).
class AppState extends ChangeNotifier {
  AppPhase phase = AppPhase.splash;
  AppTab tab = AppTab.home;
  OverlayScreen overlay = OverlayScreen.none;

  final List<CartItem> _cart = [];
  final List<int> _favs = [];
  List<Reservation> _reservations = List.of(kInitialReservations);
  final List<Purchase> _purchases = List.of(kInitialPurchases);
  UserPreferences _prefs = kDefaultPrefs;
  Purchase? _lastPurchase;
  Product? _arProduct;
  bool _isOffline = false;
  String? _toast;
  Timer? _toastTimer;

  @override
  void dispose() {
    _toastTimer?.cancel();
    super.dispose();
  }

  List<CartItem> get cart => List.unmodifiable(_cart);
  List<int> get favs => List.unmodifiable(_favs);
  List<Reservation> get reservations => List.unmodifiable(_reservations);
  List<Purchase> get purchases => List.unmodifiable(_purchases);
  UserPreferences get prefs => _prefs;
  Purchase? get lastPurchase => _lastPurchase;
  Product? get arProduct => _arProduct;
  bool get isOffline => _isOffline;
  String? get toast => _toast;

  int get cartCount => _cart.fold(0, (sum, i) => sum + i.qty);
  int get reservCount =>
      _reservations.where((r) => r.status == 'confirmada').length;
  int get favCount => _favs.length;

  void goTo(AppPhase p) {
    phase = p;
    notifyListeners();
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

  void addReservation(Reservation r) {
    _reservations.insert(0, r);
    notifyListeners();
  }

  void cancelReservation(String id) {
    _reservations = _reservations
        .map((r) => r.id == id ? r.copyWith(status: 'cancelada') : r)
        .toList();
    notifyListeners();
  }

  void completePurchase(Purchase p) {
    _purchases.insert(0, p);
    _cart.clear();
    _lastPurchase = p;
    notifyListeners();
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
