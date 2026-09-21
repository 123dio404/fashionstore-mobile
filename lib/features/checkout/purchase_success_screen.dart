import 'package:flutter/material.dart';

import '../../../core/models/fashion_models.dart';
import '../../../core/state/app_scope.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/kit/buttons.dart';

/// Confirmación de compra (overlay posterior al checkout).
class PurchaseSuccessScreen extends StatelessWidget {
  const PurchaseSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final p = s.lastPurchase;
    if (p == null) {
      return Center(
        child: DButton(label: 'Volver', onPressed: s.closeOverlay),
      );
    }
    return Column(
      children: [
        Container(
          width: double.infinity,
          color: AppColors.dark,
          padding: EdgeInsets.fromLTRB(
            28,
            MediaQuery.paddingOf(context).top + 32,
            28,
            32,
          ),
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: AppColors.successBg,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.check, size: 34, color: AppColors.success),
              ),
              const SizedBox(height: 16),
              Text('¡Compra exitosa!',
                  style: AppTextStyles.displaySize(26, color: Colors.white)),
              const SizedBox(height: 6),
              Text(
                'Tu orden ha sido confirmada',
                style: AppTextStyles.bodySize(13,
                    color: Colors.white.withValues(alpha: 0.65)),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            children: [
              _card([
                Center(
                  child: Column(
                    children: [
                      Text('NÚMERO DE ORDEN',
                          style: AppTextStyles.bodySize(11,
                              color: AppColors.muted, letterSpacing: 0.8)),
                      const SizedBox(height: 4),
                      Text(p.id,
                          style: AppTextStyles.bodySize(24,
                              weight: FontWeight.w800, letterSpacing: 1.4)),
                    ],
                  ),
                ),
              ]),
              _card([
                _row('Fecha', p.date),
                _row('Total pagado', '\$${p.total.toStringAsFixed(2)}'),
                _row('Método de pago', p.paymentMethod),
                _row('Estado', 'Procesando', success: true),
              ]),
              _card([
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.borderLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        p.deliveryMethod == 'home'
                            ? Icons.local_shipping_outlined
                            : Icons.storefront_outlined,
                        size: 20,
                        color: AppColors.dark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.deliveryMethod == 'home'
                                ? 'Envío a domicilio'
                                : 'Retiro en tienda',
                            style: AppTextStyles.bodySize(13,
                                weight: FontWeight.w700),
                          ),
                          Text(
                            p.deliveryMethod == 'home'
                                ? 'Estimado: 3–5 días hábiles'
                                : 'Disponible en 24 hrs · ${p.store ?? ''}',
                            style: AppTextStyles.bodySize(11,
                                color: AppColors.muted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ]),
              _card([
                Text(
                  '${p.items.length} ARTÍCULO${p.items.length != 1 ? 'S' : ''}',
                  style: AppTextStyles.bodySize(12,
                      weight: FontWeight.w700, letterSpacing: 0.6),
                ),
                const SizedBox(height: 12),
                ...p.items.map(
                  (it) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 64,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            color: AppColors.borderLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Image.network(
                            it.image,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.checkroom,
                              size: 20,
                              color: AppColors.mutedLight,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(it.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.bodySize(12,
                                      weight: FontWeight.w600)),
                              Text('Talla ${it.size} · ${it.color}',
                                  style: AppTextStyles.bodySize(11,
                                      color: AppColors.muted)),
                              Text('\$${it.price.toStringAsFixed(2)} ×${it.qty}',
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
              DButton(
                label: 'Ver mis compras',
                tone: DButtonTone.dark,
                expanded: true,
                size: DButtonSize.lg,
                onPressed: () => s.openOverlay(OverlayScreen.purchases),
              ),
              const SizedBox(height: 10),
              DButton(
                label: 'Seguir comprando',
                tone: DButtonTone.outline,
                expanded: true,
                size: DButtonSize.lg,
                onPressed: () {
                  s.closeOverlay();
                  s.setTab(AppTab.catalog);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _card(List<Widget> children) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: const [
            BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      );

  Widget _row(String label, String value, {bool success = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
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
}
