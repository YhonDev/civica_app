import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/network/error_messages.dart';
import '../data/platform_api_service.dart';
import '../models/platform_models.dart';

// ── State ─────────────────────────────────────────────────────────────

abstract class PlatformOverviewState extends Equatable {
  const PlatformOverviewState();

  @override
  List<Object?> get props => [];
}

class PlatformOverviewInitial extends PlatformOverviewState {
  const PlatformOverviewInitial();
}

class PlatformOverviewLoading extends PlatformOverviewState {
  const PlatformOverviewLoading();
}

class PlatformOverviewLoaded extends PlatformOverviewState {
  final PlatformOverviewData data;

  const PlatformOverviewLoaded(this.data);

  @override
  List<Object?> get props => [data];
}

class PlatformOverviewError extends PlatformOverviewState {
  final String message;

  const PlatformOverviewError(this.message);

  @override
  List<Object?> get props => [message];
}

// ── Cubit ─────────────────────────────────────────────────────────────

class PlatformOverviewCubit extends Cubit<PlatformOverviewState> {
  final PlatformApiService _apiService;

  PlatformOverviewCubit([PlatformApiService? apiService])
      : _apiService = apiService ?? PlatformApiService(),
        super(const PlatformOverviewInitial());

  Future<void> loadOverview() async {
    emit(const PlatformOverviewLoading());
    try {
      final data = await _apiService.getOverview();
      emit(PlatformOverviewLoaded(data));
    } catch (e) {
      emit(PlatformOverviewError(sanitizeApiError(e)));
    }
  }
}
