import 'package:flutter/material.dart';

import '../../core/models/fashion_models.dart';
import '../../core/state/app_scope.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/kit/buttons.dart';
import '../../shared/kit/nav.dart';
import '../../shared/kit/states.dart';

/// Pantalla del Centro de Notificaciones: compras, transacciones y reservas.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final items = s.notifications;

    return Column(
      children: [
        AppTopBar(
          title: 'Notificaciones',
          subtitle: items.isEmpty
              ? 'FashionStore'
              : '${items.length} aviso${items.length != 1 ? 's' : ''}',
          onBack: () {
            s.markNotificationsAsRead();
            s.closeOverlay();
          },
        ),
        if (items.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${s.unreadNotificationsCount} sin leer',
                  style: AppTextStyles.bodySize(12, color: AppColors.muted),
                ),
                GestureDetector(
                  onTap: s.markNotificationsAsRead,
                  child: Text(
                    'Marcar todas como leídas',
                    style: AppTextStyles.bodySize(
                      12,
                      color: AppColors.dark,
                      weight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: items.isEmpty
              ? EmptyState(
                  icon: Icons.notifications_none_outlined,
                  title: 'Sin notificaciones',
                  subtitle:
                      'Aquí recibirás confirmaciones de tus compras, estados de transacciones y avisos de reservas.',
                  cta: 'Ir al catálogo',
                  onCta: () {
                    s.closeOverlay();
                    s.setTab(AppTab.catalog);
                  },
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _NotificationCard(item: item);
                  },
                ),
        ),
      ],
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.item});

  final NotificationItem item;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final isRejected = item.type == 'payment_rejected';
    final isPurchase = item.type == 'purchase_success';

    final Color badgeColor = isRejected
        ? AppColors.danger
        : isPurchase
            ? AppColors.success
            : AppColors.dark;

    final IconData icon = isRejected
        ? Icons.error_outline
        : isPurchase
            ? Icons.check_circle_outline
            : Icons.info_outline;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: item.isRead ? AppColors.surface : const Color(0xFFFAF6F2),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: item.isRead ? AppColors.borderLight : badgeColor.withValues(alpha: 0.35),
          width: item.isRead ? 1 : 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: badgeColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: AppTextStyles.bodySize(
                              14,
                              weight: FontWeight.w700,
                              color: badgeColor,
                            ),
                          ),
                        ),
                        Text(
                          item.date,
                          style: AppTextStyles.bodySize(11, color: AppColors.muted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.message,
                      style: AppTextStyles.bodySize(12.5, color: AppColors.dark),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (item.transactionRef != null || item.invoiceNumber != null || item.amount != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (item.transactionRef != null)
                    Expanded(
                      child: Text(
                        'Transacción: ${item.transactionRef}',
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySize(11, color: AppColors.muted),
                      ),
                    ),
                  if (item.amount != null)
                    Text(
                      '\$${item.amount!.toStringAsFixed(2)}',
                      style: AppTextStyles.bodySize(12, weight: FontWeight.w700),
                    ),
                ],
              ),
            ),
          ],
          if (isPurchase) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                DButton(
                  label: 'Ver en Mis Compras',
                  size: DButtonSize.sm,
                  tone: DButtonTone.outline,
                  onPressed: () {
                    s.closeOverlay();
                    s.openOverlay(OverlayScreen.purchases);
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
