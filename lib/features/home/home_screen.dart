import 'package:flutter/material.dart';

import '../../../core/data/mock_data.dart';
import '../../../core/models/fashion_models.dart';
import '../../../core/state/app_scope.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/state/app_state.dart';
import '../../../shared/kit/buttons.dart';
import '../../../shared/kit/cart_widgets.dart';
import '../../../shared/kit/chips.dart';
import '../../../shared/kit/net_image.dart';
import '../../../shared/kit/product_card.dart';
import '../../../shared/kit/states.dart';

/// Inicio: saludo, buscador, categorías, banners, destacados y grilla.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onOpenProduct});

  final ValueChanged<Product> onOpenProduct;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _category = 'Todos';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (mounted) setState(() => _loading = false);
  }

  List<Product> get _filtered {
    if (_category == 'Todos') return kProducts;
    if (_category == 'Ofertas') {
      return kProducts.where((p) => p.discount >= 27).toList();
    }
    return kProducts.where((p) => p.category == _category).toList();
  }

  List<Product> get _featured => kProducts.where((p) => p.isFeatured).toList();

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return Stack(
      children: [
        Column(
          children: [
            _header(),
            Expanded(
              child: s.isOffline
                  ? const OfflineState()
                  : ListView(
                      padding: const EdgeInsets.only(bottom: 110),
                      children: [
                        _categories(),
                        const SizedBox(height: 16),
                        _banners(),
                        const SizedBox(height: 28),
                        _featuredRow(),
                        const SizedBox(height: 28),
                        _grid(),
                        const SizedBox(height: 24),
                      ],
                    ),
            ),
          ],
        ),
        Positioned(right: 20, bottom: 20, child: _fab(s)),
      ],
    );
  }

  Widget _header() {
    final s = AppScope.of(context);
    return Container(
      color: AppColors.background,
      padding: EdgeInsets.only(
        top: MediaQuery.paddingOf(context).top + 12,
        left: 20,
        right: 20,
        bottom: 16,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bienvenida de nuevo',
                      style: AppTextStyles.bodySize(
                        12,
                        color: AppColors.muted,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text('FashionStore', style: AppTextStyles.displaySize(24)),
                  ],
                ),
              ),
              _circleButton(
                Icons.notifications_none,
                () => s.setToast('No tienes notificaciones nuevas'),
              ),
              const SizedBox(width: 8),
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: AppColors.dark,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  'AL',
                  style: AppTextStyles.bodySize(
                    13,
                    color: Colors.white,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => s.setTab(AppTab.catalog),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, size: 16, color: AppColors.mutedLight),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Buscar productos, marcas...',
                      style: AppTextStyles.bodySize(14, color: AppColors.mutedLight),
                    ),
                  ),
                  IconCircleButton(
                    icon: Icons.mic_none,
                    size: 32,
                    iconSize: 15,
                    color: AppColors.muted,
                    background: AppColors.borderLight,
                    onPressed: () => s.openOverlay(OverlayScreen.voice),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleButton(IconData icon, VoidCallback onTap) => Container(
        width: 38,
        height: 38,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Color(0x14000000), blurRadius: 4, offset: Offset(0, 1)),
          ],
        ),
        child: IconButton(
          padding: EdgeInsets.zero,
          iconSize: 18,
          icon: Icon(icon, color: AppColors.dark),
          onPressed: onTap,
        ),
      );

  Widget _categories() => SizedBox(
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

  Widget _fab(AppState s) => Material(
        color: AppColors.dark,
        shape: const CircleBorder(),
        elevation: 6,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => s.openOverlay(OverlayScreen.chatbot),
          child: const SizedBox(
            width: 52,
            height: 52,
            child: Icon(Icons.chat_bubble_outline, color: Colors.white, size: 22),
          ),
        ),
      );

  Widget _banners() => SizedBox(
        height: 180,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: kBanners.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (_, i) {
            final b = kBanners[i];
            final bg = colorFromHex(b.bg);
            return ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.xl),
              child: SizedBox(
                width: 300,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    NetImage(url: b.image),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            bg.withValues(alpha: 0.94),
                            bg.withValues(alpha: 0.30),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(b.tag, style: _tagStyle),
                          ),
                          const SizedBox(height: 10),
                          Text(b.title,
                              style: AppTextStyles.displaySize(22,
                                  color: Colors.white)),
                          const SizedBox(height: 6),
                          Text(b.subtitle, style: _subStyle),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );

  TextStyle get _tagStyle => AppTextStyles.bodySize(9,
      color: Colors.white, weight: FontWeight.w700, letterSpacing: 0.6);

  TextStyle get _subStyle =>
      AppTextStyles.bodySize(12, color: Colors.white.withValues(alpha: 0.75));

  Widget _featuredRow() {
    final s = AppScope.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SectionHead(
            title: 'Destacados',
            action: 'Ver todos',
            onAction: () => s.setTab(AppTab.catalog),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 292,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _featured.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => _featuredCard(_featured[i]),
          ),
        ),
      ],
    );
  }

  Widget _featuredCard(Product p) => GestureDetector(
        onTap: () => widget.onOpenProduct(p),
        child: Container(
          width: 152,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F000000),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  NetImage(url: p.image, width: 152, height: 192),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text('-${p.discount}%', style: _tagStyle),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.brand.toUpperCase(),
                      style: AppTextStyles.bodySize(10,
                          color: AppColors.muted, letterSpacing: 0.6),
                    ),
                    Text(
                      p.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySize(12,
                          weight: FontWeight.w600),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '\$${p.price.toStringAsFixed(2)}',
                      style:
                          AppTextStyles.bodySize(13, weight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _grid() {
    final s = AppScope.of(context);
    final title = _category == 'Todos' ? 'Nuevos arrivals' : _category;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SectionHead(
            title: title,
            action: 'Filtrar',
            onAction: () => s.setTab(AppTab.catalog),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _loading
              ? GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.58,
                  children: List.generate(
                    4,
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
                )
              : _filtered.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          'No hay productos en esta categoría.',
                          style: AppTextStyles.bodySize(14,
                              color: AppColors.muted),
                        ),
                      ),
                    )
                  : GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _filtered.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        childAspectRatio: 0.55,
                      ),
                      itemBuilder: (_, i) {
                        final p = _filtered[i];
                        return ProductCard(
                          product: p,
                          onTap: () => widget.onOpenProduct(p),
                          onAddToCart: () => s.addToCart(p),
                          isFav: s.isFav(p.id),
                          onToggleFav: () => s.toggleFav(p.id),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
