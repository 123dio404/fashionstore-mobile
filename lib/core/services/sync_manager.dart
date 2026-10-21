import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../constants/api_constants.dart';
import '../network/api_client.dart';
import '../storage/local_database.dart';

/// Resultado de una sincronización por lotes
class SyncResult {
  final int confirmadas;
  final int conflictos;
  final int duplicadasIdempotentes;
  final List<dynamic> resultados;

  const SyncResult({
    this.confirmadas = 0,
    this.conflictos = 0,
    this.duplicadasIdempotentes = 0,
    this.resultados = const [],
  });
}

/// Administrador de sincronización bidireccional offline / online con SQLite (RN-03, RN-04, RNF05).
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

  Timer? _periodicSyncTimer;

  void _init() {
    refreshPendingCount();

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

  Future<void> refreshPendingCount() async {
    try {
      final count = await _db.countPending();
      pendingCount.value = count;
    } catch (_) {}
  }

  /// Registra una venta en modo offline generando un UUID v4 idempotente (RNF05).
  Future<String> recordOfflineSale({
    required int branchId,
    int? clientId,
    required List<Map<String, dynamic>> items,
    double? total,
  }) async {
    final uuid = _uuid.v4();
    final payload = {
      'branch_id': branchId,
      if (clientId != null) 'client_id': clientId,
      'items': items,
      if (total != null) 'total': total,
      'offline_created_at': DateTime.now().toIso8601String(),
    };

    await _db.addToQueue(
      uuid: uuid,
      type: 'venta',
      payload: payload,
    );

    // Descontar inventario localmente en SQLite para evitar sobreventas locales
    for (final it in items) {
      final vId = it['variant_id'] as int? ?? it['stock_id'] as int? ?? 0;
      final qty = (it['quantity'] as num?)?.toInt() ?? 1;
      if (vId > 0) {
        await _db.decrementStock(vId, branchId, qty);
      }
    }

    await refreshPendingCount();

    // Si hay conexión, intentar sincronizar de inmediato
    if (isOnline.value) {
      unawaited(syncAll());
    }

    return uuid;
  }

  /// Registra una reserva offline con UUID v4 idempotente (RN-03, RN-04).
  Future<String> recordOfflineReservation({
    required int branchId,
    required int variantId,
    required String date,
    required String time,
  }) async {
    final uuid = _uuid.v4();
    final payload = {
      'branch_id': branchId,
      'variant_id': variantId,
      'date': date,
      'time': time,
      'offline_created_at': DateTime.now().toIso8601String(),
    };

    await _db.addToQueue(
      uuid: uuid,
      type: 'reserva',
      payload: payload,
    );

    await refreshPendingCount();

    if (isOnline.value) {
      unawaited(syncAll());
    }

    return uuid;
  }

  /// Procesa todas las operaciones pendientes de la cola SQLite contra `POST /api/v1/sync/batch`.
  Future<SyncResult?> syncAll() async {
    if (isSyncing.value) return null;

    final pending = await _db.getPendingQueue();
    if (pending.isEmpty) {
      pendingCount.value = 0;
      return null;
    }

    isSyncing.value = true;

    try {
      final itemsToSend = pending.map((row) {
        return {
          'uuid': row['uuid'],
          'tipo': row['type'],
          'datos': row['payload_data'] ?? {},
        };
      }).toList();

      final response = await _api.dio.post(
        ApiConstants.syncBatch,
        data: {'items': itemsToSend},
        options: Options(
          sendTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );

      final data = Map<String, dynamic>.from(response.data);
      final resultados = List<dynamic>.from(data['resultados'] ?? []);

      for (final res in resultados) {
        final uuid = res['uuid'] as String?;
        final estado = res['estado'] as String? ?? 'SINCRONIZADO';
        final mensaje = res['mensaje'] as String?;
        if (uuid != null) {
          await _db.updateQueueStatus(uuid, estado, serverMessage: mensaje);
        }
      }

      // Remover confirmados
      await _db.removeConfirmedQueueItems();
      lastSyncTime.value = DateTime.now();
      isOnline.value = true;

      final result = SyncResult(
        confirmadas: (data['confirmadas'] as num?)?.toInt() ?? 0,
        conflictos: (data['conflictos'] as num?)?.toInt() ?? 0,
        duplicadasIdempotentes:
            (data['duplicadas_idempotentes'] as num?)?.toInt() ?? 0,
        resultados: resultados,
      );

      await refreshPendingCount();
      return result;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        isOnline.value = false;
      }
      return null;
    } catch (_) {
      return null;
    } finally {
      isSyncing.value = false;
      await refreshPendingCount();
    }
  }

  void dispose() {
    _periodicSyncTimer?.cancel();
  }
}
