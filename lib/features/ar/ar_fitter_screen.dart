import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/constants/ar_constants.dart';
import '../../core/data/mock_data.dart';
import '../../core/models/fashion_models.dart';
import '../../core/services/ar_service.dart';
import '../../core/state/app_scope.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/kit/buttons.dart';
import '../../shared/kit/nav.dart';
import '../../shared/kit/net_image.dart';

/// CU17 — Vestidor Virtual AR.
///
/// Flujo real: permiso de cámara del sistema → visor 3D del `.glb` del producto
/// (`model_3d_url` y, si viene vacío, el modelo de respaldo del prototipo) → sesión
/// AR de ARCore por Scene Viewer con detección y anclaje de planos (piso/mesa),
/// rotación 360°, escala real 1:1 y captura.
class ArFitterScreen extends StatefulWidget {
  const ArFitterScreen({super.key, this.initialProduct});

  final Product? initialProduct;

  @override
  State<ArFitterScreen> createState() => _ArFitterScreenState();
}

class _ArFitterScreenState extends State<ArFitterScreen> {
  final ArService _ar = ArService();

  /// `permission` (paso 1: cámara) · `viewer` (paso 2: visor 3D + AR).
  String _step = 'permission';
  bool _loading = true;
  bool _launching = false;
  bool _capturing = false;
  bool _picker = false;
  String? _error;
  ArAvailability _availability = ArAvailability.unknown;
  ArModel? _model;
  ArLaunchResult? _lastLaunch;
  WebViewController? _viewerController;
  Uint8List? _capture;

