import 'package:flutter/material.dart';
import '../../core/theme/app_breakpoints.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/format/app_currency.dart';
import '../../shared/widgets/mini_stat_card.dart';
import '../../shared/widgets/donut_chart.dart';
import '../../shared/widgets/month_selector.dart';
import '../../shared/widgets/screen_header.dart';
import 'reportes_repository.dart';

class ReportesScreen extends StatefulWidget {
  const ReportesScreen({super.key});

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> {
  final _repository = ReportesRepository();
  bool _loading = true;
  ReporteData? _data;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final data = await _repository.getReporteRecaudo(
      mes: _selectedDate.month,
      anio: _selectedDate.year,
    );
    if (mounted) {
      setState(() {
        _data = data;
        _loading = false;
      });
    }
  }

  Widget _buildKpisGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Métricas de Recaudo',
          style: AppTypography.subtitle.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            MiniStatCard(
              label: 'Total Recaudado',
              value: AppCurrency.format(_data?.totalRecaudado ?? 0),
              icon: Icons.monetization_on_rounded,
              color: AppColors.success,
            ),
            const SizedBox(width: AppSpacing.xs),
            MiniStatCard(
              label: 'Pendiente',
              value: AppCurrency.format(_data?.totalPendiente ?? 0),
              icon: Icons.pending_actions_rounded,
              color: AppColors.warning,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            MiniStatCard(
              label: 'En Mora',
              value: AppCurrency.format(_data?.totalVencido ?? 0),
              icon: Icons.error_outline_rounded,
              color: AppColors.error,
            ),
            const SizedBox(width: AppSpacing.xs),
            MiniStatCard(
              label: '% Cumplimiento',
              value: '${_data?.porcentaje ?? 0}%',
              icon: Icons.pie_chart_rounded,
              color: AppColors.primary,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChartCard() {
    final pagadas = _data?.pagadasCount ?? 0;
    final pendientes = _data?.pendientesCount ?? 0;
    final vencidas = _data?.vencidasCount ?? 0;
    final total = pagadas + pendientes + vencidas;

    final pagadasPct = total > 0 ? (pagadas / total) * 100 : 0.0;
    final pendientesPct = total > 0 ? (pendientes / total) * 100 : 0.0;
    final vencidasPct = total > 0 ? (vencidas / total) * 100 : 0.0;
    final pctCompletado = _data?.porcentaje ?? (total > 0 ? pagadasPct.round() : 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Distribución de Cobros por Estado',
          style: AppTypography.subtitle.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.sm),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            side: BorderSide(color: AppColors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Center(
              child: DonutChart(
                centerText: '$pctCompletado%',
                centerLabel: 'completado',
                segments: [
                  DonutSegment(
                    percentage: pagadasPct,
                    color: AppColors.success,
                    label: 'Pagadas ($pagadas)',
                  ),
                  DonutSegment(
                    percentage: pendientesPct,
                    color: AppColors.warning,
                    label: 'Pendientes ($pendientes)',
                  ),
                  DonutSegment(
                    percentage: vencidasPct,
                    color: AppColors.error,
                    label: 'Vencidas ($vencidas)',
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResumenPeriodoCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resumen del Período',
          style: AppTypography.subtitle.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.sm),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            side: BorderSide(color: AppColors.border),
          ),
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.flag_rounded, color: AppColors.primary),
                title: const Text('Meta del Mes'),
                trailing: Text(
                  AppCurrency.format(_data?.meta ?? 0),
                  style: AppTypography.body.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(Icons.check_circle_rounded, color: AppColors.success),
                title: const Text('Recaudado Real'),
                trailing: Text(
                  AppCurrency.format(_data?.totalRecaudado ?? 0),
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(Icons.warning_rounded, color: AppColors.error),
                title: const Text('Saldo en Riesgo (Mora)'),
                trailing: Text(
                  AppCurrency.format(_data?.totalVencido ?? 0),
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.error,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = context.isWideScreen;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ScreenHeader(title: 'Reportes'),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: isWide
                                ? AppBreakpoints.maxContentWidth
                                : double.infinity,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Month Selector
                              Center(
                                child: MonthSelector(
                                  currentMonth: _selectedDate,
                                  onMonthChanged: (newDate) {
                                    setState(() {
                                      _selectedDate = newDate;
                                    });
                                    _loadData();
                                  },
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),

                              if (isWide) ...[
                                // Fila Superior Simétrica Desktop (50% / 50%)
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: _buildKpisGrid()),
                                    const SizedBox(width: AppSpacing.lg),
                                    Expanded(child: _buildChartCard()),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                _buildResumenPeriodoCard(),
                              ] else ...[
                                // Flujo Móvil Vertical
                                _buildKpisGrid(),
                                const SizedBox(height: AppSpacing.lg),
                                _buildChartCard(),
                                const SizedBox(height: AppSpacing.lg),
                                _buildResumenPeriodoCard(),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
