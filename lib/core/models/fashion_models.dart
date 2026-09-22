import 'package:flutter/material.dart';

/// Convierte un hex (#RRGGBB) en [Color].
Color colorFromHex(String hex) {
  var h = hex.replaceAll('#', '').trim();
  if (h.length == 6) h = 'FF$h';
  return Color(int.parse(h, radix: 16));
}

enum AppPhase { splash, onboarding, login, register, app }

enum AppTab { home, catalog, reservations, cart, profile }

enum OverlayScreen {
  none,
  checkout,
  purchaseSuccess,
  purchases,
  arFitter,
  aiRecs,
  chatbot,
  voice,
  preferences,
  settings,
  support,
  stateDemo,
}

class ProductColor {
  final String name;
  final String hex;
  const ProductColor(this.name, this.hex);
  Color get color => colorFromHex(hex);
}

class Product {
  final int id;
  final String name;
  final String brand;
  final String category;
  final double price;
  final double oldPrice;
  final int discount;
  final String image;
  final List<String> images;
  final List<ProductColor> colors;
  final List<String> sizes;
  final String description;
  final Map<String, int> stock;
  final double rating;
  final int reviews;
  final bool isNew;
  final bool isFeatured;
  /// CU17: modelo 3D del producto (`model_3d_url` del backend). Si es nulo o vacío,
  /// el vestidor usa `ArConstants.fallbackModelUrl`.
  final String? model3dUrl;

  /// CU17: formato del modelo (`glb` | `gltf`).
  final String? model3dFormat;

  const Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.category,
    required this.price,
    required this.oldPrice,
    required this.discount,
    required this.image,
    this.images = const [],
    this.colors = const [],
    this.sizes = const [],
    this.description = '',
    this.stock = const {},
    this.rating = 0,
    this.reviews = 0,
    this.isNew = false,
    this.isFeatured = false,
    this.model3dUrl,
    this.model3dFormat,
  });

  /// CU17: `true` cuando el producto declara su propio modelo 3D.
  bool get hasOwnModel3d => model3dUrl != null && model3dUrl!.trim().isNotEmpty;
}

class CartItem {
  final int productId;
  final String name;
  final String brand;
  final double price;
  final String image;
  final String size;
  final String color;
  int qty;

  CartItem({
    required this.productId,
    required this.name,
    required this.brand,
    required this.price,
    required this.image,
    required this.size,
    required this.color,
    this.qty = 1,
  });
}

class Reservation {
  final String id;
  final int productId;
  final String productName;
  final String productImage;
  final String brand;
  final String size;
  final String color;
  final String date;
  final String time;
  final String store;
  final String status; // confirmada | pendiente | cancelada | completada
  final String code;

  const Reservation({
    required this.id,
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.brand,
    required this.size,
    required this.color,
    required this.date,
    required this.time,
    required this.store,
    required this.status,
    required this.code,
  });

  Reservation copyWith({String? status}) => Reservation(
        id: id,
        productId: productId,
        productName: productName,
        productImage: productImage,
        brand: brand,
        size: size,
        color: color,
        date: date,
        time: time,
        store: store,
        status: status ?? this.status,
        code: code,
      );
}

class PurchaseItem {
  final int productId;
  final String name;
  final String brand;
  final double price;
  final String image;
  final String size;
  final String color;
  final int qty;

  const PurchaseItem({
    required this.productId,
    required this.name,
    required this.brand,
    required this.price,
    required this.image,
    required this.size,
    required this.color,
    required this.qty,
  });
}

class Purchase {
  final String id;
  final String date;
  final String status; // entregado | en_camino | procesando | cancelado
  final double total;
  final double subtotal;
  final double shipping;
  final String paymentMethod;
  final String deliveryMethod; // home | pickup
  final String? store;
  final List<PurchaseItem> items;

  const Purchase({
    required this.id,
    required this.date,
    required this.status,
    required this.total,
    required this.subtotal,
    required this.shipping,
    required this.paymentMethod,
    required this.deliveryMethod,
    this.store,
    this.items = const [],
  });
}

class UserPreferences {
  List<String> brands;
  List<String> favoriteColors;
  List<String> sizes;
  bool notifications;
  String language;
  String theme;
  String currency;

  UserPreferences({
    this.brands = const [],
    this.favoriteColors = const [],
    this.sizes = const [],
    this.notifications = true,
    this.language = 'es',
    this.theme = 'light',
    this.currency = 'ARS',
  });
}

class BannerItem {
  final int id;
  final String tag;
  final String title;
  final String subtitle;
  final String image;
  final String bg;

  const BannerItem({
    required this.id,
    required this.tag,
    required this.title,
    required this.subtitle,
    required this.image,
    required this.bg,
  });
}

class StoreBranch {
  final String id;
  final String name;
  final String address;
  final String hours;

  const StoreBranch({
    required this.id,
    required this.name,
    required this.address,
    required this.hours,
  });
}

class FaqItem {
  final String q;
  final String a;
  const FaqItem(this.q, this.a);
}
