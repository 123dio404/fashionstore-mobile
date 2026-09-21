import 'package:flutter/material.dart';

import '../../core/data/mock_data.dart';
import '../../core/models/fashion_models.dart';
import '../../core/state/app_scope.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/kit/buttons.dart';
import '../../shared/kit/chips.dart';
import '../../shared/kit/nav.dart';
import '../../shared/kit/net_image.dart';

const _aiCategories = ['Mujer', 'Hombre', 'Calzado', 'Accesorios'];
const _aiSizes = ['XS', 'S', 'M', 'L', 'XL', 'XXL'];

/// Recomendaciones IA: perfil de estilo → sugerencias con puntaje de match.
class AiRecommendationsScreen extends StatefulWidget {
  const AiRecommendationsScreen({super.key, required this.onOpenProduct});

  final ValueChanged<Product> onOpenProduct;

  @override
  State<AiRecommendationsScreen> createState() =>
      _AiRecommendationsScreenState();
}

class _AiRecommendationsScreenState extends State<AiRecommendationsScreen> {
  String _category = 'Todos';
  String _brand = '';
  final Set<String> _sizes = {};
  double? _min;
  double? _max;
  bool _done = false;
  bool _generating = false;

  bool get _budgetError => _min != null && _max != null && _min! > _max!;

  int _stockOf(Product p) => p.stock.values.fold(0, (a, b) => a + b);

  List<(Product, int)> get _results {
    final scored = <(Product, int)>[];
    for (final p in kProducts) {
      if (_min != null && p.price < _min!) continue;
      if (_max != null && p.price > _max!) continue;
      var s = 0;
      if (_category != 'Todos' && p.category == _category) s += 40;
      if (_brand.isNotEmpty && p.brand == _brand) s += 25;
      if (_sizes.isNotEmpty && p.sizes.any(_sizes.contains)) s += 25;
      if (_stockOf(p) > 0) s += 10;
      scored.add((p, s));
    }
    scored.sort((a, b) => b.$2.compareTo(a.$2));
    return scored;
  }

  List<String> _reasons(Product p) {
    final r = <String>[];
    if (_category != 'Todos' && p.category == _category) {
      r.add('Categoría favorita');
    }
    if (_brand.isNotEmpty && p.brand == _brand) r.add('Tu marca');
    if (_sizes.isNotEmpty && p.sizes.any(_sizes.contains)) {
      r.add('Coincide con tu talla');
    }
    if (_stockOf(p) > 0) r.add('Disponible ahora');
    if (r.isEmpty) r.add('Basado en tus compras');
    return r.take(3).toList();
  }

  Future<void> _generate() async {
    setState(() => _generating = true);
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    setState(() {
      _generating = false;
      _done = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return Column(
      children: [
        AppTopBar(
          title: 'Recomendaciones IA',
          subtitle: _done ? 'Basado en tu estilo' : 'Cuéntanos tu estilo',
          onBack: s.closeOverlay,
        ),
        Expanded(
          child: _generating
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.accent),
                )
              : _done
                  ? _resultsList(s)
                  : _form(s),
        ),
        _footer(s),
      ],
    );
  }

  Widget _label(String t) => Text(
        t,
        style: AppTextStyles.bodySize(11,
            weight: FontWeight.w700, letterSpacing: 0.6),
      );

