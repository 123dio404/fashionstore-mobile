import 'package:flutter/material.dart';

import '../../../core/data/mock_data.dart';
import '../../../core/models/fashion_models.dart';
import '../../../core/state/app_scope.dart';
import '../../../core/state/app_state.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/kit/buttons.dart';
import '../../../shared/kit/nav.dart';
import '../../../shared/kit/net_image.dart';
import '../../../shared/kit/states.dart';

/// Checkout en 3 pasos: resumen → entrega → pago (con pantalla de proceso).
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  int _step = 0; // 0 resumen · 1 entrega · 2 pago · 3 procesando
  String _delivery = 'home';
  String _storeId = 'centro';
  String _payMethod = 'card';
  String _cardId = 'visa';

  static const _titles = ['Resumen', 'Entrega', 'Pago'];

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);

    if (s.cart.isEmpty && _step != 3) {
      return Column(
        children: [
          AppTopBar(title: 'Checkout', onBack: s.closeOverlay),
          const EmptyState(
            icon: Icons.shopping_bag_outlined,
            title: 'Nada que pagar',
            subtitle: 'Tu carrito está vacío.',
          ),
        ],
      );
    }

    if (_step == 3) return _processing();

    return Column(
      children: [
        AppTopBar(
          title: 'Checkout',
          subtitle: 'FashionStore',
          onBack: () => _step == 0 ? s.closeOverlay() : setState(() => _step--),
        ),
        _progress(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            children: [
              if (_step == 0) ..._summaryStep(s),
              if (_step == 1) ..._deliveryStep(),
              if (_step == 2) ..._paymentStep(),
              const SizedBox(height: 16),
              _costsCard(s),
            ],
          ),
        ),
        _footer(s),
      ],
    );
  }

  Widget _progress() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Row(
        children: List.generate(_titles.length, (i) {
          final done = i <= _step;
          return Expanded(
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done ? AppColors.dark : AppColors.borderLight,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${i + 1}',
                    style: AppTextStyles.bodySize(11,
                        color: done ? Colors.white : AppColors.mutedLight,
                        weight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _titles[i],
                  style: AppTextStyles.bodySize(11,
                      color: done ? AppColors.dark : AppColors.mutedLight,
                      weight: FontWeight.w600),
                ),
                if (i < _titles.length - 1)
                  const Expanded(
                    child: Divider(
                      color: AppColors.borderLight,
                      thickness: 2,
                      indent: 6,
                      endIndent: 6,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  StoreBranch get _store =>
      kStores.firstWhere((st) => st.id == _storeId, orElse: () => kStores.first);

  Widget _card(String title, List<Widget> children) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: const [
            BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title.toUpperCase(),
                style: AppTextStyles.bodySize(12,
                    weight: FontWeight.w700, letterSpacing: 0.6)),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      );

  List<Widget> _summaryStep(AppState s) => [
        _card('Resumen del pedido', [
          ...s.cart.map(
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  NetImage(
                    url: i.image,
                    width: 52,
                    height: 64,
                    radius: BorderRadius.circular(10),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(i.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodySize(12,
                                weight: FontWeight.w600)),
                        Text('Talla ${i.size} · ${i.color}',
                            style: AppTextStyles.bodySize(11,
                                color: AppColors.muted)),
                        Text('\$${(i.price * i.qty).toStringAsFixed(2)} ×${i.qty}',
                            style: AppTextStyles.bodySize(12,
                                weight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ]),
        _card('Dirección de entrega', [
          Row(
            children: [
              const Icon(Icons.place_outlined, size: 18, color: AppColors.muted),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _delivery == 'home' ? 'Av. Corrientes 1450, CABA' : _store.name,
                      style: AppTextStyles.bodySize(13, weight: FontWeight.w600),
                    ),
                    Text(
                      _delivery == 'home'
                          ? 'Envío a domicilio · 3–5 días hábiles'
                          : 'Retiro en tienda · disponible en 24 hrs',
                      style: AppTextStyles.bodySize(11, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ]),
      ];

  List<Widget> _deliveryStep() => [
        _card('Método de entrega', [
          _radioRow(
            _delivery == 'home',
            'Envío a domicilio · \$4.99',
            Icons.local_shipping_outlined,
            () => setState(() => _delivery = 'home'),
          ),
          _radioRow(
            _delivery == 'pickup',
            'Retiro en tienda · Gratis',
            Icons.storefront_outlined,
            () => setState(() => _delivery = 'pickup'),
          ),
        ]),
        if (_delivery == 'pickup')
          _card(
            'Sucursal de retiro',
            kStores
                .map((st) => _radioRow(
                      _storeId == st.id,
                      '${st.name} · ${st.hours}',
                      Icons.store_outlined,
                      () => setState(() => _storeId = st.id),
                    ))
                .toList(),
          ),
      ];

  static const _cards = <(String, String, Color)>[
    ('visa', 'Visa •••• 4242', Color(0xFF1A1F71)),
    ('mc', 'Mastercard •••• 8821', Color(0xFFEB001B)),
  ];

  String get _payLabel => switch (_payMethod) {
        'card' => _cards.firstWhere((c) => c.$1 == _cardId).$2,
        'apple' => 'Apple Pay',
        _ => 'Google Pay',
      };

  Widget _radioRow(
    bool active,
    String label,
    IconData icon,
    VoidCallback onTap, {
    Color? swatch,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: active ? AppColors.dark : AppColors.borderLight,
              width: 1.5,
            ),
            color: active ? AppColors.borderLight : AppColors.surface,
          ),
          child: Row(
            children: [
              if (swatch != null)
                Container(
                  width: 32,
                  height: 20,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: swatch,
                    borderRadius: BorderRadius.circular(4),
                  ),
                )
              else
                Icon(icon,
                    size: 18,
                    color: active ? AppColors.dark : AppColors.mutedLight),
              const SizedBox(width: 10),
              Expanded(
                child: Text(label,
                    style:
                        AppTextStyles.bodySize(13, weight: FontWeight.w600)),
              ),
              if (active)
                const Icon(Icons.check, size: 16, color: AppColors.success),
            ],
          ),
        ),
      );

  List<Widget> _paymentStep() => [
        _card('Método de pago', [
          _radioRow(
            _payMethod == 'card',
            'Tarjeta de crédito / débito',
            Icons.credit_card,
            () => setState(() => _payMethod = 'card'),
          ),
          if (_payMethod == 'card')
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 8),
              child: Column(
                children: _cards
                    .map((c) => _radioRow(
                          _cardId == c.$1,
                          c.$2,
                          Icons.credit_card,
                          () => setState(() => _cardId = c.$1),
                          swatch: c.$3,
                        ))
                    .toList(),
              ),
            ),
          _radioRow(
            _payMethod == 'apple',
            'Apple Pay',
            Icons.apple,
            () => setState(() => _payMethod = 'apple'),
          ),
          _radioRow(
            _payMethod == 'google',
            'Google Pay',
            Icons.g_mobiledata,
            () => setState(() => _payMethod = 'google'),
          ),
        ]),
      ];

  Widget _costsCard(AppState s) {
    final subtotal = s.cartSubtotal;
    final shipping = _delivery == 'home' ? 4.99 : 0.0;
    return _card('Resumen de costos', [
      _costRow('Subtotal (${s.cartCount} artículos)',
          '\$${subtotal.toStringAsFixed(2)}'),
      _costRow(
        'Envío',
        shipping == 0 ? 'Gratis' : '\$${shipping.toStringAsFixed(2)}',
        success: shipping == 0,
      ),
      const Divider(color: AppColors.borderLight, height: 20),
      Row(
        children: [
          Text('Total',
              style: AppTextStyles.bodySize(15, weight: FontWeight.w700)),
          const Spacer(),
          Text('\$${(subtotal + shipping).toStringAsFixed(2)}',
              style: AppTextStyles.bodySize(20, weight: FontWeight.w800)),
        ],
      ),
    ]);
  }

  Widget _costRow(String label, String value, {bool success = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Text(label, style: AppTextStyles.bodySize(13, color: AppColors.muted)),
            const Spacer(),
            Text(value,
                style: AppTextStyles.bodySize(13,
                    color: success ? AppColors.success : AppColors.dark,
                    weight: FontWeight.w600)),
          ],
        ),
      );

  Widget _footer(AppState s) {
    final total = s.cartSubtotal + (_delivery == 'home' ? 4.99 : 0.0);
    final label = switch (_step) {
      0 => 'Continuar con entrega',
      1 => 'Continuar con pago',
      _ => 'Pagar \$${total.toStringAsFixed(2)}',
    };
    return Container(
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
        label: label,
        icon: _step == 2 ? Icons.credit_card : null,
        tone: _step == 2 ? DButtonTone.accent : DButtonTone.dark,
        expanded: true,
        size: DButtonSize.lg,
        onPressed: () {
          if (_step == 2) {
            _pay(s, total);
          } else {
            setState(() => _step++);
          }
        },
      ),
    );
  }

  Future<void> _pay(AppState s, double total) async {
    final subtotal = s.cartSubtotal;
    final shipping = _delivery == 'home' ? 4.99 : 0.0;
    final storeName = _store.name;
    final items = s.cart
        .map((i) => PurchaseItem(
              productId: i.productId,
              name: i.name,
              brand: i.brand,
              price: i.price,
              image: i.image,
              size: i.size,
              color: i.color,
              qty: i.qty,
            ))
        .toList();
    final method = _payLabel;
    final delivery = _delivery;

    setState(() => _step = 3);
    await Future<void>.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;

    s.completePurchase(Purchase(
      id: 'ORD-${1000 + DateTime.now().millisecondsSinceEpoch % 9000}',
      date: _fmtDate(DateTime.now()),
      status: 'procesando',
      total: total,
      subtotal: subtotal,
      shipping: shipping,
      paymentMethod: method,
      deliveryMethod: delivery,
      store: delivery == 'pickup' ? storeName : null,
      items: items,
    ));
    s.openOverlay(OverlayScreen.purchaseSuccess);
    setState(() => _step = 0);
  }

  static const _months = [
    'ene', 'feb', 'mar', 'abr', 'may', 'jun',
    'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
  ];

  String _fmtDate(DateTime d) =>
      '${d.day} ${_months[d.month - 1]} ${d.year}';

  Widget _processing() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 72,
              height: 72,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AppColors.dark,
              ),
            ),
            const SizedBox(height: 24),
            Text('Procesando pago',
                style: AppTextStyles.displaySize(22)),
            const SizedBox(height: 6),
            Text(
              'Conectando con la pasarela… por favor espera.',
              style: AppTextStyles.bodySize(13, color: AppColors.muted),
            ),
          ],
        ),
      );
}
