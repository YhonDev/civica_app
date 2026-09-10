import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/format/app_currency.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/timeline_widget.dart';
import 'dashboard_repository.dart';
import 'models/dashboard_data.dart';

import '../../shared/widgets/screen_header.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/solicitud_bottom_sheet.dart';
import '../../shared/widgets/solicitud_card.dart';
import 'widgets/actividad_section.dart';

class ActividadAdminScreen extends StatefulWidget {
  const ActividadAdminScreen({super.key});

  @override
  State<ActividadAdminScreen> createState() => _ActividadAdminScreenState();
}

class _ActividadAdminScreenState extends State<ActividadAdminScreen> {
  final DashboardRepository _repository = DashboardRepository();
  List<ActividadItem> _allItems = [];
  bool _loading = true;
  String _selectedFilter = 'TODAS';

  @override
  void initState() {
    super.initState();
    _loadActivity();
  }

  Future<void> _loadActivity() async {
    try {
      final now = DateTime.now();
      final data = await _repository.getDashboard(now.month, now.year);
      if (mounted) {
        setState(() {
          _allItems = data.actividadReciente;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  List<ActividadItem> get _filteredItems {
    if (_selectedFilter == 'TODAS') return _allItems;
    if (_selectedFilter == 'JORNADAS') {
      return _allItems.where((a) => a.tipo.toLowerCase().contains('jornada') || a.tipo.toLowerCase().contains('ruta')).toList();
    }
    if (_selectedFilter == 'SOLICITUDES') {
      return _allItems.where((a) => a.tipo.toLowerCase().contains('solicitud')).toList();
    }
    if (_selectedFilter == 'PAGOS') {
      return _allItems.where((a) => a.tipo.toLowerCase().contains('pago') || a.tipo.toLowerCase().contains('cobro')).toList();
    }
    if (_selectedFilter == 'SISTEMA') {
      return _allItems.where((a) => !a.tipo.toLowerCase().contains('solicitud') && !a.tipo.toLowerCase().contains('pago') && !a.tipo.toLowerCase().contains('ruta') && !a.tipo.toLowerCase().contains('jornada')).toList();
    }
    return _allItems;
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (canPop)
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => context.pop(),
                  ),
                const Expanded(
                  child: ScreenHeader(title: 'Actividad del Sistema'),
                ),
              ],
            ),
            _buildFilterChips(),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredItems.isEmpty
                      ? const EmptyState(
                          icon: Icons.history_outlined,
                          title: 'Sin actividad registrada',
                          description: 'Aún no hay solicitudes de revisión, cobros o rutas registradas en la comunidad.',
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(AppSpacing.screenPadding),
                          child: TimelineWidget(
                            items: _filteredItems.map((a) {
                              final isPago = a.tipo.toLowerCase().contains('pago') || a.tipo.toLowerCase().contains('cobro');
                              final isSolicitud = a.tipo.toLowerCase().contains('solicitud');
                              final isResidente = a.tipo.toLowerCase().contains('residente');

                              final contextTitle = isPago
                                  ? 'Pago realizado'
                                  : (isSolicitud
                                      ? 'Solicitud de Revisión'
                                      : (isResidente ? 'Residente Actualizado' : null));

                              String? montoStr;
                              int? montoInt;
                              if (isPago) {
                                if (a.metadata['monto'] != null) {
                                  montoInt = AppCurrency.centsFromJson(a.metadata['monto']);
                                  montoStr = AppCurrency.format(montoInt);
                                } else {
                                  montoStr = ActividadSection.formatDescripcion(a);
                                }
                              }

                              final residente = a.metadata['residenteNombre'] as String? ??
                                  a.metadata['residente'] as String? ??
                                  (isPago ? null : a.usuario);
                              final inmueble = ActividadSection.formatInmueble(a.metadata);

                              return TimelineItem(
                                id: a.id,
                                tipo: a.tipo,
                                descripcion: ActividadSection.formatDescripcion(a),
                                usuario: a.usuario,
                                timestamp: a.timestamp,
                                hace: a.hace,
                                contexto: contextTitle,
                                monto: montoInt,
                                montoFormateado: montoStr,
                                residente: residente,
                                inmueble: inmueble.isNotEmpty ? inmueble : null,
                                metadata: a.metadata,
                              );
                            }).toList(),
                            onItemTap: _mostrarDetalleActividad,
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      ('TODAS', 'Todas'),
      ('JORNADAS', 'Jornadas / Rutas'),
      ('SOLICITUDES', 'Solicitudes'),
      ('PAGOS', 'Pagos'),
      ('SISTEMA', 'Sistema'),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding, vertical: AppSpacing.xs),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((f) {
            final isSelected = _selectedFilter == f.$1;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ChoiceChip(
                label: Text(f.$2),
                selected: isSelected,
                onSelected: (_) => setState(() => _selectedFilter = f.$1),
                labelStyle: AppTypography.caption.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.surface,
                visualDensity: VisualDensity.compact,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _mostrarDetalleActividad(TimelineItem item) {
    final orig = _allItems.firstWhere((a) => a.id == item.id, orElse: () => ActividadItem(
      id: item.id,
      tipo: item.tipo,
      descripcion: item.descripcion,
      usuario: item.usuario,
      timestamp: item.timestamp,
      hace: item.hace,
    ));

    final isPago = item.tipo.toLowerCase().contains('pago') || item.tipo.toLowerCase().contains('cobro');
    final isSolicitud = item.tipo.toLowerCase().contains('solicitud');
    final isJornada = item.tipo.toLowerCase().contains('jornada') || item.tipo.toLowerCase().contains('ruta');

    if (isPago) {
      ActividadSection.showPagoTicket(context, orig, itemId: item.id);
      return;
    }

    if (isSolicitud) {
      final meta = orig.metadata;
      final estadoStr = (meta['estado'] as String? ?? 'PENDIENTE').toUpperCase();
      SolicitudEstado estado = SolicitudEstado.pendiente;
      if (estadoStr.contains('RESUELT')) estado = SolicitudEstado.resuelta;
      if (estadoStr.contains('RECHAZ')) estado = SolicitudEstado.rechazada;
      if (estadoStr.contains('REVISI')) estado = SolicitudEstado.enRevision;

      SolicitudBottomSheet.show(
        context,
        SolicitudData(
          id: meta['solicitudId'] as String? ?? orig.id,
          cobroId: meta['cobroId'] as String? ?? orig.id,
          nroRecibo: 'SOL-${item.id.substring(0, 6).toUpperCase()}',
          tipo: meta['tipo'] as String? ?? 'Solicitud de Cobro',
          descripcion: meta['descripcion'] as String? ?? orig.descripcion,
          estado: estado,
          fecha: item.timestamp,
          residenteNombre: orig.usuario,
          respuesta: meta['respuesta'] as String?,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isJornada
                        ? AppColors.primary.withValues(alpha: 0.12)
                        : AppColors.warning.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isJornada
                        ? Icons.alt_route_rounded
                        : Icons.assignment_late_rounded,
                    color: isJornada ? AppColors.primary : AppColors.warning,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isJornada ? 'Resumen de Jornada de Cobro' : 'Solicitud de Revisión',
                        style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Cobrador / Usuario: ${item.usuario}',
                        style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            if (isJornada) ...[
              // Summary cards for Jornada / Ruta (dynamic from metadata)
              Builder(
                builder: (context) {
                  final meta = orig.metadata;
                  final rec = meta['totalRecaudado'] as num?;
                  final recStr = rec != null ? AppCurrency.formatCents(rec.round()) : 'Recaudo de Jornada';
                  final hInicio = meta['horaInicio'] as String?;
                  final hFin = meta['horaFin'] as String?;
                  final horarioStr = (hInicio != null && hFin != null) ? '$hInicio - $hFin' : item.hace;
                  final cobradasStr = meta['casasCobradas'] != null ? '${meta['casasCobradas']} Cobradas' : 'Ruta completada';
                  final pendientesStr = meta['casasPendientes'] != null ? '${meta['casasPendientes']} Pendientes' : 'Al día';
                  final moraStr = meta['casasMora'] != null ? '${meta['casasMora']} en Mora' : 'Sin mora';

                  return Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TOTAL RECAUDADO EN EFECTIVO A ENTREGAR',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              recStr,
                              style: AppTypography.stat.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricTile('Horario Ruta', horarioStr, Icons.schedule_rounded, AppColors.primary),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: _buildMetricTile('Casas Visitadas', cobradasStr, Icons.home_rounded, AppColors.success),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricTile('Casas Pendientes', pendientesStr, Icons.pending_actions_rounded, AppColors.warning),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: _buildMetricTile('Casas en Mora', moraStr, Icons.warning_rounded, AppColors.error),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ] else ...[
              // System or General Activity Detail (no fake ticket)
              Text(
                'Detalle del Evento:',
                style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                item.descripcion.replaceAll(': undefined', ''),
                style: AppTypography.body,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Usuario: ${item.usuario} • Registrado ${item.hace}',
                style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
              ),
            ],

            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.small.copyWith(color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}