  late Product _product = widget.initialProduct ?? kProducts.first;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  /// Verifica el soporte AR del equipo y resuelve el modelo 3D del producto.
  Future<void> _prepare() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final availability = await _ar.availability();
    final model = await _ar.resolveModel(_product);
    if (!mounted) return;
    setState(() {
      _availability = availability;
      _model = model;
      _loading = false;
    });
  }

  /// Cambia la prenda proyectada y vuelve a resolver su modelo 3D.
  Future<void> _selectProduct(Product product, AppState s) async {
    setState(() {
      _product = product;
      _picker = false;
      _loading = true;
      _capture = null;
      _lastLaunch = null;
    });
    final model = await _ar.resolveModel(product);
    if (!mounted) return;
    setState(() {
      _model = model;
      _loading = false;
    });
    s.setToast('Vestidor AR: ${product.name}');
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return Column(
      children: [
        AppTopBar(title: 'Vestidor Virtual AR', onBack: s.closeOverlay),
        Expanded(child: _step == 'permission' ? _permission(s) : _viewer(s)),
      ],
    );
  }

  // ----------------------------------------------- CU17 · paso 1: cámara ---

  Widget _permission(AppState s) => ListView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        children: [
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.dark,
                borderRadius: BorderRadius.circular(28),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.camera_alt_outlined,
                  size: 44, color: Colors.white),
            ),
          ),
          const SizedBox(height: 24),
          Text('Acceso a la cámara',
              textAlign: TextAlign.center,
              style: AppTextStyles.displaySize(22)),
          const SizedBox(height: 10),
          Text(
            'El Vestidor Virtual usa ARCore para superponer el modelo 3D de la prenda '
            'sobre tu espacio: detecta piso o mesa, la ancla a escala 1:1 y te deja girarla 360°.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySize(13,
                color: AppColors.muted, height: 1.6),
          ),
          const SizedBox(height: 8),
          Text('Formatos compatibles: .glb · .gltf',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySize(11, color: AppColors.mutedLight)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.borderLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                for (final item in const [
                  'Tu imagen no se guarda ni se comparte',
                  'El modelo se procesa en el dispositivo',
                  'El anclaje y la escala los valida ARCore',
                ])
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline,
                            size: 16, color: AppColors.success),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(item,
                              style: AppTextStyles.bodySize(12,
                                  color: AppColors.muted)),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _diagnostics(),
          const SizedBox(height: 18),
          DButton(
            label: 'Activar cámara y continuar',
            tone: DButtonTone.dark,
            expanded: true,
            size: DButtonSize.lg,
            icon: Icons.view_in_ar_outlined,
            loading: _loading,
            onPressed: _loading ? null : () => _grant(s),
          ),
        ],
      );

  /// Solicita el permiso real de cámara (diálogo del sistema) y pasa al visor.
  Future<void> _grant(AppState s) async {
    final granted = await _ar.requestCameraPermission();
    if (!mounted) return;
    s.setToast(granted
        ? 'Cámara autorizada: listo para anclar modelos en 1:1.'
        : 'Sin permiso de cámara: ARCore lo solicitará al abrir la sesión AR.');
    setState(() => _step = 'viewer');
  }

  // ------------------------------------- CU17 · paso 2: visor 3D y sesión AR --

  Widget _viewer(AppState s) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          _viewerCard(),
          const SizedBox(height: 14),
          _productStrip(s),
          const SizedBox(height: 16),
          if (_error != null) ...[
            _banner(_error!, AppColors.dangerBg, AppColors.danger,
                Icons.error_outline),
            const SizedBox(height: 12),
          ],
          if (_lastLaunch != null && !_lastLaunch!.launched) ...[
            _banner(_lastLaunch!.message, AppColors.warningBg, AppColors.warning,
                Icons.info_outline),
            const SizedBox(height: 12),
          ],
          DButton(
            label: 'Ver en mi espacio (AR)',
            tone: DButtonTone.accent,
            expanded: true,
            size: DButtonSize.lg,
            icon: Icons.view_in_ar,
            loading: _launching,
            onPressed: (_launching || _model == null) ? null : () => _launchAr(s),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DButton(
                  label: 'Capturar',
                  tone: DButtonTone.outline,
                  icon: Icons.photo_camera_outlined,
                  loading: _capturing,
                  onPressed:
                      (_capturing || _model == null) ? null : () => _takeShot(s),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DButton(
                  label: 'Solo 3D',
                  tone: DButtonTone.outline,
                  icon: Icons.threed_rotation,
                  onPressed: _model == null
                      ? null
                      : () => _launchAr(s, mode: ArConstants.mode3dPreferred),
                ),
              ),
            ],
          ),
          if (!_availability.ready) ...[
            const SizedBox(height: 10),
            DButton(
              label: 'Instalar ARCore (Play Store)',
              tone: DButtonTone.dark,
              expanded: true,
              icon: Icons.download_outlined,
              onPressed: () => _installArCore(s),
            ),
          ],
          const SizedBox(height: 18),
          if (_capture != null) ...[
            _capturePreview(),
            const SizedBox(height: 12),
          ],
          _diagnostics(),
        ],
      );

  /// Visor 3D real del `.glb` (`<model-viewer>` en un WebView local): arrastre 360°,
  /// zoom y el botón AR del propio componente para saltar a Scene Viewer.
  Widget _viewerCard() => Container(
        height: 320,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.dark,
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: (_loading || _model == null)
                  ? const Center(
                      child: CircularProgressIndicator(
                          strokeWidth: 3, color: AppColors.accent),
                    )
                  : ModelViewer(
                      key: ValueKey('ar-${_product.id}-${_model!.url}'),
                      src: _model!.url,
                      alt: 'Modelo 3D de ${_product.name}',
                      ar: true,
                      arModes: const ['scene-viewer', 'webxr', 'quick-look'],
                      arScale: ArScale.fixed,
                      arPlacement: ArPlacement.floor,
                      cameraControls: true,
                      autoRotate: true,
                      autoRotateDelay: 800,
                      rotationPerSecond: '25deg',
                      interactionPrompt: InteractionPrompt.auto,
                      backgroundColor: AppColors.dark,
                      debugLogging: false,
                      onWebViewCreated: (controller) =>
                          _viewerController = controller,
                    ),
            ),
            const Positioned(
              left: 12,
              top: 12,
              child:
                  _ViewerChip(icon: Icons.threed_rotation, label: 'Rotación 360°'),
            ),
            const Positioned(
              right: 12,
              top: 12,
              child: _ViewerChip(icon: Icons.straighten, label: 'Escala 1:1'),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: _ViewerChip(
                icon: _availability.ready
                    ? Icons.check_circle_outline
                    : Icons.info_outline,
                label: _availability.ready
                    ? 'ARCore disponible · ancla en piso o mesa'
                    : 'Sin ARCore: vista 3D interactiva',
              ),
            ),
          ],
        ),
      );

  /// Prenda proyectada + selector para cambiar de modelo sin salir del vestidor.
  Widget _productStrip(AppState s) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_product.brand.toUpperCase(),
                        style: AppTextStyles.bodySize(11,
                            color: AppColors.muted, letterSpacing: 0.8)),
                    Text(_product.name,
                        style:
                            AppTextStyles.bodySize(15, weight: FontWeight.w700)),
                    Text('\$${_product.price.toStringAsFixed(2)}',
                        style: AppTextStyles.bodySize(13,
                            color: AppColors.accent, weight: FontWeight.w700)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              DButton(
                label: _picker ? 'Cerrar' : 'Cambiar',
                tone: DButtonTone.outline,
                size: DButtonSize.sm,
                onPressed: () => setState(() => _picker = !_picker),
              ),
            ],
          ),
          if (_model != null) ...[
            const SizedBox(height: 6),
            Text('Modelo: ${_model!.label}',
                style: AppTextStyles.bodySize(10, color: AppColors.mutedLight)),
            Text(_model!.url,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySize(10, color: AppColors.mutedLight)),
          ],
          if (_picker) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 74,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: kProducts.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final p = kProducts[i];
                  return GestureDetector(
                    onTap: () => _selectProduct(p, s),
                    child: Container(
                      width: 60,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _product.id == p.id
                              ? AppColors.accent
                              : AppColors.border,
                          width: 2,
                        ),
                      ),
                      child: NetImage(url: p.image),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      );

  // -------------------------------------------------- CU17 · acciones reales --

  /// Abre la sesión AR con el `.glb` del producto en Scene Viewer (ARCore).
  Future<void> _launchAr(AppState s,
      {String mode = ArConstants.modeArPreferred}) async {
    final model = _model;
    if (model == null) return;
    setState(() {
      _launching = true;
      _error = null;
    });
    final result = await _ar.startSession(
      modelUrl: model.url,
      title: '${_product.brand} · ${_product.name}',
      mode: mode,
    );
    if (!mounted) return;
    setState(() {
      _launching = false;
      _lastLaunch = result;
    });
    s.setToast(result.message);
  }

  /// Captura la vista 3D actual del visor (`model-viewer.toDataURL`) como PNG.
  Future<void> _takeShot(AppState s) async {
    final controller = _viewerController;
    if (controller == null) {
      s.setToast('El visor 3D aún se está cargando. Intenta en un momento.');
      return;
    }
    setState(() => _capturing = true);
    Uint8List? bytes;
    try {
      final raw = await controller.runJavaScriptReturningResult(
        ArService.captureScript,
      );
      bytes = ArService.decodeCapture(raw);
    } on Object {
      bytes = null;
    }
    if (!mounted) return;
    setState(() {
      _capturing = false;
      _capture = bytes;
    });
    if (bytes == null) {
      s.setToast('No se pudo capturar el modelo. Intenta de nuevo.');
      return;
    }
    final size = (bytes.length / 1024).toStringAsFixed(0);
    s.setToast('Captura lista ($size KB)');
    await showDialog<void>(
      context: context,
      builder: (_) => _CaptureDialog(bytes: bytes!),
    );
  }

  /// Abre Play Store para instalar o actualizar Google Play Services for AR.
  Future<void> _installArCore(AppState s) async {
    final opened = await _ar.installArCore();
    if (!mounted) return;
    s.setToast(opened
        ? 'Play Store abierto: instala Google Play Services para AR.'
        : 'No se pudo abrir Play Store en este dispositivo.');
  }

  Widget _banner(String message, Color bg, Color fg, IconData icon) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: fg),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message, style: AppTextStyles.bodySize(12, color: fg)),
            ),
          ],
        ),
      );

  /// Miniatura de la última captura del visor.
  Widget _capturePreview() => Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: Image.memory(
              _capture!,
              width: 54,
              height: 54,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Última captura',
                    style: AppTextStyles.bodySize(12, weight: FontWeight.w600)),
                Text('PNG generado por el visor 3D',
                    style:
                        AppTextStyles.bodySize(11, color: AppColors.mutedLight)),
              ],
            ),
          ),
        ],
      );

  /// Estado del soporte AR: verificable en la demo del CU17.
  Widget _diagnostics() => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('DIAGNÓSTICO AR',
                style: AppTextStyles.bodySize(11,
                    color: AppColors.muted,
                    weight: FontWeight.w700,
                    letterSpacing: 0.6)),
            const SizedBox(height: 10),
            _diagRow('ARCore (Play Services for AR)', _availability.arCoreInstalled),
            _diagRow('Scene Viewer disponible', _availability.sceneViewerInstalled),
            _diagRow('Hardware con cámara AR', _availability.deviceSupported),
            if (_availability.message != null) ...[
              const SizedBox(height: 8),
              Text(_availability.message!,
                  style: AppTextStyles.bodySize(11, color: AppColors.muted)),
            ],
          ],
        ),
      );

  Widget _diagRow(String label, bool ok) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Icon(ok ? Icons.check_circle : Icons.cancel_outlined,
                size: 15, color: ok ? AppColors.success : AppColors.mutedLight),
            const SizedBox(width: 8),
            Expanded(child: Text(label, style: AppTextStyles.bodySize(12))),
            Text(ok ? 'sí' : 'no',
                style: AppTextStyles.bodySize(12,
                    color: ok ? AppColors.success : AppColors.mutedLight,
                    weight: FontWeight.w600)),
          ],
        ),
      );

}

