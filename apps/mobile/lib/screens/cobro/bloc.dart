import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:drift/drift.dart';

import '../../core/database/app_database.dart';
import '../../core/database/daos/cuota_dao.dart';
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
class CargarPropietario extends CobroEvent {
  final Propietario propietario;
  final String casaDireccion;
  final String etapaNombre;

  const CargarPropietario({
    required this.propietario,
    required this.casaDireccion,
    required this.etapaNombre,
  });

  @override
  List<Object?> get props => [propietario.id];
}

/// Selecciona o deselecciona una cuota para pagar.
class AlternarCuota extends CobroEvent {
  final String cuotaId;

  const AlternarCuota(this.cuotaId);

  @override
  List<Object?> get props => [cuotaId];
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
  final Propietario propietario;
  final String casaDireccion;
  final String etapaNombre;
  final List<CuotaConSeleccion> cuotas;
  final Set<String> selectedCuotaIds;
  final int montoManual; // en centavos, 0 si no se ingresó manual
  final String? errorMessage; // error sin perder la carga

  const CobroLoaded({
    required this.propietario,
    required this.casaDireccion,
    required this.etapaNombre,
    required this.cuotas,
    this.selectedCuotaIds = const {},
    this.montoManual = 0,
    this.errorMessage,
  });

  /// Monto total: suma de cuotas seleccionadas + monto manual adicional
  int get montoTotal {
    final deCuotas = cuotas
        .where((c) => selectedCuotaIds.contains(c.cuota.id))
        .fold(0, (sum, c) => sum + c.cuota.monto - c.cuota.montoPagado);
    return deCuotas + montoManual;
  }

  bool get puedePagar => montoTotal > 0;

  CobroLoaded copyWith({
    List<CuotaConSeleccion>? cuotas,
    Set<String>? selectedCuotaIds,
    int? montoManual,
    String? errorMessage,
  }) {
    return CobroLoaded(
      propietario: propietario,
      casaDireccion: casaDireccion,
      etapaNombre: etapaNombre,
      cuotas: cuotas ?? this.cuotas,
      selectedCuotaIds: selectedCuotaIds ?? this.selectedCuotaIds,
      montoManual: montoManual ?? this.montoManual,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        propietario.id,
        selectedCuotaIds,
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

class CuotaConSeleccion extends Equatable {
  final Cuota cuota;

  const CuotaConSeleccion({required this.cuota});

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
  final CuotaDao _cuotaDao;
  final PagoDao _pagoDao;

  CobroBloc({
    CuotaDao? cuotaDao,
    PagoDao? pagoDao,
  })  : _cuotaDao = cuotaDao ?? CuotaDao(AppDatabase.instance),
        _pagoDao = pagoDao ?? PagoDao(AppDatabase.instance),
        super(CobroInitial()) {
    on<CargarPropietario>(_onCargarPropietario);
    on<AlternarCuota>(_onAlternarCuota);
    on<CambiarMontoManual>(_onCambiarMontoManual);
    on<RegistrarPago>(_onRegistrarPago);
    on<LimpiarCobro>(_onLimpiar);
  }

  Future<void> _onCargarPropietario(
    CargarPropietario event,
    Emitter<CobroState> emit,
  ) async {
    emit(CobroLoading());
    try {
      final cuotas = await _cuotaDao.getPendientes(event.propietario.id);
      emit(CobroLoaded(
        propietario: event.propietario,
        casaDireccion: event.casaDireccion,
        etapaNombre: event.etapaNombre,
        cuotas: cuotas.map((c) => CuotaConSeleccion(cuota: c)).toList(),
      ));
    } catch (e) {
      emit(CobroError('Error al cargar datos: $e'));
    }
  }

  void _onAlternarCuota(
    AlternarCuota event,
    Emitter<CobroState> emit,
  ) {
    final s = state;
    if (s is! CobroLoaded) return;

    final selected = Set<String>.from(s.selectedCuotaIds);
    if (selected.contains(event.cuotaId)) {
      selected.remove(event.cuotaId);
    } else {
      selected.add(event.cuotaId);
    }

    emit(s.copyWith(selectedCuotaIds: selected, errorMessage: null));
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
        propietarioId: s.propietario.id,
        syncStatus: 'PENDIENTE_SYNC',
        createdAt: now,
        updatedAt: now,
      ));

      // Actualizar estado de cuotas seleccionadas
      for (final cuotaId in s.selectedCuotaIds) {
        final cuotaCon =
            s.cuotas.firstWhere((c) => c.cuota.id == cuotaId);
        final nuevoPagado =
            cuotaCon.cuota.montoPagado + cuotaCon.saldoPendiente;
        final nuevoEstado =
            nuevoPagado >= cuotaCon.cuota.monto ? 'PAGADA' : 'PARCIAL';

        await _cuotaDao.actualizarEstado(
          cuotaId: cuotaId,
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
