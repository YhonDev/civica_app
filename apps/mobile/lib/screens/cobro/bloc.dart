import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:drift/drift.dart';

import '../../core/database/app_database.dart';
import '../../core/database/daos/cobro_dao.dart';
import '../../core/database/daos/pago_dao.dart';

// ════════════════════════════════════════════════════════════
// EVENTS
// ════════════════════════════════════════════════════════════

abstract class CobroEvent extends Equatable {
  const CobroEvent();

  @override
  List<Object?> get props => [];
}

/// Carga los datos del propietario y sus cuotas pendientes.
class CargarResidente extends CobroEvent {
  final Residente propietario;
  final String casaDireccion;
  final String etapaNombre;

  const CargarResidente({
    required this.propietario,
    required this.casaDireccion,
    required this.etapaNombre,
  });

  @override
  List<Object?> get props => [propietario.id];
}

/// Selecciona o deselecciona una cuota para pagar.
class AlternarCobro extends CobroEvent {
  final String cobroId;

  const AlternarCobro(this.cobroId);

  @override
  List<Object?> get props => [cobroId];
}

/// Cambia el monto ingresado manualmente.
class CambiarMontoManual extends CobroEvent {
  final String monto;

  const CambiarMontoManual(this.monto);

  @override
  List<Object?> get props => [monto];
}

/// Registra el pago offline.
class RegistrarPago extends CobroEvent {
  final String cobradorId;
  final String? solicitudId;

  const RegistrarPago({
    this.cobradorId = 'offline',
    this.solicitudId,
  });

  @override
  List<Object?> get props => [cobradorId, solicitudId];
}

/// Limpia el estado.
class LimpiarCobro extends CobroEvent {}

// ════════════════════════════════════════════════════════════
// STATES
// ════════════════════════════════════════════════════════════

abstract class CobroState extends Equatable {
  const CobroState();

  @override
  List<Object?> get props => [];
}

class CobroInitial extends CobroState {
  const CobroInitial();
}

class CobroLoading extends CobroState {
  const CobroLoading();
}

class CobroLoaded extends CobroState {
  final Residente propietario;
  final String casaDireccion;
  final String etapaNombre;
  final List<CobroConSeleccion> cuotas;
  final Set<String> selectedCobroIds;
  final int montoManual; // en centavos, 0 si no se ingresó manual
  final String? errorMessage; // error sin perder la carga

  const CobroLoaded({
    required this.propietario,
    required this.casaDireccion,
    required this.etapaNombre,
    required this.cuotas,
    this.selectedCobroIds = const {},
    this.montoManual = 0,
    this.errorMessage,
  });

  /// Monto total: suma de cuotas seleccionadas + monto manual adicional
  int get montoTotal {
    final deCobros = cuotas
        .where((c) => selectedCobroIds.contains(c.cuota.id))
        .fold(0, (sum, c) => sum + c.cuota.monto - c.cuota.montoPagado);
    return deCobros + montoManual;
  }

  bool get puedePagar => montoTotal > 0;

  CobroLoaded copyWith({
    List<CobroConSeleccion>? cuotas,
    Set<String>? selectedCobroIds,
    int? montoManual,
    String? errorMessage,
  }) {
    return CobroLoaded(
      propietario: propietario,
      casaDireccion: casaDireccion,
      etapaNombre: etapaNombre,
      cuotas: cuotas ?? this.cuotas,
      selectedCobroIds: selectedCobroIds ?? this.selectedCobroIds,
      montoManual: montoManual ?? this.montoManual,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        propietario.id,
        selectedCobroIds,
        montoManual,
        cuotas,
        errorMessage,
      ];
}

class CobroSuccess extends CobroState {
  final String mensaje;
  final String pagoId;
  final String propietarioNombre;
  final String cobradorId;
  final String fechaPago;
  final int montoTotal; // en centavos COP

  const CobroSuccess({
    required this.mensaje,
    required this.pagoId,
    required this.propietarioNombre,
    required this.cobradorId,
    required this.fechaPago,
    required this.montoTotal,
  });

  @override
  List<Object?> get props => [
        mensaje,
        pagoId,
        propietarioNombre,
        cobradorId,
        fechaPago,
        montoTotal,
      ];
}

class CobroError extends CobroState {
  final String mensaje;

  const CobroError(this.mensaje);

  @override
  List<Object?> get props => [mensaje];
}

// ════════════════════════════════════════════════════════════
// MODELO AUXILIAR
// ════════════════════════════════════════════════════════════

class CobroConSeleccion extends Equatable {
  final Cobro cuota;

  const CobroConSeleccion({required this.cuota});

  int get saldoPendiente => cuota.monto - cuota.montoPagado;

  String get estadoLabel {
    switch (cuota.estado) {
      case 'PENDIENTE':
        return 'Pendiente';
      case 'VENCIDA':
        return 'Vencida';
      case 'PARCIAL':
        return 'Parcial';
      case 'PAGADA':
        return 'Pagada';
      default:
        return cuota.estado;
    }
  }

