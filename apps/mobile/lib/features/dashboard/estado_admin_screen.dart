import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import 'dashboard_cubit.dart';
import 'models/dashboard_data.dart';
import 'widgets/evolucion_section.dart';
import 'widgets/balance_anual_bottom_sheet.dart';
import '../../shared/widgets/kpi_card.dart';
import '../../shared/widgets/mini_stat_card.dart';

class EstadoAdminScreen extends StatelessWidget {
  const EstadoAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DashboardCubit()..loadCurrentMonth(),
      child: const _EstadoAdminBody(),
    );
  }
}

class _EstadoAdminBody extends StatelessWidget {
  const _EstadoAdminBody();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Estado Financiero',
          style: AppTypography.title.copyWith(color: AppColors.textPrimary),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: BlocBuilder<DashboardCubit, DashboardState>(
        builder: (context, state) {
          if (state is DashboardLoaded) {
            return _EstadoContent(data: state.data);
          }
          if (state is DashboardLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return const Center(child: Text('Cargando...'));
        },
      ),
    );
  }
}

class _EstadoContent extends StatefulWidget {
  final DashboardData data;

  const _EstadoContent({required this.data});

  @override
  State<_EstadoContent> createState() => _EstadoContentState();
}

class _EstadoContentState extends State<_EstadoContent> {
  String _selectedFiltro = 'General';
  final List<String> _filtros = ['General', 'Mensual', 'Quincenal', 'Semanal'];

  void _showBalanceGeneral(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const BalanceAnualBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Calculamos valores mock dinámicos basados en el filtro seleccionado para dar interactividad
    double factor = 1.0;
    if (_selectedFiltro == 'Mensual') factor = 0.65;
    if (_selectedFiltro == 'Quincenal') factor = 0.25;
    if (_selectedFiltro == 'Semanal') factor = 0.10;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Estado General del Año
          const KpiCard(
            title: 'Acumulado 2026',
            amount: '\$145.3M',
            percentage: 95.0, // Mock: 95% del total esperado anual
            subtitle: 'Recaudo total anual. Mora Histórica: \$12.5M',
          ),
          const SizedBox(height: AppSpacing.xl),

          // 2. Filtros
          Text(
            'Detalle del mes actual',
            style: AppTypography.subtitle.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.md),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _filtros.map((filtro) {
                final isSelected = filtro == _selectedFiltro;
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: FilterChip(
                    label: Text(filtro),
                    selected: isSelected,
                    onSelected: (bool selected) {
                      setState(() {
                        _selectedFiltro = filtro;
                      });
                    },
                    selectedColor: AppColors.primary.withValues(alpha: 0.1),
                    checkmarkColor: AppColors.primary,
                    labelStyle: AppTypography.body.copyWith(
                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? AppColors.primary : AppColors.border,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Métricas filtradas
          Row(
            children: [
              MiniStatCard(
                icon: Icons.arrow_upward_rounded,
                label: 'Recaudo',
                value: '\$${((widget.data.recaudoMes * factor) / 1000000).toStringAsFixed(1)}M',
                color: AppColors.success,
              ),
              const SizedBox(width: AppSpacing.sm),
              MiniStatCard(
                icon: Icons.warning_rounded,
                label: 'Pendiente',
                value: '\$${((widget.data.mora * factor) / 1000000).toStringAsFixed(1)}M',
                color: AppColors.warning,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // 3. Evolución del recaudo
          EvolucionSection(evolucion: widget.data.evolucion),
          const SizedBox(height: AppSpacing.xl),

          // 4. Botón Balance General
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () => _showBalanceGeneral(context),
              icon: const Icon(Icons.calendar_month_rounded, color: Colors.white),
              label: const Text('Ver Balance Anual (12 Meses)', style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                shadowColor: AppColors.primary.withValues(alpha: 0.4),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  // UI delegada a componentes reusables compartidos.
}
