import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/network/error_messages.dart';
import '../data/platform_api_service.dart';
import '../models/platform_models.dart';

// ── State ─────────────────────────────────────────────────────────────

class TenantDetailState extends Equatable {
  final TenantDetailData? data;
  final List<TenantInvitationItem> invitations;
  final bool isLoading;
  final bool isInviting;
  final bool isRevoking;
  final String? errorMessage;
  final String? successMessage;
  final TenantInvitationItem? lastCreatedInvitation;

  const TenantDetailState({
    this.data,
    this.invitations = const [],
    this.isLoading = false,
    this.isInviting = false,
    this.isRevoking = false,
    this.errorMessage,
    this.successMessage,
    this.lastCreatedInvitation,
  });

  TenantDetailState copyWith({
    TenantDetailData? Function()? data,
    List<TenantInvitationItem>? invitations,
    bool? isLoading,
    bool? isInviting,
    bool? isRevoking,
    String? Function()? errorMessage,
    String? Function()? successMessage,
    TenantInvitationItem? Function()? lastCreatedInvitation,
  }) {
    return TenantDetailState(
      data: data != null ? data() : this.data,
      invitations: invitations ?? this.invitations,
      isLoading: isLoading ?? this.isLoading,
      isInviting: isInviting ?? this.isInviting,
      isRevoking: isRevoking ?? this.isRevoking,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      successMessage: successMessage != null ? successMessage() : this.successMessage,
      lastCreatedInvitation: lastCreatedInvitation != null
          ? lastCreatedInvitation()
          : this.lastCreatedInvitation,
    );
  }

  @override
  List<Object?> get props => [
        data,
        invitations,
        isLoading,
        isInviting,
        isRevoking,
        errorMessage,
        successMessage,
        lastCreatedInvitation,
      ];
}

// ── Cubit ─────────────────────────────────────────────────────────────

class TenantDetailCubit extends Cubit<TenantDetailState> {
  final PlatformApiService _apiService;

  TenantDetailCubit([PlatformApiService? apiService])
      : _apiService = apiService ?? PlatformApiService(),
        super(const TenantDetailState());

  Future<void> loadDetail(String tenantId) async {
    emit(state.copyWith(
      isLoading: true,
      errorMessage: () => null,
      lastCreatedInvitation: () => null,
    ));

    try {
      final detailFuture = _apiService.getTenantDetail(tenantId);
      final invitationsFuture = _apiService.listInvitations(tenantId);

      final detail = await detailFuture;
      final invitations = await invitationsFuture;

      emit(state.copyWith(
        data: () => detail,
        invitations: invitations,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: () => sanitizeApiError(e),
      ));
    }
  }

  Future<TenantInvitationItem?> createInvitation({
    required String tenantId,
    required String email,
    required String name,
  }) async {
    emit(state.copyWith(
      isInviting: true,
      errorMessage: () => null,
      successMessage: () => null,
      lastCreatedInvitation: () => null,
    ));

    try {
      final invitation = await _apiService.createInvitation(
        tenantId,
        email: email,
        name: name,
      );

      // Re-fetch invitations to have complete sorted list
      final updatedInvitations = await _apiService.listInvitations(tenantId);

      emit(state.copyWith(
        invitations: updatedInvitations,
        isInviting: false,
        lastCreatedInvitation: () => invitation,
        successMessage: () => 'Invitación generada exitosamente para ${invitation.email}',
      ));
      return invitation;
    } catch (e) {
      emit(state.copyWith(
        isInviting: false,
        errorMessage: () => sanitizeApiError(e),
      ));
      return null;
    }
  }

  Future<bool> revokeInvitation({
    required String tenantId,
    required String invitationId,
  }) async {
    emit(state.copyWith(
      isRevoking: true,
      errorMessage: () => null,
      successMessage: () => null,
    ));

    try {
      await _apiService.revokeInvitation(invitationId);
      final updatedInvitations = await _apiService.listInvitations(tenantId);

      emit(state.copyWith(
        invitations: updatedInvitations,
        isRevoking: false,
        successMessage: () => 'Invitación revocada correctamente',
      ));
      return true;
    } catch (e) {
      emit(state.copyWith(
        isRevoking: false,
        errorMessage: () => sanitizeApiError(e),
      ));
      return false;
    }
  }

  Future<bool> updateStatus({
    required String tenantId,
    required TenantStatus newStatus,
  }) async {
    emit(state.copyWith(
      isLoading: true,
      errorMessage: () => null,
      successMessage: () => null,
    ));

    try {
      final updatedTenant = await _apiService.updateTenantStatus(tenantId, newStatus);
      if (state.data != null) {
        final current = state.data!;
        final updatedData = TenantDetailData(
          tenant: updatedTenant,
          projects: current.projects,
          administrators: current.administrators,
          summary: current.summary,
        );
        emit(state.copyWith(
          data: () => updatedData,
          isLoading: false,
          successMessage: () => 'Estado actualizado a ${newStatus.label}',
        ));
      } else {
        emit(state.copyWith(isLoading: false));
      }
      return true;
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: () => sanitizeApiError(e),
      ));
      return false;
    }
  }
}
