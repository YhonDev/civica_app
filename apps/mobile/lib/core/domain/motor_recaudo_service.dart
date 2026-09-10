import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' as drift;
import '../database/app_database.dart';
import '../format/app_currency.dart';

class MotorRecaudoService {
  final AppDatabase _db;
  final _uuid = const Uuid();

  MotorRecaudoService(this._db);

  /// Genera cuotas para el mes de cobro indicado, basándose en la tarifa de la comunidad
  /// o de las manzanas. Por ahora generaremos un Cobro para cada residente activo.
  Future<void> generarCuotas(MesesDeCobroData mes) async {
    // 1. Obtener todos los residentes activos y sus casas
    final residentes = await _db.residenteDao.buscar(tenantId: mes.tenantId);

    // 2. Iterar y crear cuota si no existe
    await _db.transaction(() async {
      for (final residente in residentes) {
        // Validar si ya tiene cuota para este mes
        final existentes = await (_db.select(_db.cobros)
              ..where((c) =>
                  c.residenteId.equals(residente.id) &
                  c.mesDeCobroId.equals(mes.id)))
            .get();

        if (existentes.isEmpty) {
          final newCobroId = _uuid.v4();
          final montoBase = 2000000; // 20.000 COP por ahora hardcoded o tomado de Tarifas
          
          // Crear cuota
          await _db.into(_db.cobros).insert(
            CobrosCompanion.insert(
              id: newCobroId,
              residenteId: residente.id,
              tenantId: mes.tenantId, // o residente.tenantId
              mesDeCobroId: drift.Value(mes.id),
              concepto: 'Cuota ${mes.mes}/${mes.anio}',
              monto: montoBase,
              montoPagado: 0,
              periodoInicio: DateTime(mes.anio, mes.mes, 1).toIso8601String(),
              periodoFin: DateTime(mes.anio, mes.mes + 1, 0).toIso8601String(),
              fechaVencimiento: DateTime(mes.anio, mes.mes, 10).toIso8601String(), // Vence el 10
              estado: 'PROGRAMADA', // o PENDIENTE si ya inició
              notificacionEnviada: false,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );

          // Disparar Actividad
          await _registrarActividad(
            tenantId: mes.tenantId, // Asume que mes.tenantId existe, verify that later
            tipo: 'CUOTA_GENERADA',
            descripcion: 'Generada cuota de \$20.000 para el residente ${residente.nombre}',
            entidadId: newCobroId,
            entidadTipo: 'COBRO',
          );
        }
      }
    });
  }

  /// Distribuye un pago a los cobros pendientes del residente.
  Future<void> registrarPago(String residenteId, int montoAbono, String cobradorId) async {
    await _db.transaction(() async {
      // 1. Obtener cobros pendientes y vencidos ordenados por vencimiento ascendente (más antiguos primero)
      final cobros = await _db.cobroDao.getPendientes(residenteId);

      int restanteAbonar = montoAbono;

      for (final cobro in cobros) {
        if (restanteAbonar <= 0) break;

        final montoDeuda = cobro.monto - cobro.montoPagado;
        if (montoDeuda <= 0) continue;

        int aplicable = restanteAbonar > montoDeuda ? montoDeuda : restanteAbonar;
        final nuevoPagado = cobro.montoPagado + aplicable;
        restanteAbonar -= aplicable;

        final nuevoEstado = nuevoPagado >= cobro.monto ? 'PAGADA' : 'PAGO_PARCIAL';

        // Actualizar Cobro
        await _db.cobroDao.actualizarEstado(
          cobroId: cobro.id,
          estado: nuevoEstado,
          montoPagado: nuevoPagado,
        );

        // Crear registro de Pago (recibo)
        final pagoId = _uuid.v4();
        await _db.pagoDao.insertOffline(
          PagosCompanion.insert(
            id: pagoId,
            clientPaymentId: pagoId,
            tenantId: cobro.tenantId,
            cobroId: drift.Value(cobro.id),
            monto: aplicable,
            fechaPago: DateTime.now().toIso8601String(),
            cobradorId: cobradorId,
            residenteId: residenteId,
            syncStatus: 'PENDIENTE_SYNC',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        // Registrar Actividad
        await _registrarActividad(
          tenantId: cobro.tenantId,
          tipo: 'PAGO_REGISTRADO',
          descripcion: 'Pago de ${AppCurrency.formatCents(aplicable.round())} registrado. Nuevo estado: $nuevoEstado',
          entidadId: pagoId,
          entidadTipo: 'PAGO',
        );
      }

      // Si quedó saldo (restanteAbonar > 0), podría crearse un saldo a favor en la tabla Residente o generar un pago huerfano.
      if (restanteAbonar > 0) {
        // Implementar lógica de saldo a favor o abono anticipado si el diseño lo soporta.
      }
    });
  }

  /// Revisa si hay cuotas pendientes que ya pasaron su fecha de vencimiento y las marca como VENCIDA.
  Future<void> verificarVencimientos() async {
    final now = DateTime.now();
    final pendientes = await (_db.select(_db.cobros)..where((c) => c.estado.equals('PENDIENTE'))).get();

    for (final cobro in pendientes) {
      final vencimiento = DateTime.parse(cobro.fechaVencimiento);
      if (now.isAfter(vencimiento)) {
        await _db.cobroDao.actualizarEstado(
          cobroId: cobro.id,
          estado: 'VENCIDA',
          montoPagado: cobro.montoPagado,
        );

        // Actividad de mora
        await _registrarActividad(
          tenantId: cobro.tenantId,
          tipo: 'MORA_DETECTADA',
          descripcion: 'La cuota de la casa pasó a estado de mora',
          entidadId: cobro.id,
          entidadTipo: 'COBRO',
        );
      }
    }
  }

  Future<void> _registrarActividad({
    required String tenantId,
    required String tipo,
    required String descripcion,
    required String entidadId,
    required String entidadTipo,
  }) async {
    final actId = _uuid.v4();
    await _db.actividadDao.insert(
      ActividadesCompanion.insert(
        id: actId,
        tenantId: tenantId,
        tipo: tipo,
        descripcion: drift.Value(descripcion),
        entidadId: entidadId,
        entidadTipo: entidadTipo,
        createdAt: DateTime.now(),
      ),
    );
  }
}