/// Chip translúcido sobre el visor 3D.
class _ViewerChip extends StatelessWidget {
  const _ViewerChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: Colors.white),
            const SizedBox(width: 6),
            Flexible(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySize(11,
                      color: Colors.white, weight: FontWeight.w600)),
            ),
          ],
        ),
      );
}

/// Vista previa y guardado de la captura PNG del vestidor (CU17).
class _CaptureDialog extends StatefulWidget {
  const _CaptureDialog({required this.bytes});

  final Uint8List bytes;

  @override
  State<_CaptureDialog> createState() => _CaptureDialogState();
}

class _CaptureDialogState extends State<_CaptureDialog> {
  bool _saving = false;
  String? _path;

  /// Guarda el PNG en el almacenamiento temporal de la app.
  Future<void> _save() async {
    setState(() => _saving = true);
    String? path;
    try {
      final file = File(
        '${Directory.systemTemp.path}/fashionstore-ar-'
        '${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(widget.bytes, flush: true);
      path = file.path;
    } on Object {
      path = null;
    }
    if (!mounted) return;
    setState(() {
      _saving = false;
      _path = path;
    });
  }

  @override
  Widget build(BuildContext context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Captura del vestidor',
                  style: AppTextStyles.displaySize(18)),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Image.memory(widget.bytes, fit: BoxFit.contain),
              ),
              const SizedBox(height: 10),
              Text(
                '${(widget.bytes.length / 1024).toStringAsFixed(0)} KB · PNG del visor 3D',
                style: AppTextStyles.bodySize(11, color: AppColors.muted),
              ),
              if (_path != null) ...[
                const SizedBox(height: 8),
                Text('Guardada en $_path',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySize(10, color: AppColors.success)),
              ],
              const SizedBox(height: 14),
              DButton(
                label: _path == null ? 'Guardar PNG' : 'Cerrar',
                tone: DButtonTone.dark,
                expanded: true,
                loading: _saving,
                onPressed: () {
                  if (_path == null) {
                    _save();
                  } else {
                    Navigator.of(context).pop();
                  }
                },
              ),
            ],
          ),
        ),
      );
}
