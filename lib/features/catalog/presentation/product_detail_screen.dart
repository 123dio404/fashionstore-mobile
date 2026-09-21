import 'package:flutter/material.dart';

import '../../../core/models/fashion_models.dart';
import '../../../core/state/app_scope.dart';
import '../../../core/state/app_state.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/kit/buttons.dart';
import '../../../shared/kit/chips.dart';
import '../../../shared/kit/net_image.dart';

/// Detalle de producto (espejo del `ProductDetail` del prototipo).
class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({
    super.key,
    required this.product,
    required this.onBack,
  });

  final Product product;
  final VoidCallback onBack;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _imgIdx = 0;
  int _colorIdx = 0;
  String? _size;
  String? _open;
  bool _added = false;

  Product get p => widget.product;

  void _add(AppState s) {
    if (_size == null) return;
    s.addToCart(p, size: _size, color: p.colors[_colorIdx].name);
    setState(() => _added = true);
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _added = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _gallery(s),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                child: _info(s),
              ),
            ],
          ),
        ),
        _bottomBar(s),
      ],
    );
  }

  Widget _gallery(AppState s) {
    final images = p.images.isEmpty ? [p.image] : p.images;
    final top = MediaQuery.paddingOf(context).top + 12;
    final fav = s.isFav(p.id);
    return SizedBox(
      height: 420,
      child: Stack(
        children: [
          PageView.builder(
            itemCount: images.length,
            onPageChanged: (i) => setState(() => _imgIdx = i),
            itemBuilder: (_, i) => NetImage(url: images[i]),
          ),
          Positioned(
            top: top,
            left: 16,
            child: IconCircleButton(
              icon: Icons.chevron_left,
              size: 38,
              iconSize: 20,
              onPressed: widget.onBack,
            ),
          ),
          Positioned(
            top: top,
            right: 16,
            child: IconCircleButton(
              icon: fav ? Icons.favorite : Icons.favorite_border,
              size: 38,
              iconSize: 18,
              color: fav ? AppColors.accent : AppColors.dark,
              onPressed: () => s.toggleFav(p.id),
            ),
          ),
          Positioned(
            bottom: 14,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                images.length,
                (i) => Container(
                  width: i == _imgIdx ? 18 : 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: i == _imgIdx ? Colors.white : Colors.white54,
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _info(AppState s) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            p.brand.toUpperCase(),
            style: AppTextStyles.bodySize(11,
                color: AppColors.muted, letterSpacing: 0.8),
          ),
          const SizedBox(height: 4),
          Text(p.name, style: AppTextStyles.displaySize(22)),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.star, size: 14, color: Color(0xFFF59E0B)),
              const SizedBox(width: 4),
              Text('${p.rating}',
                  style: AppTextStyles.bodySize(12, weight: FontWeight.w600)),
              const SizedBox(width: 4),
              Text('(${p.reviews} reseñas)',
                  style: AppTextStyles.bodySize(12, color: AppColors.muted)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('\$${p.price.toStringAsFixed(2)}',
                  style: AppTextStyles.bodySize(24, weight: FontWeight.w800)),
              const SizedBox(width: 8),
              Text(
                '\$${p.oldPrice.toStringAsFixed(2)}',
                style: AppTextStyles.bodySize(13, color: AppColors.mutedLight)
                    .copyWith(decoration: TextDecoration.lineThrough),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('-${p.discount}%',
                    style: AppTextStyles.bodySize(10,
                        color: Colors.white, weight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _label('COLOR · ${p.colors[_colorIdx].name.toUpperCase()}'),
          const SizedBox(height: 8),
          Row(children: List.generate(p.colors.length, _colorDot)),
          const SizedBox(height: 20),
          _label('TALLA'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: p.sizes
                .map((sz) => SizeChip(
                      label: sz,
                      selected: _size == sz,
                      onTap: () => setState(() => _size = sz),
                    ))
                .toList(),
          ),
          if (_size == null) ...[
            const SizedBox(height: 8),
            Text('Selecciona una talla para continuar',
                style: AppTextStyles.bodySize(11, color: AppColors.mutedLight)),
          ],
          const SizedBox(height: 22),
          _accordion('Descripción', p.description),
          _accordion(
            'Envío y devoluciones',
            'Envío a domicilio en 3–5 días hábiles (\$4.99) o retiro en tienda sin costo en 24 hrs. Cambios y devoluciones dentro de 30 días.',
          ),
          const SizedBox(height: 22),
          _label('DISPONIBILIDAD EN TIENDAS'),
          const SizedBox(height: 10),
          ...p.stock.entries.map((e) => _stockRow(e.key, e.value)),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => s.openOverlay(OverlayScreen.arFitter, product: p),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.accentSoft,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.camera_alt_outlined,
                      size: 18, color: AppColors.accent),
                  const SizedBox(width: 8),
                  Text('Probar en Probador Virtual',
                      style: AppTextStyles.bodySize(13,
                          color: AppColors.accentDark, weight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ],
      );

  Widget _label(String t) => Text(
        t,
        style: AppTextStyles.bodySize(11,
            color: AppColors.muted, weight: FontWeight.w700, letterSpacing: 0.6),
      );

  Widget _colorDot(int i) {
    final selected = i == _colorIdx;
    return GestureDetector(
      onTap: () => setState(() => _colorIdx = i),
      child: Container(
        width: 34,
        height: 34,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? AppColors.dark : AppColors.border,
            width: selected ? 2 : 1.5,
          ),
        ),
        alignment: Alignment.center,
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: p.colors[i].color,
            border: Border.all(color: AppColors.border),
          ),
        ),
      ),
    );
  }

  Widget _stockRow(String branch, int qty) => Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.borderLight)),
        ),
        child: Row(
          children: [
            const Icon(Icons.store_outlined, size: 16, color: AppColors.muted),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Sucursal $branch', style: AppTextStyles.bodySize(13)),
            ),
            Text(
              qty > 0 ? '$qty disponibles' : 'Sin stock',
              style: AppTextStyles.bodySize(12,
                  color: qty > 0 ? AppColors.success : AppColors.danger,
                  weight: FontWeight.w600),
            ),
          ],
        ),
      );

  Widget _accordion(String title, String body) {
    final open = _open == title;
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderLight)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _open = open ? null : title),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(title,
                        style:
                            AppTextStyles.bodySize(13, weight: FontWeight.w600)),
                  ),
                  Icon(open ? Icons.expand_less : Icons.expand_more,
                      size: 18, color: AppColors.mutedLight),
                ],
              ),
            ),
          ),
          if (open)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Text(body,
                  style: AppTextStyles.bodySize(13,
                      color: AppColors.muted, height: 1.65)),
            ),
        ],
      ),
    );
  }

  Widget _bottomBar(AppState s) => Container(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          16 + MediaQuery.paddingOf(context).bottom,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.borderLight)),
        ),
        child: DButton(
          label: _added ? 'Agregado ✓' : 'Agregar al carrito',
          tone: _added
              ? DButtonTone.accent
              : (_size == null ? DButtonTone.outline : DButtonTone.dark),
          expanded: true,
          size: DButtonSize.lg,
          onPressed: _size == null ? null : () => _add(s),
        ),
      );
}
