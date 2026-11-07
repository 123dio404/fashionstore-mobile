import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../core/services/ar_service.dart';
import '../../core/state/app_scope.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/kit/buttons.dart';
import '../../shared/kit/nav.dart';

const _suggestions = [
  'Ventas por sucursal del último mes',
  'Top productos más vendidos',
  'Riesgo de agotamiento de stock',
  'Comparativa de los últimos 3 meses',
];

/// CU-20 — Reporte analítico asistido por IA (texto / voz).
///
/// Envía la consulta en lenguaje natural a `POST /ai-reports/query` y muestra
/// la síntesis ejecutiva, la tabla de resultados y una visualización simple de
/// los datos devueltos por el backend.
class AiReportScreen extends StatefulWidget {
  const AiReportScreen({super.key});

  @override
  State<AiReportScreen> createState() => _AiReportScreenState();
}

class _AiReportScreenState extends State<AiReportScreen> {
  final _query = TextEditingController();
  final _arService = ArService();

  bool _loading = false;
  bool _listening = false;
  String? _error;
  Map<String, dynamic>? _report;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _ask() async {
    final prompt = _query.text.trim();
    if (prompt.length < 2 || _loading) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final report = await AppScope.read(context).generateAiReport(prompt);
      if (!mounted) return;
      setState(() {
        _report = report;
        _loading = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      final detail = e.response?.data is Map
          ? (e.response!.data['detail']?.toString())
          : null;
      setState(() {
        _error = detail ??
            'No se pudo generar el reporte. Verifica tu conexión y el plan de suscripción.';
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo generar el reporte. Intenta nuevamente.';
        _loading = false;
      });
    }
  }

  Future<void> _listen() async {
    if (_loading || _listening) return;
    setState(() => _listening = true);
    try {
      final spoken = await _arService.startVoiceRecognition();
      if (!mounted) return;
      setState(() => _listening = false);
      if (spoken != null && spoken.trim().isNotEmpty) {
        _query.text = spoken.trim();
        await _ask();
      }
    } catch (_) {
      if (mounted) setState(() => _listening = false);
    }
  }

  void _useSuggestion(String value) {
    _query.text = value;
    _ask();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return Column(
      children: [
        AppTopBar(
          title: 'Reporte IA',
          subtitle: 'Texto / Voz · CU-20',
          onBack: s.closeOverlay,
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            children: [
              _hero(),
              const SizedBox(height: 20),
              _queryCard(),
              const SizedBox(height: 12),
              _suggestionsWrap(),
              if (_error != null) ...[
                const SizedBox(height: 20),
                _errorCard(_error!),
              ],
              if (_loading) ...[
                const SizedBox(height: 24),
                const Center(
                  child: CircularProgressIndicator(color: AppColors.accent),
                ),
              ],
              if (_report != null && !_loading) ...[
                const SizedBox(height: 24),
                _summaryCard(),
                const SizedBox(height: 16),
                _chartCard(),
                const SizedBox(height: 16),
                _tableCard(),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _hero() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF111827), Color(0xFF1F2937)],
          ),
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.auto_awesome,
                  color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Asistente analítico',
                      style: AppTextStyles.displaySize(20,
                          color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(
                    'Pregunta en lenguaje natural y obtén un resumen ejecutivo con datos de tu empresa.',
                    style: AppTextStyles.bodySize(12,
                        color: Colors.white.withValues(alpha: 0.7)),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _queryCard() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('TU CONSULTA',
                style: AppTextStyles.bodySize(11,
                    weight: FontWeight.w700, letterSpacing: 0.7)),
            const SizedBox(height: 10),
            TextField(
              controller: _query,
              minLines: 2,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _ask(),
              style: AppTextStyles.bodySize(14),
              decoration: InputDecoration(
                hintText: 'Ej. ¿Cómo fueron las ventas por sucursal este mes?',
                hintStyle:
                    AppTextStyles.bodySize(13, color: AppColors.mutedLight),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                DButton(
                  label: _listening ? 'Escuchando…' : 'Voz',
                  icon: Icons.mic_none,
                  tone: DButtonTone.outline,
                  size: DButtonSize.sm,
                  onPressed: _listening ? null : _listen,
                ),
                const Spacer(),
                DButton(
                  label: 'Consultar',
                  icon: Icons.send_outlined,
                  tone: DButtonTone.accent,
                  size: DButtonSize.sm,
                  loading: _loading,
                  onPressed: _loading ? null : _ask,
                ),
              ],
            ),
          ],
        ),
      );

  Widget _suggestionsWrap() => Wrap(
        spacing: 6,
        runSpacing: 6,
        children: _suggestions
            .map((s) => InkWell(
                  onTap: () => _useSuggestion(s),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Text(s,
                        style: AppTextStyles.bodySize(11,
                            color: AppColors.dark)),
                  ),
                ))
            .toList(),
      );

  Widget _errorCard(String message) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.dangerBg,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.danger.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline,
                color: AppColors.danger, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message,
                  style: AppTextStyles.bodySize(12,
                      color: AppColors.danger)),
            ),
          ],
        ),
      );

  Widget _summaryCard() {
    final report = _report!;
    final title = report['titulo']?.toString() ?? 'Resultado del análisis';
    final summary = report['resumen_ejecutivo']?.toString() ?? '';
    final generated = report['generado_en']?.toString();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('RESUMEN EJECUTIVO',
              style: AppTextStyles.bodySize(11,
                  weight: FontWeight.w700, letterSpacing: 0.7)),
          const SizedBox(height: 8),
          Text(title, style: AppTextStyles.displaySize(18)),
          if (summary.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(summary, style: AppTextStyles.bodySize(13, height: 1.55)),
          ],
          if (generated != null && generated.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text('Generado: $generated',
                style: AppTextStyles.bodySize(10,
                    color: AppColors.mutedLight)),
          ],
        ],
      ),
    );
  }

  Widget _chartCard() {
    final chart = _report!['datos_grafico'];
    if (chart is! Map) return const SizedBox.shrink();
    final labels = (chart['labels'] as List?) ?? const [];
    final datasets = (chart['datasets'] as List?) ?? const [];
    if (labels.isEmpty || datasets.isEmpty) return const SizedBox.shrink();

    final first = datasets.first;
    if (first is! Map) return const SizedBox.shrink();
    final legend = first['label']?.toString() ?? 'Datos';
    final data = ((first['data'] as List?) ?? const [])
        .map((v) => double.tryParse('$v') ?? 0)
        .toList();
    if (data.isEmpty) return const SizedBox.shrink();
    final max = data.reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('VISUALIZACIÓN · $legend'.toUpperCase(),
              style: AppTextStyles.bodySize(11,
                  weight: FontWeight.w700, letterSpacing: 0.7)),
          const SizedBox(height: 14),
          ...List.generate(labels.length, (i) {
            final value = i < data.length ? data[i] : 0.0;
            final ratio = max <= 0 ? 0.0 : (value / max).clamp(0.0, 1.0);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('${labels[i]}',
                            style: AppTextStyles.bodySize(11,
                                color: AppColors.muted)),
                      ),
                      Text(_formatNumber(value),
                          style: AppTextStyles.bodySize(11,
                              weight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 7,
                      backgroundColor: AppColors.borderLight,
                      valueColor:
                          const AlwaysStoppedAnimation(AppColors.accent),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _tableCard() {
    final columns = ((_report!['columnas'] as List?) ?? const [])
        .map((c) => c.toString())
        .toList();
    final rows = ((_report!['filas'] as List?) ?? const [])
        .whereType<Map>()
        .toList();
    if (columns.isEmpty || rows.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('DETALLE DE DATOS',
              style: AppTextStyles.bodySize(11,
                  weight: FontWeight.w700, letterSpacing: 0.7)),
          const SizedBox(height: 12),
          ...rows.map(
            (row) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: columns
                    .map(
                      (col) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(col,
                                  style: AppTextStyles.bodySize(11,
                                      color: AppColors.muted)),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: Text('${row[col] ?? '—'}',
                                  textAlign: TextAlign.right,
                                  style: AppTextStyles.bodySize(11,
                                      weight: FontWeight.w700)),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2);
  }
}
