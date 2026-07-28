import '../../core/network/api_client.dart';
import '../../core/network/api_exceptions.dart';
import 'models/cobradores_models.dart';

class CobradoresRepository {
  final ApiClient _api;

  CobradoresRepository({ApiClient? apiClient})
      : _api = apiClient ?? ApiClient.instance;

  Future<CobradorResumen> getResumen() async {
    try {
      final response = await _api.get('/usuarios');
      
      final total = (response.data as List).length;
      final activos = total;

      return CobradorResumen(
        totalCobradores: total,
        activos: activos,
        inactivos: total - activos,
      );
    } catch (e) {
      throw e is ApiException ? e : Exception('Error al cargar resumen de cobradores: $e');
    }
  }

  Future<List<CobradorItem>> getCobradores() async {
    try {
      final response = await _api.get('/usuarios');

      final List<CobradorItem> cobradores = [];
      
      for (var u in (response.data as List)) {
        final asignaciones = u['asignaciones'] as List<dynamic>? ?? [];
        final zonas = asignaciones
            .where((a) => a['etapa'] != null)
            .map((a) => a['etapa']['nombre'].toString())
            .toList();

        cobradores.add(
          CobradorItem(
            id: u['id'].toString(),
            nombre: u['nombre'] ?? 'Sin nombre',
            telefono: 'Sin teléfono',
            correo: u['email'] ?? '',
            username: u['email'],
            usuarioId: u['id'].toString(),
            zonas: zonas,
            activo: u['activo'] ?? true,
            pagosRegistradosSemana: 0,
          ),
        );
      }

      return cobradores;
    } catch (e) {
      throw e is ApiException ? e : Exception('Error al cargar cobradores: $e');
    }
  }
}
