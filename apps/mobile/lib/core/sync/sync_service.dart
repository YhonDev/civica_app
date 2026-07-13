import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint, visibleForTesting;
import 'package:dio/dio.dart';

import '../database/app_database.dart';
import '../database/daos/pago_dao.dart';
import '../database/daos/sync_dao.dart';
import '../network/api_client.dart';
import '../network/api_exceptions.dart';
import 'connectivity_detector.dart';

/// Estados del proceso de sincronización.
enum SyncStatus {
  /// No hay sync en curso.
  idle,

  /// Sincronizando datos pendientes.
  syncing,

  /// Sync completado sin errores.
  success,

  /// Sync completado pero algunos elementos fallaron.
  partial,

  /// Error de red durante el sync (se reintentará después).
  networkError,
}

/// Resultado de una ejecución de sync.
class SyncResult {
  final int synced;
  final int conflicts;
  final int errors;

  const SyncResult({
    required this.synced,
    required this.conflicts,
    required this.errors,
  });

  bool get allOk => conflicts == 0 && errors == 0;
}

/// Orquestador de sincronización offline.
///
/// Escucha cambios de conectividad y sincroniza automáticamente los pagos
/// pendientes cuando se restaura la conexión.
class SyncService {
  static SyncService? _instance;

  final ConnectivityDetector _detector;
  final PagoDao _pagoDao;
  final SyncDao _syncDao;

  /// Callback para realizar POST /pagos.
  /// En producción usa ApiClient; en tests se inyecta un mock.
  final Future<Response<Map<String, dynamic>>> Function(Map<String, dynamic> data) _syncPayment;

  StreamSubscription<bool>? _connectivitySub;
  final _statusController = StreamController<SyncStatus>.broadcast();
  final _resultController = StreamController<SyncResult>.broadcast();
  SyncResult? _lastSyncResult;

  bool _isSyncing = false;

  /// Stream de estados del sync. Útil para mostrar indicadores en la UI.
  Stream<SyncStatus> get onStatusChanged => _statusController.stream;

  /// Stream con el resultado detallado del último sync.
  Stream<SyncResult> get onSyncResult => _resultController.stream;

  /// Último resultado del sync (útil para consultar después de un evento).
  SyncResult? get lastSyncResult => _lastSyncResult;

  /// Estado actual del sync.
  SyncStatus _status = SyncStatus.idle;
  SyncStatus get status => _status;

  SyncService._({
    required this._detector,
    required this._pagoDao,
    required this._syncDao,
    required this._syncPayment,
  }) {
    _listenConnectivity();
  }

  /// Constructor para tests que inyecta un callback en lugar de HTTP real.
  @visibleForTesting
  factory SyncService.forTesting({
    required ConnectivityDetector detector,
    required PagoDao pagoDao,
    required SyncDao syncDao,
    required Future<Response<Map<String, dynamic>>> Function(Map<String, dynamic> data) syncPayment,
  }) {
    final service = SyncService._(
      detector: detector,
      pagoDao: pagoDao,
      syncDao: syncDao,
      syncPayment: syncPayment,
    );
    return service;
  }

  /// Inicializa la instancia singleton.
  static SyncService init({
    required ConnectivityDetector detector,
    ApiClient? client,
    PagoDao? pagoDao,
    SyncDao? syncDao,
  }) {
    final httpClient = client ?? ApiClient.instance;
    _instance ??= SyncService._(
      detector: detector,
      pagoDao: pagoDao ?? PagoDao(AppDatabase.instance),
      syncDao: syncDao ?? SyncDao(AppDatabase.instance),
      syncPayment: (data) => httpClient.post<Map<String, dynamic>>('/pagos', data: data),
    );
    // Sync inicial si ya hay conexión
    if (_instance!._detector.isOnline) {
      _instance!.requestSync();
    }
    return _instance!;
  }

  /// Acceso a la instancia singleton.
  static SyncService get instance {
    if (_instance == null) {
      throw StateError('SyncService no inicializado. Llama init() primero.');
    }
    return _instance!;
  }

  /// Verifica si el SyncService ya fue inicializado.
  static bool get isInitialized => _instance != null;

