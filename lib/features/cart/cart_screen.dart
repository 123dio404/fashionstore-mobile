import 'package:flutter/material.dart';

import '../../../core/models/fashion_models.dart';
import '../../../core/state/app_scope.dart';
import '../../../core/state/app_state.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/kit/buttons.dart';
import '../../../shared/kit/cart_widgets.dart';
import '../../../shared/kit/inputs.dart';
import '../../../shared/kit/nav.dart';
import '../../../shared/kit/states.dart';

/// Carrito: ítems, cupón FASHION10, tipo de entrega y resumen de costos.
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _coupon = TextEditingController();
  String _delivery = 'home';
  bool _couponApplied = false;

  @override
  void dispose() {
    _coupon.dispose();
    super.dispose();
  }

  void _applyCoupon() {
    if (_coupon.text.trim().toLowerCase() == 'fashion10') {
      setState(() => _couponApplied = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final subtotal = s.cartSubtotal;
    final shipping = _delivery == 'home' ? 4.99 : 0.0;
    final discount = _couponApplied ? subtotal * 0.1 : 0.0;
    final total = subtotal + shipping - discount;

    if (s.isOffline) {
      return Column(
        children: [
          const AppTopBar(title: 'Mi Carrito', subtitle: 'FashionStore'),
          OfflineState(onRetry: () => s.setOffline(false)),
        ],
      );
    }

    return Column(
      children: [
        const AppTopBar(title: 'Mi Carrito', subtitle: 'FashionStore'),
        Expanded(
          child: s.cart.isEmpty
              ? EmptyState(
                  icon: Icons.shopping_bag_outlined,
                  title: 'Tu carrito está vacío',
                  subtitle: 'Explora el catálogo y agrega tus prendas favoritas.',
                  cta: 'Ir al catálogo',
                  onCta: () => s.setTab(AppTab.catalog),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  children: [
                    ...s.cart.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: CartRow(
                          item: item,
                          onInc: () => s.incQty(item.productId),
                          onDec: () => s.decQty(item.productId),
                          onRemove: () => s.removeFromCart(item.productId),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _shipCard(),
                    const SizedBox(height: 16),
                    _couponCard(),
                    const SizedBox(height: 16),
                    _summaryCard(s, subtotal, shipping, discount, total),
                  ],
                ),
        ),
        if (s.cart.isNotEmpty) _cta(s),
      ],
    );
  }

  Widget _shipCard() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('MÉTODO DE ENTREGA',
                style: AppTextStyles.bodySize(12,
                    weight: FontWeight.w700, letterSpacing: 0.6)),
            const SizedBox(height: 12),
            Row(
              children: [
                _shipOption('home', 'Envío a domicilio', '3–5 días hábiles',
                    '\$4.99', Icons.local_shipping_outlined),
                const SizedBox(width: 10),
                _shipOption('pickup', 'Retiro en tienda', 'Disponible 24 hrs',
                    'Gratis', Icons.storefront_outlined),
              ],
            ),
          ],
        ),
      );

  Widget _shipOption(
    String id,
    String label,
    String sub,
    String price,
    IconData icon,
  ) {
    final active = _delivery == id;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _delivery = id),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: active ? AppColors.dark : AppColors.borderLight,
              width: 2,
            ),
            color: active ? AppColors.borderLight : AppColors.surface,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon,
                  size: 18,
                  color: active ? AppColors.dark : AppColors.mutedLight),
              const SizedBox(height: 6),
              Text(label,
                  style: AppTextStyles.bodySize(12, weight: FontWeight.w700)),
              Text(sub,
                  style: AppTextStyles.bodySize(10, color: AppColors.muted)),
              const SizedBox(height: 5),
              Text(price,
                  style: AppTextStyles.bodySize(12,
                      color: active ? AppColors.accent : AppColors.dark,
                      weight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _couponCard() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: DTextField(
                label: 'Código de descuento',
                controller: _coupon,
                hint: 'FASHION10',
              ),
            ),
            const SizedBox(width: 12),
            DButton(
              label: _couponApplied ? 'Aplicado' : 'Aplicar',
              tone: _couponApplied ? DButtonTone.accent : DButtonTone.dark,
              size: DButtonSize.sm,
              onPressed: _couponApplied ? null : _applyCoupon,
            ),
          ],
        ),
      );

  Widget _row(String label, String value, {bool success = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Text(label,
                style: AppTextStyles.bodySize(13, color: AppColors.muted)),
            const Spacer(),
            Text(value,
                style: AppTextStyles.bodySize(13,
                    color: success ? AppColors.success : AppColors.dark,
                    weight: FontWeight.w600)),
          ],
        ),
      );

  Widget _summaryCard(
    AppState s,
    double subtotal,
    double shipping,
    double discount,
    double total,
  ) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('RESUMEN DEL PEDIDO',
                style: AppTextStyles.bodySize(12,
                    weight: FontWeight.w700, letterSpacing: 0.6)),
            const SizedBox(height: 12),
            _row(
              'Subtotal (${s.cartCount} artículo${s.cartCount != 1 ? 's' : ''})',
              '\$${subtotal.toStringAsFixed(2)}',
            ),
            _row(
              'Envío',
              _delivery == 'pickup'
                  ? 'Gratis'
                  : '\$${shipping.toStringAsFixed(2)}',
              success: _delivery == 'pickup',
            ),
            if (_couponApplied)
              _row('Descuento FASHION10',
                  '-\$${discount.toStringAsFixed(2)}',
                  success: true),
            const Divider(color: AppColors.borderLight, height: 24),
            Row(
              children: [
                Text('Total',
                    style: AppTextStyles.bodySize(15, weight: FontWeight.w700)),
                const Spacer(),
                Text('\$${total.toStringAsFixed(2)}',
                    style: AppTextStyles.bodySize(22, weight: FontWeight.w800)),
              ],
            ),
          ],
        ),
      );

  Widget _cta(AppState s) => Container(
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
        child: Column(
          children: [
            DButton(
              label: 'Ir al checkout',
              icon: Icons.credit_card,
              tone: DButtonTone.dark,
              expanded: true,
              size: DButtonSize.lg,
              onPressed: () => s.openOverlay(OverlayScreen.checkout),
            ),
            const SizedBox(height: 8),
            Text(
              'Pago seguro con cifrado SSL · Datos protegidos',
              style: AppTextStyles.bodySize(11, color: AppColors.mutedLight),
            ),
          ],
        ),
      );
}
