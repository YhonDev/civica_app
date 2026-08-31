import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../screens/auth/auth_cubit.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/lifecycle_observer_mixin.dart';

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

class _JornadaViewState extends State<_JornadaView> with LifecycleObserverMixin {
  @override
  void onAppResumed() {
    context.read<DashboardCobradorCubit>().loadDashboard(silent: true);
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

            // ── Próxima vivienda a visitar (Héroe interactivo) ──────
            if (data.proximaVivienda != null) ...[
              _buildProximaVivienda(data.proximaVivienda!),
              const SizedBox(height: AppSpacing.lg),
            ],

            // ── Card de Acceso Directo a Gestión de Cartera ─────────
            _buildCarteraDirectAccessBanner(data),

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
    final cuotas = vivienda['cuotas'] as List<dynamic>? ?? [];
    final firstCuotaMonto = cuotas.isNotEmpty
        ? (cuotas.first['monto'] as num? ?? 20000.0).toDouble()
        : (vivienda['montoAdeudado'] as num? ?? 20000.0).toDouble();
    final saldoTotal = (vivienda['montoAdeudado'] as num? ?? vivienda['saldo'] as num? ?? 20000.0).toDouble();

    final cobroItem = CobroItem(
      id: vivienda['id'] as String? ?? '0',
      concepto: 'Cuota Actual',
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

    return GestureDetector(
      onTap: () {
        final cobradorCubit = context.read<DashboardCobradorCubit>();
        RegistrarPagoBottomSheet.show(
          context,
          cobro: cobroItem,
          cuotas: cuotas,
          initialQuickMode: true,
          onSuccess: () {
            cobradorCubit.optimisticRegistrarPago(
              residenteId: cobroItem.residenteId,
              montoPesos: firstCuotaMonto > 0 ? firstCuotaMonto.toInt() : 10000,
            );
            cobradorCubit.refresh(silent: true);
          },
        );
      },
      child: Container(
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.near_me_rounded, color: Colors.white, size: 18),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Próxima vivienda a visitar',
                        style: AppTypography.caption.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Tocar para cobrar',
                      style: AppTypography.small.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
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
              if (vivienda['residenteNombre'] != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Residente: ${vivienda['residenteNombre']}',
                  style: AppTypography.caption.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
  }

  Widget _buildCarteraDirectAccessBanner(CobradorDashboardData data) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final count = data.casas.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.account_balance_wallet_outlined,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gestión de Cartera',
                      style: AppTypography.subtitle.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '$count viviendas registradas en ruta',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Gestiona todos los cobros, filtros por Manzana/Casa y liquidaciones desde el módulo oficial de Cartera.',
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                // Navigate to Cartera tab using DefaultTabController or BottomNavigationBar switch
                final mainTabState = context.findAncestorStateOfType<State>();
                if (mainTabState != null && mainTabState.mounted) {
                  // Fallback: reload state
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Selecciona la pestaña "Cobrar" en el menú inferior para gestionar la cartera.'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: const Text('Ir a Gestión de Cartera'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
              ),
            ),
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
