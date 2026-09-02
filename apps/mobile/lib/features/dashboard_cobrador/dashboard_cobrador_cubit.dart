import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../core/network/api_client.dart';
import '../../core/network/local_cache_repository.dart';

// ════════════════════════════════════════════════════════════
// DATA MODEL
// ════════════════════════════════════════════════════════════

class CobradorDashboardData extends Equatable {
  final String cobradorNombre;
  final int totalViviendas;
  final int cobradosHoy;
  final int montoCobradoHoy;
  final int pendientes;
  final int vencidas;
  final int montoEsperado;
  final List<Map<String, dynamic>> casas;
  final Map<String, dynamic>? proximaVivienda;
  final List<Map<String, dynamic>> ultimosCobros;
  final List<Map<String, dynamic>> solicitudes;

  const CobradorDashboardData({
    required this.cobradorNombre,
    required this.totalViviendas,
    required this.cobradosHoy,
    required this.montoCobradoHoy,
    required this.pendientes,
    required this.vencidas,
    required this.montoEsperado,
    required this.casas,
    this.proximaVivienda,
    required this.ultimosCobros,
    required this.solicitudes,
  });

  factory CobradorDashboardData.fromJson(Map<String, dynamic> json) {
    final stats = json['stats'] as Map<String, dynamic>? ?? {};
    return CobradorDashboardData(
      cobradorNombre: (json['cobrador'] as Map<String, dynamic>?)?['nombre'] as String? ?? '',
      totalViviendas: int.tryParse(stats['totalViviendas']?.toString() ?? '') ?? 0,
      cobradosHoy: int.tryParse(stats['cobradosHoy']?.toString() ?? '') ?? 0,
      montoCobradoHoy: int.tryParse(stats['montoCobradoHoy']?.toString() ?? '') ?? 0,
      pendientes: int.tryParse(stats['pendientes']?.toString() ?? '') ?? 0,
      vencidas: int.tryParse(stats['vencidas']?.toString() ?? '') ?? 0,
      montoEsperado: int.tryParse(stats['montoEsperado']?.toString() ?? '') ?? 0,
      casas: List<Map<String, dynamic>>.from(json['viviendas'] as List? ?? json['casas'] as List? ?? []),
      proximaVivienda: json['proximaVivienda'] as Map<String, dynamic>?,
      ultimosCobros: List<Map<String, dynamic>>.from(json['ultimosCobros'] as List? ?? []),
      solicitudes: List<Map<String, dynamic>>.from(json['solicitudes'] as List? ?? []),
    );
  }

  @override
  List<Object?> get props => [
    cobradorNombre, totalViviendas, cobradosHoy, montoCobradoHoy,
    pendientes, vencidas, montoEsperado, casas, proximaVivienda, ultimosCobros, solicitudes,
  ];
}

// ════════════════════════════════════════════════════════════
// STATE
// ════════════════════════════════════════════════════════════

abstract class CobradorDashboardState extends Equatable {
  const CobradorDashboardState();

  @override
  List<Object?> get props => [];
}

class CobradorDashboardInitial extends CobradorDashboardState {
  const CobradorDashboardInitial();
}

class CobradorDashboardLoading extends CobradorDashboardState {
  const CobradorDashboardLoading();
}

class CobradorDashboardLoaded extends CobradorDashboardState {
  final CobradorDashboardData data;

  const CobradorDashboardLoaded(this.data);

  @override
  List<Object?> get props => [data];
}

class CobradorDashboardError extends CobradorDashboardState {
  final String message;

  const CobradorDashboardError(this.message);

  @override
  List<Object?> get props => [message];
}

// ════════════════════════════════════════════════════════════
// CUBIT
// ════════════════════════════════════════════════════════════

class DashboardCobradorCubit extends Cubit<CobradorDashboardState> {
  final ApiClient _api;

  DashboardCobradorCubit({ApiClient? api})
      : _api = api ?? ApiClient.instance,
        super(const CobradorDashboardInitial());

