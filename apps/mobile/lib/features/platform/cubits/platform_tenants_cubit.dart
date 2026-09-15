import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/network/error_messages.dart';
import '../data/platform_api_service.dart';
import '../models/platform_models.dart';

// ── State ─────────────────────────────────────────────────────────────

class PlatformTenantsState extends Equatable {
  final List<PlatformTenantSummary> tenants;
  final int total;
  final int page;
  final int limit;
  final TenantStatus? statusFilter;
  final String searchQuery;
  final bool isLoading;
  final bool isCreating;
  final bool isUpdating;
  final String? errorMessage;
  final String? successMessage;

  const PlatformTenantsState({
    this.tenants = const [],
    this.total = 0,
    this.page = 1,
    this.limit = 25,
    this.statusFilter,
    this.searchQuery = '',
    this.isLoading = false,
    this.isCreating = false,
    this.isUpdating = false,
    this.errorMessage,
    this.successMessage,
  });

  /// Returns tenants filtered locally by search query.
  List<PlatformTenantSummary> get filteredTenants {
    if (searchQuery.trim().isEmpty) return tenants;
    final query = searchQuery.trim().toLowerCase();
    return tenants.where((t) {
      return t.name.toLowerCase().contains(query) ||
          t.id.toLowerCase().contains(query);
    }).toList();
  }

  PlatformTenantsState copyWith({
    List<PlatformTenantSummary>? tenants,
    int? total,
    int? page,
    int? limit,
    TenantStatus? Function()? statusFilter,
    String? searchQuery,
    bool? isLoading,
    bool? isCreating,
    bool? isUpdating,
    String? Function()? errorMessage,
    String? Function()? successMessage,
  }) {
    return PlatformTenantsState(
      tenants: tenants ?? this.tenants,
      total: total ?? this.total,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      statusFilter: statusFilter != null ? statusFilter() : this.statusFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      isCreating: isCreating ?? this.isCreating,
      isUpdating: isUpdating ?? this.isUpdating,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      successMessage: successMessage != null ? successMessage() : this.successMessage,
    );
  }

  @override
  List<Object?> get props => [
        tenants,
        total,
        page,
        limit,
        statusFilter,
        searchQuery,
        isLoading,
        isCreating,
        isUpdating,
        errorMessage,
        successMessage,
      ];
}

// ── Cubit ─────────────────────────────────────────────────────────────

class PlatformTenantsCubit extends Cubit<PlatformTenantsState> {
  final PlatformApiService _apiService;

  PlatformTenantsCubit([PlatformApiService? apiService])
      : _apiService = apiService ?? PlatformApiService(),
        super(const PlatformTenantsState());

  Future<void> loadTenants({
    int? page,
    TenantStatus? Function()? statusFilter,
  }) async {
    final targetPage = page ?? state.page;
    final targetFilter = statusFilter != null ? statusFilter() : state.statusFilter;

    emit(state.copyWith(
      isLoading: true,
      errorMessage: () => null,
      page: targetPage,
      statusFilter: () => targetFilter,
    ));

    try {
      final result = await _apiService.listTenants(
        page: targetPage,
        limit: state.limit,
        status: targetFilter,
      );

      emit(state.copyWith(
        tenants: result.data,
        total: result.total,
        page: result.page,
        limit: result.limit,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: () => sanitizeApiError(e),
      ));
    }
  }

  void updateSearchQuery(String query) {
    emit(state.copyWith(searchQuery: query));
  }

  Future<bool> createTenant({
    required String name,
    TenantStatus status = TenantStatus.active,
  }) async {
    emit(state.copyWith(
      isCreating: true,
      errorMessage: () => null,
      successMessage: () => null,
    ));

    try {
      final created = await _apiService.createTenant(name: name, status: status);
      final updatedList = [created, ...state.tenants];
      emit(state.copyWith(
        tenants: updatedList,
        total: state.total + 1,
        isCreating: false,
        successMessage: () => 'Tenant "${created.name}" creado exitosamente',
      ));
      return true;
    } catch (e) {
      emit(state.copyWith(
        isCreating: false,
        errorMessage: () => sanitizeApiError(e),
      ));
      return false;
    }
  }

  Future<bool> updateTenantStatus(String tenantId, TenantStatus newStatus) async {
    emit(state.copyWith(
      isUpdating: true,
      errorMessage: () => null,
      successMessage: () => null,
    ));

    try {
      final updated = await _apiService.updateTenantStatus(tenantId, newStatus);
      final updatedList = state.tenants.map((t) {
        return t.id == tenantId ? updated : t;
      }).toList();

      emit(state.copyWith(
        tenants: updatedList,
        isUpdating: false,
        successMessage: () => 'Estado del tenant actualizado a ${newStatus.label}',
      ));
      return true;
    } catch (e) {
      emit(state.copyWith(
        isUpdating: false,
        errorMessage: () => sanitizeApiError(e),
      ));
      return false;
    }
  }
}
