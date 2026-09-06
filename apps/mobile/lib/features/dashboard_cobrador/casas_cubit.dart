import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../core/network/api_client.dart';
import '../../core/network/local_cache_repository.dart';

// ════════════════════════════════════════════════════════════
// DATA MODELS
// ════════════════════════════════════════════════════════════

class CasaExplorer extends Equatable {
  final String id;
  final String direccion;
  final String residenteId;
  final String residenteNombre;
  final String residenteTelefono;
  final String modalidad;
  final String estado;  // AL_DIA, PENDIENTE, PARCIAL, VENCIDA
  final int saldo;
  final String? proximaCuotaNombre;
  final int proximaCuotaMonto;
  final String? proximaCuotaId;
  final String? proximaCuotaFechaVencimiento;
  final List<Map<String, dynamic>> cuotas;

  const CasaExplorer({
    required this.id,
    required this.direccion,
    this.residenteId = '',
    required this.residenteNombre,
    required this.residenteTelefono,
    this.modalidad = 'MENSUAL',
    required this.estado,
    required this.saldo,
    this.proximaCuotaNombre,
    this.proximaCuotaMonto = 0,
    this.proximaCuotaId,
    this.proximaCuotaFechaVencimiento,
    this.cuotas = const [],
  });

  factory CasaExplorer.fromJson(Map<String, dynamic> json) {
    return CasaExplorer(
      id: json['id'] as String? ?? '',
      direccion: json['direccion'] as String? ?? '',
      residenteId: json['residenteId'] as String? ?? '',
      residenteNombre: json['residenteNombre'] as String? ?? 'Sin residente',
      residenteTelefono: json['residenteTelefono'] as String? ?? '',
      modalidad: json['modalidad'] as String? ?? 'MENSUAL',
      estado: json['estado'] as String? ?? 'AL_DIA',
      saldo: json['saldo'] as int? ?? 0,
      proximaCuotaNombre: json['proximaCuotaNombre'] as String?,
      proximaCuotaMonto: json['proximaCuotaMonto'] as int? ?? 0,
      proximaCuotaId: json['proximaCuotaId'] as String?,
      proximaCuotaFechaVencimiento: json['proximaCuotaFechaVencimiento'] as String?,
      cuotas: (json['cuotas'] as List? ?? [])
          .map((c) => Map<String, dynamic>.from(c as Map))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        direccion,
        residenteId,
        residenteNombre,
        modalidad,
        estado,
        saldo,
        proximaCuotaNombre,
        proximaCuotaMonto,
        proximaCuotaId,
        proximaCuotaFechaVencimiento,
        cuotas,
      ];
}

class RecorridoExplorer extends Equatable {
  final int numero;
  final String nombre;
  final String fecha;
  final String fechaLegible;
  final bool esActual;

  const RecorridoExplorer({
    required this.numero,
    required this.nombre,
    required this.fecha,
    required this.fechaLegible,
    this.esActual = false,
  });