  Widget _priceBox(String hint, double? value, ValueChanged<double?> onChanged) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 11),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: _budgetError ? AppColors.accent : AppColors.border,
            width: 1.5,
          ),
        ),
        child: TextField(
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (v) => onChanged(double.tryParse(v)),
          style: AppTextStyles.bodySize(13),
          decoration: InputDecoration(
            border: InputBorder.none,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            prefixText: '\$ ',
            prefixStyle: AppTextStyles.bodySize(12, color: AppColors.mutedLight),
            hintText: hint,
            hintStyle: AppTextStyles.bodySize(12, color: AppColors.mutedLight),
          ),
        ),
      );

  Widget _form(AppState s) => ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          Text(
            'Cuéntanos tu estilo y generaremos sugerencias personalizadas.',
            style: AppTextStyles.bodySize(13,
                color: AppColors.muted, height: 1.6),
          ),
          const SizedBox(height: 18),
          _label('CATEGORÍA'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              PillChip(
                label: 'Todos',
                selected: _category == 'Todos',
                onTap: () => setState(() => _category = 'Todos'),
              ),
              ..._aiCategories.map((c) => PillChip(
                    label: c,
                    selected: _category == c,
                    onTap: () => setState(() => _category = c),
                  )),
            ],
          ),
          const SizedBox(height: 18),
          _label('MARCA'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              PillChip(
                label: 'Todas',
                selected: _brand.isEmpty,
                onTap: () => setState(() => _brand = ''),
              ),
              ...kBrandsList.map((b) => PillChip(
                    label: b,
                    selected: _brand == b,
                    onTap: () => setState(() => _brand = b),
                  )),
            ],
          ),
          const SizedBox(height: 18),
          _label('TU TALLA'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _aiSizes
                .map((sz) => SizeChip(
                      label: sz,
                      selected: _sizes.contains(sz),
                      onTap: () => setState(() {
                        _sizes.contains(sz)
                            ? _sizes.remove(sz)
                            : _sizes.add(sz);
                      }),
                    ))
                .toList(),
          ),
          const SizedBox(height: 18),
          _label('PRESUPUESTO'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _priceBox('Mín.', _min, (v) => setState(() => _min = v)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _priceBox('Máx.', _max, (v) => setState(() => _max = v)),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            _budgetError
                ? 'El mínimo no puede ser mayor que el máximo'
                : 'Vacío = sin límite',
            style: AppTextStyles.bodySize(11,
                color: _budgetError ? AppColors.accent : AppColors.mutedLight,
                weight: _budgetError ? FontWeight.w600 : FontWeight.w400),
          ),
        ],
      );

  Widget _resultsList(AppState s) {
    final results = _results.take(8).toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${results.length} sugerencias para ti',
                      style:
                          AppTextStyles.bodySize(14, weight: FontWeight.w700)),
                  Text('Ordenadas por coincidencia con tu estilo',
                      style:
                          AppTextStyles.bodySize(11, color: AppColors.muted)),
                ],
              ),
            ),
            PillChip(
              label: 'Ajustar',
              onTap: () => setState(() => _done = false),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ...results.map((r) => _resultCard(r.$1, r.$2, s)),
      ],
    );
  }

  Widget _resultCard(Product p, int score, AppState s) => Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                NetImage(
                  url: p.image,
                  width: 80,
                  height: 96,
                  radius: BorderRadius.circular(AppRadius.md),
                ),
                const SizedBox(width: 12),
                Expanded(child: _cardInfo(p, score)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: DButton(
                    label: 'Ver producto',
                    tone: DButtonTone.outline,
                    expanded: true,
                    size: DButtonSize.sm,
                    onPressed: () => widget.onOpenProduct(p),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DButton(
                    label: 'Agregar',
                    tone: DButtonTone.dark,
                    expanded: true,
                    size: DButtonSize.sm,
                    onPressed: () => s.addToCart(p),
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _cardInfo(Product p, int score) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(p.brand.toUpperCase(),
                    style: AppTextStyles.bodySize(10,
                        color: AppColors.muted, letterSpacing: 0.6)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text('$score% match',
                    style: AppTextStyles.bodySize(10,
                        color: AppColors.accentDark, weight: FontWeight.w700)),
              ),
            ],
          ),
          Text(p.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySize(13, weight: FontWeight.w600)),
          const SizedBox(height: 3),
          Row(
            children: [
              Text('\$${p.price.toStringAsFixed(2)}',
                  style: AppTextStyles.bodySize(14, weight: FontWeight.w700)),
              const SizedBox(width: 6),
              Text(
                '\$${p.oldPrice.toStringAsFixed(2)}',
                style: AppTextStyles.bodySize(11,
                        color: AppColors.mutedLight)
                    .copyWith(decoration: TextDecoration.lineThrough),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 5,
            runSpacing: 5,
            children: _reasons(p)
                .map((r) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.infoBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(r,
                          style: AppTextStyles.bodySize(9,
                              color: AppColors.info,
                              weight: FontWeight.w600)),
                    ))
                .toList(),
          ),
        ],
      );

  Widget _footer(AppState s) => Container(
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
        child: Row(
          children: [
            if (_done) ...[
              Expanded(
                child: DButton(
                  label: 'Ajustar estilo',
                  tone: DButtonTone.outline,
                  expanded: true,
                  onPressed: () => setState(() => _done = false),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: DButton(
                label:
                    _done ? 'Guardar preferencias' : 'Generar recomendaciones',
                tone: DButtonTone.dark,
                expanded: true,
                onPressed: _budgetError
                    ? null
                    : (_done ? () => s.setToast('Preferencias guardadas') : _generate),
              ),
            ),
          ],
        ),
      );
}
