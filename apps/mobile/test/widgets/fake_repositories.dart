import 'package:civica_pago_mobile/features/cartera/cartera_repository.dart';
import 'package:civica_pago_mobile/features/cartera/models/cartera_models.dart';
import 'package:civica_pago_mobile/features/solicitudes/solicitudes_repository.dart';
import 'package:civica_pago_mobile/shared/widgets/solicitud_card.dart';

/// Fake [CarteraRepository] that returns pre-configured data without HTTP calls.
class FakeCarteraRepository extends CarteraRepository {
  final CarteraResumen? resumen;
  final List<CobroItem> cobros;

  FakeCarteraRepository({this.resumen, List<CobroItem>? cobros})
      : cobros = cobros ?? [];

  @override
  Future<CarteraResumen> getCarteraResumen() async {
    return resumen ?? const CarteraResumen(
      totalPendiente: 0, totalMora: 0, totalPagado: 0,
      cantidadPendientes: 0, cantidadMora: 0, cantidadPagados: 0,
    );
  }

  @override
  Future<List<CobroItem>> getCobros() async => cobros;

  @override
  Future<Map<String, dynamic>> registrarPago({
    required String residenteId,
    required int montoCentavos,
  }) async => {'id': 'mock-pago'};
}

/// Convenience builders for common test scenarios.
class FakeCarteraData {
  static const _defaultResumen = CarteraResumen(
    totalPendiente: 50000, totalMora: 50000, totalPagado: 50000,
    cantidadPendientes: 1, cantidadMora: 1, cantidadPagados: 1,
  );

  static CobroItem cobro({
    required String id,
    required String nombre,
    required String estado,
    double saldo = 50000,
    double? monto,
    double? montoPagado,
  }) {
    final resolvedMonto = monto ?? saldo;
    final resolvedMontoPagado = montoPagado ?? (estado == 'Pagado' ? resolvedMonto : 0.0);
    return CobroItem(
      id: id, residenteId: 'P-$id', nombre: nombre,
      casa: 'Casa 101', manzana: 'Manzana A', etapa: 'Etapa 1',
      monto: resolvedMonto, montoPagado: resolvedMontoPagado,
      saldo: saldo, estado: estado, modalidad: 'Mensual',
    );
  }

  static FakeCarteraRepository conTresCuotas() {
    return FakeCarteraRepository(
      resumen: _defaultResumen,
      cobros: [
        cobro(id: 'C1', nombre: 'Juan Pagado', estado: 'Pagado', saldo: 0),
        cobro(id: 'C2', nombre: 'Maria Mora', estado: 'Mora'),
        cobro(id: 'C3', nombre: 'Carlos Pendiente', estado: 'Pendiente'),
      ],
    );
  }

  static FakeCarteraRepository vacio() {
    return FakeCarteraRepository(
      resumen: const CarteraResumen(
        totalPendiente: 0, totalMora: 0, totalPagado: 0,
        cantidadPendientes: 0, cantidadMora: 0, cantidadPagados: 0,
      ),
    );
  }
}

/// Fake [SolicitudesRepository] that returns pre-configured data without HTTP calls.
class FakeSolicitudesRepository extends SolicitudesRepository {
  final List<SolicitudData> solicitudes;
  final bool shouldThrow;

  FakeSolicitudesRepository({this.solicitudes = const [], this.shouldThrow = false});

  @override
  Future<List<SolicitudData>> getSolicitudes() async {
    if (shouldThrow) throw Exception('Fake error');
    return solicitudes;
  }

  @override
  Future<List<SolicitudData>> getSolicitudesPendientes() async {
    if (shouldThrow) throw Exception('Fake error');
    return solicitudes.where((s) =>
      s.estado == SolicitudEstado.pendiente ||
      s.estado == SolicitudEstado.enRevision
    ).toList();
  }

  @override
  Future<void> crearSolicitud({
    required String cobroId,
    String? pagoId,
    required String tipo,
    required String descripcion,
    String? residenteId,
  }) async {}
}

/// Convenience builders for common test scenarios.
class FakeSolicitudesData {
  static SolicitudData solicitud({
    required String id,
    required String tipo,
    SolicitudEstado estado = SolicitudEstado.pendiente,
    String? nroRecibo,
  }) {
    return SolicitudData(
      id: id, cobroId: 'C-$id',
      nroRecibo: nroRecibo ?? 'TK-${id.padLeft(6, '0')}',
      tipo: tipo,
      descripcion: 'Descripción de $tipo',
      estado: estado,
      fecha: DateTime(2026, 3, 15),
    );
  }

  static FakeSolicitudesRepository conTresSolicitudes() {
    return FakeSolicitudesRepository(solicitudes: [
      solicitud(id: 'S1', tipo: 'Revisión de pago', estado: SolicitudEstado.pendiente, nroRecibo: 'TK-000001'),
      solicitud(id: 'S2', tipo: 'Revisión de cargo', estado: SolicitudEstado.resuelta, nroRecibo: 'TK-000002'),
      solicitud(id: 'S3', tipo: 'Revisión general', estado: SolicitudEstado.rechazada, nroRecibo: 'TK-000003'),
    ]);
  }

  static FakeSolicitudesRepository vacio() => FakeSolicitudesRepository(solicitudes: []);

  static FakeSolicitudesRepository error() => FakeSolicitudesRepository(solicitudes: [], shouldThrow: true);
}
