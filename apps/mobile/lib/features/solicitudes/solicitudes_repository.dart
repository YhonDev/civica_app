import '../../core/network/api_client.dart';
import '../../shared/widgets/solicitud_card.dart';
import '../../shared/models/solicitudes_mock_store.dart';

class SolicitudesRepository {
  final ApiClient _apiClient;

  SolicitudesRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient.instance;

  Future<List<SolicitudData>> getSolicitudes() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return SolicitudesMockStore.all;
  }

  Future<List<SolicitudData>> getSolicitudesPendientes() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return SolicitudesMockStore.pending;
  }

  Future<void> crearSolicitud({
    required String cuotaId,
    required String tipo,
    required String descripcion,
  }) async {
    await _apiClient.post(
      '/solicitudes',
      data: {
        'cuotaId': cuotaId,
        'tipo': tipo,
        'descripcion': descripcion,
      },
    );
  }

  SolicitudData _mapToSolicitudData(Map<String, dynamic> json) {
    final estadoStr = json['estado'] as String;
    final estado = switch (estadoStr.toUpperCase()) {
      'PENDIENTE' => SolicitudEstado.pendiente,
      'EN_REVISION' => SolicitudEstado.enRevision,
      'RESUELTA' => SolicitudEstado.resuelta,
      'RECHAZADA' => SolicitudEstado.rechazada,
      _ => SolicitudEstado.enRevision,
    };

    return SolicitudData(
      id: json['id'] as String,
      cuotaId: json['cuotaId'] as String? ?? '',
      nroRecibo: json['nroRecibo'] as String? ?? 'TK-000000',
      tipo: json['tipo'] as String,
      descripcion: json['descripcion'] as String,
      estado: estado,
      fecha: DateTime.parse(json['fecha'] as String),
      respuesta: json['respuesta'] as String?,
    );
  }
}
