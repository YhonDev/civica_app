import '../../core/network/api_client.dart';

class ReporteData {
  final int mes;
  final int anio;
  final int totalRecaudado;
  final int totalPendiente;
  final int totalVencido;
  final int meta;
  final int porcentaje;
  final int pagadasCount;
  final int pendientesCount;
  final int vencidasCount;

  ReporteData({
    required this.mes,
    required this.anio,
    required this.totalRecaudado,
    required this.totalPendiente,
    required this.totalVencido,
    required this.meta,
    required this.porcentaje,
    required this.pagadasCount,
    required this.pendientesCount,
    required this.vencidasCount,
  });

  factory ReporteData.fromJson(Map<String, dynamic> json) {
    final desglose = json['desglosePorEstado'] as Map<String, dynamic>? ?? {};
    return ReporteData(
      mes: json['mes'] ?? DateTime.now().month,
      anio: json['anio'] ?? DateTime.now().year,
      totalRecaudado: (json['totalRecaudado'] as num?)?.toInt() ?? 0,
      totalPendiente: (json['totalPendiente'] as num?)?.toInt() ?? 0,
      totalVencido: (json['totalVencido'] as num?)?.toInt() ?? 0,
      meta: (json['meta'] as num?)?.toInt() ?? 0,
      porcentaje: (json['porcentaje'] as num?)?.toInt() ?? 0,
      pagadasCount: (desglose['pagadasCount'] as num?)?.toInt() ?? 0,
      pendientesCount: (desglose['pendientesCount'] as num?)?.toInt() ?? 0,
      vencidasCount: (desglose['vencidasCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class ReportesRepository {
  final ApiClient _apiClient;

  ReportesRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient.instance;

  Future<ReporteData> getReporteRecaudo({int? mes, int? anio}) async {
    final m = mes ?? DateTime.now().month;
    final a = anio ?? DateTime.now().year;
    final response = await _apiClient.get('/reportes/recaudo?mes=$m&anio=$a');
    return ReporteData.fromJson(response.data as Map<String, dynamic>);
  }
}
