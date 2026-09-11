import 'package:civica_pago_mobile/features/cartera/cartera_repository.dart';
import 'package:civica_pago_mobile/features/cartera/models/cartera_models.dart';

/// Repositorio de cartera con datos fijos para la galería visual (debug).
/// Autocontenido: no importa nada de test/ para poder compilar para web.
class DebugCarteraRepository extends CarteraRepository {
  DebugCarteraRepository();

  CobroItem _cobro({
    required String id,
    required String nombre,
    required String estado,
    double saldo = 90000,
    double? monto,
    double? montoPagado,
  }) {
    final resolvedMonto = monto ?? saldo;
    final resolvedPagado = montoPagado ?? (estado == 'Pagado' ? resolvedMonto : 0.0);
    return CobroItem(
      id: id,
      residenteId: 'P-$id',
      nombre: nombre,
      casa: 'Casa 101',
      manzana: 'Manzana A',
      etapa: 'Etapa 1',
      monto: resolvedMonto,
      montoPagado: resolvedPagado,
      saldo: saldo,
      estado: estado,
      modalidad: 'Mensual',
    );
  }

  @override
  Future<List<CobroItem>> getCobros() async {
    return [
      _cobro(id: 'C1', nombre: 'Juan Pérez', estado: 'Pagado', saldo: 0),
      _cobro(
        id: 'C2',
        nombre: 'María Gómez',
        estado: 'Mora',
        saldo: 180000,
        monto: 120000,
        montoPagado: 30000,
      ),
      _cobro(id: 'C3', nombre: 'Carlos Ruiz', estado: 'Pendiente', saldo: 120000),
      _cobro(id: 'C4', nombre: 'Ana Torres', estado: 'Pendiente', saldo: 120000),
      _cobro(id: 'C5', nombre: 'Luis Mora', estado: 'Pendiente', saldo: 120000),
      _cobro(id: 'C6', nombre: 'Sofía Diaz', estado: 'Pendiente', saldo: 120000),
    ];
  }
}
