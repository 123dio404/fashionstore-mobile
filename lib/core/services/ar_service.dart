import 'dart:convert';

import 'package:flutter/services.dart';

import '../../features/catalog/data/catalog_repository.dart';
import '../../features/catalog/data/models/catalog_models.dart';
import '../constants/ar_constants.dart';
import '../models/fashion_models.dart';

/// CU17 — soporte AR que reporta el canal nativo de Android.
class ArAvailability {
  const ArAvailability({
    required this.deviceSupported,
    required this.arCoreInstalled,
    required this.sceneViewerInstalled,
    this.message,
  });

  /// El hardware declara cámara AR (`android.hardware.camera.ar`).
  final bool deviceSupported;

  /// Google Play Services for AR está instalado.
  final bool arCoreInstalled;

  /// Hay un Scene Viewer resoluble (ARCore o la app de Google).
  final bool sceneViewerInstalled;

  final String? message;

  /// `true` cuando se puede abrir una sesión AR real.
  bool get ready => sceneViewerInstalled || arCoreInstalled;

  static const unknown = ArAvailability(
    deviceSupported: false,
    arCoreInstalled: false,
    sceneViewerInstalled: false,
  );
}

/// Resultado de intentar abrir la sesión AR.
class ArLaunchResult {
  const ArLaunchResult({
    required this.launched,
    required this.needsInstall,
    required this.message,
  });

  final bool launched;
  final bool needsInstall;
  final String message;
}

/// De dónde salió el `.glb` que se proyecta.
enum ArModelSource { product, catalog, category, fallback }

/// Modelo 3D resuelto para el vestidor.
class ArModel {
  const ArModel({required this.url, required this.source, this.name});

  final String url;
  final ArModelSource source;
  final String? name;

  String get label => switch (source) {
        ArModelSource.product => 'model_3d_url del producto',
        ArModelSource.catalog => 'model_3d_url del catálogo (API)',
        ArModelSource.category => 'modelo de demostración de la categoría',
        ArModelSource.fallback => 'modelo de respaldo del prototipo',
      };

  /// Póster oficial del modelo (mientras carga el 3D).
  String get previewUrl => ArConstants.previewFor(url);
}

/// CU17 — Vestidor Virtual AR.
///
/// Puente con `MainActivity.kt` (Scene Viewer/ARCore) y resolución del modelo 3D
/// del producto, con respaldo cuando el backend no expone `model_3d_url`.
class ArService {
  ArService({MethodChannel? channel, CatalogRepository? catalog})
      : _channel = channel ?? const MethodChannel(ArConstants.channel),
        _catalog = catalog ?? CatalogRepository();

  final MethodChannel _channel;
  final CatalogRepository _catalog;
  Future<List<ProductResponse>>? _productsRequest;

  /// Soporte AR del equipo. En plataformas sin canal nativo (Web, tests) responde
  /// `unknown` en vez de lanzar excepción.
  Future<ArAvailability> availability() async {
    try {
      final raw = await _channel.invokeMapMethod<String, Object?>('availability');
      if (raw == null) return ArAvailability.unknown;
      return ArAvailability(
        deviceSupported: raw['deviceSupported'] == true,
        arCoreInstalled: raw['arCoreInstalled'] == true,
        sceneViewerInstalled: raw['sceneViewerInstalled'] == true,
        message: raw['message']?.toString(),
      );
    } on Object {
      return ArAvailability.unknown;
    }
  }

  /// Permiso de cámara con el diálogo del sistema (ARCore reutiliza el permiso).
  Future<bool> requestCameraPermission() async {
    try {
      return await _channel.invokeMethod<bool>('requestCameraPermission') ?? false;
    } on Object {
      return false;
    }
  }

  /// Abre la sesión AR del modelo en Scene Viewer.
  Future<ArLaunchResult> startSession({
    required String modelUrl,
    required String title,
    String mode = ArConstants.modeArPreferred,
  }) async {
    try {
      final raw = await _channel.invokeMapMethod<String, Object?>(
        'startSession',
        <String, Object>{'url': modelUrl, 'title': title, 'mode': mode},
      );
      if (raw == null) {
        return const ArLaunchResult(
          launched: false,
          needsInstall: false,
          message: 'El visor AR no respondió.',
        );
      }
      return ArLaunchResult(
        launched: raw['launched'] == true,
        needsInstall: raw['needsInstall'] == true,
        message: raw['message']?.toString() ?? '',
      );
    } on MissingPluginException {
      return const ArLaunchResult(
        launched: false,
        needsInstall: false,
        message: 'La sesión AR está disponible en Android (Scene Viewer).',
      );
    } on PlatformException catch (error) {
      return ArLaunchResult(
        launched: false,
        needsInstall: false,
        message: error.message ?? 'No fue posible abrir la sesión AR.',
      );
    }
  }

