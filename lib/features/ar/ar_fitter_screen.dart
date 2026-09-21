import 'package:flutter/material.dart';

import '../../core/data/mock_data.dart';
import '../../core/models/fashion_models.dart';
import '../../core/state/app_scope.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/kit/buttons.dart';
import '../../shared/kit/nav.dart';
import '../../shared/kit/net_image.dart';

/// Probador virtual: permiso de cámara → carga → vista AR con controles.
class ArFitterScreen extends StatefulWidget {
  const ArFitterScreen({super.key, this.initialProduct});

  final Product? initialProduct;

  @override
  State<ArFitterScreen> createState() => _ArFitterScreenState();
}

class _ArFitterScreenState extends State<ArFitterScreen> {
  /// permission · loading · active
  String _state = 'permission';
  late Product _product = widget.initialProduct ?? kProducts.first;
  double _rotation = 0;
  double _zoom = 1;
  bool _picker = false;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return Column(
      children: [
        if (_state != 'active')
          AppTopBar(title: 'Probador Virtual', onBack: s.closeOverlay),
        Expanded(
          child: switch (_state) {
            'permission' => _permission(s),
            'loading' => const Center(
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: AppColors.accent,
                  ),
                ),
              ),
            _ => _active(s),
          },
        ),
      ],
    );
  }

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
            'El Probador Virtual usa tu cámara para superponer modelos 3D de prendas sobre tu imagen en tiempo real.',
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
                  'Tu imagen no se guarda ni comparte',
                  'Procesado localmente en tu dispositivo',
                  'Puedes desactivarla en cualquier momento',
                ])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.check,
                            size: 14, color: AppColors.success),
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
          DButton(
            label: 'Activar cámara',
            tone: DButtonTone.dark,
            expanded: true,
            size: DButtonSize.lg,
            onPressed: () async {
              setState(() => _state = 'loading');
              await Future<void>.delayed(const Duration(milliseconds: 1800));
              if (mounted) setState(() => _state = 'active');
            },
          ),
          TextButton(
            onPressed: s.closeOverlay,
            child: Text('Ahora no',
                style: AppTextStyles.bodySize(13, color: AppColors.muted)),
          ),
        ],
      );

  Widget _active(AppState s) => Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF1F2937), Color(0xFF0F172A)],
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Center(
                    child: Transform.rotate(
                      angle: _rotation * 3.14159 / 180,
                      child: Transform.scale(
                        scale: _zoom,
                        child: Stack(
                          children: [
                            SizedBox(
                              width: 200,
                              height: 300,
                              child: NetImage(
                                url: _product.image,
                                radius: BorderRadius.circular(24),
                              ),
                            ),
                            for (final alignment in const [
                              Alignment.topLeft,
                              Alignment.topRight,
                              Alignment.bottomLeft,
                              Alignment.bottomRight,
                            ])
                              Align(
                                alignment: alignment,
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: AppColors.accent,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: MediaQuery.paddingOf(context).top + 12,
                  left: 16,
                  child: IconCircleButton(
                    icon: Icons.close,
                    background: Colors.black38,
                    color: Colors.white,
                    onPressed: s.closeOverlay,
                  ),
                ),
                Positioned(
                  right: 16,
                  top: 140,
                  child: Column(
                    children: [
                      _ctrl(
                        Icons.rotate_right,
                        () => setState(() => _rotation += 30),
                      ),
                      const SizedBox(height: 8),
                      _ctrl(
                        Icons.zoom_in,
                        () => setState(
                            () => _zoom = (_zoom + .1).clamp(.7, 1.6)),
                      ),
                      const SizedBox(height: 8),
                      _ctrl(
                        Icons.zoom_out,
                        () => setState(
                            () => _zoom = (_zoom - .1).clamp(.7, 1.6)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _panel(s),
        ],
      );

  Widget _ctrl(IconData icon, VoidCallback onTap) => Material(
        color: Colors.white24,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(icon, size: 18, color: Colors.white),
          ),
        ),
      );

  Widget _panel(AppState s) => Container(
        color: const Color(0xFF111827),
        padding: EdgeInsets.fromLTRB(
          16,
          14,
          16,
          20 + MediaQuery.paddingOf(context).bottom,
        ),
        child: Column(
          children: [
            Row(
              children: [
                NetImage(
                  url: _product.image,
                  width: 52,
                  height: 62,
                  radius: BorderRadius.circular(10),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_product.brand.toUpperCase(),
                          style: AppTextStyles.bodySize(11,
                              color: Colors.white54, letterSpacing: 0.6)),
                      Text(_product.name,
                          style: AppTextStyles.bodySize(14,
                              color: Colors.white, weight: FontWeight.w600)),
                      Text('\$${_product.price.toStringAsFixed(2)}',
                          style: AppTextStyles.bodySize(13,
                              color: AppColors.accent,
                              weight: FontWeight.w700)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _picker = !_picker),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text('Cambiar',
                        style: AppTextStyles.bodySize(12,
                            color: Colors.white, weight: FontWeight.w500)),
                  ),
                ),
              ],
            ),
            if (_picker) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 68,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: kProducts.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final p = kProducts[i];
                    return GestureDetector(
                      onTap: () => setState(() {
                        _product = p;
                        _picker = false;
                      }),
                      child: Container(
                        width: 56,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _product.id == p.id
                                ? AppColors.accent
                                : Colors.transparent,
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
            const SizedBox(height: 14),
            DButton(
              label: 'Ver en mi espacio',
              tone: DButtonTone.accent,
              expanded: true,
              size: DButtonSize.lg,
              onPressed: () => s.setToast('Vista AR: $_rotation° · ${_zoom.toStringAsFixed(1)}x'),
            ),
          ],
        ),
      );
}
