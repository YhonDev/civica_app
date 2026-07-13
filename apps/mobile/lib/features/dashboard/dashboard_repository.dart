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

      final data = response.data;
      final resumen = data['resumen'];
      final estadoCobros = data['estadoCobros'];

      // Obtener total de propietarios
      int totalPropietarios = 0;
      try {
        final propsResp = await _api.get('/propietarios', queryParameters: {'tenantId': tenantId});
        totalPropietarios = (propsResp.data as List).length;
      } catch (_) {
        // Ignorar si falla, total 0
      }

      final recaudoMes = (resumen['recaudoTotal'] ?? 0) / 100.0;
      final metaMensual = (resumen['metaMensual'] ?? 0) / 100.0;
      final mora = (resumen['moraTotal'] ?? 0) / 100.0;
      final porcentaje = resumen['porcentajeMeta'] ?? 0.0;
      
      final pagaron = resumen['pagaron'] ?? 0;
      final pendientes = resumen['pendientes'] ?? 0;

      final acumuladoAnual = (data['acumuladoAnual'] ?? 0) / 100.0;
      final metaAnual = (data['metaAnual'] ?? 0) / 100.0;
      final List<MesHistorico> historialMeses = (data['historialMeses'] as List<dynamic>? ?? [])
          .map((e) => MesHistorico.fromJson(e as Map<String, dynamic>))
          .toList();

      return DashboardData(
        mes: data['mes'] ?? mes,
        anio: data['anio'] ?? anio,
        recaudoMes: recaudoMes,
        metaMensual: metaMensual,
        pagaron: pagaron,
        pendientes: pendientes,
        mora: mora,
        porcentaje: porcentaje.toDouble(),
        evolucion: (data['evolucion'] as List<dynamic>? ?? []).map((e) => 
          EvolucionPunto(dia: e['dia'].toString(), valor: (e['valor'] ?? 0) / 100.0)
        ).toList(),
        modalidades: (data['modalidades'] as List<dynamic>? ?? []).map((m) => 
          ModalidadItem(nombre: m['frecuencia'], porcentaje: (m['porcentaje'] ?? 0).toDouble(), valor: (m['montoRecaudo'] ?? 0) / 100.0)
        ).toList(),
        estadosCobro: [
          CobroEstadoItem(estado: 'Pagados', porcentaje: (estadoCobros['pagados'] ?? 0).toDouble(), cantidad: pagaron),
          CobroEstadoItem(estado: 'Pendientes', porcentaje: (estadoCobros['pendientes'] ?? 0).toDouble(), cantidad: pendientes),
          CobroEstadoItem(estado: 'En mora', porcentaje: (100 - ((estadoCobros['pagados']??0) + (estadoCobros['pendientes']??0))).toDouble(), cantidad: data['propietariosMora'] ?? 0),
        ],
        actividadReciente: (data['actividad'] as List<dynamic>? ?? [])
            .map((a) => ActividadItem.fromJson(a as Map<String, dynamic>))
            .toList(),
        totalPropietarios: totalPropietarios,
        nuevosPropietariosSemana: data['nuevosPropietariosSemana'] ?? 0,
        solicitudesPendientes: data['solicitudesPendientes'] ?? 0,
        propietariosMora: data['propietariosMora'] ?? 0,
        pagosRevision: estadoCobros['revision'] ?? 0,
        cobrosPorSemana: (data['cobrosPorSemana'] as List<dynamic>? ?? [])
            .map((s) => CobroSemanaItem(
                semana: s['semana'] as int? ?? 1,
                pagados: s['pagados'] as int? ?? 0,
                pendientes: s['pendientes'] as int? ?? 0,
                mora: s['mora'] as int? ?? 0,
            )).toList(),
        acumuladoAnual: acumuladoAnual,
        metaAnual: metaAnual,
        historialMeses: historialMeses,
      );
    } catch (e) {
      throw e is ApiException ? e : Exception('Error al cargar dashboard: $e');
    }
  }

}
