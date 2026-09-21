import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/kit/buttons.dart';

/// Onboarding de 3 slides (fondo oscuro + CTA terracota).
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _Slide {
  final String title;
  final String subtitle;
  final Color bg;
  final IconData icon;
  const _Slide(this.title, this.subtitle, this.bg, this.icon);
}

const _slides = <_Slide>[
  _Slide(
    'Descubre tu estilo',
    'Explora miles de prendas, accesorios y calzado seleccionados para ti.',
    Color(0xFF111827),
    Icons.checkroom,
  ),
  _Slide(
    'Reserva y prueba',
    'Reserva un turno en el probador de tu sucursal favorita y asegura tu talla antes de comprar.',
    Color(0xFF1E293B),
    Icons.calendar_month_outlined,
  ),
  _Slide(
    'Recomendaciones con IA',
    'Sugerencias personalizadas según tus preferencias, favoritos y compras anteriores.',
    Color(0xFF0F172A),
    Icons.auto_awesome,
  ),
];

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _idx = 0;

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_idx];
    final isLast = _idx == _slides.length - 1;

    return Scaffold(
      backgroundColor: slide.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: widget.onDone,
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.12),
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  ),
                  child: Text(
                    'Saltar',
                    style: AppTextStyles.bodySize(
                      13,
                      color: Colors.white70,
                      weight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  transitionBuilder: (child, anim) =>
                      ScaleTransition(scale: anim, child: FadeTransition(opacity: anim, child: child)),
                  child: Container(
                    key: ValueKey(_idx),
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                    alignment: Alignment.center,
                    child: Icon(slide.icon, size: 96, color: AppColors.accent),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Column(
                      key: ValueKey('text-$_idx'),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          slide.title,
                          style: AppTextStyles.displaySize(
                            28,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          slide.subtitle,
                          style: AppTextStyles.bodySize(
                            14,
                            color: Colors.white.withValues(alpha: 0.65),
                            height: 1.65,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: List.generate(_slides.length, (i) {
                      final active = i == _idx;
                      return GestureDetector(
                        onTap: () => setState(() => _idx = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.only(right: 6),
                          height: 4,
                          width: active ? 28 : 8,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(100),
                            color: active
                                ? AppColors.accent
                                : Colors.white.withValues(alpha: 0.25),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
                  DButton(
                    label: isLast ? 'Comenzar' : 'Siguiente',
                    tone: DButtonTone.accent,
                    expanded: true,
                    size: DButtonSize.lg,
                    onPressed: () {
                      if (isLast) {
                        widget.onDone();
                      } else {
                        setState(() => _idx++);
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
