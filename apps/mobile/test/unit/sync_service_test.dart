import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:civica_pago_mobile/core/network/api_client.dart';
import 'package:civica_pago_mobile/core/database/app_database.dart';
import 'package:civica_pago_mobile/core/database/daos/pago_dao.dart';
import 'package:civica_pago_mobile/core/database/daos/sync_dao.dart';
import 'package:civica_pago_mobile/core/sync/connectivity_detector.dart';
import 'package:civica_pago_mobile/core/sync/sync_service.dart';

// ═══════════════════════════════════════════════════════════════
// Mock ConnectivityDetector
// ═══════════════════════════════════════════════════════════════

class MockDetector implements ConnectivityDetector {
  bool _isOnline = true;

  @override
  bool get isOnline => _isOnline;

  final _statusController = StreamController<bool>.broadcast();

  @override
  Stream<bool> get onStatusChanged => _statusController.stream;

  void setOnline(bool online) {
    _isOnline = online;
    _statusController.add(online);
  }

  @override
  void dispose() {
    _statusController.close();
  }
}

// ═══════════════════════════════════════════════════════════════
// Tests
// ═══════════════════════════════════════════════════════════════

void main() {
  late AppDatabase db;
  late PagoDao pagoDao;
  late SyncDao syncDao;
  late MockDetector mockDetector;

  /// Cola de factories que producen Future<Response>.
  /// Cada factory puede retornar un valor o lanzar un error.
  final responseQueue = <Future<Response<Map<String, dynamic>>> Function()>[];

  /// Callback syncPayment que consume la cola de factories.
  Future<Response<Map<String, dynamic>>> mockSyncPayment(
      Map<String, dynamic> data) async {
    if (responseQueue.isEmpty) {
      throw Exception('No hay más respuestas mockeadas en la cola');
    }
    final fn = responseQueue.removeAt(0);
    return fn();
  }

  void queueSuccess({String? serverId}) {
    responseQueue.add(() => Future.value(Response(
          requestOptions: RequestOptions(path: '/pagos'),
          statusCode: 201,
          data: serverId != null ? {'id': serverId} : <String, dynamic>{},
        )));
  }

  void queueConflict({String? serverId}) {
    responseQueue.add(() async {
      throw DioException(
        requestOptions: RequestOptions(path: '/pagos'),
        response: Response(
          requestOptions: RequestOptions(path: '/pagos'),
          statusCode: 409,
          data: {
            'message': 'Conflicto',
            'serverId': ?serverId,
          },
        ),
        type: DioExceptionType.badResponse,
      );
    });
  }

  void queueNetworkError() {
    responseQueue.add(() async {
      throw DioException(
        requestOptions: RequestOptions(path: '/pagos'),
        type: DioExceptionType.connectionError,
        message: 'No internet',
      );
    });
  }

  void queueAuthError() {
    responseQueue.add(() async {
      throw DioException(
        requestOptions: RequestOptions(path: '/pagos'),
        response: Response(
          requestOptions: RequestOptions(path: '/pagos'),
          statusCode: 401,
          data: {'message': 'No autorizado'},
        ),
        type: DioExceptionType.badResponse,
      );
    });
  }

  /// Helper: inserta un pago offline pendiente de sync.
  Future<String> insertarPagoPendiente({
    String? id,
    int monto = 50000,
  }) async {
    final now = DateTime.now();
    final pagoId = id ?? 'PAG_${now.microsecondsSinceEpoch}';
    await pagoDao.insertOffline(PagosCompanion.insert(
      id: pagoId,
      clientPaymentId: '${pagoId}_client',
      tenantId: 't1',
      monto: monto,
      fechaPago: now.toIso8601String(),
      cobradorId: 'COB_1',
      residenteId: 'PRO_1',
      syncStatus: 'PENDIENTE_SYNC',
      createdAt: now,
      updatedAt: now,
    ));
    return pagoId;
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    ApiClient.init(baseUrl: 'http://localhost:3000');

    db = AppDatabase.forTesting(NativeDatabase.memory());
    AppDatabase.setTestingInstance(db);

    pagoDao = PagoDao(db);
    syncDao = SyncDao(db);
    mockDetector = MockDetector();
    responseQueue.clear();
  });

  tearDown(() async {
    await AppDatabase.reset();
  });

  // ──────────────────────────────────────────────────────────
  // Estado inicial
  // ──────────────────────────────────────────────────────────

  group('requestSync()', () {
    test('debe sincronizar pago pendiente exitosamente', () async {
      final syncService = SyncService.forTesting(
        detector: mockDetector,
        pagoDao: pagoDao,
        syncDao: syncDao,
        syncPayment: mockSyncPayment,
      );

      await insertarPagoPendiente(id: 'PAG_OK');
      queueSuccess(serverId: 'SRV_1');

      final result = await syncService.requestSync();

      expect(result, isNotNull);
      expect(result!.synced, 1);
      expect(result.errors, 0);
      expect(result.conflicts, 0);
      expect(syncService.status, SyncStatus.success);

      final pendientes = await pagoDao.getPendientesSync();
      expect(pendientes, isEmpty);

      syncService.dispose();
    });

    test('debe retornar null si no hay conexión', () async {
      final syncService = SyncService.forTesting(
        detector: mockDetector,
        pagoDao: pagoDao,
        syncDao: syncDao,
        syncPayment: mockSyncPayment,
      );

      mockDetector.setOnline(false);

      final result = await syncService.requestSync();
      expect(result, isNull);
      expect(syncService.status, SyncStatus.networkError);

      syncService.dispose();
    });

    test('debe retornar SyncResult(0,0,0) si no hay pagos pendientes',
        () async {
      final syncService = SyncService.forTesting(
        detector: mockDetector,
        pagoDao: pagoDao,
        syncDao: syncDao,
        syncPayment: mockSyncPayment,
      );

      final result = await syncService.requestSync();

      expect(result, isNotNull);
      expect(result!.synced, 0);
      expect(result.conflicts, 0);
      expect(result.errors, 0);
      expect(syncService.status, SyncStatus.success);

      syncService.dispose();
    });

    test('debe retornar null si ya hay un sync en curso', () async {
      final syncService = SyncService.forTesting(
        detector: mockDetector,
        pagoDao: pagoDao,
        syncDao: syncDao,
        syncPayment: mockSyncPayment,
      );

      await insertarPagoPendiente(id: 'PAG_DEDUP');
      queueSuccess(serverId: 'SRV_1');

      final future1 = syncService.requestSync();
      final result2 = await syncService.requestSync();
      expect(result2, isNull);

      await future1;
      syncService.dispose();
    });
  });

  // ──────────────────────────────────────────────────────────
  // Múltiples pagos
  // ──────────────────────────────────────────────────────────

  group('Múltiples pagos', () {
    test('debe sincronizar 3 pagos en orden FIFO', () async {
      final syncService = SyncService.forTesting(
        detector: mockDetector,
        pagoDao: pagoDao,
        syncDao: syncDao,
        syncPayment: mockSyncPayment,
      );

      await insertarPagoPendiente(id: 'PAG_1', monto: 10000);
      await insertarPagoPendiente(id: 'PAG_2', monto: 20000);
      await insertarPagoPendiente(id: 'PAG_3', monto: 30000);

      queueSuccess(serverId: 'SRV_1');
      queueSuccess(serverId: 'SRV_2');
      queueSuccess(serverId: 'SRV_3');

      final result = await syncService.requestSync();

      expect(result!.synced, 3);
      expect(result.errors, 0);
      expect(result.conflicts, 0);

      syncService.dispose();
    });
  });

  // ──────────────────────────────────────────────────────────
  // Manejo de errores — usar SyncService separado por test
  // ──────────────────────────────────────────────────────────

  group('Manejo de errores', () {
    test('debe manejar conflicto 409 y marcar como conflicto', () async {
      final syncService = SyncService.forTesting(
        detector: mockDetector,
        pagoDao: pagoDao,
        syncDao: syncDao,
        syncPayment: mockSyncPayment,
      );

      await insertarPagoPendiente(id: 'PAG_CONF');
      queueConflict(serverId: 'SRV_CONF');

      final result = await syncService.requestSync();

      expect(result!.conflicts, 1);
      expect(result.synced, 0);
      expect(result.errors, 0);
      expect(syncService.status, SyncStatus.conflicto);

      final pendientes = await pagoDao.getPendientesSync();
      expect(pendientes, isEmpty);

      final conflictos = await pagoDao.getEnConflicto();
      expect(conflictos.length, 1);
      expect(conflictos.first.id, 'PAG_CONF');
      expect(conflictos.first.syncStatus, 'CONFLICTO');

      syncService.dispose();
    });

    test('debe continuar procesando cola tras error de red en pago anterior',
        () async {
      final syncService = SyncService.forTesting(
        detector: mockDetector,
        pagoDao: pagoDao,
        syncDao: syncDao,
        syncPayment: mockSyncPayment,
      );

      await insertarPagoPendiente(id: 'PAG_OK_1', monto: 10000);
      await insertarPagoPendiente(id: 'PAG_NET_ERR', monto: 20000);
      await insertarPagoPendiente(id: 'PAG_OK_2', monto: 30000);

      queueSuccess(serverId: 'SRV_OK_1');
      queueNetworkError();
      queueSuccess(serverId: 'SRV_OK_2');

      final result = await syncService.requestSync();

      expect(result!.synced, 2);
      expect(result.errors, 1);
      expect(syncService.status, SyncStatus.partial);

      final pendientes = await pagoDao.getPendientesSync();
      expect(pendientes.length, 1);
      expect(pendientes.first.id, 'PAG_NET_ERR');

      syncService.dispose();
    });

    test('debe detener sync en error de red y dejar pagos pendientes',
        () async {
      final syncService = SyncService.forTesting(
        detector: mockDetector,
        pagoDao: pagoDao,
        syncDao: syncDao,
        syncPayment: mockSyncPayment,
      );

      await insertarPagoPendiente(id: 'PAG_OK_1', monto: 10000);
      await insertarPagoPendiente(id: 'PAG_NET_ERR', monto: 20000);

      queueSuccess(serverId: 'SRV_OK');
      queueNetworkError();

      final result = await syncService.requestSync();

      expect(result!.synced, 1);
      expect(result.errors, 1);
      expect(syncService.status, SyncStatus.partial);

      final pendientes = await pagoDao.getPendientesSync();
      expect(pendientes.length, 1);
      expect(pendientes.first.id, 'PAG_NET_ERR');

      syncService.dispose();
    });

    test('debe detener sync en error de autenticación', () async {
      final syncService = SyncService.forTesting(
        detector: mockDetector,
        pagoDao: pagoDao,
        syncDao: syncDao,
        syncPayment: mockSyncPayment,
      );

      await insertarPagoPendiente(id: 'PAG_AUTH');
      queueAuthError();

      final result = await syncService.requestSync();

      expect(result!.errors, 1);
      expect(result.synced, 0);
      expect(syncService.status, SyncStatus.partial);

      syncService.dispose();
    });
  });

  // ──────────────────────────────────────────────────────────
  // Auto-sync al reconectar
  // ──────────────────────────────────────────────────────────

  group('Auto-sync al reconectar', () {
    test('debe sincronizar automáticamente al reconectar', () async {
      final syncService = SyncService.forTesting(
        detector: mockDetector,
        pagoDao: pagoDao,
        syncDao: syncDao,
        syncPayment: mockSyncPayment,
      );

      await insertarPagoPendiente(id: 'PAG_RECON');
      queueSuccess(serverId: 'SRV_RECON');

      mockDetector.setOnline(true);
      await Future.delayed(const Duration(milliseconds: 150));

      final pendientes = await pagoDao.getPendientesSync();
      expect(pendientes, isEmpty);

      syncService.dispose();
    });
  });

  // ──────────────────────────────────────────────────────────
  // Streams de resultado
  // ──────────────────────────────────────────────────────────

  group('Streams de resultado', () {
    test('onSyncResult debe emitir resultado tras sync exitoso', () async {
      final syncService = SyncService.forTesting(
        detector: mockDetector,
        pagoDao: pagoDao,
        syncDao: syncDao,
        syncPayment: mockSyncPayment,
      );

      await insertarPagoPendiente(id: 'PAG_STREAM');
      queueSuccess(serverId: 'SRV_STREAM');

      final results = <SyncResult>[];
      final sub = syncService.onSyncResult.listen(results.add);

      await syncService.requestSync();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(results.length, 1);
      expect(results.first.synced, 1);
      expect(results.first.allOk, true);

      await sub.cancel();
      syncService.dispose();
    });

    test('lastSyncResult debe actualizarse tras sync exitoso', () async {
      final syncService = SyncService.forTesting(
        detector: mockDetector,
        pagoDao: pagoDao,
        syncDao: syncDao,
        syncPayment: mockSyncPayment,
      );

      await insertarPagoPendiente(id: 'PAG_LAST');
      queueSuccess(serverId: 'SRV_LAST');

      await syncService.requestSync();

      expect(syncService.lastSyncResult, isNotNull);
      expect(syncService.lastSyncResult!.synced, 1);

      syncService.dispose();
    });
  });
}
