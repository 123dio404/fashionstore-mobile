import 'package:flutter/material.dart';

import '../../../core/models/fashion_models.dart';
import '../../../core/state/app_scope.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/kit/buttons.dart';
import '../../../shared/kit/chips.dart';
import '../../../shared/kit/nav.dart';
import '../../../shared/kit/net_image.dart';
import '../../../shared/kit/states.dart';

/// Historial de compras con detalle expandible y tracking.
class PurchasesScreen extends StatefulWidget {
  const PurchasesScreen({super.key});

  @override
  State<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends State<PurchasesScreen> {
  String? _expanded;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final purchases = s.purchases;

    return Column(
      children: [
        AppTopBar(
          title: 'Mis Compras',
          subtitle: purchases.isEmpty
              ? 'FashionStore'
              : '${purchases.length} pedido${purchases.length != 1 ? 's' : ''}',
          onBack: s.closeOverlay,
        ),
        Expanded(
          child: purchases.isEmpty
              ? EmptyState(
                  icon: Icons.inventory_2_outlined,
                  title: 'Sin compras',
                  subtitle:
                      'Cuando realices tu primera compra, aparecerá aquí.',
                  cta: 'Ir al catálogo',
                  onCta: () {
                    s.closeOverlay();
                    s.setTab(AppTab.catalog);
                  },
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  children: purchases.map((p) => _card(p)).toList(),
                ),
        ),
      ],
    );
  }

