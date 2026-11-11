import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../constants/api_constants.dart';
import '../network/api_client.dart';
import '../storage/local_database.dart';

/// Resultado de una sincronización por lotes.
class SyncResult {
  final int processed;
  final int confirmadas;
  final int conflictos;
  final int duplicadasIdempotentes;
  final List<dynamic> resultados;

  const SyncResult({
    this.processed = 0,
    this.confirmadas = 0,
    this.conflictos = 0,
    this.duplicadasIdempotentes = 0,
    this.resultados = const [],
  });
}

/// Administrador de sincronización bidireccional offline / online con SQLite (RN-03, RN-04, RNF05).
///
/// Contrato con el backend (`POST /sync/batch`):
/// ```json
/// { "operations": [ { "uuid", "type": "SALE|RESERVATION", "created_at",
///   "branch_id", "client_id", "total", "payment_method",
///   "items": [{ "stock_id", "quantity", "unit_price" }] } ] }
/// ```
/// Respuesta: `{ processed, confirmed, conflicts, results[] }`.
class SyncManager {
  static final SyncManager instance = SyncManager._internal();
  SyncManager._internal() {
    _init();
  }

  final LocalDatabase _db = LocalDatabase.instance;
  final ApiClient _api = ApiClient();
  static const _uuid = Uuid();

  final ValueNotifier<bool> isOnline = ValueNotifier<bool>(true);
  final ValueNotifier<bool> isSyncing = ValueNotifier<bool>(false);
  final ValueNotifier<int> pendingCount = ValueNotifier<int>(0);
  final ValueNotifier<DateTime?> lastSyncTime = ValueNotifier<DateTime?>(null);
  final ValueNotifier<String?> lastError = ValueNotifier<String?>(null);
  final ValueNotifier<List<Map<String, dynamic>>> queue =
      ValueNotifier<List<Map<String, dynamic>>>(const []);

  int? _activeTenantId;

  Timer? _periodicSyncTimer;

