import '../../core/network/api_client.dart';
import '../../core/network/api_exceptions.dart';
import '../../core/network/local_cache_repository.dart';
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

  /// Devuelve la lista detallada de cobros.
  Future<List<CobroItem>> getCobros() async {
    try {
      final response = await _api.get(_cuotasEndpoint);
      final cuotas = response.data as List<dynamic>;

      return cuotas.map((c) => CobroItem.fromJson(c as Map<String, dynamic>)).toList();
    } catch (e) {
      throw e is ApiException ? e : Exception('Error al cargar cobros: $e');
    }
  }

  /// Register a payment online via POST /pagos.
  Future<Map<String, dynamic>> registrarPago({
    required String residenteId,
    required int montoCentavos,
  }) async {
    try {
      final clientPaymentId = 'online-${DateTime.now().millisecondsSinceEpoch}';
      final response = await _api.post('/pagos', data: {
        'clientPaymentId': clientPaymentId,
        'residenteId': residenteId,
        'monto': montoCentavos,
        'fechaPago': DateTime.now().toIso8601String(),
      });
      LocalCacheRepository.instance.invalidate('dashboard:cobrador');
      LocalCacheRepository.instance.invalidate('cobrador:viviendas');
      LocalCacheRepository.instance.invalidate('dashboard:residente');
      LocalCacheRepository.instance.invalidate('dashboard:administrador');
      LocalCacheRepository.instance.invalidate(cacheKey);
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw e is ApiException ? e : Exception('Error al registrar pago: $e');
    }
  }
}