  Widget _card(Purchase p) {
    final expanded = _expanded == p.id;
    final progress = switch (p.status) {
      'procesando' => 1,
      'en_camino' => 2,
      'entregado' => 3,
      _ => 0,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: const [
          BoxShadow(color: Color(0x0D000000), blurRadius: 10, offset: Offset(0, 2)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = expanded ? null : p.id),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.id,
                                style: AppTextStyles.bodySize(15,
                                    weight: FontWeight.w800, letterSpacing: 0.6)),
                            const SizedBox(height: 2),
                            Text(
                              '${p.date} · ${p.items.length} artículo${p.items.length != 1 ? 's' : ''}',
                              style: AppTextStyles.bodySize(11,
                                  color: AppColors.muted),
                            ),
                          ],
                        ),
                      ),
                      badgeForStatus(p.status),
                      const SizedBox(width: 8),
                      Icon(
                        expanded ? Icons.expand_less : Icons.expand_more,
                        size: 18,
                        color: AppColors.mutedLight,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 44,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            itemCount: p.items.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 8),
                            itemBuilder: (_, i) => Container(
                              width: 36,
                              height: 44,
                              clipBehavior: Clip.antiAlias,
                              decoration: BoxDecoration(
                                color: AppColors.borderLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: NetImage(
                                url: p.items[i].image,
                                width: 36,
                                height: 44,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text('\$${p.total.toStringAsFixed(2)}',
                          style: AppTextStyles.bodySize(16,
                              weight: FontWeight.w800)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (expanded) ...[
            const Divider(color: AppColors.borderLight, height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (p.status != 'cancelado') _tracking(progress),
                  const SizedBox(height: 12),
                  ...p.items.map(
                    (it) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 62,
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              color: AppColors.borderLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: NetImage(
                              url: it.image,
                              width: 52,
                              height: 62,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${it.brand} · ${it.name}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.bodySize(12,
                                        weight: FontWeight.w600)),
                                const SizedBox(height: 2),
                                Text(
                                  'Talla ${it.size} · ${it.color} · ×${it.qty}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.bodySize(11,
                                      color: AppColors.muted),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '\$${(it.price * it.qty).toStringAsFixed(2)}',
                                  style: AppTextStyles.bodySize(13,
                                      weight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(color: AppColors.borderLight, height: 20),
                  _row('Subtotal', '\$${p.subtotal.toStringAsFixed(2)}'),
                  _row(
                    'Envío',
                    p.shipping == 0 ? 'Gratis' : '\$${p.shipping.toStringAsFixed(2)}',
                    success: p.shipping == 0,
                  ),
                  _row('Pago con', p.paymentMethod),
                  _row(
                    'Entrega',
                    p.deliveryMethod == 'home'
                        ? 'Domicilio'
                        : 'Retiro · ${p.store ?? ''}',
                  ),
                  const Divider(color: AppColors.borderLight, height: 20),
                  Row(
                    children: [
                      Text('Total',
                          style: AppTextStyles.bodySize(14,
                              weight: FontWeight.w700)),
                      const Spacer(),
                      Text('\$${p.total.toStringAsFixed(2)}',
                          style: AppTextStyles.bodySize(16,
                              weight: FontWeight.w800)),
                    ],
                  ),
                  if (p.status != 'cancelado') ...[
                    const SizedBox(height: 12),
                    DButton(
                      label: 'Rastrear pedido',
                      tone: DButtonTone.outline,
                      expanded: true,
                      size: DButtonSize.sm,
                      onPressed: () => AppScope.read(context)
                          .setToast('Tu pedido ${p.id} está en camino'),
                    ),
                    const SizedBox(height: 8),
                    DButton(
                      label: 'Solicitar cambio de prenda (máx. 30 días)',
                      icon: Icons.swap_horiz,
                      tone: DButtonTone.dark,
                      expanded: true,
                      size: DButtonSize.sm,
                      onPressed: () => _showExchangeDialog(context, p),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showExchangeDialog(BuildContext context, Purchase p) {
    final s = AppScope.read(context);
    PurchaseItem? selectedReturned = p.items.isNotEmpty ? p.items.first : null;
    Product? selectedNew = s.products.isNotEmpty ? s.products.first : null;
    const reason = 'Cambio por talle o modelo (política 30 días)';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final oldPrice = selectedReturned?.price ?? 0.0;
            final newPrice = selectedNew?.price ?? 0.0;
            final diff = newPrice - oldPrice;

            return Container(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.swap_horiz, color: AppColors.accent, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cambio de Prenda (RN-02)',
                              style: AppTextStyles.bodySize(16, weight: FontWeight.w700),
                            ),
                            Text(
                              'Orden: ${p.id} · Plazo máx. 30 días',
                              style: AppTextStyles.bodySize(11, color: AppColors.muted),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('Prenda a devolver:', style: AppTextStyles.bodySize(12, weight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<PurchaseItem>(
                    initialValue: selectedReturned,
                    isExpanded: true,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.background,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.borderLight),
                      ),
                    ),
                    items: p.items.map((it) {
                      return DropdownMenuItem(
                        value: it,
                        child: Text('${it.name} (${it.size}) - Bs. ${it.price.toStringAsFixed(2)}'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedReturned = val);
                    },
                  ),
                  const SizedBox(height: 14),
                  Text('Nueva prenda por la que cambia:', style: AppTextStyles.bodySize(12, weight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<Product>(
                    initialValue: selectedNew,
                    isExpanded: true,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.background,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.borderLight),
                      ),
                    ),
                    items: s.products.map((prod) {
                      return DropdownMenuItem(
                        value: prod,
                        child: Text('${prod.name} - Bs. ${prod.price.toStringAsFixed(2)}'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedNew = val);
                    },
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: diff > 0
                          ? AppColors.accent.withValues(alpha: 0.1)
                          : (diff < 0 ? AppColors.successBg : AppColors.background),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Ajuste de precio:', style: AppTextStyles.bodySize(13, weight: FontWeight.w600)),
                        Text(
                          diff > 0
                              ? '+ Bs. ${diff.toStringAsFixed(2)} (Abonar)'
                              : (diff < 0 ? '- Bs. ${(-diff).toStringAsFixed(2)} (A favor)' : 'Bs. 0.00'),
                          style: AppTextStyles.bodySize(
                            13,
                            weight: FontWeight.w800,
                            color: diff > 0 ? AppColors.accent : (diff < 0 ? AppColors.success : AppColors.dark),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  DButton(
                    label: 'Confirmar y generar comprobante',
                    tone: DButtonTone.dark,
                    expanded: true,
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final rawId = p.id.replaceAll(RegExp(r'[^0-9]'), '');
                      final saleId = int.tryParse(rawId) ?? 1;
                      final branchId = p.store?.toLowerCase().contains('norte') == true
                          ? 2
                          : (p.store?.toLowerCase().contains('sur') == true ? 3 : 1);

                      try {
                        await s.createExchange(
                          branchId: branchId,
                          originalSaleId: saleId,
                          returnedVariantId: selectedReturned?.productId ?? 1,
                          newVariantId: selectedNew?.id ?? 1,
                          reason: reason,
                        );
                      } catch (e) {
                        s.setToast('Error al procesar cambio: $e');
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _row(String label, String value, {bool success = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            Text(label,
                style: AppTextStyles.bodySize(12, color: AppColors.muted)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySize(12,
                    color: success ? AppColors.success : AppColors.dark,
                    weight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );

  Widget _tracking(int progress) {
    const labels = ['Procesando', 'En camino', 'Entregado'];
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            Column(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < progress ? AppColors.success : AppColors.borderLight,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.check,
                    size: 13,
                    color: i < progress ? Colors.white : AppColors.mutedLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  labels[i],
                  style: AppTextStyles.bodySize(9,
                      color: i < progress ? AppColors.success : AppColors.mutedLight,
                      weight: FontWeight.w600),
                ),
              ],
            ),
            if (i < labels.length - 1)
              Expanded(
                child: Container(
                  height: 2,
                  margin: const EdgeInsets.only(bottom: 16, left: 4, right: 4),
                  color: i < progress - 1 ? AppColors.success : AppColors.borderLight,
                ),
              ),
          ],
        ],
      ),
    );
  }
}