  factory RecorridoExplorer.fromJson(Map<String, dynamic> json) {
    return RecorridoExplorer(
      numero: json['numero'] as int? ?? 1,
      nombre: json['nombre'] as String? ?? 'Recorrido',
      fecha: json['fecha'] as String? ?? '',
      fechaLegible: json['fechaLegible'] as String? ?? '',
      esActual: json['esActual'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [numero, nombre, fecha, fechaLegible, esActual];
}

/// Estados de cuota que cuentan como "por cobrar en su semana".
const List<String> kEstadosCuotaPorCobrar = ['PENDIENTE', 'PARCIAL'];

/// Veredicto de una casa frente al filtro de ruta activo.
enum CasaFiltroVeredicto { incluir, excluir, mora }

///
/// Decide si [casa] entra al recorrido según [filtro] y la fecha de corte
/// del recorrido seleccionado ([fechaCorte], YYYY-MM-DD).
///
/// - PENDIENTES: alguna cuota por cobrar (PENDIENTE/PARCIAL) con saldo y
///   `fechaVencimiento <= fechaCorte`. Las cuotas de sábados futuros NO
///   entran al recorrido actual. `VENCIDA` no es "pendiente": es mora.
/// - MORA: alguna cuota VENCIDA (fallback al estado de la casa si no hay
///   detalle de cuotas). No depende de ningún sábado: [fechaCorte] se ignora.
///
/// Con [fechaCorte] null (payload cacheado antiguo) se conserva el
/// comportamiento previo, solo por estado de la casa.
CasaFiltroVeredicto evaluarCasaParaRecorrido(
  CasaExplorer casa,
  String filtro,
  String? fechaCorte,
) {
  switch (filtro) {
    case 'PENDIENTES':
      if (fechaCorte == null) {
        return (casa.estado == 'PENDIENTE' ||
                casa.estado == 'PARCIAL' ||
                casa.estado == 'VENCIDA') &&
              casa.saldo > 0
            ? CasaFiltroVeredicto.incluir
            : CasaFiltroVeredicto.excluir;
      }
      bool tieneVigente = false;
      bool tieneVencida = false;
      for (final cuota in casa.cuotas) {
        final estado = cuota['estado'] as String? ?? '';
        final saldoCuota = (cuota['saldo'] as num?)?.toInt() ?? 0;
        if (saldoCuota <= 0) continue;
        if (estado == 'VENCIDA') {
          tieneVencida = true;
        } else if (kEstadosCuotaPorCobrar.contains(estado) &&
            _venceEnOAntesDe(cuota['fechaVencimiento'] as String?, fechaCorte)) {
          tieneVigente = true;
        }
      }
      // La casa entra al recorrido si tiene cuota por cobrar esta semana
      // (allí también se cobra la mora); si solo debe mora, se reporta como mora.
      if (tieneVigente) return CasaFiltroVeredicto.incluir;
      if (tieneVencida) return CasaFiltroVeredicto.mora;
      return CasaFiltroVeredicto.excluir;

    case 'MORA':
      if (casa.cuotas.isNotEmpty) {
        final tieneVencida = casa.cuotas.any(
          (cuota) => (cuota['estado'] as String? ?? '') == 'VENCIDA',
        );
        if (!tieneVencida) return CasaFiltroVeredicto.excluir;
      } else if (!(casa.estado == 'VENCIDA' ||
          casa.estado == 'MORA' ||
          casa.estado == 'EN_MORA')) {
        return CasaFiltroVeredicto.excluir;
      }
      return casa.saldo > 0
          ? CasaFiltroVeredicto.incluir
          : CasaFiltroVeredicto.excluir;

    default:
      // Solo existen los filtros PENDIENTES y MORA.
      return CasaFiltroVeredicto.excluir;
  }
}

/// Fecha de vencimiento (YYYY-MM-DD) más antigua con saldo pendiente dentro
/// de [cuotas]; '' si ninguna cuota la tiene. ISO compara lexicográfico =
/// cronológico, así que ascendente = más vieja primero.
String fechaVencimientoMasAntiguaDeCuotas(List<Map<String, dynamic>> cuotas) {
  String masAntigua = '';
  for (final cuota in cuotas) {
    final saldo = (cuota['saldo'] as num?)?.toInt() ?? 0;
    if (saldo <= 0) continue;
    final fv = cuota['fechaVencimiento'] as String?;
    if (fv == null || fv.isEmpty) continue;
    final dia = fv.length >= 10 ? fv.substring(0, 10) : fv;
    if (masAntigua.isEmpty || dia.compareTo(masAntigua) < 0) {
      masAntigua = dia;
    }
  }
  return masAntigua;
}

/// Comparador para rutas de MORA: primero la casa con la deuda más vieja
/// (menor fechaVencimiento con saldo). Empate o sin fechas conserva el orden
/// de caminata (entrada estable de List.sort en Dart no está garantizada,
/// por lo que el empate devuelve 0 y el llamador decide el orden base).
int compararCasasPorMoraAntigua(CasaExplorer a, CasaExplorer b) {
  final fa = fechaVencimientoMasAntiguaDeCuotas(a.cuotas);
  final fb = fechaVencimientoMasAntiguaDeCuotas(b.cuotas);
  if (fa.isEmpty && fb.isEmpty) return 0;
  if (fa.isEmpty) return 1; // sin fecha utilizable: al final
  if (fb.isEmpty) return -1;
  return fa.compareTo(fb);
}

bool _venceEnOAntesDe(String? fechaVencimiento, String fechaCorte) {
  if (fechaVencimiento == null || fechaVencimiento.isEmpty) return true;
  final dia = fechaVencimiento.length >= 10
      ? fechaVencimiento.substring(0, 10)
      : fechaVencimiento;
  return dia.compareTo(fechaCorte) <= 0;
}

class ManzanaExplorer extends Equatable {
  final String id;
  final String nombre;
  final List<CasaExplorer> casas;

  const ManzanaExplorer({required this.id, required this.nombre, required this.casas});

  factory ManzanaExplorer.fromJson(Map<String, dynamic> json) {
    return ManzanaExplorer(
      id: json['id'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      casas: (json['casas'] as List? ?? [])
          .map((c) => CasaExplorer.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [id, nombre, casas];
}

class EtapaExplorer extends Equatable {
  final String id;
  final String nombre;
  final List<ManzanaExplorer> manzanas;

  const EtapaExplorer({required this.id, required this.nombre, required this.manzanas});

  factory EtapaExplorer.fromJson(Map<String, dynamic> json) {
    return EtapaExplorer(
      id: json['id'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      manzanas: (json['manzanas'] as List? ?? [])
          .map((m) => ManzanaExplorer.fromJson(m as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [id, nombre, manzanas];
}

// ════════════════════════════════════════════════════════════
// STATE
// ════════════════════════════════════════════════════════════

abstract class CasasState extends Equatable {
  const CasasState();
  @override
  List<Object?> get props => [];
}

class ViviendasInitial extends CasasState {
  const ViviendasInitial();
}

class ViviendasLoading extends CasasState {
  const ViviendasLoading();
}

class ViviendasLoaded extends CasasState {
  final List<EtapaExplorer> etapas;
  final List<Map<String, dynamic>> solicitudes;
  final List<RecorridoExplorer> recorridos;
  final int recorridoActualNumero;

  const ViviendasLoaded(
    this.etapas, {
    this.solicitudes = const [],
    this.recorridos = const [],
    this.recorridoActualNumero = 1,
  });

  @override
  List<Object?> get props => [
        etapas,
        solicitudes,
        recorridos,
        recorridoActualNumero,
      ];
}

class ViviendasError extends CasasState {
  final String message;
  const ViviendasError(this.message);
  @override
  List<Object?> get props => [message];
}

// ════════════════════════════════════════════════════════════
// CUBIT
// ════════════════════════════════════════════════════════════

class CasasCubit extends Cubit<CasasState> {
  final ApiClient _api;

  CasasCubit({ApiClient? api})
      : _api = api ?? ApiClient.instance,
        super(const ViviendasInitial());

  Future<void> loadViviendas({bool silent = false, bool forceFresh = true}) async {
    if (forceFresh) {
      LocalCacheRepository.instance.invalidate('cobrador:viviendas');
    }

    if (!silent && LocalCacheRepository.instance.getCached('cobrador:viviendas') == null) {
      emit(const ViviendasLoading());
    }

    await LocalCacheRepository.instance.executeSWR<Map<String, dynamic>>(
      key: 'cobrador:viviendas',
      fetcher: () async {
        final response = await _api.get('/dashboard/cobrador/viviendas');
        return response.data as Map<String, dynamic>;
      },
      onData: (data, isStale) {
        final etapas = (data['etapas'] as List? ?? [])
            .map((e) => EtapaExplorer.fromJson(e as Map<String, dynamic>))
            .toList();
        final solicitudes = List<Map<String, dynamic>>.from(data['solicitudes'] as List? ?? []);
        final recorridos = (data['recorridos'] as List? ?? [])
            .map((r) => RecorridoExplorer.fromJson(r as Map<String, dynamic>))
            .toList();
        final recorridoActualNumero = data['recorridoActualNumero'] as int? ?? 1;

        emit(ViviendasLoaded(
          etapas,
          solicitudes: solicitudes,
          recorridos: recorridos,
          recorridoActualNumero: recorridoActualNumero,
        ));
      },
      onError: (e) {
        if (!silent && LocalCacheRepository.instance.getCached('cobrador:viviendas') == null) {
          emit(ViviendasError('Error al cargar casas: $e'));
        }
      },
    );
  }

  void cambiarEstadoSolicitud(String solicitudId, String nuevoEstado) {
    if (state is! ViviendasLoaded) return;
    final current = state as ViviendasLoaded;
    final updatedSolicitudes = current.solicitudes.map((s) {
      if (s['id'] == solicitudId) {
        final map = Map<String, dynamic>.from(s);
        map['estado'] = nuevoEstado;
        return map;
      }
      return s;
    }).toList();

    emit(ViviendasLoaded(
      current.etapas,
      solicitudes: updatedSolicitudes,
      recorridos: current.recorridos,
      recorridoActualNumero: current.recorridoActualNumero,
    ));

    if (nuevoEstado == 'EN_CAMINO') {
      _api.patch('/solicitudes/$solicitudId/en-camino').ignore();
    }
  }

  Future<void> refresh() async {
    await loadViviendas(silent: false, forceFresh: true);
  }
}
