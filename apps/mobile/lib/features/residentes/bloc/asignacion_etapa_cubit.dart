import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/network/api_client.dart';

// ════════════════════════════════════════════════════════════
// STATE
// ════════════════════════════════════════════════════════════

class AsignacionEtapaState extends Equatable {
  final List<Map<String, dynamic>> allEtapas;
  final Set<String> selectedIds;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final bool isSuccess;

  const AsignacionEtapaState({
    this.allEtapas = const [],
    this.selectedIds = const {},
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
    this.isSuccess = false,
  });

  AsignacionEtapaState copyWith({
    List<Map<String, dynamic>>? allEtapas,
    Set<String>? selectedIds,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    bool? isSuccess,
  }) {
    return AsignacionEtapaState(
      allEtapas: allEtapas ?? this.allEtapas,
      selectedIds: selectedIds ?? this.selectedIds,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }

  @override
  List<Object?> get props => [
        allEtapas,
        selectedIds,
        isLoading,
        isSaving,
        errorMessage,
        isSuccess,
      ];
}

// ════════════════════════════════════════════════════════════
// CUBIT
// ════════════════════════════════════════════════════════════

class AsignacionEtapaCubit extends Cubit<AsignacionEtapaState> {
  final ApiClient _api;
  late final String _cobradorId;

  AsignacionEtapaCubit({ApiClient? apiClient})
      : _api = apiClient ?? ApiClient.instance,
        super(const AsignacionEtapaState());

  /// Carga todas las etapas disponibles y las etapas asignadas al cobrador.
  Future<void> load(String cobradorId) async {
    _cobradorId = cobradorId;
    emit(state.copyWith(isLoading: true, errorMessage: null, isSuccess: false));
    try {
      final resEtapas = await _api.get('/comunidad/etapas');
      final etapas = List<Map<String, dynamic>>.from(resEtapas.data as List? ?? []);

      final resAsignadas = await _api.get('/usuarios/$cobradorId/etapas');
      final asignadas = List<Map<String, dynamic>>.from(resAsignadas.data as List? ?? []);
      final asignadasIds = asignadas.map((a) => a['etapaId'] as String).toSet();

      emit(state.copyWith(
        allEtapas: etapas,
        selectedIds: asignadasIds,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: 'Error al cargar etapas: $e'));
    }
  }

  /// Alterna la selección de una etapa en memoria.
  void toggle(String etapaId) {
    final updated = Set<String>.from(state.selectedIds);
    if (updated.contains(etapaId)) {
      updated.remove(etapaId);
    } else {
      updated.add(etapaId);
    }
    emit(state.copyWith(selectedIds: updated));
  }

  /// Guarda todas las etapas seleccionadas usando el endpoint PUT (bulk).
  Future<void> save() async {
    emit(state.copyWith(isSaving: true, errorMessage: null));
    try {
      await _api.put(
        '/usuarios/$_cobradorId/etapas',
        data: {'etapaIds': state.selectedIds.toList()},
      );
      emit(state.copyWith(isSaving: false, isSuccess: true));
    } catch (e) {
      emit(state.copyWith(isSaving: false, errorMessage: 'Error al guardar asignaciones: $e'));
    }
  }

  /// Elimina una etapa específica usando el endpoint DELETE.
  Future<void> remove(String etapaId) async {
    emit(state.copyWith(isSaving: true, errorMessage: null));
    try {
      await _api.delete('/usuarios/$_cobradorId/etapas/$etapaId');
      final updated = Set<String>.from(state.selectedIds)..remove(etapaId);
      emit(state.copyWith(isSaving: false, selectedIds: updated));
    } catch (e) {
      emit(state.copyWith(isSaving: false, errorMessage: 'Error al desasignar etapa: $e'));
    }
  }
}
