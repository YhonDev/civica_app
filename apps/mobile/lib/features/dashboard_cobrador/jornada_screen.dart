import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../screens/auth/auth_cubit.dart';
import '../../screens/cobro/payment_screen.dart';
import '../../core/database/app_database.dart';
import '../../core/database/daos/propietario_dao.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

import '../../core/network/api_client.dart';

/// Cobrador Dashboard — "Mi Jornada"
///
/// Per ROLE_DASHBOARDS.md and doc/19-dashboard-specification.md:
/// Responde: ¿Qué viviendas debo visitar hoy?
///
/// Layout:
///   Header: Buenos días + fecha
///   Stats: Cobros pendientes + Monto esperado
///   Botón principal: Iniciar / Continuar Jornada
///   Lista de cobros del día
class JornadaScreen extends StatefulWidget {
  const JornadaScreen({super.key});

  @override
  State<JornadaScreen> createState() => _JornadaScreenState();
}

class _JornadaScreenState extends State<JornadaScreen> {
  final _api = ApiClient.instance;
  Map<String, dynamic>? _dashboard;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final response = await _api.get('/dashboard/cobrador');
      if (mounted) {
        setState(() {
          _dashboard = response.data as Map<String, dynamic>;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading cobrador dashboard: $e');
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthCubit>().state.usuario;
    final nombre = user?['nombre'] as String? ?? 'Usuario';
    final hoy = DateFormat("EEEE, d 'de' MMMM", 'es').format(DateTime.now());

    return Scaffold(
      body: SafeArea(
        child: _loading 
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.lg),

              // ── Header ──────────────────────────────────────────────
              Text(
                'Buenos días,',
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                nombre.split(' ').first,
                style: AppTypography.title.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                hoy[0].toUpperCase() + hoy.substring(1),
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // ── Stats cards ─────────────────────────────────────────
              Row(
                children: [
                  Expanded(child: _StatCard(
                    icon: Icons.pending_actions_rounded,
                    label: 'Cobros pendientes',
                    value: '${_dashboard?['stats']?['pendientes'] ?? 0}',
                    color: AppColors.warning,
                  )),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: _StatCard(
                    icon: Icons.attach_money_rounded,
                    label: 'Monto esperado',
                    value: _formatMonto(_dashboard?['stats']?['montoEsperado'] ?? 0),
                    color: AppColors.primary,
                  )),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: _StatCard(
                    icon: Icons.check_circle_rounded,
                    label: 'Cobrados hoy',
                    value: '${_dashboard?['stats']?['cobradosHoy'] ?? 0}',
                    color: AppColors.success,
                  )),
                ],
              ),

              const SizedBox(height: AppSpacing.lg),

              const SizedBox(height: AppSpacing.md),

              // ── Lista de viviendas a cobrar ─────────────────────────
              Text(
                'Viviendas pendientes',
                style: AppTypography.subtitle.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              final viviendas = (_dashboard?['viviendas'] as List<dynamic>? ?? []);
              if (viviendas.isEmpty)
                Text(
                  'No hay viviendas pendientes',
                  style: AppTypography.body.copyWith(color: AppColors.textSecondary),
                )
              else
                ...viviendas.map((v) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _CobroCard(
                    casa: v['casaDireccion'] ?? '',
                    nombre: v['propietarioNombre'] ?? '',
                    monto: v['saldoTotal'] ?? v['saldo'] ?? 0,
                    estado: v['estado'] ?? 'PENDIENTE',
                    onCobrar: () async {
                      final user = context.read<AuthCubit>().state.usuario;
                      final db = context.read<AppDatabase>();
                      final tenantId = user?['tenantId'];
                      if (tenantId == null || v['propietarioId'] == null) return;

                      final propietarioDao = PropietarioDao(db);
                      final res = await propietarioDao.buscarCompleto(
                        tenantId: tenantId,
                        nombre: v['propietarioNombre'] ?? '',
                      );
                      
                      if (res.isNotEmpty && mounted) {
                        final p = res.first;
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => PaymentScreen(
                            propietario: p.propietario,
                            casaDireccion: p.casaDireccion,
                            etapaNombre: p.etapaNombre,
                            cobradorId: user?['id'] ?? 'offline',
                          ),
                        ));
                      }
                    },
                  ),
                )),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: registrar pago o propietario
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

/// Small stat card for the jornada header.
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
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Individual cobro card for a house visit.
class _CobroCard extends StatelessWidget {
  final String casa;
  final String nombre;
  final int monto;
  final String estado;
  final VoidCallback? onCobrar;

  const _CobroCard({
    required this.casa,
    required this.nombre,
    required this.monto,
    required this.estado,
    this.onCobrar,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Row(
          children: [
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$casa — $nombre',
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    r'$' + _format(monto),
                    style: AppTypography.subtitle.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            // Estado + action
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Icon(
                  Icons.circle_rounded,
                  color: estado == 'VENCIDA' ? AppColors.error : AppColors.warning,
                  size: 10,
                ),
                const SizedBox(height: 2),
                Text(
                  estado == 'VENCIDA' ? 'Vencido' : estado == 'PARCIAL' ? 'Parcial' : 'Pendiente',
                  style: AppTypography.small.copyWith(
color: estado == 'VENCIDA' ? AppColors.error : AppColors.warning,
                  ),
                ),
              ],
            ),
            const SizedBox(width: AppSpacing.sm),
            FilledButton(
              onPressed: onCobrar,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              child: const Text('Cobrar'),
            ),
          ],
        ),
      ),
    );
  }

  String _format(int pesos) {
    if (pesos >= 1000000) {
      return '${(pesos / 1000000).toStringAsFixed(1)}M';
    }
    if (pesos >= 1000) {
      return '${(pesos / 1000).toStringAsFixed(0)}K';
    }
    return pesos.toStringAsFixed(0);
  }
}

String _formatMonto(dynamic value) {
  final pesos = (value is int ? value : 0);
  if (pesos >= 1000000) {
    return '\$${(pesos / 1000000).toStringAsFixed(1)}M';
  }
  if (pesos >= 1000) {
    return '\$${(pesos / 1000).toStringAsFixed(0)}K';
  }
  return '\$$pesos';
}
