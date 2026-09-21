import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/models/fashion_models.dart';
import '../../core/state/app_scope.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/kit/buttons.dart';
import '../../shared/kit/nav.dart';

const _demos = [
  'Buscar blazer negro talla M',
  'Mostrar ofertas de calzado',
  'Quiero ver vestidos de la marca Zara Studio',
  'Zapatillas blancas talla 39',
];

const _history = [
  ('Blazer oversize negro', 'Hace 2 horas'),
  ('Vestidos de verano en oferta', 'Ayer 15:30'),
  ('Sneakers talla 40', 'Hace 3 días'),
];

/// Búsqueda por voz con transcripción simulada e historial.
class VoiceScreen extends StatefulWidget {
  const VoiceScreen({super.key});

  @override
  State<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends State<VoiceScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat();

  /// idle · listening · processing · done
  String _state = 'idle';
  String _transcript = '';
  Timer? _typer;
  Timer? _delayer;

  @override
  void dispose() {
    _typer?.cancel();
    _delayer?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  void _listen() {
    setState(() {
      _state = 'listening';
      _transcript = '';
    });
    final demo = _demos[DateTime.now().millisecond % _demos.length];
    var chars = 0;
    _typer = Timer.periodic(const Duration(milliseconds: 60), (t) {
      chars++;
      if (!mounted) return;
      setState(() => _transcript = demo.substring(0, chars.clamp(0, demo.length)));
      if (chars >= demo.length) {
        t.cancel();
        _delayer = Timer(const Duration(milliseconds: 600), () {
          if (!mounted) return;
          setState(() => _state = 'processing');
          _delayer = Timer(const Duration(milliseconds: 900), () {
            if (mounted) setState(() => _state = 'done');
          });
        });
      }
    });
  }

  void _reset() => setState(() {
        _state = 'idle';
        _transcript = '';
      });

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return Column(
      children: [
        AppTopBar(title: 'Búsqueda por Voz', onBack: s.closeOverlay),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _micArea(),
                      const SizedBox(height: 24),
                      Text(_label, style: AppTextStyles.displaySize(18)),
                      const SizedBox(height: 10),
                      if (_transcript.isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x14000000),
                                blurRadius: 16,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            '"$_transcript"',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodySize(15,
                                weight: FontWeight.w600, height: 1.4),
                          ),
                        ),
                      if (_state == 'done') ...[
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            DButton(
                              label: 'Reintentar',
                              tone: DButtonTone.outline,
                              onPressed: _reset,
                            ),
                            const SizedBox(width: 10),
                            DButton(
                              label: 'Buscar →',
                              tone: DButtonTone.dark,
                              onPressed: () {
                                s.setToast('Buscando: $_transcript');
                                s.closeOverlay();
                                s.setTab(AppTab.catalog);
                              },
                            ),
                          ],
                        ),
                      ],
                      if (_state == 'idle')
                        Text(
                          'Di algo como: "Blazer negro talla M"\no "Mostrar ofertas de calzado"',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodySize(12,
                              color: AppColors.mutedLight, height: 1.5),
                        ),
                    ],
                  ),
                ),
                if (_state == 'idle') _historyCard(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String get _label => switch (_state) {
        'idle' => 'Toca para hablar',
        'listening' => 'Escuchando…',
        'processing' => 'Procesando…',
        _ => 'Búsqueda lista',
      };

  Widget _micArea() {
    final listening = _state == 'listening';
    final done = _state == 'done';
    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (listening)
            AnimatedBuilder(
              animation: _pulse,
              builder: (context, _) => Stack(
                alignment: Alignment.center,
                children: List.generate(3, (i) {
                  final t = (_pulse.value + i / 3) % 1.0;
                  final size = 140 + t * 84;
                  return Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.accent.withValues(alpha: (1 - t) * 0.5),
                        width: 2,
                      ),
                    ),
                  );
                }),
              ),
            ),
          GestureDetector(
            onTap: _state == 'processing'
                ? null
                : (_state == 'idle' ? _listen : _reset),
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: listening
                    ? AppColors.accent
                    : done
                        ? AppColors.success
                        : AppColors.dark,
              ),
              alignment: Alignment.center,
              child: Icon(
                listening
                    ? Icons.mic
                    : done
                        ? Icons.check
                        : Icons.mic_none,
                size: 40,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _historyCard() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('BÚSQUEDAS RECIENTES',
              style: AppTextStyles.bodySize(12,
                  weight: FontWeight.w700, letterSpacing: 0.6)),
          const SizedBox(height: 10),
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Column(
              children: [
                for (var i = 0; i < _history.length; i++)
                  InkWell(
                    onTap: () => setState(() {
                      _transcript = _history[i].$1;
                      _state = 'done';
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        border: i < _history.length - 1
                            ? const Border(
                                bottom:
                                    BorderSide(color: AppColors.borderLight),
                              )
                            : null,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                              color: AppColors.borderLight,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: const Icon(Icons.mic_none,
                                size: 15, color: AppColors.muted),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_history[i].$1,
                                    style: AppTextStyles.bodySize(13,
                                        weight: FontWeight.w500)),
                                Text(_history[i].$2,
                                    style: AppTextStyles.bodySize(11,
                                        color: AppColors.mutedLight)),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right,
                              size: 14, color: AppColors.mutedLight),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      );
}
