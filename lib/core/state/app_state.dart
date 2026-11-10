import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../features/app_repository.dart';
import '../../features/auth/data/models/auth_models.dart';
import '../../features/catalog/data/catalog_repository.dart';
import '../../features/catalog/data/models/catalog_models.dart';
import '../../features/commerce/data/commerce_repository.dart';
import '../data/mock_data.dart';
import '../models/fashion_models.dart';
import '../network/api_client.dart';
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

  int? _selectedTenantId = 3;
  String _selectedTenantName = 'Moda Urbana S.A.';
  NotificationItem? _activePushBanner;
  Timer? _pushDismissTimer;
  Timer? _notifPollTimer;

  static const List<Map<String, dynamic>> kDefaultStores = [
    {'id': 3, 'name': 'Moda Urbana S.A.', 'slug': 'urban-style', 'category': 'Streetwear & Casual', 'plan': 'Básico'},
    {'id': 5, 'name': 'Mundo Medias S.R.L.', 'slug': 'mundo-medias', 'category': 'Calcetería & Térmicos', 'plan': 'Básico'},
    {'id': 6, 'name': 'Tenis Urbanos S.R.L.', 'slug': 'tenis-urbanos', 'category': 'Calzado & Sneakers', 'plan': 'Pro'},
    {'id': 7, 'name': 'SportActive Ropa Deportiva', 'slug': 'sport-active', 'category': 'Ropa Técnica Deportiva', 'plan': 'Básico'},
    {'id': 4, 'name': 'Elegance Boutique S.R.L.', 'slug': 'elegance-fashion', 'category': 'Alta Costura & Gala', 'plan': 'Enterprise'},
    {'id': 8, 'name': 'Denim Co. Jeans Factory', 'slug': 'denim-co', 'category': 'Jeans & Denim', 'plan': 'Pro'},
    {'id': 9, 'name': 'Relax Homewear & Pijamas', 'slug': 'relax-homewear', 'category': 'Pijamas & Hogar', 'plan': 'Básico'},
    {'id': 10, 'name': 'Sartoria Milán Bespoke', 'slug': 'sartoria-milan', 'category': 'Sastrería & Trajes', 'plan': 'Enterprise'},
    {'id': 11, 'name': 'Nordic Winter & Coats', 'slug': 'nordic-winter', 'category': 'Abrigos & Parkas', 'plan': 'Pro'},
  ];

  static final Map<String, String> _exactProductImages = {
    // ── Moda Urbana S.A. (Tenant 3) ──
    'camisa oxford streetwear': 'https://images.unsplash.com/photo-1602810318383-e386cc2a3ccf?w=800&auto=format&fit=crop&q=80',
    'chaqueta denim retro': 'https://images.unsplash.com/photo-1603189343302-e603f7add05a?w=800&auto=format&fit=crop&q=80',
    'hoodie gráfico streetwear': 'https://images.unsplash.com/photo-1556905055-8f358a7a47b2?w=800&auto=format&fit=crop&q=80',
    'pantalón cargo urbano': 'https://images.unsplash.com/photo-1624378439575-d8705ad7ae80?w=800&auto=format&fit=crop&q=80',
    'remera oversize graphic lab': 'https://images.unsplash.com/photo-1583743814966-8936f5b7be1a?w=800&auto=format&fit=crop&q=80',
    'rompevientos windbreaker techwear': 'https://images.unsplash.com/photo-1544441893-675973e31985?w=800&auto=format&fit=crop&q=80',
    'jogger baggy streetwear': 'https://images.unsplash.com/photo-1552902865-b72c031ac5ea?w=800&auto=format&fit=crop&q=80',
    'gorra urbana trucker edition': 'https://images.unsplash.com/photo-1588850561407-ed78c282e89b?w=800&auto=format&fit=crop&q=80',

    // ── Elegance Boutique S.R.L. (Tenant 4) ──
    'vestido de gala seda royale': 'https://images.unsplash.com/photo-1566174053879-31528523f8ae?w=800&auto=format&fit=crop&q=80',
    'traje ejecutivo italiano': 'https://images.unsplash.com/photo-1594938298603-c8148c4dae35?w=800&auto=format&fit=crop&q=80',
    'smoking ceremonia black tie': 'https://images.unsplash.com/photo-1507679799987-c73779587ccf?w=800&auto=format&fit=crop&q=80',
    'vestido sirena escote corset': 'https://images.unsplash.com/photo-1518895949257-7621c3c786d7?w=800&auto=format&fit=crop&q=80',
    'abrigo de cachemira imperial': 'https://images.unsplash.com/photo-1539533018447-63fcce2678e3?w=800&auto=format&fit=crop&q=80',
    'blazer doble botonadura sartorial': 'https://images.unsplash.com/photo-1598033129183-c4f50c736f10?w=800&auto=format&fit=crop&q=80',
    'vestido midi plisado champagne': 'https://images.unsplash.com/photo-1572804013309-59a88b7e92f1?w=800&auto=format&fit=crop&q=80',
    'blusa de seda crepe organza': 'https://images.unsplash.com/photo-1551803091-e20673f15770?w=800&auto=format&fit=crop&q=80',

    // ── Mundo Medias S.R.L. (Tenant 5) ──
    'medias tobilleras deportivas (pack x3)': 'https://images.unsplash.com/photo-1586350977771-b3b0abd50c82?w=800&auto=format&fit=crop&q=80',
    'medias de compresión graduada': 'https://images.unsplash.com/photo-1582966772680-860e372bb558?w=800&auto=format&fit=crop&q=80',
    'medias térmicas polar de invierno': 'https://images.unsplash.com/photo-1646725582781-c09e1bcd431d?w=800&auto=format&fit=crop&q=80',
    'medias invisibles antideslizantes': 'https://images.unsplash.com/photo-1585499583264-491df5142e83?w=800&auto=format&fit=crop&q=80',
    'pantis de seda fina elegance': 'https://images.unsplash.com/photo-1509631179647-0177331693ae?w=800&auto=format&fit=crop&q=80',
    'medias ejecutivas hilo de escocia': 'https://images.unsplash.com/photo-1608256246200-53e635b5b65f?w=800&auto=format&fit=crop&q=80',
    'calcetines lana merino senderismo': 'https://images.unsplash.com/photo-1576566588028-4147f3842f27?w=800&auto=format&fit=crop&q=80',
    'medias bucaneras canalé algodón': 'https://images.unsplash.com/photo-1516762689617-e1cffcef479d?w=800&auto=format&fit=crop&q=80',

    // ── Tenis Urbanos S.R.L. (Tenant 6) ──
    'tenis running boost pro': 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=800&auto=format&fit=crop&q=80',
    'tenis court vintage leather': 'https://images.unsplash.com/photo-1525966222134-fcfa99b8ae77?w=800&auto=format&fit=crop&q=80',
    'tenis skate canvas low': 'https://images.unsplash.com/photo-1560769629-975ec94e6a86?w=800&auto=format&fit=crop&q=80',
    'tenis plataforma chunky bold': 'https://images.unsplash.com/photo-1595950653106-6c9ebd614d3a?w=800&auto=format&fit=crop&q=80',
    'tenis trail all-terrain outdoor': 'https://images.unsplash.com/photo-1551107696-a4b085a6d91a?w=800&auto=format&fit=crop&q=80',

    // ── SportActive Ropa Deportiva (Tenant 7) ──
    'remera técnica dry-fit pro': 'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?w=800&auto=format&fit=crop&q=80',
    'leggings seamless alta compresión': 'https://images.unsplash.com/photo-1506126613408-eca07ce68773?w=800&auto=format&fit=crop&q=80',
    'short running 2 en 1 con bolsillo': 'https://images.unsplash.com/photo-1539185441755-769473a23570?w=800&auto=format&fit=crop&q=80',
    'top deportivo alto impacto': 'https://images.unsplash.com/photo-1518611012118-696072aa579a?w=800&auto=format&fit=crop&q=80',
    'cortaviento running ultraligero': 'https://images.unsplash.com/photo-1516826957135-700dedea698c?w=800&auto=format&fit=crop&q=80',

    // ── Denim Co. Jeans Factory (Tenant 8) ──
    'jeans slim fit índigo clásico': 'https://images.unsplash.com/photo-1542272604-780c96856592?w=800&auto=format&fit=crop&q=80',
    'jeans mom fit vintage celeste': 'https://images.unsplash.com/photo-1541099649105-f69ad21f3246?w=800&auto=format&fit=crop&q=80',
    'cazadora denim forro sherpa': 'https://images.unsplash.com/photo-1576995853123-5a10305d93c0?w=800&auto=format&fit=crop&q=80',
    'falda midi denim abotonada': 'https://images.unsplash.com/photo-1583496661160-fb5886a0aaaa?w=800&auto=format&fit=crop&q=80',
    'overol denim carpenter tradicional': 'https://images.unsplash.com/photo-1538329972958-465d6d2144ed?w=800&auto=format&fit=crop&q=80',

    // ── Relax Homewear & Pijamas (Tenant 9) ──
    'pijama franela cuadros invierno': 'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=800&auto=format&fit=crop&q=80',
    'bata kimono satén seda royale': 'https://images.unsplash.com/photo-1582533561751-ef6f6ab93a2e?w=800&auto=format&fit=crop&q=80',
    'conjunto soft fleece confort': 'https://images.unsplash.com/photo-1578632767115-351597cf2477?w=800&auto=format&fit=crop&q=80',
    'pantuflas nordic acolchadas': 'https://images.unsplash.com/photo-1595341888016-a392ef81b7de?w=800&auto=format&fit=crop&q=80',
    'short pijama modal transpirable': 'https://images.unsplash.com/photo-1598033129183-c4f50c736f10?w=800&auto=format&fit=crop&q=80',

    // ── Sartoria Milán Bespoke (Tenant 10) ──
    'traje 3 piezas príncipe de gales': 'https://images.unsplash.com/photo-1593030761757-71fae45fa0e7?w=800&auto=format&fit=crop&q=80',
    'smoking solapa chal velvet black tie': 'https://images.unsplash.com/photo-1507679799987-c73779587ccf?w=800&auto=format&fit=crop&q=80',
    'blazer doble botonadura navy wool': 'https://images.unsplash.com/photo-1598033129183-c4f50c736f10?w=800&auto=format&fit=crop&q=80',
    'camisa cuello francés hilo doble 120s': 'https://images.unsplash.com/photo-1602810318383-e386cc2a3ccf?w=800&auto=format&fit=crop&q=80',
    'pantalón sartorial pliegues tiro alto': 'https://images.unsplash.com/photo-1506630448388-4e683c67ddb0?w=800&auto=format&fit=crop&q=80',

    // ── Nordic Winter & Coats (Tenant 11) ──
    'gabardina trench coat impermeable': 'https://images.unsplash.com/photo-1544441893-675973e31985?w=800&auto=format&fit=crop&q=80',
    'parka plumífero expedition térmica': 'https://images.unsplash.com/photo-1548883354-7622d03aca27?w=800&auto=format&fit=crop&q=80',
    'chaquetón doble faz lana merino': 'https://images.unsplash.com/photo-1539533018447-63fcce2678e3?w=800&auto=format&fit=crop&q=80',
    'abrigo imperial cachemira italiana': 'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=800&auto=format&fit=crop&q=80',
    'bufanda alpaca suri tejida a mano': 'https://images.unsplash.com/photo-1520903920243-00d872a2d1c9?w=800&auto=format&fit=crop&q=80',
  };

  static String resolveProductImage(String name) {
    final key = name.trim().toLowerCase();
    if (_exactProductImages.containsKey(key)) {
      return _exactProductImages[key]!;
    }
    for (final entry in _exactProductImages.entries) {
      if (key.contains(entry.key) || entry.key.contains(key)) {
        return entry.value;
      }
    }
    final n = key;
    // Calcetines y medias
    if (n.contains('media') || n.contains('calcet') || n.contains('panti') || n.contains('tobillera')) {
      if (n.contains('compresion') || n.contains('compresión')) {
        return 'https://images.unsplash.com/photo-1582966772680-860e372bb558?w=800&auto=format&fit=crop&q=80';
      }
      if (n.contains('termica') || n.contains('térmica') || n.contains('polar')) {
        return 'https://images.unsplash.com/photo-1646725582781-c09e1bcd431d?w=800&auto=format&fit=crop&q=80';
      }
      if (n.contains('invisible') || n.contains('antideslizante')) {
        return 'https://images.unsplash.com/photo-1585499583264-491df5142e83?w=800&auto=format&fit=crop&q=80';
      }
      return 'https://images.unsplash.com/photo-1586350977771-b3b0abd50c82?w=800&auto=format&fit=crop&q=80';
    }
    // Tenis y calzado
    if (n.contains('tenis') || n.contains('sneaker') || n.contains('running') || n.contains('skate') || n.contains('zapatilla')) {
      if (n.contains('running') || n.contains('boost')) {
        return 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=800&auto=format&fit=crop&q=80';
      }
      if (n.contains('court') || n.contains('vintage')) {
        return 'https://images.unsplash.com/photo-1525966222134-fcfa99b8ae77?w=800&auto=format&fit=crop&q=80';
      }
      if (n.contains('skate') || n.contains('canvas')) {
        return 'https://images.unsplash.com/photo-1560769629-975ec94e6a86?w=800&auto=format&fit=crop&q=80';
      }
      if (n.contains('plataforma') || n.contains('chunky')) {
        return 'https://images.unsplash.com/photo-1595950653106-6c9ebd614d3a?w=800&auto=format&fit=crop&q=80';
      }
      return 'https://images.unsplash.com/photo-1552346154-21d32810aba3?w=800&auto=format&fit=crop&q=80';
    }
    // Ropa deportiva / SportActive
    if (n.contains('dry-fit') || n.contains('seamless') || n.contains('legging') || n.contains('deportiv') || n.contains('top deportivo')) {
      if (n.contains('legging')) {
        return 'https://images.unsplash.com/photo-1506126613408-eca07ce68773?w=800&auto=format&fit=crop&q=80';
      }
      if (n.contains('short')) {
        return 'https://images.unsplash.com/photo-1539185441755-769473a23570?w=800&auto=format&fit=crop&q=80';
      }
      if (n.contains('top')) {
        return 'https://images.unsplash.com/photo-1518611012118-696072aa579a?w=800&auto=format&fit=crop&q=80';
      }
      return 'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?w=800&auto=format&fit=crop&q=80';
    }
    // Jeans / Denim Co.
    if (n.contains('jeans') || n.contains('denim') || n.contains('cazadora denim') || n.contains('vaquera')) {
      if (n.contains('slim')) {
        return 'https://images.unsplash.com/photo-1542272604-780c96856592?w=800&auto=format&fit=crop&q=80';
      }
      if (n.contains('mom') || n.contains('vintage')) {
        return 'https://images.unsplash.com/photo-1541099649105-f69ad21f3246?w=800&auto=format&fit=crop&q=80';
      }
      if (n.contains('cazadora') || n.contains('chaqueta')) {
        return 'https://images.unsplash.com/photo-1603189343302-e603f7add05a?w=800&auto=format&fit=crop&q=80';
      }
      return 'https://images.unsplash.com/photo-1582418702059-97ebafb35d09?w=800&auto=format&fit=crop&q=80';
    }
    // Alta Costura / Trajes / Elegance Boutique
    if (n.contains('vestido') || n.contains('gala') || n.contains('seda royale') || n.contains('sirena')) {
      if (n.contains('sirena') || n.contains('corset')) {
        return 'https://images.unsplash.com/photo-1518895949257-7621c3c786d7?w=800&auto=format&fit=crop&q=80';
      }
      return 'https://images.unsplash.com/photo-1566174053879-31528523f8ae?w=800&auto=format&fit=crop&q=80';
    }
    if (n.contains('traje') || n.contains('smoking') || n.contains('príncipe') || n.contains('sartoria')) {
      return 'https://images.unsplash.com/photo-1594938298603-c8148c4dae35?w=800&auto=format&fit=crop&q=80';
    }
    // Abrigos / Nordic Winter
    if (n.contains('gabardina') || n.contains('parka') || n.contains('abrigo') || n.contains('chaquetón')) {
      return 'https://images.unsplash.com/photo-1539533018447-63fcce2678e3?w=800&auto=format&fit=crop&q=80';
    }
    // Pijamas / Relax Homewear
    if (n.contains('pijama') || n.contains('bata') || n.contains('fleece') || n.contains('pantuflas')) {
      return 'https://images.unsplash.com/photo-1578632767115-351597cf2477?w=800&auto=format&fit=crop&q=80';
    }
    // Streetwear / Moda Urbana
    if (n.contains('hoodie') || n.contains('sudadera')) {
      return 'https://images.unsplash.com/photo-1556905055-8f358a7a47b2?w=800&auto=format&fit=crop&q=80';
    }
    if (n.contains('cargo') || n.contains('pantalon') || n.contains('pantalón')) {
      return 'https://images.unsplash.com/photo-1624378439575-d8705ad7ae80?w=800&auto=format&fit=crop&q=80';
    }
    if (n.contains('oxford') || n.contains('camisa')) {
      return 'https://images.unsplash.com/photo-1602810318383-e386cc2a3ccf?w=800&auto=format&fit=crop&q=80';
    }
    return 'https://images.unsplash.com/photo-1523381210434-271e8be1f52b?w=800&auto=format&fit=crop&q=80';
  }

  static String resolveProductCategory(String name) {
    final n = name.toLowerCase();
    if (n.contains('media') || n.contains('calcet') || n.contains('panti') || n.contains('tobillera')) return 'Calcetería';
    if (n.contains('tenis') || n.contains('sneaker') || n.contains('running') || n.contains('skate') || n.contains('zapatilla')) return 'Calzado';
    if (n.contains('dry-fit') || n.contains('seamless') || n.contains('legging') || n.contains('deportiv') || n.contains('top deportivo')) return 'Deportivo';
    if (n.contains('jeans') || n.contains('denim')) return 'Jeans & Denim';
    if (n.contains('traje') || n.contains('smoking') || n.contains('sartoria')) return 'Sastrería';
    if (n.contains('vestido') || n.contains('gala') || n.contains('sirena')) return 'Alta Costura';
    if (n.contains('gabardina') || n.contains('parka') || n.contains('abrigo')) return 'Abrigos';
    if (n.contains('pijama') || n.contains('bata') || n.contains('fleece') || n.contains('pantuflas')) return 'Homewear';
    if (n.contains('hoodie') || n.contains('cargo') || n.contains('oxford') || n.contains('camisa')) return 'Streetwear';
    return 'Moda';
  }

  AppState() {
    syncManager.isOnline.addListener(_handleOnlineChanged);
    syncManager.pendingCount.addListener(notifyListeners);
    syncManager.isSyncing.addListener(notifyListeners);
    unawaited(_loadCachedCatalog());

    _startConnectivityMonitor();

    _notifPollTimer = Timer.periodic(const Duration(seconds: 12), (_) {
      if (!_isOffline && _currentUser != null) {
        fetchNotificationsFromRemote();
      }
    });
  }

  Timer? _connectivityPollTimer;

  void _startConnectivityMonitor() {
    _connectivityPollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      try {
        final result = await InternetAddress.lookup('google.com')
            .timeout(const Duration(milliseconds: 1800));
        final online = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
        if (online != syncManager.isOnline.value) {
          syncManager.setOnlineStatus(online);
        }
      } catch (_) {
        if (syncManager.isOnline.value) {
          syncManager.setOnlineStatus(false);
        }
      }
    });
  }

  void _handleOnlineChanged() {
    _isOffline = !syncManager.isOnline.value;
    notifyListeners();
  }

  @override
  void dispose() {
    _toastTimer?.cancel();
    _pushDismissTimer?.cancel();
    _notifPollTimer?.cancel();
    _connectivityPollTimer?.cancel();
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

  int? get selectedTenantId => _selectedTenantId ?? _currentUser?.tenantId ?? 3;
  String get selectedTenantName => _selectedTenantName;
  NotificationItem? get activePushBanner => _activePushBanner;

  bool get isAdmin => _currentUser?.role == Role.administrador;
  bool get isCashier => _currentUser?.role == Role.cajero;
  bool get isCustomer => _currentUser?.role == Role.cliente || _currentUser == null;

  int get cartCount => _cart.fold(0, (sum, i) => sum + i.qty);
  int get reservCount =>
      _reservations.where((r) => r.status == 'confirmada').length;
  int get favCount => _favs.length;

  void triggerPushBanner(NotificationItem item) {
    _activePushBanner = item;
    _pushDismissTimer?.cancel();
    _pushDismissTimer = Timer(const Duration(seconds: 6), () {
      _activePushBanner = null;
      notifyListeners();
    });
    notifyListeners();
  }

  void dismissPushBanner() {
    _pushDismissTimer?.cancel();
    _activePushBanner = null;
    notifyListeners();
  }

  void setCurrentUser(UserResponse? user) {
    _currentUser = user;
    syncManager.setActiveTenantId(user?.tenantId);
    if (user != null && user.tenantId != null) {
      _selectedTenantId = user.tenantId;
      _selectedTenantName = user.tenantName ?? 'Empresa #${user.tenantId}';
    } else if (user != null && user.role == Role.cliente) {
      _selectedTenantId ??= 3;
      _selectedTenantName = 'Moda Urbana S.A.';
    }
    notifyListeners();
  }

  Future<void> changeSelectedStore({required int tenantId, required String tenantName}) async {
    _selectedTenantId = tenantId;
    _selectedTenantName = tenantName;
    _cart.clear();
    notifyListeners();
    await refreshStockFromRemote(tenantId: tenantId);
    setToast('Tienda seleccionada: $tenantName');
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
  Future<void> refreshStockFromRemote({CatalogRepository? catalogRepo, int? tenantId}) async {
    final repo = catalogRepo ?? _catalogRepo;
    final targetTenant = tenantId ?? _selectedTenantId ?? _currentUser?.tenantId ?? 3;
    try {
      final branches = await repo.branches();
      final apiProducts = await repo.products(tenantId: targetTenant);
      final stocks = await repo.inventoryStock();
      List<Map<String, dynamic>> sizes = const [];
      try {
        sizes = await repo.sizes();
      } catch (_) {}

      _branches = branches;
      _apiStocks = stocks;
      _variants = _buildVariants(apiProducts, sizes);

      if (apiProducts.isNotEmpty) {
        _products = apiProducts.map((ap) {
          final variantIds = ap.variants.map((v) => v.id).toSet();
          final newStockMap = <String, int>{};

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

          final pSizes = ap.variants
              .map((v) => sizes.firstWhere(
                    (sz) => sz['id'] == v.sizeId,
                    orElse: () => {'name': 'U'},
                  )['name']?.toString() ?? 'U')
              .toSet()
              .toList();
          if (pSizes.isEmpty) pSizes.addAll(['S', 'M', 'L']);

          final image = resolveProductImage(ap.name);
          final cat = resolveProductCategory(ap.name);

          return Product(
            id: ap.id,
            name: ap.name,
            brand: _selectedTenantName,
            category: cat,
            price: ap.price,
            oldPrice: ap.price * 1.15,
            discount: (ap.discountPercentage ?? 0).toInt(),
            image: image,
            images: [image],
            colors: const [
              ProductColor('Negro', '#111827'),
              ProductColor('Gris', '#6B7280'),
              ProductColor('Blanco', '#FFFFFF'),
            ],
            sizes: pSizes,
            description: ap.description ??
                'Prenda de confección de alta calidad con diseño exclusivo de $_selectedTenantName.',
            stock: newStockMap,
            rating: 4.9,
            reviews: 18,
            isNew: true,
            isFeatured: true,
            model3dUrl: ap.model3dUrl,
            model3dFormat: 'glb',
          );
        }).toList();
      }

      await fetchNotificationsFromRemote();

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

  Future<void> completePurchase(
    Purchase p, {
    int? branchId,
    List<Map<String, dynamic>>? saleItems,
    bool? remoteCompleted,
  }) async {
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

    final targetBranchId = branchId ?? resolveBranchId(storeName);

    // Se encola cuando la app está offline o cuando el checkout remoto falló
    // a mitad de camino: en ambos casos el backend aún no conoce la venta.
    final mustQueue = _isOffline || remoteCompleted == false;

    if (mustQueue) {
      final items = saleItems ?? _resolveSaleItems(p, targetBranchId);
      final targetTenantId = _currentUser?.tenantId ?? _selectedTenantId ?? 3;
      final queueItems = items.isNotEmpty
          ? items
          : [
              for (final it in p.items)
                {
                  'stock_id': (it.productId > 0 ? it.productId : 1),
                  'quantity': it.qty,
                  'unit_price': it.price,
                }
            ];

      final uuid = await syncManager.recordOfflineSale(
        tenantId: targetTenantId,
        branchId: targetBranchId,
        clientId: _currentUser?.id,
        items: queueItems,
        total: p.total,
      );
      setToast('Venta guardada offline (UUID: ${uuid.substring(0, 8)})');
    } else {
      unawaited(refreshStockFromRemote().catchError((_) {}));
      unawaited(syncRemoteSales().catchError((_) {}));
    }

    notifyListeners();
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

  /// Recupera las notificaciones reales del usuario desde el servidor SaaS
  Future<void> fetchNotificationsFromRemote() async {
    try {
      final dio = ApiClient().dio;
      final res = await dio.get('/notifications/me');
      if (res.data is List) {
        final list = (res.data as List).map((raw) {
          final m = raw as Map<String, dynamic>;
          return NotificationItem(
            id: m['id']?.toString() ?? UniqueKey().toString(),
            title: m['title']?.toString() ?? 'Aviso',
            message: m['message']?.toString() ?? '',
            date: m['created_at'] != null ? '${m['created_at']}'.split('T').first : 'Hoy',
            type: m['channel']?.toString() ?? 'info',
            isRead: m['is_read'] as bool? ?? false,
          );
        }).toList();

        if (list.isNotEmpty) {
          final existingIds = _notifications.map((n) => n.id).toSet();
          final newUnread = list.where((n) => !n.isRead && !existingIds.contains(n.id)).toList();

          _notifications.clear();
          _notifications.addAll(list);

          if (newUnread.isNotEmpty) {
            triggerPushBanner(newUnread.first);
          }
          notifyListeners();
        }
      }
    } catch (_) {}
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
