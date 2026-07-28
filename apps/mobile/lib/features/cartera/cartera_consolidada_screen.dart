import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/status_badge.dart';
import '../../shared/widgets/empty_state.dart';
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
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0, locale: 'es_CO');

    return BlocProvider(
      create: (context) => ConsolidatedCubit()..load(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Cartera Consolidada'),
          centerTitle: false,
        ),
        body: BlocBuilder<ConsolidatedCubit, ConsolidatedState>(
          builder: (context, state) {
            if (state.isLoading && state.items.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            return RefreshIndicator(
              onRefresh: () => context.read<ConsolidatedCubit>().load(
                    etapaId: state.selectedEtapaId,
                    manzanaId: state.selectedManzanaId,
                  ),
              child: Column(
                children: [
                  // ════════════════════════════════════════════════════════════
                  // SUMMARY METRICS HEADER
                  // ════════════════════════════════════════════════════════════
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: AppColors.border),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Row(
                          children: [
                            Expanded(
                              child: _MetricItem(
                                title: 'En Mora',
                                value: currencyFormat.format(state.totalMora),
                                color: AppColors.error,
                              ),
                            ),
                            Container(width: 1, height: 40, color: AppColors.border),
                            Expanded(
                              child: _MetricItem(
                                title: 'Pendiente',
                                value: currencyFormat.format(state.totalPorCobrar),
                                color: AppColors.warning,
                              ),
                            ),
                            Container(width: 1, height: 40, color: AppColors.border),
                            Expanded(
                              child: _MetricItem(
                                title: 'Total Adeudado',
                                value: currencyFormat.format(state.totalAdeudado),
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ════════════════════════════════════════════════════════════
                  // DROPDOWN FILTERS (ETAPA / MANZANA)
                  // ════════════════════════════════════════════════════════════
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String?>(
                            decoration: InputDecoration(
                              labelText: 'Etapa',
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            initialValue: state.selectedEtapaId,
                            items: [
                              const DropdownMenuItem(value: null, child: Text('Todas')),
                              ...state.etapas.map((e) => DropdownMenuItem(
                                    value: e['id'] as String?,
                                    child: Text(e['nombre'] ?? 'Etapa'),
                                  )),
                            ],
                            onChanged: (etapaId) {
                              context.read<ConsolidatedCubit>().selectEtapa(etapaId);
                            },
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: DropdownButtonFormField<String?>(
                            decoration: InputDecoration(
                              labelText: 'Manzana',
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            initialValue: state.selectedManzanaId,
                            items: [
                              const DropdownMenuItem(value: null, child: Text('Todas')),
                              ...state.manzanas.map((m) => DropdownMenuItem(
                                    value: m['id'] as String?,
                                    child: Text(m['nombre'] ?? 'Manzana'),
                                  )),
                            ],
                            onChanged: state.selectedEtapaId == null
                                ? null
                                : (manzanaId) {
                                    context.read<ConsolidatedCubit>().selectManzana(manzanaId);
                                  },
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // ════════════════════════════════════════════════════════════
                  // STATUS FILTER CHIPS
                  // ════════════════════════════════════════════════════════════
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                    child: Row(
                      children: [
                        _buildFilterChip(context, 'TODOS', 'Todos (${state.items.length})', state.activeFilter),
                        const SizedBox(width: 8),
                        _buildFilterChip(context, 'EN_MORA', 'En Mora (${state.items.where((i) => i.estado == "EN_MORA").length})', state.activeFilter),
                        const SizedBox(width: 8),
                        _buildFilterChip(context, 'PENDIENTE', 'Pendiente (${state.items.where((i) => i.estado == "PENDIENTE").length})', state.activeFilter),
                        const SizedBox(width: 8),
                        _buildFilterChip(context, 'AL_DIA', 'Al Día (${state.items.where((i) => i.estado == "AL_DIA").length})', state.activeFilter),
                      ],
                    ),
                  ),

                  // ════════════════════════════════════════════════════════════
                  // RESIDENTS LIST
                  // ════════════════════════════════════════════════════════════
                  Expanded(
                    child: state.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : state.filteredItems.isEmpty
                            ? const EmptyState(
                                icon: Icons.people_outline_rounded,
                                title: 'Sin residentes',
                                description: 'No se encontraron residentes con este filtro.',
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                itemCount: state.filteredItems.length,
                                separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                                itemBuilder: (context, index) {
                                  final item = state.filteredItems[index];
                                  StatusType statusType;
                                  if (item.estado == 'EN_MORA') {
                                    statusType = StatusType.mora;
                                  } else if (item.estado == 'PENDIENTE') {
                                    statusType = StatusType.pendiente;
                                  } else {
                                    statusType = StatusType.alDia;
                                  }

                                  return Card(
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      side: BorderSide(color: AppColors.border),
                                    ),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.md,
                                        vertical: AppSpacing.xs,
                                      ),
                                      title: Text(
                                        item.nombre,
                                        style: AppTypography.subtitle.copyWith(fontWeight: FontWeight.bold),
                                      ),
                                      subtitle: Text(
                                        item.email ?? item.telefono ?? 'Sin contacto',
                                        style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                                      ),
                                      trailing: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          StatusBadge(status: statusType),
                                          const SizedBox(height: 4),
                                          if (item.totalAdeudado > 0)
                                            Text(
                                              currencyFormat.format(item.totalAdeudado),
                                              style: AppTypography.caption.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: item.estado == 'EN_MORA' ? AppColors.error : AppColors.warning,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, String value, String label, String activeFilter) {
    final selected = activeFilter == value;
    return FilterChip(
      selected: selected,
      label: Text(label),
      onSelected: (_) {
        context.read<ConsolidatedCubit>().setFilter(value);
      },
    );
  }
}

class _MetricItem extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _MetricItem({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
