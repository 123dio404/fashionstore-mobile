import 'package:flutter/material.dart';

import '../../core/models/fashion_models.dart';
import '../../core/theme/app_theme.dart';

/// Barra de navegación inferior con 5 pestañas y badges.
class BottomNav extends StatelessWidget {
  const BottomNav({
    super.key,
    required this.active,
    required this.onTab,
    this.cartCount = 0,
    this.reservCount = 0,
  });

  final AppTab active;
  final ValueChanged<AppTab> onTab;
  final int cartCount;
  final int reservCount;

  static const _tabs = <(AppTab, String, IconData)>[
    (AppTab.home, 'Inicio', Icons.home_outlined),
    (AppTab.catalog, 'Catálogo', Icons.grid_view_outlined),
    (AppTab.reservations, 'Reservas', Icons.calendar_today_outlined),
    (AppTab.cart, 'Carrito', Icons.shopping_bag_outlined),
    (AppTab.profile, 'Perfil', Icons.person_outline),
  ];

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    return Container(
      height: 78 + safeBottom,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.borderLight)),
      ),
      padding: EdgeInsets.only(top: 6, bottom: 10 + safeBottom),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: _tabs.map((t) {
          final (tab, label, icon) = t;
          final badge = switch (tab) {
            AppTab.cart => cartCount,
            AppTab.reservations => reservCount,
            _ => 0,
          };
          return _NavButton(
            icon: icon,
            label: label,
            active: active == tab,
            badge: badge,
            onTap: () => onTab(tab),
          );
        }).toList(),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.badge,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final int badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.dark : AppColors.mutedLight;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, size: 22, color: color),
                if (badge > 0)
                  Positioned(
                    top: -5,
                    right: -8,
                    child: Container(
                      width: 15,
                      height: 15,
                      decoration: const BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        badge > 9 ? '9+' : '$badge',
                        style: AppTextStyles.bodySize(
                          9,
                          color: Colors.white,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: AppTextStyles.bodySize(
                10,
                color: color,
                weight: active ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            const SizedBox(height: 3),
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active ? AppColors.accent : Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
