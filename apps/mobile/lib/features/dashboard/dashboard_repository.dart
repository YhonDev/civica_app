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
      recaudoMes: 7800000,
      metaMensual: 10560000,
      pagaron: 65,
      pendientes: 17,
      mora: 720000,
      porcentaje: 73.9,
      evolucion: const [
        EvolucionPunto(dia: '01', valor: 1200000),
        EvolucionPunto(dia: '05', valor: 3500000),
        EvolucionPunto(dia: '10', valor: 5800000),
        EvolucionPunto(dia: '15', valor: 7800000),
      ],
      modalidades: const [
        ModalidadItem(nombre: 'Mensual', porcentaje: 65, valor: 5070000),
        ModalidadItem(nombre: 'Quincenal', porcentaje: 25, valor: 1950000),
        ModalidadItem(nombre: 'Semanal', porcentaje: 10, valor: 780000),
      ],
      estadosCobro: const [
        CobroEstadoItem(estado: 'Pagados', porcentaje: 73.9, cantidad: 65),
        CobroEstadoItem(estado: 'Pendientes', porcentaje: 19.3, cantidad: 17),
        CobroEstadoItem(estado: 'En mora', porcentaje: 6.8, cantidad: 6),
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
          hace: 'hace 1h',
        ),
        ActividadItem(
          id: 'A4',
          tipo: 'nuevo_propietario',
          descripcion: 'Se registró en la plataforma',
          usuario: 'Carlos Ruiz',
          timestamp: DateTime.now().subtract(const Duration(hours: 3)),
          hace: 'hace 3h',
        ),
      ],
      totalPropietarios: 257,
      nuevosPropietariosSemana: 3,
      solicitudesPendientes: 5,
      propietariosMora: 6,
      pagosRevision: 3,
      cobrosPorSemana: const [
        CobroSemanaItem(semana: 1, pagados: 25, pendientes: 5, mora: 2),
        CobroSemanaItem(semana: 2, pagados: 40, pendientes: 12, mora: 4),
      ],
    );
  }
}