  Future<void> loadDashboard({bool silent = false}) async {
    if (!silent && LocalCacheRepository.instance.getCached('dashboard:cobrador') == null) {
      emit(const CobradorDashboardLoading());
    }

    await LocalCacheRepository.instance.executeSWR<Map<String, dynamic>>(
      key: 'dashboard:cobrador',
      fetcher: () async {
        final response = await _api.get('/dashboard/cobrador');
        return response.data as Map<String, dynamic>;
      },
      onData: (json, isStale) {
        final data = CobradorDashboardData.fromJson(json);
        emit(CobradorDashboardLoaded(data));
      },
      onError: (e) {
        if (!silent && LocalCacheRepository.instance.getCached('dashboard:cobrador') == null) {
          emit(CobradorDashboardError('Error al cargar jornada: $e'));
        }
      },
    );
  }

  Future<void> refresh({bool silent = true}) async {
    await loadDashboard(silent: silent);
  }

  /// Mutación optimista e instantánea al registrar un pago en la jornada
  void optimisticRegistrarPago({
    required String residenteId,
    required int montoPesos,
  }) {
    if (state is! CobradorDashboardLoaded) return;
    final currentData = (state as CobradorDashboardLoaded).data;

    // 1. Filtrar o actualizar viviendas
    final updatedCasas = currentData.casas.map((c) {
      if (c['residenteId'] == residenteId || c['id'] == residenteId) {
        final currentMonto = (c['montoAdeudado'] as num? ?? c['saldo'] as num? ?? 0).toInt();
        final newMonto = (currentMonto - montoPesos).clamp(0, 99999999);
        final newMap = Map<String, dynamic>.from(c);
        newMap['montoAdeudado'] = newMonto;
        newMap['saldo'] = newMonto;
        if (newMonto == 0) {
          newMap['peorEstado'] = 'AL_DIA';
          newMap['estado'] = 'AL_DIA';
        }
        return newMap;
      }
      return c;
    }).where((c) {
      final monto = (c['montoAdeudado'] as num? ?? c['saldo'] as num? ?? 0).toInt();
      return monto > 0;
    }).toList();

    // 2. Determinar próxima vivienda activa
    Map<String, dynamic>? newProxima = currentData.proximaVivienda;
    if (updatedCasas.isNotEmpty) {
      newProxima = updatedCasas.first;
    } else {
      newProxima = null;
    }

    // 3. Remover cualquier solicitud resuelta para este residente
    final updatedSolicitudes = currentData.solicitudes.where((s) {
      final rId = s['residenteId'] as String? ?? s['usuarioId'] as String? ?? '';
      return rId != residenteId;
    }).toList();

    final newData = CobradorDashboardData(
      cobradorNombre: currentData.cobradorNombre,
      totalViviendas: currentData.totalViviendas,
      cobradosHoy: currentData.cobradosHoy + 1,
      montoCobradoHoy: currentData.montoCobradoHoy + montoPesos,
      pendientes: (currentData.pendientes - 1).clamp(0, 99999),
      vencidas: currentData.vencidas,
      montoEsperado: currentData.montoEsperado,
      casas: updatedCasas,
      proximaVivienda: newProxima,
      ultimosCobros: currentData.ultimosCobros,
      solicitudes: updatedSolicitudes,
    );

    emit(CobradorDashboardLoaded(newData));
  }

  /// Cambia el estado de una solicitud (ej. a EN_CAMINO) optimista e invoca la API
  void cambiarEstadoSolicitud(String solicitudId, String nuevoEstado) {
    if (state is! CobradorDashboardLoaded) return;
    final currentData = (state as CobradorDashboardLoaded).data;

    final updatedSolicitudes = currentData.solicitudes.map((s) {
      if (s['id'] == solicitudId) {
        final map = Map<String, dynamic>.from(s);
        map['estado'] = nuevoEstado;
        return map;
      }
      return s;
    }).toList();

    final newData = CobradorDashboardData(
      cobradorNombre: currentData.cobradorNombre,
      totalViviendas: currentData.totalViviendas,
      cobradosHoy: currentData.cobradosHoy,
      montoCobradoHoy: currentData.montoCobradoHoy,
      pendientes: currentData.pendientes,
      vencidas: currentData.vencidas,
      montoEsperado: currentData.montoEsperado,
      casas: currentData.casas,
      proximaVivienda: currentData.proximaVivienda,
      ultimosCobros: currentData.ultimosCobros,
      solicitudes: updatedSolicitudes,
    );

    emit(CobradorDashboardLoaded(newData));

    if (nuevoEstado == 'EN_CAMINO') {
      _api.patch('/solicitudes/$solicitudId/en-camino').ignore();
    }
  }
}
