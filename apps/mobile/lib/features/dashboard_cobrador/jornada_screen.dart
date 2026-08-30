import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../screens/auth/auth_cubit.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

import '../cartera/models/cartera_models.dart';
import '../cartera/widgets/registrar_pago_bottom_sheet.dart';
import 'dashboard_cobrador_cubit.dart';

/// Cobrador Jornada — Pantalla principal del Cobrador.
///
/// Enfocada en la **ruta de trabajo**, no en residentes.
/// Muestra: stats de la jornada, próxima vivienda a visitar,
/// lista de casas pendientes con semáforo 🟢🟠🔴.
class JornadaScreen extends StatelessWidget {
  final DashboardCobradorCubit? cubit;

  const JornadaScreen({super.key, this.cubit});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DashboardCobradorCubit>(
      create: (_) => cubit ?? (DashboardCobradorCubit()..loadDashboard()),
      child: const _JornadaView(),
    );
  }
}

class _JornadaView extends StatefulWidget {
  const _JornadaView();

  @override
  State<_JornadaView> createState() => _JornadaViewState();
}

class _JornadaViewState extends State<_JornadaView> {
  String _filterModalidad = 'TODAS';
  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthCubit>().state.usuario;
    final nombre = user?['nombre'] as String? ?? 'Usuario';
    final hoy = DateFormat("EEEE, d 'de' MMMM", 'es').format(DateTime.now());

