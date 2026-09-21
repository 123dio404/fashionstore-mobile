import 'package:flutter/material.dart';

import '../../core/data/mock_data.dart';
import '../../core/state/app_scope.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/kit/buttons.dart';
import '../../shared/kit/nav.dart';

/// Ayuda y soporte: FAQ, canales de contacto y formulario de consulta.
class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final _msg = TextEditingController();
  int? _open;
  bool _sent = false;

  @override
  void dispose() {
    _msg.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return Column(
      children: [
        AppTopBar(title: 'Ayuda y Soporte', onBack: s.closeOverlay),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            children: [
              _hero(),
              const SizedBox(height: 24),
              _label('PREGUNTAS FRECUENTES'),
              const SizedBox(height: 12),
              _faqCard(),
              const SizedBox(height: 24),
              _label('CONTACTO DIRECTO'),
              const SizedBox(height: 12),
              Row(
                children: [
                  _channel(
                    Icons.mail_outline,
                    'Email',
                    'soporte@fashionstore.com',
                    'Responde en 24 hs',
                  ),
                  const SizedBox(width: 10),
                  _channel(
                    Icons.phone_outlined,
                    'WhatsApp',
                    '+54 9 11 0000-0000',
                    'Lun–Vie 9:00–18:00',
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _label('ENVIAR MENSAJE'),
              const SizedBox(height: 12),
              _form(s),
            ],
          ),
        ),
      ],
    );
  }

  Widget _label(String t) => Text(
        t,
        style: AppTextStyles.bodySize(12,
            weight: FontWeight.w700, letterSpacing: 0.7),
      );

  Widget _hero() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF111827), Color(0xFF1F2937)],
          ),
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.help_outline,
                  size: 26, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Text('¿En qué podemos ayudarte?',
                style: AppTextStyles.displaySize(20, color: Colors.white)),
            const SizedBox(height: 6),
            Text(
              'Respuestas rápidas a las preguntas más frecuentes',
              style: AppTextStyles.bodySize(12,
                  color: Colors.white.withValues(alpha: 0.6)),
            ),
          ],
        ),
      );

  Widget _channel(IconData icon, String label, String sub, String time) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: AppColors.accent),
              const SizedBox(height: 8),
              Text(label,
                  style: AppTextStyles.bodySize(13, weight: FontWeight.w700)),
              Text(sub,
                  style: AppTextStyles.bodySize(10, color: AppColors.muted)),
              const SizedBox(height: 4),
              Text(time,
                  style: AppTextStyles.bodySize(10,
                      color: AppColors.mutedLight)),
            ],
          ),
        ),
      );

  Widget _faqCard() => Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Column(
          children: [
            for (var i = 0; i < kFaq.length; i++)
              Container(
                decoration: BoxDecoration(
                  border: i < kFaq.length - 1
                      ? const Border(
                          bottom: BorderSide(color: AppColors.borderLight),
                        )
                      : null,
                ),
                child: Column(
                  children: [
                    InkWell(
                      onTap: () => setState(() => _open = _open == i ? null : i),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(kFaq[i].q,
                                  style: AppTextStyles.bodySize(13,
                                      weight: FontWeight.w600, height: 1.4)),
                            ),
                            Icon(
                              _open == i
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                              size: 18,
                              color: AppColors.mutedLight,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_open == i)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            kFaq[i].a,
                            style: AppTextStyles.bodySize(13,
                                color: AppColors.muted, height: 1.65),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      );

  Widget _form(AppState s) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: _sent
            ? Column(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: AppColors.successBg,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.check,
                        size: 22, color: AppColors.success),
                  ),
                  const SizedBox(height: 10),
                  Text('¡Mensaje enviado!',
                      style: AppTextStyles.bodySize(14,
                          color: AppColors.success, weight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(
                    'Te responderemos dentro de las próximas 24 horas.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySize(12, color: AppColors.muted),
                  ),
                  TextButton(
                    onPressed: () {
                      _msg.clear();
                      setState(() => _sent = false);
                    },
                    child: Text('Enviar otro mensaje',
                        style: AppTextStyles.bodySize(12,
                            color: AppColors.muted)),
                  ),
                ],
              )
            : Column(
                children: [
                  TextField(
                    controller: _msg,
                    maxLines: 4,
                    onChanged: (_) => setState(() {}),
                    style: AppTextStyles.bodySize(13),
                    decoration: InputDecoration(
                      hintText: 'Describe tu consulta o problema…',
                      hintStyle: AppTextStyles.bodySize(13,
                          color: AppColors.mutedLight),
                      filled: true,
                      fillColor: AppColors.background,
                      contentPadding: const EdgeInsets.all(13),
                      enabledBorder: _border(AppColors.border),
                      focusedBorder: _border(AppColors.accent),
                    ),
                  ),
                  const SizedBox(height: 10),
                  DButton(
                    label: 'Enviar consulta',
                    tone: DButtonTone.dark,
                    expanded: true,
                    onPressed: _msg.text.trim().isEmpty
                        ? null
                        : () {
                            setState(() => _sent = true);
                            s.setToast('Mensaje enviado a soporte');
                          },
                  ),
                ],
              ),
      );

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: color, width: 1.5),
      );
}
