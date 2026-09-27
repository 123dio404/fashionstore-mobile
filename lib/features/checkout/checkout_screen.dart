import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
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
import '../catalog/data/catalog_repository.dart';
import '../catalog/data/models/catalog_models.dart';
import '../commerce/data/commerce_repository.dart';

/// Checkout en 3 pasos: resumen → entrega → pago (con pantalla de proceso).
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final CommerceRepository _commerce = CommerceRepository();
  final CatalogRepository _catalog = CatalogRepository();

  int _step = 0; // 0 resumen · 1 entrega · 2 pago · 3 procesando
  String _delivery = 'home';
  String _storeId = 'centro';
  String _payMethod = 'card'; // card · qr · cash
  String _cardId = 'visa'; // visa · mc
  String? _qrCodeBase64;
  String? _qrPaymentUrl;
  bool _loadingQr = false;
  bool _paying = false;
  String _payProgress = '';

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
              if (_step == 2) ..._paymentStep(s),
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

  static const _cards = <(String, String, Color, String, bool)>[
    ('visa', 'Visa •••• 4242', Color(0xFF1A1F71), 'pm_card_visa', false),
    ('mc', 'Mastercard •••• 0002', Color(0xFFEB001B), 'pm_card_declined', true),
  ];

  String get _payLabel => switch (_payMethod) {
        'card' => _cards.firstWhere((c) => c.$1 == _cardId).$2,
        'qr' => 'Stripe QR',
        'cash' => 'Efectivo en tienda / entrega',
        _ => 'Tarjeta Stripe',
      };

  Future<void> _loadQr(double total) async {
    if (_loadingQr) return;
    setState(() => _loadingQr = true);
    try {
      final res = await _commerce.createQrPayment(amount: total);
      if (mounted) {
        setState(() {
          _qrCodeBase64 = res['qr_code_base64'] as String?;
          _qrPaymentUrl = res['payment_url'] as String?;
          _loadingQr = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loadingQr = false);
      }
    }
  }

  Widget _radioRow(
    bool active,
    String label,
    IconData icon,
    VoidCallback onTap, {
    Color? swatch,
    Widget? trailing,
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
            color: active ? AppColors.borderLight.withValues(alpha: 0.3) : AppColors.surface,
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
              if (trailing != null) trailing,
              if (active && trailing == null)
                const Icon(Icons.check_circle, size: 18, color: AppColors.dark),
            ],
          ),
        ),
      );

  List<Widget> _paymentStep(AppState s) {
    final total = s.cartSubtotal + (_delivery == 'home' ? 4.99 : 0.0);
    return [
      _card('Método de pago (Stripe & Efectivo)', [
        _radioRow(
          _payMethod == 'card',
          'Tarjeta de crédito / débito (Stripe)',
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
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: c.$5 ? const Color(0xFFFFEBEE) : const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            c.$5 ? 'Simular Rechazo' : 'Aprobación',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: c.$5 ? AppColors.danger : const Color(0xFF2E7D32),
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
        _radioRow(
          _payMethod == 'qr',
          'Stripe QR (Escaneo dinámico)',
          Icons.qr_code_2,
          () {
            setState(() => _payMethod = 'qr');
            _loadQr(total);
          },
        ),
        if (_payMethod == 'qr')
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              children: [
                if (_loadingQr) ...[
                  const SizedBox(height: 12),
                  const CircularProgressIndicator(strokeWidth: 2, color: AppColors.dark),
                  const SizedBox(height: 12),
                  Text('Generando QR seguro con Stripe…',
                      style: AppTextStyles.bodySize(12, color: AppColors.muted)),
                ] else if (_qrCodeBase64 != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      base64Decode(
                        _qrCodeBase64!.contains(',')
                            ? _qrCodeBase64!.split(',').last
                            : _qrCodeBase64!,
                      ),
                      width: 170,
                      height: 170,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Escanea para pagar \$${total.toStringAsFixed(2)} con Stripe',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySize(12, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Validación en tiempo real por pasarela Stripe.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySize(11, color: AppColors.muted),
                  ),
                  if (_qrPaymentUrl != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      _qrPaymentUrl!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodySize(10, color: AppColors.muted),
                    ),
                  ],
                ] else ...[
                  Text('No se pudo generar el QR dinámico.',
                      style: AppTextStyles.bodySize(12, color: AppColors.danger)),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => _loadQr(total),
                    child: const Text('Reintentar QR'),
                  ),
                ],
              ],
            ),
          ),
        _radioRow(
          _payMethod == 'cash',
          'Efectivo (Pago en tienda o contra entrega)',
          Icons.payments_outlined,
          () => setState(() => _payMethod = 'cash'),
        ),
      ]),
    ];
  }

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

  /// CU11 — cobra con pasarela Stripe (validación o rechazo), QR o efectivo,
  /// y emite la factura del documento fiscal simulado.
  Future<void> _pay(AppState s, double total) async {
    if (_paying) return;
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

    setState(() {
      _paying = true;
      _step = 3;
      _payProgress = 'Ubicando la sucursal…';
    });

    try {
      final branches = await _catalog.branches();
      if (branches.isEmpty) {
        throw Exception('El sistema no tiene sucursales configuradas.');
      }
      final wanted = _store.id.toLowerCase();
      final branch = branches.firstWhere(
        (candidate) => candidate.name.toLowerCase().contains(wanted),
        orElse: () => branches.first,
      );

      _setProgress('Leyendo el catálogo…');
      final products = await _catalog.products();

      final missing = <String>[];
      for (final item in s.cart) {
        _setProgress('Reservando stock: ${item.name}…');
        final product = _matchProduct(products, item.name);
        if (product == null) {
          missing.add('${item.name} (no está en el catálogo)');
          continue;
        }
        final rows = await _catalog.availability(product.id, branch.id);
        final free = _freeStock(rows, item.qty);
        if (free == null) {
          missing.add('${item.name} (sin stock en la sucursal)');
          continue;
        }
        final quantity =
            item.qty > free.availableStock ? free.availableStock : item.qty;
        await _commerce.addItem(free.stockId, quantity);
      }

      _setProgress('Procesando pago con la pasarela Stripe…');
      final selectedCard = _cards.firstWhere((c) => c.$1 == _cardId, orElse: () => _cards.first);
      final isCard = _payMethod == 'card';
      final isQr = _payMethod == 'qr';
      final isCash = _payMethod == 'cash';

      final provider = isCash ? 'efectivo' : (isQr ? 'stripe_qr' : 'stripe');
      final cardToken = isCard ? selectedCard.$4 : null;
      final simulateRejection = isCard && selectedCard.$5;

      final sale = await _commerce.checkout(
        branchId: branch.id,
        provider: provider,
        cardToken: cardToken,
        simulateRejection: simulateRejection,
      );

      _setProgress('Emitiendo factura fiscal simulada…');
      final invoice = await _commerce.invoice(sale.id);
      final pdfPath = await _saveInvoice(sale.id, await _commerce.invoicePdf(sale.id));

      if (!mounted) return;
      final purchase = Purchase(
        id: 'ORD-${sale.id}',
        date: _fmtDate(DateTime.now()),
        status: 'completado',
        total: invoice.total,
        subtotal: invoice.subtotal,
        shipping: shipping,
        paymentMethod: '${invoice.paymentStatus} · ${sale.reference ?? method}',
        deliveryMethod: delivery,
        store: delivery == 'pickup' ? storeName : null,
        items: items,
      );
      s.completePurchase(purchase);

      // Despacha notificación de compra exitosa a la app
      s.addNotification(NotificationItem(
        id: 'succ-${DateTime.now().millisecondsSinceEpoch}',
        title: '¡Compra confirmada! Factura ${invoice.invoiceNumber}',
        message: 'Tu pago de \$${invoice.total.toStringAsFixed(2)} mediante $method fue validado exitosamente. Ref: ${sale.reference ?? "ORD-${sale.id}"}.',
        date: _fmtDate(DateTime.now()),
        type: 'purchase_success',
        saleId: sale.id,
        amount: invoice.total,
        transactionRef: sale.reference ?? 'ORD-${sale.id}',
        invoiceNumber: invoice.invoiceNumber,
      ));

      setState(() {
        _step = 0;
        _paying = false;
        _payProgress = '';
      });
      s.setToast(
        '${invoice.invoiceNumber} · \$${invoice.total.toStringAsFixed(2)}'
        '${pdfPath != null ? ' · PDF guardado' : ''}',
      );
      if (missing.isNotEmpty) {
        s.setToast('Fuera de la venta: ${missing.join(', ')}');
      }
      s.openOverlay(OverlayScreen.purchaseSuccess);
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _step = 2;
        _paying = false;
        _payProgress = '';
      });

      String errorMsg = _describe(error);
      bool isDeclined = false;

      if (error is DioException) {
        if (error.response?.statusCode == 402) {
          isDeclined = true;
          final d = error.response?.data;
          if (d is Map && d['detail'] != null) {
            errorMsg = d['detail'].toString();
          }
        }
      }

      if (isDeclined ||
          errorMsg.toLowerCase().contains('rechazad') ||
          errorMsg.toLowerCase().contains('declined')) {
        // Despacha notificación de pago rechazado a la app
        s.addNotification(NotificationItem(
          id: 'rej-${DateTime.now().millisecondsSinceEpoch}',
          title: 'Pago rechazado por Stripe',
          message: errorMsg,
          date: _fmtDate(DateTime.now()),
          type: 'payment_rejected',
          amount: total,
          transactionRef: 'STRIPE-DECLINED',
        ));

        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.error_outline, color: AppColors.danger, size: 24),
                SizedBox(width: 8),
                Text('Pago Rechazado', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            content: Text(
              '$errorMsg\n\nTu carrito y reservas de inventario se mantienen intactos. Puedes seleccionar otra tarjeta o método de pago para reintentar.',
              style: AppTextStyles.bodySize(13),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Reintentar pago', style: TextStyle(color: AppColors.dark, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      } else {
        s.setToast(errorMsg);
      }
    }
  }

  void _setProgress(String message) {
    if (mounted) setState(() => _payProgress = message);
  }

  /// Producto del catálogo del backend con el mismo nombre que la prenda del carrito.
  ProductResponse? _matchProduct(List<ProductResponse> products, String name) {
    final wanted = name.trim().toLowerCase();
    for (final product in products) {
      if (product.name.trim().toLowerCase() == wanted) return product;
    }
    return null;
  }

  /// Fila de inventario con stock suficiente (o al menos con algo disponible).
  AvailabilityResponse? _freeStock(List<AvailabilityResponse> rows, int quantity) {
    for (final row in rows) {
      if (row.availableStock >= quantity) return row;
    }
    for (final row in rows) {
      if (row.availableStock > 0) return row;
    }
    return null;
  }

  /// Guarda la factura PDF en el almacenamiento temporal de la app.
  Future<String?> _saveInvoice(int saleId, List<int> bytes) async {
    if (bytes.isEmpty) return null;
    try {
      final file =
          File('${Directory.systemTemp.path}/fashionstore-factura-$saleId.pdf');
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    } on Object {
      return null;
    }
  }

  String _describe(Object error) {
    if (error is DioException) {
      if (error.response?.statusCode == 401) {
        return 'Inicia sesión como cliente para completar la compra.';
      }
      return error.message ?? 'No se pudo completar la compra.';
    }
    return error.toString().replaceFirst('Exception: ', '');
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
              _payProgress.isEmpty
                  ? 'Conectando con la pasarela… por favor espera.'
                  : _payProgress,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySize(13, color: AppColors.muted),
            ),
          ],
        ),
      );
}
