import 'package:flutter/material.dart';

import '../../core/state/app_scope.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/kit/buttons.dart';
import '../../shared/kit/nav.dart';

/// Cola de sincronización offline (CU-12): muestra las ventas y reservas
/// guardadas en SQLite, su estado frente a `POST /sync/batch` y permite
/// reintentar, descartar conflictos o limpiar operaciones ya procesadas.
class SyncQueueScreen extends StatefulWidget {
  const SyncQueueScreen({super.key});

  @override
  State<SyncQueueScreen> createState() => _SyncQueueScreenState();
}

class _SyncQueueScreenState extends State<SyncQueueScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      AppScope.read(context).syncManager.refreshQueue();
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final manager = s.syncManager;

    return Column(
      children: [
        AppTopBar(
          title: 'Cola de sincronización',
          subtitle: 'Offline · SQLite',
          onBack: s.closeOverlay,
          right: IconButton(
            tooltip: 'Actualizar',
            onPressed: manager.refreshQueue,
            icon: const Icon(Icons.refresh, size: 20, color: AppColors.dark),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Row(
            children: [
              _StatusPill(
                label: manager.isOnline.value ? 'Online' : 'Offline',
                color: manager.isOnline.value
                    ? AppColors.success
                    : AppColors.muted,
              ),
              const SizedBox(width: 8),
              _StatusPill(
                label: '${manager.pendingCount.value} pendientes',
                color: AppColors.accent,
              ),
              const Spacer(),
              if (manager.isSyncing.value)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.dark,
                  ),
                )
              else
                DButton(
                  label: 'Sincronizar',
                  icon: Icons.sync,
                  tone: DButtonTone.dark,
                  size: DButtonSize.sm,
                  onPressed: () async {
                    final result = await manager.syncAll();
                    if (!context.mounted) return;
                    if (result != null) {
                      s.setToast(
                        'Sincronizado: ${result.confirmadas} confirmadas, ${result.conflictos} conflictos',
                      );
                    } else if (manager.lastError.value != null) {
                      s.setToast(manager.lastError.value);
                    }
                  },
                ),
            ],
          ),
        ),
        if (manager.lastError.value != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Text(
                manager.lastError.value!,
                style: AppTextStyles.bodySize(11, color: AppColors.danger),
              ),
            ),
          ),
        Expanded(
          child: ValueListenableBuilder<List<Map<String, dynamic>>>(
            valueListenable: manager.queue,
            builder: (context, rows, _) {
              if (rows.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.cloud_done_outlined,
                            size: 44, color: AppColors.mutedLight),
                        SizedBox(height: 12),
                        Text('No hay operaciones pendientes'),
                        SizedBox(height: 4),
                        Text(
                          'Las ventas y reservas hechas sin conexión aparecerán aquí.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.muted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                itemCount: rows.length + 1,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  if (i == rows.length) {
                    return DButton(
                      label: 'Limpiar procesadas',
                      icon: Icons.cleaning_services_outlined,
                      tone: DButtonTone.outline,
                      expanded: true,
                      onPressed: manager.clearProcessed,
                    );
                  }
                  return _QueueCard(
                    row: rows[i],
                    onDiscard: () => manager.discard(rows[i]['uuid'] as String),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _QueueCard extends StatelessWidget {
  const _QueueCard({required this.row, required this.onDiscard});

  final Map<String, dynamic> row;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    final uuid = '${row['uuid'] ?? ''}';
    final isReservation = row['type'] == 'reserva';
    final status = '${row['status'] ?? 'LOCAL'}';
    final payload = (row['payload_data'] as Map?) ?? const {};
    final items = (payload['items'] as List?)?.length ?? 0;
    final total = (payload['total'] as num?)?.toDouble() ?? 0;
    final branch = payload['branch_id'] ?? '-';
    final createdAt = '${row['created_at'] ?? ''}'.replaceFirst('T', ' ');
    final message = row['server_message']?.toString();
    final canDiscard = status == 'LOCAL' || status == 'CONFLICTO';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: status == 'CONFLICTO'
              ? AppColors.danger.withValues(alpha: 0.4)
              : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isReservation
                    ? Icons.calendar_today_outlined
                    : Icons.point_of_sale_outlined,
                size: 18,
                color: AppColors.dark,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${isReservation ? 'Reserva' : 'Venta'} · ${uuid.length > 8 ? uuid.substring(0, 8) : uuid}',
                  style: AppTextStyles.bodySize(13, weight: FontWeight.w700),
                ),
              ),
              _StatusPill(
                label: _statusLabel(status),
                color: _statusColor(status),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Sucursal $branch · $items artículo(s) · \$${total.toStringAsFixed(2)}',
            style: AppTextStyles.bodySize(11, color: AppColors.muted),
          ),
          if (createdAt.isNotEmpty)
            Text(
              createdAt,
              style: AppTextStyles.bodySize(10, color: AppColors.mutedLight),
            ),
          if (message != null && message.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              message,
              style: AppTextStyles.bodySize(11, color: AppColors.danger),
            ),
          ],
          if (canDiscard) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onDiscard,
                child: Text(
                  status == 'CONFLICTO' ? 'Descartar conflicto' : 'Descartar',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.danger,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _statusLabel(String status) => switch (status) {
        'CONFIRMADO' => 'Confirmada',
        'CONFLICTO' => 'Conflicto',
        'DUPLICADO_IDEMPOTENTE' => 'Duplicada',
        _ => 'Pendiente',
      };

  static Color _statusColor(String status) => switch (status) {
        'CONFIRMADO' => AppColors.success,
        'CONFLICTO' => AppColors.danger,
        'DUPLICADO_IDEMPOTENTE' => AppColors.dark,
        _ => AppColors.accent,
      };
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
