import '../../core/network/api_client.dart';
import '../../core/network/api_exceptions.dart';
import '../residentes/comunidad_repository.dart';
import '../../shared/widgets/solicitud_card.dart';

class SolicitudesRepository {
  final ApiClient _api;

  SolicitudesRepository({ApiClient? apiClient})
      : _api = apiClient ?? ApiClient.instance;

  Future<List<SolicitudData>> getSolicitudes() async {
    try {
      final tenantId = ComunidadRepository.currentTenantId;
      final response = await _api.get('/solicitudes/admin', queryParameters: {
        'tenantId': tenantId,
      });
      return (response.data as List).map((json) => _mapToSolicitudData(json)).toList();
    } catch (e) {
      throw e is ApiException ? e : Exception('Error al cargar solicitudes: $e');
    }
  }

  Future<List<SolicitudData>> getSolicitudesPendientes() async {
    try {
      final response = await _api.get('/solicitudes/pendientes');
      return (response.data as List).map((json) => _mapToSolicitudData(json)).toList();
    } catch (e) {
      throw e is ApiException ? e : Exception('Error al cargar solicitudes pendientes: $e');
    }
  }

  Future<void> crearSolicitud({
    required String cobroId,
    required String tipo,
    required String descripcion,
    required String propietarioId,
  }) async {
    try {
      // propietarioId is implied via CurrentUser in the backend for residents,
      // but if an admin creates it for a resident, they might need an admin route.
      // Assuming this is used properly by the backend
      await _api.post('/solicitudes', data: {
        'cobroId': cobroId,
        'tipo': tipo,
        'descripcion': descripcion,
        // Backend handles tenantId and userId (propietarioId)
      });
    } catch (e) {
      throw e is ApiException ? e : Exception('Error al crear solicitud: $e');
    }
  }

  SolicitudData _mapToSolicitudData(Map<String, dynamic> json) {
    final estadoStr = (json['estado'] as String?) ?? 'PENDIENTE';
    final estado = switch (estadoStr.toUpperCase()) {
      'PENDIENTE' => SolicitudEstado.pendiente,
      'EN_REVISION' => SolicitudEstado.enRevision,
      'RESUELTA' => SolicitudEstado.resuelta,
      'RECHAZADA' => SolicitudEstado.rechazada,
      _ => SolicitudEstado.enRevision,
    };

    return SolicitudData(
      id: json['id'] as String,
      cobroId: json['cobroId'] as String? ?? '',
      nroRecibo: json['nroRecibo'] as String? ?? 'TK-000000',
      tipo: json['tipo'] as String,
      descripcion: json['descripcion'] as String,
      estado: estado,
      fecha: DateTime.parse((json['fecha'] ?? json['createdAt']) as String),
      respuesta: json['respuesta'] as String?,
      propietarioId: json['usuarioId'] as String?,
      propietarioNombre: (json['usuario']?['nombre']) as String?,
    );
  }

  /// Resolve or reject a solicitud (admin only).
  Future<void> resolverSolicitud({
    required String id,
    required String estado,
    required String respuesta,
  }) async {
    try {
      await _api.patch('/solicitudes/$id/resolver', data: {
        'estado': estado,
        'respuesta': respuesta,
      });
    } catch (e) {
      throw e is ApiException ? e : Exception('Error al resolver solicitud: $e');
    }
  }
}