    return Scaffold(
      body: BlocBuilder<DashboardCobradorCubit, CobradorDashboardState>(
        builder: (context, state) {
          if (state is CobradorDashboardLoading || state is CobradorDashboardInitial) {
            return _buildSkeletonLoading(nombre, hoy);
          } else if (state is CobradorDashboardLoaded) {
            return _buildContent(state.data, nombre, hoy);
          }
          return _buildError((state as CobradorDashboardError).message);
        },
      ),
    );
  }

  // ── Skeleton Loading ──────────────────────────────────────────────

  Widget _buildSkeletonLoading(String nombre, String hoy) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.lg),
            _skeletonText(width: 100, height: 16),
            const SizedBox(height: AppSpacing.xs),
            _skeletonText(width: 140, height: 28),
            const SizedBox(height: AppSpacing.xs),
            _skeletonText(width: 180, height: 14),
            const SizedBox(height: AppSpacing.lg),
            // Stats row skeleton
            Row(
              children: List.generate(3, (i) => Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: i == 2 ? 0 : AppSpacing.sm),
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  ),
                ),
              )),
            ),
            const SizedBox(height: AppSpacing.lg),
            // Próxima vivienda skeleton
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _skeletonText(width: 160, height: 20),
            const SizedBox(height: AppSpacing.md),
            // List skeletons
            ...List.generate(4, (i) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _skeletonText({double width = 80, double height = 14}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  // ── Content ───────────────────────────────────────────────────────

  Widget _buildContent(CobradorDashboardData data, String nombre, String hoy) {
    final filteredCasas = data.casas.where((v) {
      if (_filterModalidad == 'TODAS') return true;
      final proximoVenc = v['proximoVencimiento'] as String?;
      if (proximoVenc == null) return true;
      final date = DateTime.tryParse(proximoVenc);
      if (date == null) return true;

      final now = DateTime.now();
      if (_filterModalidad == 'SEMANA') {
        final diffDays = date.difference(now).inDays;
        return diffDays <= 7 || date.isBefore(now);
      } else if (_filterModalidad == 'QUINCENA') {
        final diffDays = date.difference(now).inDays;
        return diffDays <= 15 || date.isBefore(now);
      } else if (_filterModalidad == 'MES') {
        return (date.month == now.month && date.year == now.year) || date.isBefore(now);
      }
      return true;
    }).toList();

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => context.read<DashboardCobradorCubit>().refresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.lg),

            // ── Header ──────────────────────────────────────────────
            Text(
              'Buenos días,',
              style: AppTypography.body.copyWith(color: AppColors.textSecondary),
            ),
            Text(
              nombre.split(' ').first,
              style: AppTypography.title.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              hoy[0].toUpperCase() + hoy.substring(1),
              style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
            ),

            const SizedBox(height: AppSpacing.lg),

            // ── Stats: resumen de la jornada ────────────────────────
            _buildStatsRow(data),

            const SizedBox(height: AppSpacing.lg),

            // ── Próxima vivienda a visitar ──────────────────────────
            if (data.proximaVivienda != null) ...[
              _buildProximaVivienda(data.proximaVivienda!),
              const SizedBox(height: AppSpacing.lg),
            ],

            // ── Lista de casas pendientes ───────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Viviendas pendientes',
                  style: AppTypography.subtitle.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${filteredCasas.length} de ${data.casas.length}',
                  style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // Chips de filtrado por ventana de vencimiento
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip('Todas', 'TODAS'),
                  const SizedBox(width: 8),
                  _filterChip('Esta Semana', 'SEMANA'),
                  const SizedBox(width: 8),
                  _filterChip('Esta Quincena', 'QUINCENA'),
                  const SizedBox(width: 8),
                  _filterChip('Este Mes', 'MES'),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            if (filteredCasas.isEmpty)
              _buildEmptyState()
            else
              ...filteredCasas.map((v) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _ViviendaCard(vivienda: v),
              )),

            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  // ── Stats Row ────────────────────────────────────────────────────

  Widget _buildStatsRow(CobradorDashboardData data) {
    return Column(
      children: [
        // Fila principal: stats grandes
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.home_work_rounded,
                label: 'Total casas',
                value: '${data.totalViviendas}',
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _StatCard(
                icon: Icons.check_circle_rounded,
                label: 'Cobradas hoy',
                value: '${data.cobradosHoy}',
                color: AppColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        // Fila secundaria: pendientes y vencidas con semáforo
        Row(
          children: [
            Expanded(
              child: _MiniStatCard(
                icon: Icons.schedule_rounded,
                label: 'Pendientes',
                value: '${data.pendientes}',
                color: AppColors.warning,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _MiniStatCard(
                icon: Icons.error_outline_rounded,
                label: 'Vencidas',
                value: '${data.vencidas}',
                color: AppColors.error,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _MiniStatCard(
                icon: Icons.attach_money_rounded,
                label: 'Esperado',
                value: _formatPesos(data.montoEsperado),
                color: AppColors.info,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Próxima Vivienda ─────────────────────────────────────────────

  Widget _buildProximaVivienda(Map<String, dynamic> vivienda) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.near_me_rounded, color: Colors.white, size: 18),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Próxima vivienda',
                style: AppTypography.caption.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '${vivienda['etapaNombre'] ?? ''}',
            style: AppTypography.body.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${vivienda['manzanaNombre'] ?? ''} — ${vivienda['casaDireccion'] ?? ''}',
            style: AppTypography.subtitle.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final isSelected = _filterModalidad == value;
    final colorScheme = Theme.of(context).colorScheme;
    return FilterChip(
      selected: isSelected,
      label: Text(label),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? colorScheme.onPrimary : AppColors.textPrimary,
      ),
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.surface,
      onSelected: (_) {
        setState(() {
          _filterModalidad = value;
        });
      },
    );
  }

  // ── Empty State ──────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Column(
        children: [
          Icon(Icons.check_circle_outline_rounded, size: 48, color: AppColors.success),
          const SizedBox(height: AppSpacing.md),
          Text(
            '¡Jornada completa!',
            style: AppTypography.subtitle.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'No hay casas pendientes de cobro.',
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── Error View ───────────────────────────────────────────────────

  Widget _buildError(String message) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.error),
              const SizedBox(height: AppSpacing.md),
              Text(
                'No se pudo cargar la jornada',
                style: AppTypography.subtitle.copyWith(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Verifica tu conexión e intenta de nuevo.',
                style: AppTypography.body.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: () => context.read<DashboardCobradorCubit>().loadDashboard(),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// STAT CARDS
// ═══════════════════════════════════════════════════════════════════

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: AppSpacing.sm),
            Text(
              value,
              style: AppTypography.subtitle.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MiniStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(
              label,
              style: AppTypography.small.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// VIVIENDA CARD — Con semáforo 🟢🟠🔴
// ═══════════════════════════════════════════════════════════════════

class _ViviendaCard extends StatelessWidget {
  final Map<String, dynamic> vivienda;

  const _ViviendaCard({required this.vivienda});

  Color _semaforoColor(String estado) {
    switch (estado) {
      case 'PAGADA':
        return AppColors.success;
      case 'VENCIDA':
        return AppColors.error;
      case 'PARCIAL':
        return AppColors.info;
      default:
        return AppColors.warning;
    }
  }

  String _semaforoLabel(String estado) {
    switch (estado) {
      case 'PAGADA':
        return 'Pagó';
      case 'VENCIDA':
        return 'En mora';
      case 'PARCIAL':
        return 'Parcial';
      default:
        return 'Pendiente';
    }
  }

  String _semaforoIcon(String estado) {
    switch (estado) {
      case 'PAGADA':
        return '🟢';
      case 'VENCIDA':
        return '🔴';
      case 'PARCIAL':
        return '🔵';
      default:
        return '🟠';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final estado = vivienda['peorEstado'] as String? ?? 'PENDIENTE';
    final semaforoColor = _semaforoColor(estado);

    final cardBorderColor = estado == 'VENCIDA'
        ? AppColors.error.withValues(alpha: 0.4)
        : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0));

    final cuotas = vivienda['cuotas'] as List?;
    final firstCuota = cuotas != null && cuotas.isNotEmpty ? cuotas.first : null;

    // Formatear detalle de cuota + días vencidos
    String cuotaDetalleStr = '';
    if (firstCuota != null) {
      final concepto = firstCuota['concepto'] as String? ?? '';
      final periodo = firstCuota['periodoInicio'] as String? ?? '';
      final fechaVenc = firstCuota['fechaVencimiento'] as String? ?? '';
      
      String cuotaName = concepto.isNotEmpty ? concepto : periodo;
      if (cuotaName.isEmpty) cuotaName = 'Cuota de Recaudo';

      if (fechaVenc.isNotEmpty) {
        final date = DateTime.tryParse(fechaVenc);
        if (date != null) {
          final monthName = DateFormat('MMMM', 'es').format(date);
          final capitalizedMonth = monthName[0].toUpperCase() + monthName.substring(1);
          final fechaFormat = DateFormat("dd/MM/yyyy", 'es').format(date);
          final diffDays = DateTime.now().difference(date).inDays;
          final diasText = diffDays > 0 ? ' (Hace $diffDays días)' : '';

          if (estado == 'VENCIDA') {
            cuotaDetalleStr = '$capitalizedMonth · Vencido el $fechaFormat$diasText';
          } else {
            cuotaDetalleStr = '$capitalizedMonth · Vence el $fechaFormat';
          }
        }
      }
    }

    final manzanaName = vivienda['manzanaNombre'] as String? ?? 'Manzana A';
    final casaName = vivienda['casaDireccion'] as String? ?? '';
    final mainTitle = casaName.contains(manzanaName) ? casaName : '$manzanaName — $casaName';
    final etapaName = vivienda['etapaNombre'] as String? ?? 'Etapa 1';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cardBorderColor,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
                    final cobroId = firstCuota != null ? (firstCuota['id'] as String? ?? '') : '';
                    final firstCuotaMonto = firstCuota != null ? ((firstCuota['monto'] as num? ?? 20000).toDouble()) : 20000.0;
                    final saldoTotal = (vivienda['saldo'] as num? ?? 0).toDouble();

                    final cobroItem = CobroItem(
                      id: cobroId,
                      concepto: 'Cuota de Recaudo — $mainTitle',
                      monto: firstCuotaMonto > 0 ? firstCuotaMonto : 20000.0,
                      montoPagado: 0,
                      saldo: saldoTotal,
                      estado: vivienda['peorEstado'] as String? ?? 'Pendiente',
                      modalidad: vivienda['modalidadPago'] as String? ?? 'Mensual',
                      casa: vivienda['casaDireccion'] as String? ?? '',
                      manzana: vivienda['manzanaNombre'] as String? ?? '',
                      etapa: vivienda['etapaNombre'] as String? ?? '',
                      residenteId: vivienda['residenteId'] as String? ?? '',
                      nombre: vivienda['residenteNombre'] as String? ?? '',
                    );

                    RegistrarPagoBottomSheet.show(
                      context,
                      cobro: cobroItem,
                      cuotas: cuotas,
                      onSuccess: () {
                        context.read<DashboardCobradorCubit>().refresh();
                      },
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.cardInnerPadding),
                    child: Row(
                      children: [
                        // Semáforo circular
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: semaforoColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: semaforoColor.withValues(alpha: 0.3), width: 1),
                          ),
                          child: Center(
                            child: Text(
                              _semaforoIcon(estado),
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),

                        // Info de la vivienda
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  // TÍTULO: Ubicación / Casa (ej. Manzana A — Casa 2)
                                  Flexible(
                                    child: Text(
                                      '$mainTitle ($etapaName)',
                                      style: AppTypography.bodyMedium.copyWith(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (vivienda['tieneSolicitud'] == true) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.error.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: AppColors.error, width: 0.8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.notifications_active_rounded, size: 10, color: AppColors.error),
                                          const SizedBox(width: 3),
                                          Text(
                                            'Solicitud',
                                            style: AppTypography.small.copyWith(
                                              color: AppColors.error,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 3),
                              // Detalle de Cuota + Vencimiento (ej. Julio · Vencido el 15/07/2026 (Hace 44 días))
                              if (cuotaDetalleStr.isNotEmpty) ...[
                                Text(
                                  cuotaDetalleStr,
                                  style: AppTypography.caption.copyWith(
                                    color: estado == 'VENCIDA' ? AppColors.error : AppColors.primary,
                                    fontWeight: estado == 'VENCIDA' ? FontWeight.w700 : FontWeight.w600,
                                    fontSize: 11.5,
                                  ),
                                ),
                                const SizedBox(height: 3),
                              ],
                              // Residente + modalidad
                              Row(
                                children: [
                                  Icon(Icons.person_rounded, size: 14, color: AppColors.textSecondary),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      vivienda['residenteNombre'] ?? vivienda['propietarioNombre'] ?? 'Sin residente',
                                      style: AppTypography.small.copyWith(
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (vivienda['modalidadPago'] != null) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 0.8),
                                      ),
                                      child: Text(
                                        '${vivienda['modalidadPago']}',
                                        style: AppTypography.small.copyWith(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Monto + estado
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _formatPesos(vivienda['saldo'] as int? ?? 0),
                              style: AppTypography.bodyMedium.copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: estado == 'VENCIDA' ? AppColors.error : (isDark ? Colors.white : const Color(0xFF0F172A)),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: semaforoColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: semaforoColor.withValues(alpha: 0.4), width: 0.8),
                              ),
                              child: Text(
                                _semaforoLabel(estado),
                                style: AppTypography.small.copyWith(
                                  color: semaforoColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// HELPERS
// ═══════════════════════════════════════════════════════════════════

String _formatPesos(int pesos) {
  if (pesos >= 1000000) {
    return '\$${(pesos / 1000000).toStringAsFixed(1)}M';
  }
  if (pesos >= 1000) {
    return '\$${(pesos / 1000).toStringAsFixed(0)}K';
  }
  return '\$$pesos';
}
