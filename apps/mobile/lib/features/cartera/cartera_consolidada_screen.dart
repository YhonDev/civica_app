import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/format/app_currency.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/status_badge.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/screen_header.dart';
import 'bloc/consolidated_cubit.dart';

class ResidentConsolidadoItem {
  final String residenteId;
  final String nombre;
  final String? telefono;
  final String? email;
  final String estado; // AL_DIA, PENDIENTE, EN_MORA
  final int saldoPendiente;
  final int saldoVencido;
  final int totalAdeudado;

  ResidentConsolidadoItem({
    required this.residenteId,
    required this.nombre,
    this.telefono,
    this.email,
    required this.estado,
    required this.saldoPendiente,
    required this.saldoVencido,
    required this.totalAdeudado,
  });

  factory ResidentConsolidadoItem.fromJson(Map<String, dynamic> json) {
    return ResidentConsolidadoItem(
      residenteId: json['residenteId'] ?? '',
      nombre: json['nombre'] ?? 'Residente',
      telefono: json['telefono'],
      email: json['email'],
      estado: json['estado'] ?? 'AL_DIA',
      saldoPendiente: (json['saldoPendiente'] as num?)?.toInt() ?? 0,
      saldoVencido: (json['saldoVencido'] as num?)?.toInt() ?? 0,
      totalAdeudado: (json['totalAdeudado'] as num?)?.toInt() ?? 0,
    );
  }
}

class CarteraConsolidadaScreen extends StatelessWidget {
  const CarteraConsolidadaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ConsolidatedCubit()..load(),
      child: Scaffold(
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ScreenHeader(title: 'Cobros'),
              Expanded(
                child: BlocBuilder<ConsolidatedCubit, ConsolidatedState>(
                  builder: (context, state) {
                    if (state.isLoading && state.items.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    return Column(
                      children: [
                        // ── CARTERA RESUMEN HEADER (CARTERA CARD ESTÁNDAR) ───
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.cardInnerPadding),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                              border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.account_balance_wallet_outlined, size: 18, color: AppColors.primary),
                                    const SizedBox(width: AppSpacing.xs),
                                    Text(
                                      'Resumen de Cartera Consolidada',
                                      style: AppTypography.caption.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildMetricTile(
                                        label: 'Mora',
                                        amount: state.totalMora.toDouble(),
                                        count: state.items.where((i) => i.estado == 'EN_MORA').length,
                                        badgeColor: AppColors.error,
                                        icon: Icons.warning_amber_rounded,
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.xs),
                                    Expanded(
                                      child: _buildMetricTile(
                                        label: 'Por Cobrar',
                                        amount: state.totalPorCobrar.toDouble(),
                                        count: state.items.where((i) => i.estado == 'PENDIENTE').length,
                                        badgeColor: AppColors.warning,
                                        icon: Icons.hourglass_top_rounded,
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.xs),
                                    Expanded(
                                      child: _buildMetricTile(
                                        label: 'Total Adeudado',
                                        amount: state.totalAdeudado.toDouble(),
                                        count: state.items.length,
                                        badgeColor: AppColors.primary,
                                        icon: Icons.check_circle_outline_rounded,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: AppSpacing.xs),

                        // ── FILTER CHIPS ─────────────────────────────────────
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.screenPadding,
                            vertical: AppSpacing.xs,
                          ),
                          child: Row(
                            children: [
                              _buildFilterChip(context, 'EN_MORA', 'En Mora (${state.items.where((i) => i.estado == "EN_MORA").length})', state.activeFilter, AppColors.error),
                              const SizedBox(width: 8),
                              _buildFilterChip(context, 'PENDIENTE', 'Pendiente (${state.items.where((i) => i.estado == "PENDIENTE").length})', state.activeFilter, AppColors.warning),
                              const SizedBox(width: 8),
                              _buildFilterChip(context, 'AL_DIA', 'Al Día (${state.items.where((i) => i.estado == "AL_DIA").length})', state.activeFilter, AppColors.success),
                              const SizedBox(width: 8),
                              _buildFilterChip(context, 'TODOS', 'Todos (${state.items.length})', state.activeFilter, AppColors.primary),
                            ],
                          ),
                        ),

                        // ── RESIDENTS LIST ───────────────────────────────────
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: () => context.read<ConsolidatedCubit>().load(
                                  etapaId: state.selectedEtapaId,
                                  manzanaId: state.selectedManzanaId,
                                ),
                            child: state.filteredItems.isEmpty
                                ? const SingleChildScrollView(
                                    physics: AlwaysScrollableScrollPhysics(),
                                    child: EmptyState(
                                      icon: Icons.people_outline_rounded,
                                      title: 'Sin residentes',
                                      description: 'No se encontraron residentes con este filtro.',
                                    ),
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.screenPadding,
                                      vertical: AppSpacing.xs,
                                    ),
                                    itemCount: state.filteredItems.length,
                                    itemBuilder: (context, index) {
                                      final item = state.filteredItems[index];
                                      return _buildResidentCobroCard(context, item);
                                    },
                                  ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required double amount,
    required int count,
    required Color badgeColor,
    required IconData icon,
  }) {
    final amountFormatted = AppCurrency.format(amount.round());

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
        border: Border.all(color: badgeColor.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: badgeColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.smallBold.copyWith(
                    color: badgeColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              amountFormatted,
              style: AppTypography.cardTitle.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$count casas',
            style: AppTypography.micro.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, String key, String label, String activeFilter, Color activeColor) {
    final isSelected = activeFilter == key;
    return FilterChip(
      selected: isSelected,
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      labelPadding: EdgeInsets.zero,
      label: Text(
        label,
        style: AppTypography.label.copyWith(
          color: isSelected ? Colors.white : AppColors.textPrimary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        ),
      ),
      selectedColor: activeColor,
      backgroundColor: AppColors.card,
      side: BorderSide(
        color: isSelected ? activeColor : AppColors.border.withValues(alpha: 0.5),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.chipRadius)),
      onSelected: (_) {
        context.read<ConsolidatedCubit>().setFilter(key);
      },
    );
  }

  Widget _buildResidentCobroCard(BuildContext context, ResidentConsolidadoItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isOverdue = item.estado == 'EN_MORA';
    final cardBorderColor = isOverdue
        ? AppColors.error.withValues(alpha: 0.4)
        : AppColors.track;

    StatusType statusType;
    if (item.estado == 'EN_MORA') {
      statusType = StatusType.mora;
    } else if (item.estado == 'PENDIENTE') {
      statusType = StatusType.pendiente;
    } else {
      statusType = StatusType.alDia;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: isDark ? AppColors.elevatedCard : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(
          color: cardBorderColor,
          width: isOverdue ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isOverdue
                    ? AppColors.error.withValues(alpha: 0.1)
                    : AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
              ),
              child: Icon(
                isOverdue ? Icons.home_work_outlined : Icons.person_outline_rounded,
                color: isOverdue ? AppColors.error : AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.nombre,
                    style: AppTypography.cardTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.email ?? item.telefono ?? 'Sin contacto asignado',
                    style: AppTypography.label.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                StatusBadge(status: statusType),
                const SizedBox(height: 6),
                if (item.totalAdeudado > 0)
                  Text(
                    AppCurrency.format(item.totalAdeudado),
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isOverdue ? AppColors.error : AppColors.warning,
                    ),
                  )
                else
                  Text(
                    'Al día',
                    style: AppTypography.label.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
