import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../core/network/api_client.dart';

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
  final List<Map<String, dynamic>> viviendas;
  final Map<String, dynamic>? proximaVivienda;
  final List<Map<String, dynamic>> ultimosCobros;

  const CobradorDashboardData({
    required this.cobradorNombre,
    required this.totalViviendas,
    required this.cobradosHoy,
    required this.montoCobradoHoy,
    required this.pendientes,
    required this.vencidas,
    required this.montoEsperado,
    required this.viviendas,
    this.proximaVivienda,
    required this.ultimosCobros,
  });

  factory CobradorDashboardData.fromJson(Map<String, dynamic> json) {
    final stats = json['stats'] as Map<String, dynamic>? ?? {};
    return CobradorDashboardData(
      cobradorNombre: (json['cobrador'] as Map<String, dynamic>?)?['nombre'] as String? ?? '',
      totalViviendas: stats['totalViviendas'] as int? ?? 0,
      cobradosHoy: stats['cobradosHoy'] as int? ?? 0,
      montoCobradoHoy: stats['montoCobradoHoy'] as int? ?? 0,
      pendientes: stats['pendientes'] as int? ?? 0,
      vencidas: stats['vencidas'] as int? ?? 0,
      montoEsperado: stats['montoEsperado'] as int? ?? 0,
      viviendas: List<Map<String, dynamic>>.from(json['viviendas'] as List? ?? []),
      proximaVivienda: json['proximaVivienda'] as Map<String, dynamic>?,
      ultimosCobros: List<Map<String, dynamic>>.from(json['ultimosCobros'] as List? ?? []),
    );
  }

  @override
  List<Object?> get props => [
    cobradorNombre, totalViviendas, cobradosHoy, montoCobradoHoy,
    pendientes, vencidas, montoEsperado, viviendas, proximaVivienda, ultimosCobros,
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

  Future<void> loadDashboard() async {
    emit(const CobradorDashboardLoading());
    try {
      final response = await _api.get('/dashboard/cobrador');
      final data = CobradorDashboardData.fromJson(
        response.data as Map<String, dynamic>,
      );
      emit(CobradorDashboardLoaded(data));
    } catch (e) {
      emit(CobradorDashboardError('Error al cargar jornada: $e'));
    }
  }

  Future<void> refresh() async {
    await loadDashboard();
  }
}
