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

import '../solicitudes/solicitudes_repository.dart';
import '../../shared/widgets/solicitud_card.dart';

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
  final _solicitudesRepo = SolicitudesRepository();
  List<SolicitudData> _solicitudesCobro = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final solicitudes = await _solicitudesRepo.getSolicitudesPendientes();
      if (mounted) {
        setState(() {
          _solicitudesCobro = solicitudes.where((s) => s.tipo == 'SOLICITUD_COBRO').toList();
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading solicitudes cobro: $e');
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
                    value: '${_solicitudesCobro.length}',
                    color: AppColors.warning,
                  )),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: _StatCard(
                    icon: Icons.attach_money_rounded,
                    label: 'Monto esperado',
                    value: r'---',
                    color: AppColors.primary,
                  )),
                ],
              ),

              const SizedBox(height: AppSpacing.lg),

              // ── Botón principal ─────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    // TODO: iniciar jornada
                  },
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Iniciar Jornada'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // ── Lista de cobros ────────────────────────────────────
              Text(
                'Solicitudes de Cobro',
                style: AppTypography.subtitle.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              if (_solicitudesCobro.isEmpty)
                Text(
                  'No hay solicitudes pendientes',
                  style: AppTypography.body.copyWith(color: AppColors.textSecondary),
                )
              else
                ..._solicitudesCobro.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: SolicitudCard(
                    solicitud: s,
                    onTap: () async {
                      if (s.propietarioId == null) return;
                      final db = context.read<AppDatabase>();
                      final tenantId = context.read<AuthCubit>().state.usuario?['tenantId'];
                      if (tenantId == null) return;
                      
                      final propietarioDao = PropietarioDao(db);
                      final res = await propietarioDao.buscarCompleto(tenantId: tenantId, nombre: s.propietarioNombre);
                      
                      PropietarioConInfo? propInfo;
                      for (final p in res) {
                        if (p.propietario.id == s.propietarioId) {
                          propInfo = p;
                          break;
                        }
                      }
                      
                      if (propInfo != null && mounted) {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => PaymentScreen(
                            propietario: propInfo!.propietario,
                            casaDireccion: propInfo!.casaDireccion,
                            etapaNombre: propInfo!.etapaNombre,
                            cobradorId: user?['id'] ?? 'offline',
                            solicitudId: s.id,
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

  const _CobroCard({
    required this.casa,
    required this.nombre,
    required this.monto,
    required this.estado,
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
                  color: AppColors.warning,
                  size: 10,
                ),
                const SizedBox(height: 2),
                Text(
                  estado,
                  style: AppTypography.small.copyWith(
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
            const SizedBox(width: AppSpacing.sm),
            FilledButton(
              onPressed: () {},
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

  String _format(int centavos) {
    final pesos = centavos / 100;
    if (pesos >= 1000000) {
      return '${(pesos / 1000000).toStringAsFixed(1)}M';
    }
    if (pesos >= 1000) {
      return '${(pesos / 1000).toStringAsFixed(0)}K';
    }
    return pesos.toStringAsFixed(0);
  }
}
