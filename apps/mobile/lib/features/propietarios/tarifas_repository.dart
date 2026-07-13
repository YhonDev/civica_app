import '../../core/network/api_client.dart';
import '../../core/network/api_exceptions.dart';

class TarifasRepository {
  final ApiClient _api = ApiClient.instance;

  Future<Map<String, dynamic>> getTarifasVigentes(String conjuntoId) async {
    try {
      final response = await _api.get('/tarifas/vigentes', queryParameters: {
        'conjuntoId': conjuntoId,
      });
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw e is ApiException ? e : Exception('Error al cargar tarifas: $e');
    }
  }

  Future<Map<String, dynamic>> actualizarTarifa(String id, int montoPesos) async {
    try {
      final response = await _api.patch('/tarifas/$id', data: {
        'monto': montoPesos,
      });
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw e is ApiException ? e : Exception('Error al actualizar tarifa: $e');
    }
  }
}
