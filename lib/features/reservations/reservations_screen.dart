import 'package:flutter/material.dart';

import '../../core/data/mock_data.dart';
import '../../core/models/fashion_models.dart';
import '../../core/state/app_scope.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/kit/buttons.dart';
import '../../shared/kit/cart_widgets.dart';
import '../../shared/kit/chips.dart';
import '../../shared/kit/nav.dart';
import '../../shared/kit/net_image.dart';
import '../../shared/kit/states.dart';

const _dates = [
  ('Lun', '22', '22 sep 2026'),
  ('Mar', '23', '23 sep 2026'),
  ('Mié', '24', '24 sep 2026'),
  ('Jue', '25', '25 sep 2026'),
  ('Vie', '26', '26 sep 2026'),
  ('Sáb', '27', '27 sep 2026'),
  ('Dom', '28', '28 sep 2026'),
];

/// Reservas de probador: listado y flujo de creación en 4 pasos.
class ReservationsScreen extends StatefulWidget {
  const ReservationsScreen({super.key});

  @override
  State<ReservationsScreen> createState() => _ReservationsScreenState();
}

class _ReservationsScreenState extends State<ReservationsScreen> {
  bool _loading = true;

  /// list · product · store · datetime · done
  String _step = 'list';
  Product? _product;
  StoreBranch? _store;
  String _date = '';
  String _time = '';
  String _size = '';
  Reservation? _created;
  String? _cancelId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (mounted) setState(() => _loading = false);
  }

  void _reset() => setState(() {
        _step = 'list';
        _product = null;
        _store = null;
        _date = '';
        _time = '';
        _size = '';
        _created = null;
      });

  void _confirm(AppState s) {
    final p = _product;
    final st = _store;
    if (p == null || st == null || _date.isEmpty || _time.isEmpty || _size.isEmpty) {
      return;
    }
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final r = Reservation(
      id: 'RES-${stamp % 100000}',
      productId: p.id,
      productName: p.name,
      productImage: p.image,
      brand: p.brand,
      size: _size,
      color: p.colors.isNotEmpty ? p.colors.first.name : '',
      date: _date,
      time: _time,
      store: st.name,
      status: 'confirmada',
      code: 'FS-${1000 + stamp % 9000}',
    );
    s.addReservation(r);
    s.setToast('Reserva ${r.code} confirmada');
    setState(() {
      _created = r;
      _step = 'done';
    });
  }

  String get _title => switch (_step) {
        'product' => 'Elegir prenda',
        'store' => 'Elegir sucursal',
        'datetime' => 'Fecha y hora',
        'done' => 'Reserva confirmada',
        _ => 'Mis Reservas',
      };

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    if (s.isOffline) {
      return Column(
        children: [
          const AppTopBar(title: 'Mis Reservas', subtitle: 'FashionStore'),
          OfflineState(onRetry: () => s.setOffline(false)),
        ],
      );
    }
    return Stack(
      children: [
        Column(
          children: [
            AppTopBar(
              title: _title,
              subtitle: 'FashionStore',
              onBack: _step == 'list' ? null : _reset,
            ),
            Expanded(child: _body(s)),
          ],
        ),
        if (_step == 'list' && s.reservations.isNotEmpty) _fab(s),
        if (_cancelId != null) _cancelSheet(s),
      ],
    );
  }

  Widget _body(AppState s) {
    if (_loading && _step == 'list') {
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: List.generate(
          3,
          (_) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: const Row(
              children: [
                SkeletonBox(width: 72, height: 88, radius: 12),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBox(height: 11, width: 110),
                      SizedBox(height: 8),
                      SkeletonBox(height: 14),
                      SizedBox(height: 8),
                      SkeletonBox(height: 10, width: 140),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return switch (_step) {
      'product' => _productStep(),
      'store' => _storeStep(s),
      'datetime' => _datetimeStep(s),
      'done' => _doneStep(s),
      _ => _list(s),
    };
  }

  Widget _list(AppState s) {
    final items = s.reservations;
    if (items.isEmpty) {
      return EmptyState(
        icon: Icons.calendar_today_outlined,
        title: 'Sin reservas',
        subtitle:
            'Reserva un turno en el probador de tu sucursal favorita y asegura tu talla antes de comprar.',
        cta: 'Nueva reserva',
        onCta: () => setState(() => _step = 'product'),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
      children: [
        ...items.map(_card),
        const SizedBox(height: 4),
        DButton(
          label: 'Nueva reserva',
          icon: Icons.add,
          tone: DButtonTone.dark,
          expanded: true,
          onPressed: () => setState(() => _step = 'product'),
        ),
      ],
    );
  }

  Widget _card(Reservation r) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NetImage(
                  url: r.productImage,
                  width: 72,
                  height: 88,
                  radius: BorderRadius.circular(AppRadius.md),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(r.brand.toUpperCase(),
                                style: AppTextStyles.bodySize(10,
                                    color: AppColors.muted, letterSpacing: 0.6)),
                          ),
                          badgeForStatus(r.status),
                        ],
                      ),
                      Text(r.productName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySize(13,
                              weight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text('Talla ${r.size} · ${r.color}',
                          style: AppTextStyles.bodySize(11,
                              color: AppColors.muted)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined,
                              size: 11, color: AppColors.muted),
                          const SizedBox(width: 3),
                          Text(r.date,
                              style: AppTextStyles.bodySize(11,
                                  color: AppColors.muted)),
                          const SizedBox(width: 10),
                          const Icon(Icons.access_time,
                              size: 11, color: AppColors.muted),
                          const SizedBox(width: 3),
                          Text(r.time,
                              style: AppTextStyles.bodySize(11,
                                  color: AppColors.muted)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(r.store,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySize(11,
                              color: AppColors.mutedLight)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: AppColors.borderLight, height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Código de reserva',
                          style: AppTextStyles.bodySize(10,
                              color: AppColors.muted)),
                      Text(r.code,
                          style: AppTextStyles.bodySize(14,
                              weight: FontWeight.w800, letterSpacing: 1)),
                    ],
                  ),
                ),
                if (r.status != 'cancelada' && r.status != 'completada')
                  DButton(
                    label: 'Cancelar',
                    tone: DButtonTone.outline,
                    size: DButtonSize.sm,
                    onPressed: () => setState(() => _cancelId = r.id),
                  ),
              ],
            ),
          ],
        ),
      );

  Widget _fab(AppState s) => Material(
        color: AppColors.dark,
        shape: const CircleBorder(),
        elevation: 6,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => setState(() => _step = 'product'),
          child: const SizedBox(
            width: 52,
            height: 52,
            child: Icon(Icons.add, color: Colors.white, size: 24),
          ),
        ),
      );

  Widget _productStep() => ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          Text('Elige la prenda que quieres probar',
              style: AppTextStyles.bodySize(13, color: AppColors.muted)),
          const SizedBox(height: 14),
          ...kProducts.map(
            (p) => GestureDetector(
              onTap: () => setState(() {
                _product = p;
                _size = '';
                _step = 'store';
              }),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(
                    color: _product?.id == p.id
                        ? AppColors.accent
                        : AppColors.borderLight,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    NetImage(
                      url: p.image,
                      width: 56,
                      height: 70,
                      radius: BorderRadius.circular(10),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.brand.toUpperCase(),
                              style: AppTextStyles.bodySize(10,
                                  color: AppColors.muted, letterSpacing: 0.6)),
                          Text(p.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodySize(13,
                                  weight: FontWeight.w600)),
                          Text('\$${p.price.toStringAsFixed(2)}',
                              style: AppTextStyles.bodySize(13,
                                  weight: FontWeight.w700)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right,
                        size: 18, color: AppColors.mutedLight),
                  ],
                ),
              ),
            ),
          ),
        ],
      );

  Widget _storeStep(AppState s) => ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          Text('¿En qué sucursal quieres probarla?',
              style: AppTextStyles.bodySize(13, color: AppColors.muted)),
          const SizedBox(height: 14),
          ...kStores.map(
            (st) => GestureDetector(
              onTap: () => setState(() {
                _store = st;
                _step = 'datetime';
              }),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(
                    color: _store?.id == st.id
                        ? AppColors.accent
                        : AppColors.borderLight,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.store_outlined,
                        size: 20, color: AppColors.dark),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(st.name,
                              style: AppTextStyles.bodySize(14,
                                  weight: FontWeight.w600)),
                          Text(st.address,
                              style: AppTextStyles.bodySize(11,
                                  color: AppColors.muted)),
                          Text('Horario ${st.hours}',
                              style: AppTextStyles.bodySize(11,
                                  color: AppColors.mutedLight)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right,
                        size: 18, color: AppColors.mutedLight),
                  ],
                ),
              ),
            ),
          ),
        ],
      );

  Widget _stepLabel(String t) => Text(
        t,
        style: AppTextStyles.bodySize(11,
            weight: FontWeight.w700, letterSpacing: 0.6),
      );

  Widget _datetimeStep(AppState s) {
    final sizes = _product?.sizes ?? kSizesList;
    final ready = _product != null &&
        _store != null &&
        _date.isNotEmpty &&
        _time.isNotEmpty &&
        _size.isNotEmpty;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        _stepLabel('TALLA'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: sizes
              .map((sz) => SizeChip(
                    label: sz,
                    selected: _size == sz,
                    onTap: () => setState(() => _size = sz),
                  ))
              .toList(),
        ),
        const SizedBox(height: 20),
        _stepLabel('FECHA'),
        const SizedBox(height: 8),
        SizedBox(
          height: 70,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _dates.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final d = _dates[i];
              final active = _date == d.$3;
              return GestureDetector(
                onTap: () => setState(() => _date = d.$3),
                child: Container(
                  width: 58,
                  decoration: BoxDecoration(
                    color: active ? AppColors.dark : AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: active ? AppColors.dark : AppColors.border,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(d.$1,
                          style: AppTextStyles.bodySize(11,
                              color: active ? Colors.white70 : AppColors.muted)),
                      Text(d.$2,
                          style: AppTextStyles.bodySize(17,
                              color: active ? Colors.white : AppColors.dark,
                              weight: FontWeight.w800)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        _stepLabel('HORARIO'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: kTimeSlots
              .map((t) => PillChip(
                    label: t,
                    selected: _time == t,
                    onTap: () => setState(() => _time = t),
                  ))
              .toList(),
        ),
        const SizedBox(height: 24),
        DButton(
          label: 'Confirmar reserva',
          tone: DButtonTone.dark,
          expanded: true,
          size: DButtonSize.lg,
          onPressed: ready ? () => _confirm(s) : null,
        ),
      ],
    );
  }

  Widget _doneStep(AppState s) => ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: AppColors.successBg,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.check,
                      size: 30, color: AppColors.success),
                ),
                const SizedBox(height: 14),
                Text('¡Reserva confirmada!',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.displaySize(20)),
                const SizedBox(height: 6),
                Text(
                  'Presenta este código al llegar a la sucursal.',
                  textAlign: TextAlign.center,
                  style:
                      AppTextStyles.bodySize(12, color: AppColors.muted),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.borderLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(_created?.code ?? '',
                      style: AppTextStyles.bodySize(20,
                          weight: FontWeight.w800, letterSpacing: 2)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (_created != null) _card(_created!),
          const SizedBox(height: 10),
          DButton(
            label: 'Volver a mis reservas',
            tone: DButtonTone.dark,
            expanded: true,
            size: DButtonSize.lg,
            onPressed: _reset,
          ),
        ],
      );

  Widget _cancelSheet(AppState s) => Positioned.fill(
        child: GestureDetector(
          onTap: () => setState(() => _cancelId = null),
          child: Container(
            color: Colors.black54,
            alignment: Alignment.bottomCenter,
            child: GestureDetector(
              onTap: () {},
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(
                  24,
                  20,
                  24,
                  28 + MediaQuery.paddingOf(context).bottom,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(24)),
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
                    Text('¿Cancelar reserva?',
                        style: AppTextStyles.bodySize(18,
                            weight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    Text(
                      'Esta acción no se puede deshacer.\nPodrás crear una nueva reserva cuando quieras.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodySize(13,
                          color: AppColors.muted, height: 1.55),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: DButton(
                            label: 'Mantener',
                            tone: DButtonTone.outline,
                            expanded: true,
                            onPressed: () =>
                                setState(() => _cancelId = null),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DButton(
                            label: 'Sí, cancelar',
                            tone: DButtonTone.accent,
                            expanded: true,
                            onPressed: () {
                              final id = _cancelId;
                              if (id != null) {
                                s.cancelReservation(id);
                                s.setToast('Reserva cancelada');
                              }
                              setState(() => _cancelId = null);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}
