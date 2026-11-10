import 'package:flutter/material.dart';

import '../../core/models/fashion_models.dart';
import '../../core/state/app_scope.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';

/// Panel gerencial móvil exclusivo para el rol Administrador de Empresa.
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({
    super.key,
    required this.onOpenProduct,
  });

  final ValueChanged<Product> onOpenProduct;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final totalUnits = s.products.fold<int>(
      0,
      (sum, p) => sum + p.stock.values.fold<int>(0, (a, b) => a + b),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _header(context, s),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              children: [
                _kpiGrid(s, totalUnits),
                const SizedBox(height: 20),
                _quickActions(s),
                const SizedBox(height: 24),
                _stockSection(s),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context, AppState s) {
    final tenantName = s.selectedTenantName;
    final initials = tenantName.isNotEmpty
        ? tenantName
            .split(' ')
            .take(2)
            .map((w) => w.isNotEmpty ? w[0] : '')
            .join()
        : 'FS';

    return Container(
      color: AppColors.surface,
      padding: EdgeInsets.only(
        top: MediaQuery.paddingOf(context).top + 12,
        left: 20,
        right: 20,
        bottom: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.dark,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tenantName,
                      style: AppTextStyles.displaySize(18),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Panel de Administrador · SaaS Activo',
                          style: AppTextStyles.bodySize(
                            11,
                            color: AppColors.muted,
                            weight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none, size: 24),
                    onPressed: () => s.openOverlay(OverlayScreen.notifications),
                  ),
                  if (s.unreadNotificationsCount > 0)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        alignment: Alignment.center,
                        child: Text(
                          '${s.unreadNotificationsCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _kpiGrid(AppState s, int totalUnits) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MÉTRICAS DEL NEGOCIO',
          style: AppTextStyles.bodySize(
            11,
            color: AppColors.muted,
            weight: FontWeight.w700,
            letterSpacing: 0.7,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _kpiCard(
                'Ventas Turno',
                'Bs. 1,450.00',
                Icons.trending_up,
                const Color(0xFF10B981),
                '+18% vs ayer',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _kpiCard(
                'Prendas en Stock',
                '$totalUnits uds.',
                Icons.inventory_2_outlined,
                const Color(0xFF3B82F6),
                '${s.products.length} productos',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _kpiCard(
                'Reservas',
                '${s.reservations.length} activas',
                Icons.event_seat_outlined,
                const Color(0xFFF59E0B),
                'Probadores en tienda',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _kpiCard(
                'Sucursales',
                '3 activas',
                Icons.storefront_outlined,
                const Color(0xFF8B5CF6),
                'Centro, Norte, Sur',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _kpiCard(
    String label,
    String value,
    IconData icon,
    Color color,
    String footnote,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: AppTextStyles.bodySize(
                  11,
                  color: AppColors.muted,
                  weight: FontWeight.w600,
                ),
              ),
              Icon(icon, size: 18, color: color),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.displaySize(16),
          ),
          const SizedBox(height: 4),
          Text(
            footnote,
            style: AppTextStyles.bodySize(10, color: AppColors.mutedLight),
          ),
        ],
      ),
    );
  }

  Widget _quickActions(AppState s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'HERRAMIENTAS GERENCIALES',
          style: AppTextStyles.bodySize(
            11,
            color: AppColors.muted,
            weight: FontWeight.w700,
            letterSpacing: 0.7,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _actionTile(
                title: 'Reportes IA',
                subtitle: 'Voz y Analítica',
                icon: Icons.auto_awesome,
                color: AppColors.accent,
                onTap: () => s.openOverlay(OverlayScreen.aiReport),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _actionTile(
                title: 'Inventario',
                subtitle: 'Stock Sucursales',
                icon: Icons.inventory_2_outlined,
                color: const Color(0xFF2563EB),
                onTap: () => s.setTab(AppTab.catalog),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _actionTile(
                title: 'Reservas',
                subtitle: 'Probadores Tienda',
                icon: Icons.calendar_month_outlined,
                color: const Color(0xFFD97706),
                onTap: () => s.setTab(AppTab.reservations),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _actionTile(
                title: 'Ajustes SaaS',
                subtitle: 'Configuración',
                icon: Icons.tune,
                color: AppColors.dark,
                onTap: () => s.openOverlay(OverlayScreen.settings),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _actionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodySize(
                      13,
                      weight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySize(
                      10,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stockSection(AppState s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'INVENTARIO DE ${s.selectedTenantName.toUpperCase()}',
              style: AppTextStyles.bodySize(
                11,
                color: AppColors.muted,
                weight: FontWeight.w700,
                letterSpacing: 0.7,
              ),
            ),
            GestureDetector(
              onTap: () => s.setTab(AppTab.catalog),
              child: Text(
                'Ver todo (${s.products.length})',
                style: AppTextStyles.bodySize(
                  11,
                  color: AppColors.accent,
                  weight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...s.products.map((p) {
          final total = p.stock.values.fold<int>(0, (a, b) => a + b);
          final isLow = total <= 5;

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: InkWell(
              onTap: () => onOpenProduct(p),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      p.image,
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 52,
                        height: 52,
                        color: AppColors.borderLight,
                        child: const Icon(Icons.checkroom, size: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.name,
                          style: AppTextStyles.bodySize(13, weight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Bs. ${p.price.toStringAsFixed(2)} · ${p.category}',
                          style: AppTextStyles.bodySize(11, color: AppColors.muted),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: p.stock.entries.map((e) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Text(
                                '${e.key}: ${e.value}',
                                style: AppTextStyles.bodySize(
                                  10,
                                  color: e.value > 0
                                      ? AppColors.dark
                                      : AppColors.danger,
                                  weight: FontWeight.w600,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isLow
                          ? const Color(0xFFFEF3C7)
                          : const Color(0xFFD1FAE5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isLow ? 'Stock Bajo' : '$total uds',
                      style: TextStyle(
                        color: isLow
                            ? const Color(0xFFB45309)
                            : const Color(0xFF065F46),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
