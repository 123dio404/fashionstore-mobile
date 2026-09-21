import 'package:flutter/material.dart';

import '../../core/data/mock_data.dart';
import '../../core/models/fashion_models.dart';
import '../../core/state/app_scope.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/kit/chips.dart';
import '../../shared/kit/nav.dart';

/// Preferencias de estilo: marcas, colores, tallas, notificación y moneda.
class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  UserPreferences? _local;
  bool _saved = false;

  static const _colorHex = <String, String>{
    'Negro': '#111827',
    'Blanco': '#F8F9FA',
    'Terracota': '#E05A47',
    'Beige': '#D4C5A9',
    'Azul': '#1E3A5F',
    'Gris': '#9CA3AF',
    'Verde': '#6B7C5C',
    'Rojo': '#DC2626',
    'Camel': '#C4A882',
  };

  UserPreferences _prefs(AppState s) => _local ??= UserPreferences(
        brands: [...s.prefs.brands],
        favoriteColors: [...s.prefs.favoriteColors],
        sizes: [...s.prefs.sizes],
        notifications: s.prefs.notifications,
        language: s.prefs.language,
        theme: s.prefs.theme,
        currency: s.prefs.currency,
      );

  void _toggle(List<String> list, String value) {
    setState(() {
      list.contains(value) ? list.remove(value) : list.add(value);
      _saved = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final p = _prefs(s);

    return Column(
      children: [
        AppTopBar(title: 'Preferencias', onBack: s.closeOverlay),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: [
              _section('Marcas favoritas',
                  'Filtraremos el catálogo con estas marcas primero'),
              _brandsWrap(p),
              const SizedBox(height: 24),
              _section('Colores favoritos', null),
              _colorsWrap(p),
              const SizedBox(height: 24),
              _section('Tallas habituales', null),
              _sizesWrap(p),
              const SizedBox(height: 24),
              _switchCard(p),
              const SizedBox(height: 16),
              _currencyCard(p),
              if (_saved) ...[
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                  decoration: BoxDecoration(
                    color: AppColors.successBg,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check,
                          size: 16, color: AppColors.success),
                      const SizedBox(width: 8),
                      Text('Preferencias guardadas',
                          style: AppTextStyles.bodySize(13,
                              color: AppColors.success,
                              weight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        _footer(s, p),
      ],
    );
  }

  Widget _section(String title, String? subtitle) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title.toUpperCase(),
                style: AppTextStyles.bodySize(12,
                    weight: FontWeight.w700, letterSpacing: 0.7)),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(subtitle,
                  style: AppTextStyles.bodySize(11,
                      color: AppColors.mutedLight)),
            ],
          ],
        ),
      );

  Widget _brandsWrap(UserPreferences p) => Wrap(
        spacing: 7,
        runSpacing: 7,
        children: kBrandsList
            .map((b) => PillChip(
                  label: b,
                  selected: p.brands.contains(b),
                  onTap: () => _toggle(p.brands, b),
                ))
            .toList(),
      );

  Widget _colorsWrap(UserPreferences p) => Wrap(
        spacing: 7,
        runSpacing: 7,
        children: kColorsList.map((c) {
          final selected = p.favoriteColors.contains(c);
          return GestureDetector(
            onTap: () => _toggle(p.favoriteColors, c),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? AppColors.dark : AppColors.borderLight,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colorFromHex(_colorHex[c] ?? '#9CA3AF'),
                      border: c == 'Blanco'
                          ? Border.all(color: AppColors.border)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(c,
                      style: AppTextStyles.bodySize(12,
                          color: selected ? Colors.white : AppColors.muted,
                          weight: FontWeight.w500)),
                ],
              ),
            ),
          );
        }).toList(),
      );

  Widget _sizesWrap(UserPreferences p) => Wrap(
        spacing: 7,
        runSpacing: 7,
        children: kSizesList
            .map((sz) => PillChip(
                  label: sz,
                  selected: p.sizes.contains(sz),
                  onTap: () => _toggle(p.sizes, sz),
                ))
            .toList(),
      );

  Widget _switchCard(UserPreferences p) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text('Notificaciones push',
                  style: AppTextStyles.bodySize(14, weight: FontWeight.w500)),
            ),
            Switch.adaptive(
              value: p.notifications,
              activeThumbColor: Colors.white,
              activeTrackColor: AppColors.accent,
              onChanged: (v) => setState(() {
                p.notifications = v;
                _saved = false;
              }),
            ),
          ],
        ),
      );

  Widget _currencyCard(UserPreferences p) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text('Mostrar precios en',
                  style: AppTextStyles.bodySize(14, weight: FontWeight.w500)),
            ),
            for (final c in const ['ARS', 'USD'])
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: PillChip(
                  label: c,
                  selected: p.currency == c,
                  onTap: () => setState(() {
                    p.currency = c;
                    _saved = false;
                  }),
                ),
              ),
          ],
        ),
      );

  Widget _footer(AppState s, UserPreferences p) => Container(
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
        child: GestureDetector(
          onTap: () {
            s.updatePrefs(p);
            setState(() => _saved = true);
            s.setToast('Preferencias guardadas');
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: _saved ? AppColors.success : AppColors.dark,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              _saved ? 'Guardado ✓' : 'Guardar preferencias',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySize(15,
                  color: Colors.white, weight: FontWeight.w700),
            ),
          ),
        ),
      );
}
