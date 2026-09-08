import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:uuid/uuid.dart';
import '../../core/database/app_database.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exceptions.dart';
import '../../core/network/local_cache_repository.dart';
import '../../core/sync/connectivity_detector.dart';
import 'models/cartera_models.dart';

class CarteraRepository {
  final ApiClient _api;
  final String? _role;
  final String? _residenteId;

  CarteraRepository({ApiClient? apiClient, this._role, this._residenteId})
      : _api = apiClient ?? ApiClient.instance;

  /// Unique cache key scoped to user role and residente ID.
  String get cacheKey => 'cartera:cobros:${_residenteId ?? _role ?? "all"}';

  /// Returns the correct cuotas endpoint based on user role.
  String get _cuotasEndpoint {
    if ((_role == 'PROPIETARIO' || _role == 'RESIDENTE') && _residenteId != null) {
      return '/cobros/residente/$_residenteId';
    }
    return '/cobros';
  }

  /// Calcula el resumen general de la cartera de forma local a partir de la lista de cobros.
  static CarteraResumen computeResumen(List<CobroItem> cobros) {
    double totalPendiente = 0;
    double totalMora = 0;
    double totalPagado = 0;
    
    int cantidadPendientes = 0;
    int cantidadMora = 0;
    int cantidadPagados = 0;

    for (var cobro in cobros) {
      final st = cobro.estado.toUpperCase();
      if (st == 'PAGADO' || st == 'PAGADA') {
        totalPagado += cobro.montoPagado;
        cantidadPagados++;
      } else if (st == 'MORA' || st == 'VENCIDA') {
        totalMora += cobro.saldo;
        totalPagado += cobro.montoPagado;
        cantidadMora++;
      } else {
        totalPendiente += cobro.saldo;
        totalPagado += cobro.montoPagado;
        cantidadPendientes++;
      }
    }

    return CarteraResumen(
      totalPendiente: totalPendiente,
      totalMora: totalMora,
      totalPagado: totalPagado,
      cantidadPendientes: cantidadPendientes,
      cantidadMora: cantidadMora,
      cantidadPagados: cantidadPagados,
    );
  }

  /// Compatibility method. Retrieves all cobros and computes the summary.
  Future<CarteraResumen> getCarteraResumen() async {
    final cobros = await getCobros();
    return computeResumen(cobros);
  }

  /// Fetches the raw list of cuotas from the server and parses them into [CobroItem].
  /// Compatible con ambos formatos: lista plana (legacy) y { data: [...], total } (paginado).
  Future<List<CobroItem>> getCobros() async {
    try {
      final response = await _api.get(_cuotasEndpoint);
      final dynamic raw = response.data;
      final List<dynamic> cuotas;
      if (raw is List<dynamic>) {
        cuotas = raw;
      } else if (raw is Map<String, dynamic> && raw['data'] is List<dynamic>) {
        cuotas = raw['data'] as List<dynamic>;
      } else {
        cuotas = const [];
      }

      return cuotas.map((c) => CobroItem.fromJson(c as Map<String, dynamic>)).toList();
    } catch (e) {
      final cached = LocalCacheRepository.instance.getCached(cacheKey);
      if (cached != null && cached is List) {
        return cached
            .map((json) => CobroItem.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      throw e is ApiException ? e : Exception('Error al cargar cobros: $e');
    }
  }

  /// Registra un pago.
  /// - Cobrador en móvil: Si no hay señal o se corta la red durante el proceso,
  ///   se salvaguarda en la cola local SQLite (Drift) con estado PENDIENTE_SYNC. Cero pérdida de datos.
  /// - Admin o Web: Opera 100% online; si no hay red, notifica error de conexión sin encolar en SQLite.
  Future<Map<String, dynamic>> registrarPago({
    required String residenteId,
    required int montoCentavos,
    String? cobroId,
    String? cobradorId,
    String? tenantId,
    bool isCobrador = false,
  }) async {
    // UUID: garantiza unicidad incluso para dos pagos del mismo residente
    // en el mismo milisegundo (el timestamp + prefijo podía colisionar).
    final clientPaymentId = 'pay-${const Uuid().v4()}';
    final isOnline = ConnectivityDetector.isCurrentOnline;

    // Caso 1: Cobrador en Móvil sin conexión -> Encolar de inmediato en SQLite local
    if (isCobrador && !kIsWeb && !isOnline) {
      return _guardarPagoEnColaLocal(
        clientPaymentId: clientPaymentId,
        residenteId: residenteId,
        montoCentavos: montoCentavos,
        cobroId: cobroId,
        cobradorId: cobradorId,
        tenantId: tenantId,
      );
    }

    // Caso 2: Intento Online (Cobrador con conexión, o Admin/Residente siempre online)
    try {
      final response = await _api.post('/pagos', data: {
        'clientPaymentId': clientPaymentId,
        'residenteId': residenteId,
        'monto': montoCentavos,
        'fechaPago': DateTime.now().toIso8601String(),
        if (cobroId != null && cobroId.isNotEmpty) 'cobroId': cobroId,
        if (cobradorId != null && cobradorId.isNotEmpty) 'cobradorId': cobradorId,
      });

      _invalidarCaches();
      return response.data as Map<String, dynamic>;
    } catch (e) {
      // Caso 3: Fallo de red en Cobrador mientras transmitía en terreno
      // Garantía de CERO pérdida de datos: salvaguardar en SQLite local
      if (isCobrador && !kIsWeb) {
        return _guardarPagoEnColaLocal(
          clientPaymentId: clientPaymentId,
          residenteId: residenteId,
          montoCentavos: montoCentavos,
          cobroId: cobroId,
          cobradorId: cobradorId,
          tenantId: tenantId,
          isFallback: true,
        );
      }

      // Para Admin o Web, propagar el error claro de red sin tocar SQLite
      throw e is ApiException ? e : Exception('Error al registrar pago: $e');
    }
  }

  Future<Map<String, dynamic>> _guardarPagoEnColaLocal({
    required String clientPaymentId,
    required String residenteId,
    required int montoCentavos,
    String? cobroId,
    String? cobradorId,
    String? tenantId,
    bool isFallback = false,
  }) async {
    try {
      final db = AppDatabase.instance;
      await db.pagoDao.insertOffline(
        PagosCompanion.insert(
          id: clientPaymentId,
          clientPaymentId: clientPaymentId,
          tenantId: tenantId ?? 'default',
          cobroId: drift.Value(cobroId),
          monto: montoCentavos,
          fechaPago: DateTime.now().toIso8601String(),
          cobradorId: cobradorId ?? '',
          residenteId: residenteId,
          syncStatus: 'PENDIENTE_SYNC',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      _invalidarCaches();

      return {
        'offline': true,
        'clientPaymentId': clientPaymentId,
        'status': isFallback ? 'OFFLINE_FALLBACK' : 'OFFLINE_QUEUED',
        'message': isFallback
            ? 'Conexión inestable. El recaudo fue salvaguardado de forma segura en la cola local.'
            : 'Recaudo guardado en la cola local sin conexión. Se sincronizará automáticamente.',
      };
    } catch (dbError) {
      throw Exception('Fallo crítico al guardar pago en cola local: $dbError');
    }
  }

  void _invalidarCaches() {
    LocalCacheRepository.instance.invalidate('dashboard:cobrador');
    LocalCacheRepository.instance.invalidate('cobrador:viviendas');
    LocalCacheRepository.instance.invalidate('dashboard:residente');
    LocalCacheRepository.instance.invalidate('dashboard:administrador');
    LocalCacheRepository.instance.invalidate(cacheKey);
  }
}