  void _listenConnectivity() {
    _connectivitySub = _detector.onStatusChanged.listen((online) {
      if (online) {
        debugPrint('[SyncService] Conexión restaurada → iniciando sync');
        requestSync();
      }
    });
  }

  /// Solicita una sincronización manual.
  /// No-op si ya hay un sync en curso.
  Future<SyncResult?> requestSync() async {
    if (_isSyncing) {
      debugPrint('[SyncService] Sync ya en curso, ignorando solicitud');
      return null;
    }

    if (!_detector.isOnline) {
      debugPrint('[SyncService] Sin conexión, no se puede sincronizar');
      _setStatus(SyncStatus.networkError);
      return null;
    }

    return _executeSync();
  }

  Future<SyncResult> _executeSync() async {
    _isSyncing = true;
    _setStatus(SyncStatus.syncing);

    try {
      final pendientes = await _pagoDao.getPendientesSync();

      if (pendientes.isEmpty) {
        debugPrint('[SyncService] No hay pagos pendientes de sync');
        _setStatus(SyncStatus.success);
        return const SyncResult(synced: 0, conflicts: 0, errors: 0);
      }

      debugPrint('[SyncService] Sincronizando ${pendientes.length} pago(s)');

      int synced = 0;
      int conflicts = 0;
      int errors = 0;

      for (final pago in pendientes) {
        try {
          final response = await _syncPayment({
              'clientPaymentId': pago.clientPaymentId,
              'monto': pago.monto,
              'fechaPago': pago.fechaPago,
              'propietarioId': pago.propietarioId,
              if (pago.solicitudId != null) 'solicitudId': pago.solicitudId,
            });

          if (response.statusCode! >= 200 && response.statusCode! < 300) {
            final serverId = response.data?['id'] as String?;
            await _pagoDao.marcarSincronizado(pago.id, serverId ?? pago.id);
            synced++;
          } else {
            errors++;
            debugPrint('[SyncService] Código inesperado ${response.statusCode}');
          }
        } catch (e) {
          if (e is DioException) {
            final mapped = mapDioError(e);
            if (mapped is ConflictException) {
              // Conflicto 409 — el pago ya existe en el servidor
              final serverId = mapped.serverId;
              await _pagoDao.marcarSincronizado(
                pago.id,
                serverId ?? pago.clientPaymentId,
              );
              conflicts++;
              debugPrint('[SyncService] Conflicto en pago ${pago.id}: $mapped');
            } else if (mapped is NetworkException) {
              // Error de red — detener sync, reintentar después
              errors++;
              debugPrint('[SyncService] Error de red en pago ${pago.id}: parando sync');
              break;
            } else if (mapped is AuthException) {
              // Sesión expirada — no se puede sync
              errors++;
              debugPrint('[SyncService] Auth error en pago ${pago.id}: $mapped');
              break;
            } else {
              // Otro error — marcar pago como error
              errors++;
              debugPrint('[SyncService] Error en pago ${pago.id}: $mapped');
            }
          } else {
            errors++;
            debugPrint('[SyncService] Error inesperado en pago ${pago.id}: $e');
          }
        }
      }

      // Limpiar datos viejos después del sync
      try {
        await _syncDao.limpiarDatosAntiguos();
      } catch (e) {
        debugPrint('[SyncService] Error al limpiar datos antiguos: $e');
      }

      final result = SyncResult(
        synced: synced,
        conflicts: conflicts,
        errors: errors,
      );

      _setStatus(result.allOk ? SyncStatus.success : SyncStatus.partial);
      _lastSyncResult = result;
      _resultController.add(result);

      debugPrint('[SyncService] Sync completado: '
          '$synced ok, $conflicts conflictos, $errors errores');

      return result;
    } catch (e) {
      debugPrint('[SyncService] Error en sync: $e');
      _setStatus(SyncStatus.networkError);
      return const SyncResult(synced: 0, conflicts: 0, errors: 1);
    } finally {
      _isSyncing = false;
    }
  }

  void _setStatus(SyncStatus status) {
    _status = status;
    _statusController.add(status);
  }

  /// Libera recursos.
  void dispose() {
    _connectivitySub?.cancel();
    _statusController.close();
    _resultController.close();
    _instance = null;
  }
}
