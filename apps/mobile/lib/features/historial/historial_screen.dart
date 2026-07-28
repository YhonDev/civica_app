import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/status_badge.dart';
import '../../shared/widgets/cobro_card.dart';
import '../../shared/widgets/ticket_bottom_sheet.dart';
import '../../shared/widgets/empty_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../screens/auth/auth_cubit.dart';
import '../../core/network/api_client.dart';
import '../solicitudes/solicitudes_repository.dart';
import '../../shared/widgets/solicitud_card.dart';

/// Historial screen — Timeline of cuotas/payments.
///
/// Per doc/20-screen-specifications.md (HISTORIAL):
///   Vista: Timeline.
///   Cada elemento: Mes, Estado, Fecha, Valor.
///   Click → Abrir Ticket.
///   Límite: Últimos 12 meses + botón "Ver más".
///
/// Per DESIGN_SYSTEM.md:
///   Never use tables for movements.
///   Timeline is the official component for history.
class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  List<Map<String, dynamic>> _cuotasDb = [];
  List<SolicitudData> _solicitudes = [];
  bool _loading = true;
  int _visibleCount = 6;

  final _solicitudesRepo = SolicitudesRepository();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadHistorial();
    });
  }

  Future<void> _loadHistorial() async {
    try {
      final user = context.read<AuthCubit>().state.usuario;
      final residenteId = user?['id'] as String?;
      if (residenteId == null) {
        setState(() {
          _loading = false;
        });
        return;
      }

      final response = await ApiClient.instance.get<List<dynamic>>('/cobros/residente/$residenteId');
      final listCuotas = response.data!.map((item) => item as Map<String, dynamic>).toList();

      final listSolicitudes = await _solicitudesRepo.getSolicitudes();

      if (mounted) {
        setState(() {
          _cuotasDb = listCuotas;
          _solicitudes = listSolicitudes;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading history: $e');
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.lg),

            // ── Header ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Historial',
                    style: AppTypography.title.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Movimientos de tu cuenta',
                    style: AppTypography.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // ── Cuota list ────────────────────────────────────────
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _cuotasDb.isEmpty
                      ? const EmptyState(
                          icon: Icons.receipt_long_outlined,
                          title: 'Sin movimientos',
                          description: 'Aún no tienes cuotas ni pagos registrados.',
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.screenPadding,
                            vertical: AppSpacing.sm,
                          ),
                          itemCount: _itemCount,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: AppSpacing.sm),
                          itemBuilder: (context, index) {
                            if (index == _visibleCount &&
                                _visibleCount < _cuotasDb.length) {
                              return _buildVerMas();
                            }

                            final c = _cuotasDb[index];
                            final periodoInicioStr = c['periodoInicio'] as String;
                            final date = DateTime.parse(periodoInicioStr);
                            final rawPeriod = DateFormat.yMMMM('es').format(date);
                            final period = rawPeriod[0].toUpperCase() + rawPeriod.substring(1);

                            final monto = (c['monto'] as int) ~/ 100;
                            final montoPagado = (c['montoPagado'] as int) ~/ 100;
                            final pagosEsperados = c['pagosEsperados'] as int?;
                            final pagosRegistrados = c['pagosRegistrados'] as int?;

                            final matchingList = _solicitudes.where((s) => s.cobroId == c['id']).toList();
                            final hasSolicitud = matchingList.isNotEmpty;

                            final StatusType status = hasSolicitud
                                ? StatusType.revision
                                : c['estado'] == 'PAGADA'
                                    ? StatusType.alDia
                                    : c['estado'] == 'VENCIDA'
                                        ? StatusType.mora
                                        : c['estado'] == 'PARCIAL'
                                            ? StatusType.pendiente
                                        : StatusType.pendiente;

                            final DateTime? fechaPago = c['estado'] == 'PAGADA'
                                ? DateTime.parse(c['updatedAt'] as String)
                                : null;

                            final String? cobrador = c['estado'] == 'PAGADA' ? 'Administración' : null;

                            return CobroCard(
                              periodo: period,
                              monto: monto,
                              montoPagado: montoPagado,
                              pagosEsperados: pagosEsperados,
                              pagosRegistrados: pagosRegistrados,
                              status: status,
                              fechaPago: fechaPago,
                              cobrador: cobrador,
                              onTap: () => _handleCuotaTap(c),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  int get _itemCount {
    final visible = _visibleCount.clamp(0, _cuotasDb.length);
    return visible + (visible < _cuotasDb.length ? 1 : 0);
  }

  Widget _buildVerMas() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Center(
        child: TextButton.icon(
          onPressed: () {
            setState(() {
              _visibleCount = (_visibleCount + 6).clamp(0, _cuotasDb.length);
            });
          },
          icon: const Icon(Icons.expand_more_rounded, size: 18),
          label: Text(
            'Ver más (${_cuotasDb.length - _visibleCount} restantes)',
            style: AppTypography.body.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  void _handleCuotaTap(Map<String, dynamic> c) {
    final matchingList = _solicitudes.where((s) => s.cobroId == c['id']).toList();
    final SolicitudData? matchingSolicitud = matchingList.isNotEmpty ? matchingList.first : null;

    if (matchingSolicitud != null) {
      _mostrarDetalleSolicitud(matchingSolicitud);
    } else if (c['estado'] == 'PAGADA') {
      final date = DateTime.parse(c['updatedAt'] as String);
      final monto = ((c['monto'] as int) / 100).round();
      TicketBottomSheet.show(
        context,
        TicketData(
          numero: 'TK-${c['id'].hashCode.abs().toString().padLeft(6, '0')}',
          fecha: date,
          residente: context.read<AuthCubit>().state.usuario?['nombre'] as String? ?? 'Residente',
          casa: 'Mi Casa',
          monto: monto,
          metodo: 'Efectivo',
          estado: 'Pagado',
          cobrador: 'Administración',
        ),
      );
    }
  }

  void _mostrarDetalleSolicitud(SolicitudData solicitud) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final dateStr = DateFormat('dd/MM/yyyy').format(solicitud.fecha);
        Color statusColor = AppColors.warning;
        String statusText = 'Pendiente';

        if (solicitud.estado == SolicitudEstado.enRevision) {
          statusColor = AppColors.info;
          statusText = (solicitud.tipo.toLowerCase().contains('pago') ||
                        solicitud.tipo.toLowerCase().contains('pagad'))
              ? 'Pago en revisión'
              : 'En revisión';
        }

        final isPago = solicitud.tipo.toLowerCase().contains('pago') ||
                       solicitud.tipo.toLowerCase().contains('pagad');

        return Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.screenPadding,
            right: AppSpacing.screenPadding,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.xl,
            top: AppSpacing.sm,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.description_outlined,
                      color: statusColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          solicitud.tipo,
                          style: AppTypography.subtitle.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Referencia vinculante: ${solicitud.nroRecibo}',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Fecha reporte: $dateStr',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Estado de la solicitud',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.lens, color: statusColor, size: 10),
                  const SizedBox(width: 6),
                  Text(
                    statusText,
                    style: AppTypography.bodyMedium.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Tu Observación',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.cardInnerPadding),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                ),
                child: Text(
                  solicitud.descripcion,
                  style: AppTypography.body,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (isPago) ...[
                Text(
                  'Recibo digital reportado',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.cardInnerPadding),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('N° Recibo', style: AppTypography.caption),
                          Text(solicitud.nroRecibo, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Valor', style: AppTypography.caption),
                          Text('\$40.000', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700, color: AppColors.primary)),
                        ],
                      ),
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Fecha pago', style: AppTypography.caption),
                          Text(DateFormat('dd/MM/yyyy').format(solicitud.fecha), style: AppTypography.bodyMedium),
                        ],
                      ),
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Cobrador', style: AppTypography.caption),
                          Text('Carlos Gómez', style: AppTypography.bodyMedium),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cerrar'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
