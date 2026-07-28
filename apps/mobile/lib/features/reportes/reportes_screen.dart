import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/mini_stat_card.dart';
import '../../shared/widgets/donut_chart.dart';
import '../../shared/widgets/month_selector.dart';
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

  final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0, locale: 'es_CO');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes de Recaudo'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Month Selector
                  MonthSelector(
                    currentMonth: _selectedDate,
                    onMonthChanged: (newDate) {
                      setState(() {
                        _selectedDate = newDate;
                      });
                      _loadData();
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Main KPIs Grid
                  Row(
                    children: [
                      MiniStatCard(
                        label: 'Total Recaudado',
                        value: currencyFormat.format(_data?.totalRecaudado ?? 0),
                        icon: Icons.monetization_on_rounded,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      MiniStatCard(
                        label: 'Pendiente',
                        value: currencyFormat.format(_data?.totalPendiente ?? 0),
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
                        value: currencyFormat.format(_data?.totalVencido ?? 0),
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

                  const SizedBox(height: AppSpacing.lg),

                  // Donut Chart - Distribution
                  Text(
                    'Distribución de Cobros por Estado',
                    style: AppTypography.subtitle.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: AppColors.border),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Center(
                        child: DonutChart(
                          segments: [
                            DonutSegment(
                              percentage: (_data?.pagadasCount ?? 1).toDouble(),
                              color: AppColors.success,
                              label: 'Pagadas (${_data?.pagadasCount})',
                            ),
                            DonutSegment(
                              percentage: (_data?.pendientesCount ?? 0).toDouble(),
                              color: AppColors.warning,
                              label: 'Pendientes (${_data?.pendientesCount})',
                            ),
                            DonutSegment(
                              percentage: (_data?.vencidasCount ?? 0).toDouble(),
                              color: AppColors.error,
                              label: 'Vencidas (${_data?.vencidasCount})',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Summary Table
                  Text(
                    'Resumen del Período',
                      style: AppTypography.subtitle.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            leading: Icon(Icons.flag_rounded, color: AppColors.primary),
                            title: const Text('Meta del Mes'),
                            trailing: Text(
                              currencyFormat.format(_data?.meta ?? 0),
                              style: AppTypography.body.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: Icon(Icons.check_circle_rounded, color: AppColors.success),
                            title: const Text('Recaudado Real'),
                            trailing: Text(
                              currencyFormat.format(_data?.totalRecaudado ?? 0),
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
                              currencyFormat.format(_data?.totalVencido ?? 0),
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
                ),
              ),
    );
  }
}