  void _init() {
    refreshPendingCount();
    refreshQueue();

    // Sincronización periódica cada 30 segundos si hay conexión
    _periodicSyncTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (isOnline.value && !isSyncing.value && pendingCount.value > 0) {
        syncAll();
      }
    });
  }

  void setOnlineStatus(bool online) {
    if (isOnline.value != online) {
      isOnline.value = online;
      if (online && pendingCount.value > 0) {
        syncAll();
      }
    }
  }

  void setActiveTenantId(int? tenantId) {
    _activeTenantId = tenantId;
  }

  Future<void> refreshPendingCount() async {
    try {
      pendingCount.value = await _db.countPending();
    } catch (_) {}
  }

  Future<void> refreshQueue() async {
    try {
      queue.value = await _db.getQueue();
    } catch (_) {}
  }

  /// Registra una venta en modo offline generando un UUID v4 idempotente (RNF05).
  ///
  /// RN-03: sin conexión solo se permite efectivo. Se rechaza cualquier otro
  /// método para no encolar un cobro que la pasarela no pudo autorizar.
  Future<String> recordOfflineSale({
    required int tenantId,
    required int branchId,
    int? clientId,
    required List<Map<String, dynamic>> items,
    double? total,
    String paymentMethod = 'efectivo',
    DateTime? createdAt,
  }) async {
    final requested = paymentMethod.trim().toLowerCase();
    if (requested != 'efectivo' && requested != 'cash' && requested != 'contado') {
      throw ArgumentError(
        'Sin conexión solo se permiten ventas en efectivo (RN-03). '
        'Conéctate para cobrar con tarjeta, QR o datáfono.',
      );
    }
    final normalized = _normalizeItems(items);
    if (normalized.isEmpty) {
      throw ArgumentError(
        'La venta offline no tiene líneas válidas asociadas al inventario (stock_id).',
      );
    }
    final uuid = _uuid.v4();
    final payload = {
      'tenant_id': tenantId,
      'branch_id': branchId,
      'client_id': clientId,
      'total': total ?? _totalOf(normalized),
      'payment_method': 'efectivo',
      'items': normalized,
      'created_at': (createdAt ?? DateTime.now()).toIso8601String(),
    };

    await _db.addToQueue(uuid: uuid, type: 'venta', payload: payload);

    // Descontar inventario localmente en SQLite para evitar sobreventas locales.
    for (final it in normalized) {
      final stockId = (it['stock_id'] as num?)?.toInt() ?? 0;
      final qty = (it['quantity'] as num?)?.toInt() ?? 1;
      if (stockId > 0) {
        await _db.decrementStockByStockId(stockId, qty);
      }
    }

    await refreshPendingCount();
    await refreshQueue();

    if (isOnline.value) {
      unawaited(syncAll());
    }

    return uuid;
  }

  /// Registra una reserva offline con UUID v4 idempotente (RN-03, RN-04).
  ///
  /// `scheduledAt` es la fecha/hora elegida por el cliente: el backend de sync
  /// usa `created_at` como fecha de la reserva.
  Future<String> recordOfflineReservation({
    required int tenantId,
    required int branchId,
    int? clientId,
    required List<Map<String, dynamic>> items,
    required DateTime scheduledAt,
    double? total,
  }) async {
    final uuid = _uuid.v4();
    final normalized = _normalizeItems(items);
    final payload = {
      'tenant_id': tenantId,
      'branch_id': branchId,
      'client_id': clientId,
      'total': total ?? _totalOf(normalized),
      'payment_method': 'efectivo',
      'items': normalized,
      'created_at': scheduledAt.toIso8601String(),
    };

    await _db.addToQueue(uuid: uuid, type: 'reserva', payload: payload);

    await refreshPendingCount();
    await refreshQueue();

    if (isOnline.value) {
      unawaited(syncAll());
    }

    return uuid;
  }

  List<Map<String, dynamic>> _normalizeItems(List<Map<String, dynamic>> items) {
    return items
        .map((item) => {
              'stock_id': (item['stock_id'] as num?)?.toInt() ?? 0,
              'quantity': (item['quantity'] as num?)?.toInt() ?? 1,
              'unit_price': (item['unit_price'] as num?)?.toDouble() ?? 0.0,
            })
        .where((item) => (item['stock_id'] as int) > 0)
        .toList();
  }

  double _totalOf(List<Map<String, dynamic>> items) {
    return items.fold<double>(
      0,
      (sum, item) =>
          sum +
          ((item['unit_price'] as num?)?.toDouble() ?? 0) *
              ((item['quantity'] as num?)?.toInt() ?? 0),
    );
  }

  /// Procesa todas las operaciones pendientes de la cola SQLite contra `POST /api/v1/sync/batch`.
  Future<SyncResult?> syncAll() async {
    if (isSyncing.value) return null;

    final allPending = await _db.getPendingQueue();
    if (allPending.isEmpty) {
      pendingCount.value = 0;
      await refreshQueue();
      return null;
    }

    final tenantId = _activeTenantId;
    if (tenantId == null || tenantId <= 0) {
      lastError.value = 'Inicia sesión en una empresa para sincronizar las operaciones offline.';
      return null;
    }
    final pending = allPending.where((row) {
      final payload = row['payload_data'];
      return payload is Map && payload['tenant_id'] == tenantId;
    }).toList();
    if (pending.isEmpty) {
      if (allPending.isNotEmpty) {
        lastError.value =
            'Hay operaciones offline de otra empresa o sin tenant asociado. Inicia sesión en la empresa correspondiente para sincronizarlas.';
      }
      await refreshQueue();
      return null;
    }

    isSyncing.value = true;
    lastError.value = null;

    try {
      final operations = pending
          .map((row) {
            final payload = Map<String, dynamic>.from(
              (row['payload_data'] as Map?) ?? const {},
            );
            final isReservation = row['type'] == 'reserva';
            return {
              'uuid': row['uuid'],
              'type': isReservation ? 'RESERVATION' : 'SALE',
              'created_at':
                  payload['created_at'] ?? row['created_at'] ?? DateTime.now().toIso8601String(),
              'branch_id': (payload['branch_id'] as num?)?.toInt() ?? 1,
              if ((payload['client_id'] as num?) != null)
                'client_id': (payload['client_id'] as num).toInt(),
              'total': (payload['total'] as num?)?.toDouble() ?? 0.0,
              'payment_method': payload['payment_method'] ?? 'efectivo',
              'items': (payload['items'] as List?) ?? const [],
            };
          })
          .where((op) => (op['items'] as List).isNotEmpty)
          .toList();

      if (operations.isEmpty) {
        pendingCount.value = 0;
        await refreshQueue();
        return null;
      }

      final response = await _api.dio.post(
        ApiConstants.syncBatch,
        data: {'operations': operations},
        options: Options(
          sendTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );

      final data = Map<String, dynamic>.from(response.data as Map);
      final results = List<dynamic>.from(data['results'] ?? []);

      var confirmed = 0;
      var conflicts = 0;
      var duplicates = 0;
      for (final res in results.whereType<Map>()) {
        final uuid = res['uuid'] as String?;
        final status = (res['status'] as String?) ?? 'CONFIRMADO';
        final message = res['message'] as String?;
        if (status == 'CONFIRMADO') confirmed++;
        if (status == 'CONFLICTO') conflicts++;
        if (status == 'DUPLICADO_IDEMPOTENTE') duplicates++;
        if (uuid != null) {
          await _db.updateQueueStatus(uuid, status, serverMessage: message);
        }
      }

      // Las operaciones confirmadas (o ya procesadas) salen de la cola.
      await _db.removeConfirmedQueueItems();
      lastSyncTime.value = DateTime.now();
      isOnline.value = true;

      final result = SyncResult(
        processed: (data['processed'] as num?)?.toInt() ?? operations.length,
        confirmadas: (data['confirmed'] as num?)?.toInt() ?? confirmed,
        conflictos: (data['conflicts'] as num?)?.toInt() ?? conflicts,
        duplicadasIdempotentes: duplicates,
        resultados: results,
      );

      if (result.conflictos > 0) {
        lastError.value =
            '${result.conflictos} operación(es) quedaron en conflicto por stock insuficiente.';
      }

      await refreshPendingCount();
      await refreshQueue();
      return result;
    } on DioException catch (e) {
      if (_isConnectionError(e)) {
        isOnline.value = false;
      }
      lastError.value =
          e.response?.statusCode != null ? _describeError(e) : 'Sin conexión con el servidor.';
      return null;
    } catch (e) {
      lastError.value = 'Error al sincronizar: $e';
      return null;
    } finally {
      isSyncing.value = false;
      await refreshPendingCount();
      await refreshQueue();
    }
  }

  /// Elimina definitivamente una operación de la cola local (p. ej. un conflicto).
  Future<void> discard(String uuid) async {
    await _db.deleteQueueItem(uuid);
    await refreshPendingCount();
    await refreshQueue();
  }

  /// Limpia el historial de operaciones ya confirmadas.
  Future<void> clearProcessed() async {
    await _db.clearProcessedQueue();
    await refreshQueue();
  }

  static bool _isConnectionError(DioException e) =>
      e.type == DioExceptionType.connectionError ||
      e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.sendTimeout ||
      e.type == DioExceptionType.receiveTimeout ||
      e.type == DioExceptionType.unknown && e.response == null;

  String _describeError(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['detail'] is String) return data['detail'] as String;
    return e.message ?? 'No se pudo sincronizar con el servidor.';
  }

  void dispose() {
    _periodicSyncTimer?.cancel();
  }
}
