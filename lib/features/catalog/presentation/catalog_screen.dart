import 'package:flutter/material.dart';

import '../../../core/data/mock_data.dart';
import '../../../core/models/fashion_models.dart';
import '../../../core/state/app_scope.dart';
import '../../../core/state/app_state.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/kit/buttons.dart';
import '../../../shared/kit/cart_widgets.dart';
import '../../../shared/kit/chips.dart';
import '../../../shared/kit/product_card.dart';
import '../../../shared/kit/states.dart';

const _sorts = [
  'Relevancia',
  'Precio: menor a mayor',
  'Precio: mayor a menor',
  'Más nuevo',
  'Mejor valorado',
];

/// Catálogo: búsqueda, categorías, orden, filtros y grilla de productos.
class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key, required this.onOpenProduct});

  final ValueChanged<Product> onOpenProduct;

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final _search = TextEditingController();
  String _category = 'Todos';
  String _sort = _sorts.first;
  String? _brand;
  final Set<String> _sizes = {};
  double? _minPrice;
  double? _maxPrice;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (mounted) setState(() => _loading = false);
  }

  void _clear() {
    setState(() {
      _brand = null;
      _sizes.clear();
      _minPrice = null;
      _maxPrice = null;
      _category = 'Todos';
      _search.clear();
    });
  }

  bool get _hasFilters =>
      _brand != null || _sizes.isNotEmpty || _minPrice != null || _maxPrice != null;

  List<Product> get _results {
    final q = _search.text.trim().toLowerCase();
    final list = kProducts.where((p) {
      if (_category == 'Ofertas' && p.discount < 27) return false;
      if (_category != 'Todos' &&
          _category != 'Ofertas' &&
          p.category != _category) {
        return false;
      }
      if (_brand != null && p.brand != _brand) return false;
      if (_sizes.isNotEmpty && !p.sizes.any(_sizes.contains)) return false;
      if (_minPrice != null && p.price < _minPrice!) return false;
      if (_maxPrice != null && p.price > _maxPrice!) return false;
      if (q.isNotEmpty &&
          !p.name.toLowerCase().contains(q) &&
          !p.brand.toLowerCase().contains(q)) {
        return false;
      }
      return true;
    }).toList();

    switch (_sort) {
      case 'Precio: menor a mayor':
        list.sort((a, b) => a.price.compareTo(b.price));
      case 'Precio: mayor a menor':
        list.sort((a, b) => b.price.compareTo(a.price));
      case 'Más nuevo':
        list.sort((a, b) =>
            (b.isNew ? 1 : 0).compareTo(a.isNew ? 1 : 0));
      case 'Mejor valorado':
        list.sort((a, b) => b.rating.compareTo(a.rating));
    }
    return list;
  }

  List<String> get _brands =>
      kProducts.map((p) => p.brand).toSet().toList()..sort();

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final results = _results;
    return Stack(
      children: [
        Column(
          children: [
            _header(s),
            Expanded(
              child: s.isOffline
                  ? const OfflineState()
                  : RefreshIndicator(
                      color: AppColors.accent,
                      onRefresh: _load,
                      child: _loading
                          ? _skeleton()
                          : results.isEmpty
                              ? SingleChildScrollView(
                                  child: EmptyState(
                                    icon: Icons.search_off,
                                    title: 'Sin resultados',
                                    subtitle:
                                        'No encontramos productos que coincidan con tu búsqueda. Prueba con otros términos.',
                                    cta: 'Limpiar filtros',
                                    onCta: _clear,
                                  ),
                                )
                              : ListView(
                                  padding:
                                      const EdgeInsets.fromLTRB(20, 0, 20, 110),
                                  children: [
                                    Text(
                                      '${results.length} producto${results.length != 1 ? 's' : ''}',
                                      style: AppTextStyles.bodySize(12,
                                          color: AppColors.muted),
                                    ),
                                    const SizedBox(height: 12),
                                    _grid(results, s),
                                  ],
                                ),
                    ),
            ),
          ],
        ),
        Positioned(
          right: 20,
          bottom: 20,
          child: Material(
            color: AppColors.dark,
            shape: const CircleBorder(),
            elevation: 6,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => s.openOverlay(OverlayScreen.chatbot),
              child: const SizedBox(
                width: 52,
                height: 52,
                child:
                    Icon(Icons.chat_bubble_outline, color: Colors.white, size: 22),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _header(AppState s) => Container(
        color: AppColors.background,
        padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top + 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Catálogo',
                        style: AppTextStyles.displaySize(24)),
                  ),
                  IconCircleButton(
                    icon: Icons.mic_none,
                    size: 36,
                    iconSize: 16,
                    onPressed: () => s.openOverlay(OverlayScreen.voice),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search,
                        size: 16, color: AppColors.mutedLight),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _search,
                        onChanged: (_) => setState(() {}),
                        style: AppTextStyles.bodySize(14),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 14),
                          hintText: 'Buscar productos, marcas...',
                          hintStyle: AppTextStyles.bodySize(14,
                              color: AppColors.mutedLight),
                        ),
                      ),
                    ),
                    if (_search.text.isNotEmpty)
                      InkWell(
                        onTap: () {
                          _search.clear();
                          setState(() {});
                        },
                        child: const Icon(Icons.close,
                            size: 16, color: AppColors.mutedLight),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            _categoriesRow(),
            const SizedBox(height: 12),
            _sortRow(s),
            const SizedBox(height: 14),
          ],
        ),
      );

  Widget _categoriesRow() => SizedBox(
        height: 34,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: kCategories.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final c = kCategories[i];
            return PillChip(
              label: c,
              selected: _category == c,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              onTap: () => setState(() => _category = c),
            );
          },
        ),
      );

  Widget _sortRow(AppState s) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Expanded(
              child: PopupMenuButton<String>(
                onSelected: (v) => setState(() => _sort = v),
                itemBuilder: (_) => _sorts
                    .map((o) => PopupMenuItem(
                          value: o,
                          child: Text(o, style: AppTextStyles.bodySize(13)),
                        ))
                    .toList(),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.sort, size: 14, color: AppColors.muted),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(_sort,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodySize(12,
                                color: AppColors.muted)),
                      ),
                      const Icon(Icons.expand_more,
                          size: 14, color: AppColors.mutedLight),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _openFilters(),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: _hasFilters ? AppColors.dark : AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(
                    color: _hasFilters ? AppColors.dark : AppColors.border,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.tune,
                        size: 14,
                        color: _hasFilters ? Colors.white : AppColors.muted),
                    const SizedBox(width: 6),
                    Text(
                      'Filtros',
                      style: AppTextStyles.bodySize(12,
                          color: _hasFilters ? Colors.white : AppColors.muted,
                          weight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );

  Widget _grid(List<Product> results, AppState s) => GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: results.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 0.55,
        ),
        itemBuilder: (_, i) {
          final p = results[i];
          return ProductCard(
            product: p,
            onTap: () => widget.onOpenProduct(p),
            onAddToCart: () => s.addToCart(p),
            isFav: s.isFav(p.id),
            onToggleFav: () => s.toggleFav(p.id),
          );
        },
      );

  Widget _skeleton() => GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.58,
        children: List.generate(
          6,
          (_) => const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: SkeletonBox(height: 400, radius: 16)),
              SizedBox(height: 8),
              SkeletonBox(height: 12),
              SizedBox(height: 6),
              SkeletonBox(height: 12, width: 80),
            ],
          ),
        ),
      );

  void _openFilters() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            24 + MediaQuery.paddingOf(ctx).bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text('Filtros', style: AppTextStyles.displaySize(20)),
              const SizedBox(height: 18),
              _sheetLabel('MARCA'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _brands
                    .map((b) => PillChip(
                          label: b,
                          selected: _brand == b,
                          onTap: () {
                            setState(() => _brand = _brand == b ? null : b);
                            setSheet(() {});
                          },
                        ))
                    .toList(),
              ),
              const SizedBox(height: 18),
              _sheetLabel('TALLA'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: kSizesList
                    .map((sz) => SizeChip(
                          label: sz,
                          selected: _sizes.contains(sz),
                          onTap: () {
                            setState(() {
                              _sizes.contains(sz)
                                  ? _sizes.remove(sz)
                                  : _sizes.add(sz);
                            });
                            setSheet(() {});
                          },
                        ))
                    .toList(),
              ),
              const SizedBox(height: 18),
              _sheetLabel('PRECIO (\$)'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _priceBox(
                      'Mín.',
                      _minPrice,
                      (v) => setState(() => _minPrice = v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _priceBox(
                      'Máx.',
                      _maxPrice,
                      (v) => setState(() => _maxPrice = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: DButton(
                      label: 'Limpiar',
                      tone: DButtonTone.outline,
                      expanded: true,
                      onPressed: () {
                        _clear();
                        setSheet(() {});
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DButton(
                      label: 'Aplicar',
                      tone: DButtonTone.dark,
                      expanded: true,
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetLabel(String t) => Text(
        t,
        style: AppTextStyles.bodySize(11,
            weight: FontWeight.w700, letterSpacing: 0.6),
      );

  Widget _priceBox(
    String hint,
    double? value,
    ValueChanged<double?> onChanged,
  ) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 11),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: TextField(
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (v) => onChanged(double.tryParse(v)),
          style: AppTextStyles.bodySize(13),
          decoration: InputDecoration(
            border: InputBorder.none,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 11),
            prefixText: '\$ ',
            prefixStyle: AppTextStyles.bodySize(12, color: AppColors.mutedLight),
            hintText: hint,
            hintStyle: AppTextStyles.bodySize(12, color: AppColors.mutedLight),
          ),
        ),
      );
}
