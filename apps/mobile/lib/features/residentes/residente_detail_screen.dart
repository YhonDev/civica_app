import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../screens/auth/auth_cubit.dart';
import 'models/residentes_models.dart';
import 'residentes_repository.dart';
import 'widgets/security_section.dart';

class ResidenteDetailScreen extends StatefulWidget {
  final ResidenteItem residente;

  const ResidenteDetailScreen({super.key, required this.residente});

  @override
  State<ResidenteDetailScreen> createState() => _ResidenteDetailScreenState();
}

class _ResidenteDetailScreenState extends State<ResidenteDetailScreen> {
  late ResidenteItem _residente;
  bool _cargando = false;

  final _repo = ResidentesRepository();

  @override
  void initState() {
    super.initState();
    _residente = widget.residente;
  }

  Future<void> _recargarResidente() async {
    setState(() => _cargando = true);
    try {
      final lista = await _repo.getResidentes();
      final actualizado = lista.where((p) => p.id == _residente.id).firstOrNull;
      if (actualizado != null && mounted) {
        setState(() => _residente = actualizado);
      }
    } catch (_) {
      // Si falla la recarga, se queda con los datos actuales
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  // ── Mock: upcoming payment dates based on modality ──────────────
  List<_ProximoCobro> _getProximosCobros() {
    final now = DateTime.now();
    final year = now.year;
    final month = now.month;
    final modalidad = _residente.modalidadPago.toUpperCase();

    List<DateTime> fechas;
    switch (modalidad) {
      case 'SEMANAL':
        fechas = _sabadosDelMes(year, month);
        break;
      case 'QUINCENAL':
        final ancla1 = DateTime(year, month, 15);
        final ancla2 = DateTime(year, month + 1, 0); // last day
        fechas = [_sabadoCercano(ancla1), _sabadoCercano(ancla2)];
        break;
      default: // MENSUAL
        final ultimoDia = DateTime(year, month + 1, 0);
        fechas = [_sabadoCercano(ultimoDia)];
    }

    // Mock: mark dates before today as paid, today as current, future as pending
    return fechas.map((f) {
      final dateOnly = DateTime(f.year, f.month, f.day);
      final todayOnly = DateTime(now.year, now.month, now.day);

      _CobroStatus status;
      if (dateOnly.isBefore(todayOnly)) {
        status = _CobroStatus.pagado;
      } else if (dateOnly.isAtSameMomentAs(todayOnly)) {
        status = _CobroStatus.hoy;
      } else {
        status = _CobroStatus.pendiente;
      }
      return _ProximoCobro(fecha: f, status: status);
    }).toList();
  }

  List<DateTime> _sabadosDelMes(int year, int month) {
    final ultimoDia = DateTime(year, month + 1, 0).day;
    final sabados = <DateTime>[];
    for (int d = 1; d <= ultimoDia; d++) {
      final fecha = DateTime(year, month, d);
      if (fecha.weekday == DateTime.saturday) sabados.add(fecha);
    }
    // Business rule: exactly 4 weekly payments per month
    if (sabados.length == 5) {
      if (sabados.first.day <= 2) {
        sabados.removeAt(0);
      } else {
        sabados.removeLast();
      }
    }
    return sabados;
  }

  DateTime _sabadoCercano(DateTime ancla) {
    final weekday = ancla.weekday;
    // DateTime.saturday == 6
    final diff = (DateTime.saturday - weekday) % 7;
    if (diff == 0) return ancla;
    // pick the closest saturday (before or after)
    final after = ancla.add(Duration(days: diff));
    final before = ancla.subtract(Duration(days: 7 - diff));
    return (diff <= 3) ? after : before;
  }

  String _proximoVencimiento() {
    final cobros = _getProximosCobros();
    final pendientes = cobros.where((c) => c.status != _CobroStatus.pagado);
    if (pendientes.isEmpty) return 'Sin vencimientos';
    return DateFormat("d 'de' MMMM", 'es').format(pendientes.first.fecha);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Residente'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(true),
        ),
        actions: [
          if (_cargando)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Módulos',
              style: AppTypography.subtitle.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildGrid(context),
            const SizedBox(height: AppSpacing.xl),
            // ── Módulo de Seguridad ──
            if (_residente.usuarioId != null) ...[
              SecuritySection(
                usuarioId: _residente.usuarioId!,
                nombre: _residente.nombre,
                initialUsername: _residente.username,
                isAdmin: context.read<AuthCubit>().state.usuario?['rol'] == 'ADMIN',
                onCredentialsUpdated: () {
                  // Recargar para mostrar el nuevo username
                  _recargarResidente();
                },
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final cobros = _getProximosCobros();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _residente.nombre,
                      style: AppTypography.title.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),

                    Text(
                      _residente.casa,
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _residente.etapa,
                      style: AppTypography.caption.copyWith(color: AppColors.textDisabled),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Deuda Actual', style: AppTypography.caption),
                        const SizedBox(height: 4),
                        Text(
                          '\$${_residente.saldoPendiente.toStringAsFixed(2)}',
                          style: AppTypography.title.copyWith(
                            color: _residente.saldoPendiente > 0 ? AppColors.error : AppColors.success,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Estado', style: AppTypography.caption),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _residente.saldoPendiente > 0 
                                ? AppColors.error.withValues(alpha: 0.1) 
                                : AppColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _residente.estadoFinanciero,
                            style: AppTypography.caption.copyWith(
                              color: _residente.saldoPendiente > 0 ? AppColors.error : AppColors.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(height: AppSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Modalidad', style: AppTypography.caption),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              _modalidadIcon(),
                              size: 16,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _residente.modalidadPago,
                              style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Próximo Venc.', style: AppTypography.caption),
                        const SizedBox(height: 4),
                        Text(
                          _proximoVencimiento(),
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.info,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildProximosCobros(cobros),
        ],
      ),
    );
  }

  IconData _modalidadIcon() {
    switch (_residente.modalidadPago.toUpperCase()) {
      case 'SEMANAL':
        return Icons.view_week_rounded;
      case 'QUINCENAL':
        return Icons.date_range_rounded;
      default:
        return Icons.calendar_month_rounded;
    }
  }

  // ── Próximos Cobros (replaces old static mini-timeline) ─────────
  Widget _buildProximosCobros(List<_ProximoCobro> cobros) {
    final modalidad = _residente.modalidadPago.toUpperCase();
    final mesActual = DateFormat('MMMM', 'es').format(DateTime.now());
    final label = switch (modalidad) {
      'SEMANAL' => 'Cobros semanales de $mesActual',
      'QUINCENAL' => 'Cobros quincenales de $mesActual',
      _ => 'Cobro mensual de $mesActual',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.event_note_rounded, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(label, style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        // Timeline row
        Row(
          children: [
            for (int i = 0; i < cobros.length; i++) ...[
              if (i > 0)
                Expanded(
                  child: Container(
                    height: 2,
                    color: cobros[i - 1].status == _CobroStatus.pagado
                        ? AppColors.success
                        : AppColors.border,
                  ),
                ),
              _buildCobroNode(cobros[i]),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildCobroNode(_ProximoCobro cobro) {
    final dayLabel = DateFormat('d', 'es').format(cobro.fecha);
    final dayName = DateFormat('EEE', 'es').format(cobro.fecha);

    Color nodeColor;
    Color bgColor;
    Widget? icon;

    switch (cobro.status) {
      case _CobroStatus.pagado:
        nodeColor = AppColors.success;
        bgColor = AppColors.success;
        icon = const Icon(Icons.check, size: 10, color: Colors.white);
        break;
      case _CobroStatus.hoy:
        nodeColor = AppColors.info;
        bgColor = AppColors.info;
        icon = const Icon(Icons.circle, size: 6, color: Colors.white);
        break;
      case _CobroStatus.pendiente:
        nodeColor = AppColors.border;
        bgColor = AppColors.background;
        icon = null;
        break;
    }

    return Column(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: bgColor,
            border: cobro.status == _CobroStatus.pendiente
                ? Border.all(color: nodeColor, width: 2)
                : null,
            boxShadow: cobro.status == _CobroStatus.hoy
                ? [BoxShadow(color: nodeColor.withValues(alpha: 0.4), blurRadius: 6, spreadRadius: 1)]
                : null,
          ),
          child: Center(child: icon),
        ),
        const SizedBox(height: 4),
        Text(
          dayLabel,
          style: AppTypography.small.copyWith(
            fontWeight: FontWeight.w700,
            color: cobro.status == _CobroStatus.hoy ? AppColors.info : AppColors.textPrimary,
          ),
        ),
        Text(
          dayName,
          style: AppTypography.small.copyWith(
            fontSize: 9,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      childAspectRatio: 2.8,
      crossAxisSpacing: AppSpacing.md,
      mainAxisSpacing: AppSpacing.md,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildModuleCard(
          context,
          title: 'Finanzas',
          icon: Icons.account_balance_wallet_rounded,
          color: AppColors.primary,
          route: '/comunidad/residentes/detalle/finanzas',
          extra: _residente,
        ),
        _buildModuleCard(
          context,
          title: 'Historial',
          icon: Icons.receipt_long_rounded,
          color: AppColors.success,
          route: '/comunidad/residentes/detalle/historial',
          extra: _residente,
        ),
        _buildModuleCard(
          context,
          title: 'Editar',
          icon: Icons.edit_rounded,
          color: AppColors.info,
          routeName: 'comunidad-propietario-editar',
          extra: _residente,
        ),
        _buildModuleCard(
          context,
          title: 'Eliminar',
          icon: Icons.delete_forever_rounded,
          color: AppColors.error,
          onTap: () => _confirmarEliminacion(context),
        ),
      ],
    );
  }

  Widget _buildModuleCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    String? route,
    String? routeName,
    Object? extra,
    VoidCallback? onTap,
    String? subtitle,
    bool isDanger = false,
  }) {
    return InkWell(
      onTap: onTap ?? () async {
        if (routeName == 'comunidad-residente-editar') {
          final editado = await context.pushNamed<bool>(routeName!, extra: extra);
          if (editado == true) {
            await _recargarResidente();
          }
        } else if (routeName != null) {
          context.pushNamed(routeName, extra: extra);
        } else if (route != null) {
          context.push(route, extra: extra);
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: AppSpacing.sm),
            Text(
              title,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: color == AppColors.error ? color : null,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmarEliminacion(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Residente'),
        content: Text('¿Estás seguro de eliminar a ${_residente.nombre}? Esta acción no se puede deshacer y eliminará sus deudas.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final success = await _repo.deleteResidente(_residente.id);
      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Residente eliminado correctamente')),
        );
        context.pop(true);
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al eliminar el residente')),
        );
      }
    }
  }
}

// ── Private helpers ──────────────────────────────────────────────

enum _CobroStatus { pagado, hoy, pendiente }

class _ProximoCobro {
  final DateTime fecha;
  final _CobroStatus status;

  const _ProximoCobro({required this.fecha, required this.status});
}
