import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/network/error_messages.dart';
import '../data/platform_api_service.dart';
import '../models/platform_models.dart';

// ── State ─────────────────────────────────────────────────────────────

class PlatformAuditState extends Equatable {
  final List<PlatformAuditEventItem> events;
  final int total;
  final int page;
  final int limit;
  final String? actionFilter;
  final String? resourceFilter;
  final bool isLoading;
  final String? errorMessage;

  const PlatformAuditState({
    this.events = const [],
    this.total = 0,
    this.page = 1,
    this.limit = 25,
    this.actionFilter,
    this.resourceFilter,
    this.isLoading = false,
    this.errorMessage,
  });

  PlatformAuditState copyWith({
    List<PlatformAuditEventItem>? events,
    int? total,
    int? page,
    int? limit,
    String? Function()? actionFilter,
    String? Function()? resourceFilter,
    bool? isLoading,
    String? Function()? errorMessage,
  }) {
    return PlatformAuditState(
      events: events ?? this.events,
      total: total ?? this.total,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      actionFilter: actionFilter != null ? actionFilter() : this.actionFilter,
      resourceFilter: resourceFilter != null ? resourceFilter() : this.resourceFilter,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        events,
        total,
        page,
        limit,
        actionFilter,
        resourceFilter,
        isLoading,
        errorMessage,
      ];
}

// ── Cubit ─────────────────────────────────────────────────────────────

class PlatformAuditCubit extends Cubit<PlatformAuditState> {
  final PlatformApiService _apiService;

  PlatformAuditCubit([PlatformApiService? apiService])
      : _apiService = apiService ?? PlatformApiService(),
        super(const PlatformAuditState());

  Future<void> loadEvents({
    int? page,
    String? Function()? actionFilter,
    String? Function()? resourceFilter,
  }) async {
    final targetPage = page ?? state.page;
    final targetAction = actionFilter != null ? actionFilter() : state.actionFilter;
    final targetResource = resourceFilter != null ? resourceFilter() : state.resourceFilter;

    emit(state.copyWith(
      isLoading: true,
      errorMessage: () => null,
      page: targetPage,
      actionFilter: () => targetAction,
      resourceFilter: () => targetResource,
    ));

    try {
      final result = await _apiService.getAuditEvents(
        page: targetPage,
        limit: state.limit,
        action: targetAction,
        resource: targetResource,
      );

      emit(state.copyWith(
        events: result.data,
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
}