  @override
  List<Object?> get props => [
        cuota.id,
        cuota.monto,
        cuota.montoPagado,
        cuota.estado,
      ];
}

// ════════════════════════════════════════════════════════════
// BLoC
// ════════════════════════════════════════════════════════════

class CobroBloc extends Bloc<CobroEvent, CobroState> {
  final CobroDao _cuotaDao;
  final PagoDao _pagoDao;

  CobroBloc({
    CobroDao? cuotaDao,
    PagoDao? pagoDao,
  })  : _cuotaDao = cuotaDao ?? CobroDao(AppDatabase.instance),
        _pagoDao = pagoDao ?? PagoDao(AppDatabase.instance),
        super(CobroInitial()) {
    on<CargarResidente>(_onCargarResidente);
    on<AlternarCobro>(_onAlternarCobro);
    on<CambiarMontoManual>(_onCambiarMontoManual);
    on<RegistrarPago>(_onRegistrarPago);
    on<LimpiarCobro>(_onLimpiar);
  }

  Future<void> _onCargarResidente(
    CargarResidente event,
    Emitter<CobroState> emit,
  ) async {
    emit(CobroLoading());
    try {
      final cuotas = await _cuotaDao.getPendientes(event.propietario.id);
      emit(CobroLoaded(
        propietario: event.propietario,
        casaDireccion: event.casaDireccion,
        etapaNombre: event.etapaNombre,
        cuotas: cuotas.map((c) => CobroConSeleccion(cuota: c)).toList(),
      ));
    } catch (e) {
      emit(CobroError('Error al cargar datos: $e'));
    }
  }

  void _onAlternarCobro(
    AlternarCobro event,
    Emitter<CobroState> emit,
  ) {
    final s = state;
    if (s is! CobroLoaded) return;

    final selected = Set<String>.from(s.selectedCobroIds);
    if (selected.contains(event.cobroId)) {
      selected.remove(event.cobroId);
    } else {
      selected.add(event.cobroId);
    }

    emit(s.copyWith(selectedCobroIds: selected, errorMessage: null));
  }

  void _onCambiarMontoManual(
    CambiarMontoManual event,
    Emitter<CobroState> emit,
  ) {
    final s = state;
    if (s is! CobroLoaded) return;

    final monto = int.tryParse(event.monto) ?? 0;
    emit(s.copyWith(montoManual: monto, errorMessage: null));
  }

  Future<void> _onRegistrarPago(
    RegistrarPago event,
    Emitter<CobroState> emit,
  ) async {
    final s = state;
    if (s is! CobroLoaded || !s.puedePagar) return;

    emit(CobroLoading());
    try {
      final now = DateTime.now();
      final pagoId =
          'PAG_${now.microsecondsSinceEpoch}_${s.propietario.id.length >= 4 ? s.propietario.id.substring(0, 4) : s.propietario.id}';
      final tenantId = s.propietario.tenantId;
      final clientPaymentId = '${pagoId}_${now.millisecondsSinceEpoch}';

      // Crear el pago offline
      await _pagoDao.insertOffline(PagosCompanion.insert(
        id: pagoId,
        clientPaymentId: clientPaymentId,
        tenantId: tenantId,
        solicitudId: event.solicitudId == null ? const Value.absent() : Value(event.solicitudId!),
        monto: s.montoTotal,
        fechaPago: now.toIso8601String(),
        cobradorId: event.cobradorId,
        residenteId: s.propietario.id,
        syncStatus: 'PENDIENTE_SYNC',
        createdAt: now,
        updatedAt: now,
      ));

      // Actualizar estado de cuotas seleccionadas
      for (final cobroId in s.selectedCobroIds) {
        final cuotaCon =
            s.cuotas.firstWhere((c) => c.cuota.id == cobroId);
        final nuevoPagado =
            cuotaCon.cuota.montoPagado + cuotaCon.saldoPendiente;
        final nuevoEstado =
            nuevoPagado >= cuotaCon.cuota.monto ? 'PAGADA' : 'PARCIAL';

        await _cuotaDao.actualizarEstado(
          cobroId: cobroId,
          estado: nuevoEstado,
          montoPagado: nuevoPagado,
        );
      }

      emit(CobroSuccess(
        mensaje:
            'Pago registrado offline por \$${_formatPesos(s.montoTotal)}',
        pagoId: pagoId,
        propietarioNombre: s.propietario.nombre,
        cobradorId: event.cobradorId,
        fechaPago: now.toIso8601String(),
        montoTotal: s.montoTotal,
      ));
    } catch (e) {
      // No emitimos CobroError — eso reemplazaría el formulario.
      // En lugar de eso, añadimos el error al CobroLoaded existente
      // para que la UI muestre el error inline sin perder selecciones.
      emit(s.copyWith(errorMessage: 'Error al registrar pago: $e'));
    }
  }

  void _onLimpiar(LimpiarCobro event, Emitter<CobroState> emit) {
    emit(CobroInitial());
  }

  String _formatPesos(int centavos) {
    final pesos = centavos.toString();
    final len = pesos.length;
    if (len <= 3) return pesos;
    final parts = <String>[];
    for (var i = len; i > 0; i -= 3) {
      parts.add(pesos.substring(i > 3 ? i - 3 : 0, i));
    }
    return parts.reversed.join('.');
  }
}
