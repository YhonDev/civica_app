import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/network/local_cache_repository.dart';
import '../../../core/search/cartera_search_index.dart';
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

  /// Retorna la lista de cobros filtrada según el filtro activo y ordenada por criterio financiero.
  List<CobroItem> get filteredCobros {
    final filterLower = activeFilter.toLowerCase();
    final List<CobroItem> list;

    if (activeFilter == 'Todos') {
      list = List.from(cobros);
    } else {
      list = cobros.where((c) {
        final estadoLower = c.estado.toLowerCase();
        if (filterLower == 'mora') {
          return estadoLower == 'mora' || estadoLower == 'vencida';
        }
        if (filterLower == 'pagado') {
          return estadoLower == 'pagado' || estadoLower == 'pagada';
        }
        return estadoLower == filterLower;
      }).toList();
    }

    // Reglas de ordenamiento financiero:
    if (filterLower == 'mora') {
      // Mora: Deuda más antigua arriba (ascendente por fecha de vencimiento)
      list.sort((a, b) => a.fechaVencimiento.compareTo(b.fechaVencimiento));
    } else if (filterLower == 'pendiente') {
      // Pendiente: Próximo vencimiento arriba (ascendente por fecha de vencimiento)
      list.sort((a, b) => a.fechaVencimiento.compareTo(b.fechaVencimiento));
    } else if (filterLower == 'pagado') {
      // Pagado: Recaudo más reciente arriba (descendente por fecha de pago)
      list.sort((a, b) {
        final dateA = a.fechaPago.isNotEmpty ? a.fechaPago : a.fechaVencimiento;
        final dateB = b.fechaPago.isNotEmpty ? b.fechaPago : b.fechaVencimiento;
        return dateB.compareTo(dateA);
      });
    }

    return list;
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

  // ── Índice de búsqueda precomputado ────────────────────────
  CarteraSearchIndex? _searchIndex;
  List<CobroItem>? _indexedSource;

  /// Índice de búsqueda para los cobros cargados. Se construye UNA vez por
  /// lista (identidad por referencia: cada carga del repository produce una
  /// lista nueva) y se reutiliza en cada pulsación del buscador o cambio de
  /// filtro, evitando reconstruirlo (O(n)) en cada rebuild del widget.
  CarteraSearchIndex get searchIndex {
    final cobros = state.cobros;
    if (_searchIndex == null || !identical(_indexedSource, cobros)) {
      _searchIndex = CarteraSearchIndex.build(cobros);
      _indexedSource = cobros;
    }
    return _searchIndex!;
  }

  /// Carga los cobros de la cartera y calcula el resumen de forma local.
  Future<void> loadCobros({bool silent = false}) async {
    final key = _repository.cacheKey;
    if (!silent && LocalCacheRepository.instance.getCached(key) == null) {
      emit(state.copyWith(isLoading: true, error: null));
    }

    await LocalCacheRepository.instance.executeSWR<List<CobroItem>>(
      key: key,
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
        if (!silent && LocalCacheRepository.instance.getCached(key) == null) {
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
