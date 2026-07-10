import '../../core/network/api_client.dart';
import '../../core/network/api_exceptions.dart';
import 'models/dashboard_data.dart';

/// Repository for fetching dashboard data from the API.
class DashboardRepository {
  final ApiClient _apiClient;

  DashboardRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient.instance;

  /// Fetches dashboard data for a given month and year.
  ///
  /// Calls GET /dashboard/administrador?mes=X&anio=Y
  /// and returns a [DashboardData] with all KPIs, charts, and activity.
  Future<DashboardData> getDashboard(int mes, int anio) async {
    // MOCK DATA for UI/UX testing
    await Future.delayed(const Duration(milliseconds: 600));
    
    return DashboardData(
      mes: mes,
      anio: anio,
      recaudoMes: 12580000,
      metaMensual: 15000000,
      pagaron: 184,
      pendientes: 42,
      mora: 2450000,
      porcentaje: 83.8,
      evolucion: const [
        EvolucionPunto(dia: '01', valor: 1200000),
        EvolucionPunto(dia: '05', valor: 3500000),
        EvolucionPunto(dia: '10', valor: 5800000),
        EvolucionPunto(dia: '15', valor: 8200000),
        EvolucionPunto(dia: '20', valor: 10500000),
        EvolucionPunto(dia: '25', valor: 11800000),
        EvolucionPunto(dia: '30', valor: 12580000),
      ],
      modalidades: const [
        ModalidadItem(nombre: 'Mensual', porcentaje: 65, valor: 8177000),
        ModalidadItem(nombre: 'Quincenal', porcentaje: 25, valor: 3145000),
        ModalidadItem(nombre: 'Semanal', porcentaje: 10, valor: 1258000),
      ],
      estadosCobro: const [
        CobroEstadoItem(estado: 'Pagados', porcentaje: 78, cantidad: 184),
        CobroEstadoItem(estado: 'Pendientes', porcentaje: 15, cantidad: 35),
        CobroEstadoItem(estado: 'En mora', porcentaje: 7, cantidad: 16),
      ],
      actividadReciente: [
        ActividadItem(
          id: 'A1',
          tipo: 'pago_registrado',
          descripcion: 'Pagó la cuota mensual',
          usuario: 'Juan Pérez',
          timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
          hace: 'hace 5 min',
        ),
        ActividadItem(
          id: 'A2',
          tipo: 'mora_generada',
          descripcion: 'Sistema detectó mora',
          usuario: 'Automatización',
          timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
          hace: 'hace 15 min',
        ),
        ActividadItem(
          id: 'A3',
          tipo: 'solicitud_revision',
          descripcion: 'Solicitó revisión de pago',
          usuario: 'María Gómez',
          timestamp: DateTime.now().subtract(const Duration(hours: 1)),
          hace: 'Ayer',
        ),
      ],
    );
  }
}
