import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../screens/auth/auth_cubit.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

import 'dashboard_cobrador_cubit.dart';

/// Cobrador Jornada — Pantalla principal del Cobrador.
///
/// Enfocada en la **ruta de trabajo**, no en propietarios.
/// Muestra: stats de la jornada, próxima vivienda a visitar,
/// lista de casas pendientes con semáforo 🟢🟠🔴.
class JornadaScreen extends StatefulWidget {
  const JornadaScreen({super.key});

  @override
  State<JornadaScreen> createState() => _JornadaScreenState();
}

class _JornadaScreenState extends State<JornadaScreen> {
  @override
  void initState() {
    super.initState();
    context.read<DashboardCobradorCubit>().loadDashboard();
  }

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
                  '${data.casas.length}',
                  style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            if (data.casas.isEmpty)
              _buildEmptyState()
            else
              ...data.casas.map((v) => Padding(
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
              value,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
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
    final estado = vivienda['peorEstado'] as String? ?? 'PENDIENTE';
    final semaforoColor = _semaforoColor(estado);

    // Determinar borde izquierdo según estado
    final leftBorderColor = estado == 'VENCIDA'
        ? AppColors.error
        : estado == 'PARCIAL'
            ? AppColors.info
            : AppColors.warning;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: leftBorderColor, width: 4),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.cardInnerPadding),
          child: Row(
            children: [
              // Semáforo circular
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: semaforoColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
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
                    Text(
                      '${vivienda['casaDireccion'] ?? ''}',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${vivienda['etapaNombre'] ?? ''} — Mz. ${vivienda['manzanaNombre'] ?? ''}',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Propietario + teléfono
                    Row(
                      children: [
                        Icon(Icons.person_rounded, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            vivienda['propietarioNombre'] ?? 'Sin propietario',
                            style: AppTypography.small.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Monto + estado
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatPesos(vivienda['saldo'] as int? ?? 0),
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: semaforoColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _semaforoLabel(estado),
                      style: AppTypography.small.copyWith(
                        color: semaforoColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
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
