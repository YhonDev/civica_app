import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/network/api_client.dart';
import '../cartera_consolidada_screen.dart';

// ════════════════════════════════════════════════════════════
// STATE
// ════════════════════════════════════════════════════════════

class ConsolidatedState extends Equatable {
  final List<ResidentConsolidadoItem> items;
  final String activeFilter; // 'TODOS', 'EN_MORA', 'PENDIENTE', 'AL_DIA'
  final String? selectedEtapaId;
  final String? selectedManzanaId;
  final List<Map<String, dynamic>> etapas;
  final List<Map<String, dynamic>> manzanas;
  final bool isLoading;
  final String? error;

  const ConsolidatedState({
    this.items = const [],
    this.activeFilter = 'TODOS',
    this.selectedEtapaId,
    this.selectedManzanaId,
    this.etapas = const [],
    this.manzanas = const [],
    this.isLoading = false,
    this.error,
  });

  ConsolidatedState copyWith({
    List<ResidentConsolidadoItem>? items,
    String? activeFilter,
    String? selectedEtapaId,
    String? selectedManzanaId,
    List<Map<String, dynamic>>? etapas,
    List<Map<String, dynamic>>? manzanas,
    bool? isLoading,
    String? error,
  }) {
    return ConsolidatedState(
      items: items ?? this.items,
      activeFilter: activeFilter ?? this.activeFilter,
      selectedEtapaId: selectedEtapaId ?? this.selectedEtapaId,
      selectedManzanaId: selectedManzanaId ?? this.selectedManzanaId,
      etapas: etapas ?? this.etapas,
      manzanas: manzanas ?? this.manzanas,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  // Calculated totals in the current filtered set (in COP)
  int get totalPorCobrar => items.fold(0, (sum, i) => sum + i.saldoPendiente);
  int get totalMora => items.fold(0, (sum, i) => sum + i.saldoVencido);
  int get totalAdeudado => items.fold(0, (sum, i) => sum + i.totalAdeudado);

  /// Retorna la lista de residentes filtrada por estado.
  List<ResidentConsolidadoItem> get filteredItems {
    if (activeFilter == 'TODOS') return items;
    return items.where((i) => i.estado == activeFilter).toList();
  }

  @override
  List<Object?> get props => [
        items,
        activeFilter,
        selectedEtapaId,
        selectedManzanaId,
        etapas,
        manzanas,
        isLoading,
        error
      ];
}

// ════════════════════════════════════════════════════════════
// CUBIT
// ════════════════════════════════════════════════════════════

class ConsolidatedCubit extends Cubit<ConsolidatedState> {
  final ApiClient _api;

  ConsolidatedCubit({ApiClient? apiClient})
      : _api = apiClient ?? ApiClient.instance,
        super(const ConsolidatedState());

  /// Carga la cartera consolidada junto con el listado de etapas y manzanas.
  Future<void> load({String? etapaId, String? manzanaId}) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      // 1. Cargar todas las etapas para los filtros
      final resEtapas = await _api.get('/comunidad/etapas');
      final etapas = List<Map<String, dynamic>>.from(resEtapas.data as List? ?? []);

      // 2. Cargar manzanas si hay una etapa seleccionada
      List<Map<String, dynamic>> manzanas = [];
      if (etapaId != null) {
        final resManzanas = await _api.get('/comunidad/etapas/$etapaId/manzanas');
        manzanas = List<Map<String, dynamic>>.from(resManzanas.data as List? ?? []);
      }

      // 3. Cargar la cartera consolidada con filtros de etapa y manzana
      final Map<String, dynamic> qParams = {};
      if (etapaId != null) qParams['etapaId'] = etapaId;
      if (manzanaId != null) qParams['manzanaId'] = manzanaId;

      final response = await _api.get('/dashboard/cartera-consolidada', queryParameters: qParams);
      final list = (response.data as List).map((i) => ResidentConsolidadoItem.fromJson(i)).toList();

      // Emitimos el nuevo estado limpio de manzana si es null o no pertenece a la lista actual de manzanas
      final bool manzanaValida = manzanas.any((m) => m['id'] == manzanaId);
      final String? finalManzanaId = manzanaValida ? manzanaId : null;

      emit(ConsolidatedState(
        items: list,
        etapas: etapas,
        manzanas: manzanas,
        selectedEtapaId: etapaId,
        selectedManzanaId: finalManzanaId,
        activeFilter: state.activeFilter,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: 'Error al cargar cartera consolidada: $e'));
    }
  }

  /// Cambia el filtro de estado seleccionado.
  void setFilter(String filter) {
    emit(state.copyWith(activeFilter: filter));
  }

  /// Cambia la etapa seleccionada y recarga los datos (resetea la manzana).
  Future<void> selectEtapa(String? etapaId) async {
    await load(etapaId: etapaId, manzanaId: null);
  }

  /// Cambia la manzana seleccionada y recarga los datos.
  Future<void> selectManzana(String? manzanaId) async {
    await load(etapaId: state.selectedEtapaId, manzanaId: manzanaId);
  }
}
