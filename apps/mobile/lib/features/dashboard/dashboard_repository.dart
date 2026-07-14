import '../../core/network/api_client.dart';
import '../../core/network/api_exceptions.dart';
import '../propietarios/comunidad_repository.dart';
import 'models/dashboard_data.dart';

class DashboardRepository {
  final ApiClient _api;

  DashboardRepository({ApiClient? apiClient})
      : _api = apiClient ?? ApiClient.instance;

  Future<DashboardData> getDashboard(int mes, int anio) async {
    try {
      final tenantId = ComunidadRepository.currentTenantId;

      // Llamada principal al backend NestJS
      final response = await _api.get('/dashboard/administrador', queryParameters: {
        'mes': mes,
        'anio': anio,
        'tenantId': tenantId,
      });

      // Obtener total de propietarios (dato no incluido en el dashboard endpoint)
      int totalPropietarios = 0;
      try {
        final propsResp = await _api.get('/propietarios', queryParameters: {'tenantId': tenantId});
        totalPropietarios = (propsResp.data as List).length;
      } catch (_) {
        // Ignorar si falla, total 0
      }

      return DashboardData.fromJson(
        response.data as Map<String, dynamic>,
        totalPropietariosOverride: totalPropietarios,
      );
    } catch (e) {
      throw e is ApiException ? e : Exception('Error al cargar dashboard: $e');
    }
  }

}
