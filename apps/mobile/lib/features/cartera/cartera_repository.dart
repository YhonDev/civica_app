import '../../core/network/api_client.dart';
import '../../core/network/api_exceptions.dart';
import '../propietarios/comunidad_repository.dart';
import 'models/cartera_models.dart';

class CarteraRepository {
  final ApiClient _api = ApiClient.instance;

  /// Devuelve el resumen general de la cartera.
  Future<CarteraResumen> getCarteraResumen() async {
    try {
      final tenantId = ComunidadRepository.currentTenantId;

      final response = await _api.get('/cuotas', queryParameters: {
        'tenantId': tenantId,
      });
      final cuotas = response.data as List<dynamic>;

    double totalPendiente = 0;
    double totalMora = 0;
    double totalPagado = 0;
    
    int cantidadPendientes = 0;
    int cantidadMora = 0;
    int cantidadPagados = 0;

      for (var cuota in cuotas) {
        final estado = cuota['estado'];
        final double monto = (cuota['monto'] ?? 0) / 100.0;
        final double pagado = (cuota['montoPagado'] ?? 0) / 100.0;
        final double restante = monto - pagado;

        if (estado == 'PAGADA') {
          totalPagado += pagado;
          cantidadPagados++;
        } else if (estado == 'VENCIDA') {
          totalMora += restante;
          totalPagado += pagado;
          cantidadMora++;
        } else if (estado == 'PENDIENTE') {
          totalPendiente += restante;
          totalPagado += pagado;
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
    } catch (e) {
      throw e is ApiException ? e : Exception('Error al cargar resumen cartera: $e');
    }
  }

  /// Devuelve la lista detallada de cobros.
  Future<List<CobroItem>> getCobros() async {
    try {
      final tenantId = ComunidadRepository.currentTenantId;

      final response = await _api.get('/cuotas', queryParameters: {
        'tenantId': tenantId,
      });
      final cuotas = response.data as List<dynamic>;

      final List<CobroItem> cobros = [];

      for (var c in cuotas) {
        final estadoDb = c['estado'];
        String estadoUi = 'Pendiente';
        if (estadoDb == 'PAGADA') estadoUi = 'Pagado';
        if (estadoDb == 'VENCIDA') estadoUi = 'Mora';

        final double monto = (c['monto'] ?? 0) / 100.0;
        final double pagado = (c['montoPagado'] ?? 0) / 100.0;
        final double saldo = monto - pagado;

        final propietario = c['propietario'];
        String nombre = propietario?['nombre'] ?? 'Desconocido';
        
        String casaNombre = 'Sin casa';
        String etapaNombre = 'Sin etapa';

        final tenencias = propietario?['tenencias'] as List<dynamic>? ?? [];
        if (tenencias.isNotEmpty) {
          final casa = tenencias.first['casa'];
          if (casa != null) {
            casaNombre = casa['direccionInterna'] ?? 'Sin casa';
            final manzana = casa['manzana'];
            if (manzana != null) {
              final etapa = manzana['etapa'];
              if (etapa != null) {
                etapaNombre = etapa['nombre'] ?? 'Sin etapa';
              }
            }
          }
        }

        final propId = propietario?['id'] as String? ?? '';

        cobros.add(
          CobroItem(
            id: c['id'].toString(),
            propietarioId: propId,
            nombre: nombre,
            casa: casaNombre,
            etapa: etapaNombre,
            saldo: saldo,
            estado: estadoUi,
            modalidad: 'Mensual', // Por ahora fijo
          ),
        );
      }

      return cobros;
    } catch (e) {
      throw e is ApiException ? e : Exception('Error al cargar cobros: $e');
    }
  }

  /// Register a payment online via POST /pagos.
  Future<Map<String, dynamic>> registrarPago({
    required String propietarioId,
    required int montoCentavos,
  }) async {
    try {
      final clientPaymentId = 'online-${DateTime.now().millisecondsSinceEpoch}';
      final response = await _api.post('/pagos', data: {
        'clientPaymentId': clientPaymentId,
        'propietarioId': propietarioId,
        'monto': montoCentavos,
        'fechaPago': DateTime.now().toIso8601String(),
      });
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw e is ApiException ? e : Exception('Error al registrar pago: $e');
    }
  }
}
