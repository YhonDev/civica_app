import '../widgets/solicitud_card.dart';

/// A static in-memory store to simulate real requests (solicitudes) behavior.
///
/// This allows SolicitudesScreen, NuevaSolicitudScreen, and MiEstadoScreen
/// to share and manipulate the same requests data during manual testing,
/// making the simulation feel 100% real.
class SolicitudesMockStore {
  SolicitudesMockStore._();

  static final List<SolicitudData> _solicitudes = [
    SolicitudData(
      id: 'sol-1',
      cuotaId: '',
      nroRecibo: 'TK-948271',
      tipo: 'Revisión pago de Agosto 2026',
      descripcion: 'El cobro de agosto no corresponde al monto acordado de la cuota ordinaria.',
      estado: SolicitudEstado.enRevision,
      fecha: DateTime(2026, 8, 5),
    ),
    SolicitudData(
      id: 'sol-2',
      cuotaId: '',
      nroRecibo: 'TK-847291',
      tipo: 'Revisión pago de Julio 2026',
      descripcion: 'Realicé el pago por transferencia bancaria el día 10 pero sigue apareciendo como pendiente.',
      estado: SolicitudEstado.resuelta,
      fecha: DateTime(2026, 7, 10),
      respuesta: 'Hemos verificado el comprobante bancario. El pago fue aplicado correctamente a tu periodo de Julio.',
    ),
    SolicitudData(
      id: 'sol-3',
      cuotaId: '',
      nroRecibo: 'TK-539201',
      tipo: 'Revisión recargo de Junio 2026',
      descripcion: 'Recargo por mora injustificado ya que pagué antes de la fecha límite establecida.',
      estado: SolicitudEstado.rechazada,
      fecha: DateTime(2026, 6, 12),
      respuesta: 'El pago se recibió después de la hora de corte de la fecha límite (15 de Junio, 6:00 PM).',
    ),
  ];

  static List<SolicitudData> get all => List.unmodifiable(_solicitudes);

  static List<SolicitudData> get pending =>
      _solicitudes.where((s) => s.estado == SolicitudEstado.pendiente || s.estado == SolicitudEstado.enRevision).toList();

  static void add({
    required String tipo,
    required String descripcion,
    String cuotaId = '',
    String nroRecibo = 'TK-000000',
  }) {
    final nueva = SolicitudData(
      id: 'sol-${DateTime.now().millisecondsSinceEpoch}',
      cuotaId: cuotaId,
      nroRecibo: nroRecibo,
      tipo: tipo,
      descripcion: descripcion,
      estado: SolicitudEstado.enRevision,
      fecha: DateTime.now(),
    );
    _solicitudes.insert(0, nueva); // Insert at beginning of the list
  }
}
