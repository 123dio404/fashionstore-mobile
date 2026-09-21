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
                      ClipRect(
                        child: SizedBox(
                          height: 44,
                          child: OverflowBox(
                            maxWidth: 200,
                            alignment: Alignment.centerLeft,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(
                                p.items.take(3).length,
                                (i) => Container(
                                  width: 36,
                                  height: 44,
                                  margin: EdgeInsets.only(left: i > 0 ? 8 : 0),
                                  clipBehavior: Clip.antiAlias,
                                  decoration: BoxDecoration(
                                    color: AppColors.borderLight,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: NetImage(url: p.items[i].image),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
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
                            child: NetImage(url: it.image),
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
                                Text(
                                  'Talla ${it.size} · ${it.color} · ×${it.qty}',
                                  style: AppTextStyles.bodySize(11,
                                      color: AppColors.muted),
                                ),
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
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool success = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            Text(label,
                style: AppTextStyles.bodySize(12, color: AppColors.muted)),
            const Spacer(),
            Flexible(
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
