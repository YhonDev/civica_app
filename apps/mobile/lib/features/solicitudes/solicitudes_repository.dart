import '../../core/network/api_client.dart';
import '../../core/network/api_exceptions.dart';
import '../../shared/widgets/solicitud_card.dart';

class SolicitudesRepository {
  final ApiClient _api;

  SolicitudesRepository({ApiClient? apiClient})
      : _api = apiClient ?? ApiClient.instance;

  Future<List<SolicitudData>> getSolicitudes() async {
    try {
      final response = await _api.get('/solicitudes/admin');
      return (response.data as List).map((json) => _mapToSolicitudData(json)).toList();
    } catch (e) {
      throw e is ApiException ? e : Exception('Error al cargar solicitudes: $e');
    }
  }

  Future<List<SolicitudData>> getMisSolicitudes() async {
    try {
      final response = await _api.get('/solicitudes');
      return (response.data as List).map((json) => _mapToSolicitudData(json as Map<String, dynamic>)).toList();
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
    String? pagoId,
    required String tipo,
    required String descripcion,
    String? residenteId,
  }) async {
    try {
      await _api.post('/solicitudes', data: {
        'cobroId': cobroId,
        'cuotaId': cobroId,
        'pagoId': ?pagoId,
        'tipo': tipo,
        'descripcion': descripcion,
      });
    } catch (e) {
      throw e is ApiException ? e : Exception('Error al crear solicitud: $e');
    }
  }

  SolicitudData _mapToSolicitudData(Map<String, dynamic> json) {
    final estadoStr = (json['estado'] as String?) ?? 'PENDIENTE';
    final estado = switch (estadoStr.toUpperCase()) {
      'PENDIENTE' => SolicitudEstado.pendiente,
      'EN_ESPERA' => SolicitudEstado.enEspera,
      'EN_CAMINO' => SolicitudEstado.enCamino,
      'COBRADA' => SolicitudEstado.cobrada,
      'EN_REVISION' => SolicitudEstado.enRevision,
      'RESUELTA' => SolicitudEstado.resuelta,
      'APROBADA' => SolicitudEstado.aprobada,
      'RECHAZADA' => SolicitudEstado.rechazada,
      'VENCIDA' => SolicitudEstado.vencida,
      _ => SolicitudEstado.enEspera,
    };

    final cobroMap = json['cobro'] as Map<String, dynamic>?;
    final cuotaConcepto = cobroMap?['concepto'] as String?;

    return SolicitudData(
      id: json['id'] as String,
      cobroId: json['cobroId'] as String? ?? '',
      pagoId: json['pagoId'] as String?,
      nroRecibo: json['nroRecibo'] as String? ?? 'TK-000000',
      tipo: json['tipo'] as String,
      descripcion: json['descripcion'] as String,
      estado: estado,
      fecha: (DateTime.tryParse((json['fecha'] ?? json['createdAt'])?.toString() ?? '') ?? DateTime.now()).toLocal(),
      respuesta: json['respuesta'] as String?,
      residenteId: json['usuarioId'] as String?,
      residenteNombre: (json['usuario']?['nombre']) as String?,
      cuotaConcepto: cuotaConcepto,
    );
  }

  /// Mark a collection request as "en camino" (cobrador on the way).
  Future<void> marcarEnCamino(String id) async {
    try {
      await _api.patch('/solicitudes/$id/en-camino');
    } catch (e) {
      throw e is ApiException ? e : Exception('Error al actualizar a en camino: $e');
    }
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

  /// Fetch full resolution details (associated cobro, pago, ticket) for admin review.
  Future<Map<String, dynamic>> getDetalleResolucion(String id) async {
    try {
      final response = await _api.get('/solicitudes/$id/detalle-resolucion');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw e is ApiException ? e : Exception('Error al obtener detalle de resolución: $e');
    }
  }

  /// Correct associated payment amount and resolve solicitud (admin only).
  Future<void> corregirPagoDesdeSolicitud({
    required String id,
    required int nuevoMonto,
    required String motivo,
  }) async {
    try {
      await _api.patch('/solicitudes/$id/corregir-pago', data: {
        'nuevoMonto': nuevoMonto,
        'motivo': motivo,
      });
    } catch (e) {
      throw e is ApiException ? e : Exception('Error al corregir pago: $e');
    }
  }

  /// Revert associated payment, reset cuota to PENDIENTE/VENCIDA, annul ticket, and resolve solicitud (admin only).
  Future<void> revertirPagoDesdeSolicitud({
    required String id,
    required String motivo,
  }) async {
    try {
      await _api.patch('/solicitudes/$id/revertir-pago', data: {
        'motivo': motivo,
      });
    } catch (e) {
      throw e is ApiException ? e : Exception('Error al revertir pago: $e');
    }
  }

  /// Delete or cancel a solicitud.
  Future<void> eliminarSolicitud(String id) async {
    try {
      await _api.delete('/solicitudes/$id');
    } catch (e) {
      throw e is ApiException ? e : Exception('Error al eliminar solicitud: $e');
    }
  }
}