  /// Abre la ficha de ARCore en Play Store.
  Future<bool> installArCore() async {
    try {
      return await _channel.invokeMethod<bool>('installArCore') ?? false;
    } on Object {
      return false;
    }
  }

  /// Resuelve el `.glb` del vestidor en este orden:
  /// 1. `Product.model3dUrl` — el dato que ya trae la UI.
  /// 2. `model_3d_url` del producto en el catálogo del backend (`GET /products`, público).
  /// 3. Modelo de demostración de la categoría (prenda, calzado o accesorio).
  /// 4. `ArConstants.fallbackModelUrl` — respaldo del prototipo.
  Future<ArModel> resolveModel(Product product) async {
    final own = product.model3dUrl?.trim();
    if (own != null && own.isNotEmpty) {
      return ArModel(url: own, source: ArModelSource.product, name: product.name);
    }
    final remote = await _catalogModelUrl(product.name);
    if (remote != null) {
      return ArModel(url: remote, source: ArModelSource.catalog, name: product.name);
    }
    final category = product.category.trim();
    if (category.isEmpty) {
      return ArModel(
        url: ArConstants.fallbackModelUrl,
        source: ArModelSource.fallback,
        name: product.name,
      );
    }
    return ArModel(
      url: ArConstants.modelForCategory(category),
      source: ArModelSource.category,
      name: product.name,
    );
  }

  /// Busca en el catálogo del backend un producto homónimo que exponga
  /// `model_3d_url`. Si la API falla o ningún producto trae modelo, devuelve `null`.
  Future<String?> _catalogModelUrl(String productName) async {
    try {
      final products = await (_productsRequest ??= _catalog.products());
      final wanted = _normalizeName(productName);
      if (wanted.isEmpty) return null;
      for (final item in products) {
        final url = item.model3dUrl?.trim();
        if (url == null || url.isEmpty) continue;
        final candidate = _normalizeName(item.name);
        if (candidate.isEmpty) continue;
        if (candidate == wanted ||
            candidate.contains(wanted) ||
            wanted.contains(candidate)) {
          return url;
        }
      }
      return null;
    } on Object {
      _productsRequest = null; // permite reintentar al reabrir el vestidor
      return null;
    }
  }

  /// Compara nombres ignorando mayúsculas y separadores
  /// ("Blazer Oversize Lana" ≈ "blazer-oversize-lana").
  static String _normalizeName(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  /// `true` si el archivo es un modelo soportado (`glb`/`gltf`).
  static bool isSupportedModel(String url) {
    final path = Uri.tryParse(url)?.path.toLowerCase() ?? url.toLowerCase();
    return ArConstants.supportedFormats.any((f) => path.endsWith('.$f'));
  }

  /// JS que exporta la vista 3D actual del visor `<model-viewer>` como PNG.
  static const captureScript =
      "(() => { const v = document.querySelector('model-viewer'); "
      "return v && v.toDataURL ? v.toDataURL('image/png') : ''; })()";

  /// Convierte el resultado de `captureScript` en bytes PNG.
  ///
  /// `webview_flutter` puede devolver el literal JSON (`"\"data:image/png;base64..\""`),
  /// así que se quitan comillas y escapes antes de decodificar.
  static Uint8List? decodeCapture(Object? raw) {
    if (raw is! String) return null;
    var text = raw.trim();
    if (text.length > 1 && text.startsWith('"') && text.endsWith('"')) {
      text = text.substring(1, text.length - 1);
    }
    text = text
        .replaceAll(r'\/', '/')
        .replaceAll(r'\u002F', '/')
        .replaceAll(r'\u002f', '/')
        .replaceAll(r'\u003D', '=')
        .replaceAll(r'\u003d', '=')
        .replaceAll(r'\u002B', '+')
        .replaceAll(r'\u002b', '+');
    final marker = text.indexOf('base64,');
    if (marker < 0) return null;
    final payload =
        text.substring(marker + 'base64,'.length).replaceAll(RegExp(r'\s'), '');
    if (payload.isEmpty) return null;
    try {
      return base64Decode(payload);
    } on FormatException {
      return null;
    }
  }
}
