import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import 'dashboard_repository.dart';
import 'models/dashboard_data.dart';

// ════════════════════════════════════════════════════════════
// STATE
// ════════════════════════════════════════════════════════════

abstract class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {
  const DashboardInitial();
}

class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

class DashboardLoaded extends DashboardState {
  final DashboardData data;
  final int mes;
  final int anio;

  const DashboardLoaded({
    required this.data,
    required this.mes,
    required this.anio,
  });

  @override
  List<Object?> get props => [data, mes, anio];
}

class DashboardError extends DashboardState {
  final String message;

  const DashboardError(this.message);

  @override
  List<Object?> get props => [message];
}

// ════════════════════════════════════════════════════════════
// CUBIT
// ════════════════════════════════════════════════════════════

class DashboardCubit extends Cubit<DashboardState> {
  final DashboardRepository _repository;

  DashboardCubit({DashboardRepository? repository})
      : _repository = repository ?? DashboardRepository(),
        super(const DashboardInitial());

  /// Load the dashboard for a specific month/year.
  Future<void> loadDashboard(int mes, int anio) async {
    emit(const DashboardLoading());
    try {
      final data = await _repository.getDashboard(mes, anio);
      emit(DashboardLoaded(data: data, mes: mes, anio: anio));
    } catch (e) {
      emit(DashboardError('Error al cargar dashboard: $e'));
    }
  }

  /// Change month and reload.
  void changeMonth(int mes, int anio) {
    loadDashboard(mes, anio);
  }

  /// Load current month's dashboard.
  Future<void> loadCurrentMonth() async {
    final now = DateTime.now();
    await loadDashboard(now.month, now.year);
  }
}
