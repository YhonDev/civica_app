import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/network/local_cache_repository.dart';
import '../cartera_repository.dart';
import '../models/cartera_models.dart';

// ════════════════════════════════════════════════════════════
// STATE
// ════════════════════════════════════════════════════════════

class CarteraState extends Equatable {
  final List<CobroItem> cobros;
  final CarteraResumen resumen;
  final String activeFilter; // 'Todos', 'Pendiente', 'Mora', 'Pagado'
  final bool showCalendar;
  final bool isLoading;
  final String? error;

  const CarteraState({
    this.cobros = const [],
    this.resumen = const CarteraResumen(
      totalPendiente: 0,
      totalMora: 0,
      totalPagado: 0,
      cantidadPendientes: 0,
      cantidadMora: 0,
      cantidadPagados: 0,
    ),
    this.activeFilter = 'Pendiente',
    this.showCalendar = false,
    this.isLoading = false,
    this.error,
  });

  CarteraState copyWith({
    List<CobroItem>? cobros,
    CarteraResumen? resumen,
    String? activeFilter,
    bool? showCalendar,
    bool? isLoading,
    String? error,
  }) {
    return CarteraState(
      cobros: cobros ?? this.cobros,
      resumen: resumen ?? this.resumen,
      activeFilter: activeFilter ?? this.activeFilter,
      showCalendar: showCalendar ?? this.showCalendar,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// Retorna la lista de cobros filtrada según el filtro activo.
  List<CobroItem> get filteredCobros {
    if (activeFilter == 'Todos') return cobros;
    // Normalizamos a minúsculas para comparar con los estados 'Pendiente', 'Mora', 'Pagado'
    final filterLower = activeFilter.toLowerCase();
    return cobros.where((c) {
      final estadoLower = c.estado.toLowerCase();
      // Soporte para variaciones de nombres de estado
      if (filterLower == 'mora') {
        return estadoLower == 'mora' || estadoLower == 'vencida';
      }
      if (filterLower == 'pagado') {
        return estadoLower == 'pagado' || estadoLower == 'pagada';
      }
      return estadoLower == filterLower;
    }).toList();
  }

  @override
  List<Object?> get props => [cobros, resumen, activeFilter, showCalendar, isLoading, error];
}

// ════════════════════════════════════════════════════════════
// CUBIT
// ════════════════════════════════════════════════════════════

class CarteraCubit extends Cubit<CarteraState> {
  final CarteraRepository _repository;

  CarteraCubit(this._repository) : super(const CarteraState());

  /// Carga los cobros de la cartera y calcula el resumen de forma local.
  Future<void> loadCobros({bool silent = false}) async {
    if (!silent && LocalCacheRepository.instance.getCached('cartera:cobros') == null) {
      emit(state.copyWith(isLoading: true, error: null));
    }

    await LocalCacheRepository.instance.executeSWR<List<CobroItem>>(
      key: 'cartera:cobros',
      fetcher: () => _repository.getCobros(),
      onData: (cobros, isStale) {
        final resumen = CarteraRepository.computeResumen(cobros);
        emit(state.copyWith(
          cobros: cobros,
          resumen: resumen,
          isLoading: false,
          error: null,
        ));
      },
      onError: (e) {
        if (!silent && LocalCacheRepository.instance.getCached('cartera:cobros') == null) {
          emit(state.copyWith(isLoading: false, error: e.toString()));
        }
      },
    );
  }

  /// Cambia el filtro de estado de cuenta seleccionado.
  void setFilter(String filter) {
    emit(state.copyWith(activeFilter: filter));
  }

  /// Alterna entre vista de calendario y vista de lista.
  void toggleView() {
    emit(state.copyWith(showCalendar: !state.showCalendar));
  }
}
