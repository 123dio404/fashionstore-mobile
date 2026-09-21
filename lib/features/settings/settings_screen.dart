import 'package:flutter/material.dart';

import '../../core/models/fashion_models.dart';
import '../../core/state/app_scope.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/kit/buttons.dart';
import '../../shared/kit/nav.dart';

/// Configuración: apariencia, notificaciones, privacidad, acerca de y logout.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  UserPreferences? _local;
  bool _saved = false;

  UserPreferences _prefs(AppState s) => _local ??= UserPreferences(
        brands: [...s.prefs.brands],
        favoriteColors: [...s.prefs.favoriteColors],
        sizes: [...s.prefs.sizes],
        notifications: s.prefs.notifications,
        language: s.prefs.language,
        theme: s.prefs.theme,
        currency: s.prefs.currency,
      );

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final p = _prefs(s);

    return Stack(
      children: [
        Column(
          children: [
            AppTopBar(title: 'Configuración', onBack: s.closeOverlay),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                children: [
                  _group('Apariencia', [
                    _row('Tema', 'Aspecto visual de la app', [
                      ('light', 'Claro'),
                      ('dark', 'Oscuro'),
                      ('system', 'Auto'),
                    ], p.theme, (v) => setState(() => p.theme = v)),
                    _row('Idioma', 'Idioma de la interfaz', [
                      ('es', 'Español'),
                      ('en', 'English'),
                    ], p.language, (v) => setState(() => p.language = v)),
                  ]),
                  _group('Notificaciones', [
                    _switchRow('Notificaciones push', p.notifications,
                        (v) => setState(() => p.notifications = v)),
                    _switchRow('Ofertas y promociones', true, (_) {}),
                    _switchRow('Novedades de la tienda', true, (_) {}),
                  ]),
                  _group('Privacidad', [
                    _switchRow('Compartir datos anónimos', true, (_) {}),
                    _switchRow('Historial de búsquedas', true, (_) {}),
                  ]),
                  _group('Acerca de', [
                    _infoRow('Versión de la app', '2.4.1'),
                    _infoRow('Términos y condiciones', null, chevron: true),
                    _infoRow('Política de privacidad', null, chevron: true),
                  ]),
                  if (_saved) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.successBg,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check,
                              size: 15, color: AppColors.success),
                          const SizedBox(width: 8),
                          Text('Cambios guardados',
                              style: AppTextStyles.bodySize(13,
                                  color: AppColors.success,
                                  weight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  DButton(
                    label: 'Guardar cambios',
                    tone: DButtonTone.dark,
                    expanded: true,
                    size: DButtonSize.lg,
                    onPressed: () {
                      s.updatePrefs(p);
                      setState(() => _saved = true);
                      s.setToast('Cambios guardados');
                    },
                  ),
                  const SizedBox(height: 10),
                  DButton(
                    label: 'Cerrar sesión',
                    tone: DButtonTone.outline,
                    expanded: true,
                    onPressed: _confirmLogout,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _group(String title, List<Widget> children) => Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title.toUpperCase(),
                style: AppTextStyles.bodySize(11,
                    color: AppColors.muted,
                    weight: FontWeight.w700,
                    letterSpacing: 0.7)),
            const SizedBox(height: 8),
            Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Column(children: children),
            ),
          ],
        ),
      );

  Widget _row(
    String label,
    String sub,
    List<(String, String)> options,
    String value,
    ValueChanged<String> onChanged,
  ) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.borderLight)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style:
                          AppTextStyles.bodySize(14, weight: FontWeight.w500)),
                  Text(sub,
                      style: AppTextStyles.bodySize(11,
                          color: AppColors.mutedLight)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Row(
                children: options
                    .map((o) => GestureDetector(
                          onTap: () => onChanged(o.$1),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: value == o.$1
                                  ? AppColors.dark
                                  : Colors.transparent,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.pill),
                            ),
                            child: Text(o.$2,
                                style: AppTextStyles.bodySize(11,
                                    color: value == o.$1
                                        ? Colors.white
                                        : AppColors.muted,
                                    weight: FontWeight.w600)),
                          ),
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      );

  Widget _switchRow(String label, bool value, ValueChanged<bool> onChanged) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.borderLight)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(label,
                  style: AppTextStyles.bodySize(14, weight: FontWeight.w500)),
            ),
            Switch.adaptive(
              value: value,
              activeThumbColor: Colors.white,
              activeTrackColor: AppColors.accent,
              onChanged: onChanged,
            ),
          ],
        ),
      );

  Widget _infoRow(String label, String? value, {bool chevron = false}) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.borderLight)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(label,
                  style: AppTextStyles.bodySize(14, weight: FontWeight.w500)),
            ),
            if (value != null)
              Text(value,
                  style: AppTextStyles.bodySize(13,
                      color: AppColors.mutedLight)),
            if (chevron)
              const Icon(Icons.chevron_right,
                  size: 16, color: AppColors.mutedLight),
          ],
        ),
      );

  void _confirmLogout() {
    final s = AppScope.read(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          16,
          24,
          28 + MediaQuery.paddingOf(ctx).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text('¿Cerrar sesión?',
                style: AppTextStyles.bodySize(18,
                    weight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(
              'Se cerrará tu sesión actual. Podrás volver a ingresar cuando quieras.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySize(13,
                  color: AppColors.muted, height: 1.55),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: DButton(
                    label: 'Cancelar',
                    tone: DButtonTone.outline,
                    expanded: true,
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DButton(
                    label: 'Cerrar sesión',
                    tone: DButtonTone.accent,
                    expanded: true,
                    onPressed: () {
                      Navigator.pop(ctx);
                      s.goTo(AppPhase.login);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
