import '../../core/network/api_client.dart';
import '../../core/network/api_exceptions.dart';

class TarifasRepository {
  final ApiClient _api = ApiClient.instance;

  Future<Map<String, dynamic>> getTarifasVigentes(String proyectoId) async {
    try {
      final response = await _api.get('/tarifas/vigentes', queryParameters: {
        'proyectoId': proyectoId,
      });
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw e is ApiException ? e : Exception('Error al cargar tarifas: $e');
    }
  }

  Future<Map<String, dynamic>> crearTarifa({
    required String proyectoId,
    required String modalidad,
    required int montoPesos,
    String fechaVigencia = '2026-01-01',
  }) async {
    try {
      final response = await _api.post('/tarifas', data: {
        'proyectoId': proyectoId,
        'modalidad': modalidad,
        'monto': montoPesos,
        'fechaVigencia': fechaVigencia,
      });
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw e is ApiException ? e : Exception('Error al crear tarifa: $e');
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

  Future<void> desactivarTarifa(String id) async {
    try {
      await _api.delete('/tarifas/$id');
    } catch (e) {
      throw e is ApiException ? e : Exception('Error al eliminar tarifa: $e');
    }
  }
}
