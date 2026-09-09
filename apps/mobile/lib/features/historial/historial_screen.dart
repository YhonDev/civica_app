import 'package:flutter/material.dart';
import '../../../core/format/app_currency.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/ticket_bottom_sheet.dart';
import '../../shared/widgets/empty_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/auth/auth_cubit.dart';
import '../../core/network/api_client.dart';
import '../solicitudes/solicitudes_repository.dart';
import '../../shared/widgets/solicitud_card.dart';
import '../../core/widgets/responsive_builder.dart';
import '../../shared/widgets/screen_header.dart';
import '../cartera/widgets/cobro_card.dart';
import '../cartera/models/cartera_models.dart';

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

  Future<void> _loadHistorial({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
      });
    }
    try {
      final user = context.read<AuthCubit>().state.usuario;
      final rol = user?['rol'] as String? ?? 'RESIDENTE';

      if (rol == 'COBRADOR') {
        try {
          final response = await ApiClient.instance.get<List<dynamic>>('/pagos/cobrador/mis-cobros');
          final listPagos = (response.data ?? []).map((item) => item as Map<String, dynamic>).toList();
          if (mounted) {
            setState(() {
              _cuotasDb = listPagos;
              _solicitudes = [];
              _loading = false;
            });
          }
          return;
        } catch (e) {
          debugPrint('Error fetching cobrador pagos: $e');
        }
      }

      final residenteId = (user?['residenteId'] as String?) ?? (user?['id'] as String?);
      if (residenteId == null) {
        if (mounted && !silent) {
          setState(() {
            _loading = false;
          });
        }
        return;
      }

      final response = await ApiClient.instance.get<List<dynamic>>('/cobros/residente/$residenteId');
      final listCuotas = (response.data ?? []).map((item) => item as Map<String, dynamic>).toList();

      // Ordenar: si están pagadas o en el módulo de pagos, las más recientes primero
      listCuotas.sort((a, b) {
        final aPagada = a['estado'] == 'PAGADA';
        final bPagada = b['estado'] == 'PAGADA';
        if (aPagada && bPagada) {
          final dateA = DateTime.tryParse(a['updatedAt'] as String? ?? a['periodoInicio'] as String? ?? '') ?? DateTime(2000);
          final dateB = DateTime.tryParse(b['updatedAt'] as String? ?? b['periodoInicio'] as String? ?? '') ?? DateTime(2000);
          return dateB.compareTo(dateA); // Descenso: más reciente arriba
        }
        return 0;
      });

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
      if (mounted && !silent) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthCubit>().state.usuario;
    final isCobrador = user?['rol'] == 'COBRADOR';

    return Scaffold(
      body: SafeArea(
        // En tablet/desktop el contenido no debe estirarse a todo el ancho.
        child: ContentConstrainedBox(
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScreenHeader(title: isCobrador ? 'Actividad' : 'Historial'),

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

                            if (isCobrador) {
                              final c = _cuotasDb[index];
                              final fechaStr = c['fechaPago'] as String? ?? c['createdAt'] as String? ?? '';
                              final fecha = DateTime.tryParse(fechaStr) ?? DateTime.now();
                              final dateFormatted = DateFormat('dd/MM/yyyy - hh:mm a').format(fecha);
                              final rawMonto = c['monto'] as int? ?? 0;
                              final monto = rawMonto > 1000 ? (rawMonto / 100).round() : rawMonto;
                              final residente = c['residenteNombre'] as String? ?? 'Residente';
                              final casa = c['casaDireccion'] as String? ?? 'Inmueble';
                              final manzana = c['manzanaNombre'] as String? ?? '';
                              final etapa = c['etapaNombre'] as String? ?? '';
                              final nroRecibo = c['nroRecibo'] as String? ?? 'TK-000000';
                              final esViaSolicitud = c['esViaSolicitud'] == true;

                              return Card(
                                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(color: AppColors.success.withValues(alpha: 0.3)),
                                ),
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? const Color(0xFF0F172A)
                                    : Colors.white,
                                elevation: 1,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () {
                                    TicketBottomSheet.show(
                                      context,
                                      TicketData(
                                        numero: nroRecibo,
                                        fecha: fecha,
                                        residente: residente,
                                        casa: '$etapa $manzana $casa',
                                        monto: monto,
                                        metodo: 'Efectivo',
                                        estado: 'Cobrado',
                                        cobrador: user?['nombre'] as String? ?? 'Ricardo Arrieta',
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: AppColors.success.withValues(alpha: 0.12),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.check_circle_rounded,
                                            color: AppColors.success,
                                            size: 22,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      '$manzana $casa',
                                                      style: AppTypography.cardTitle,
                                                    ),
                                                  ),
                                                  if (esViaSolicitud)
                                                    Container(
                                                      margin: const EdgeInsets.only(left: 6),
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                      decoration: BoxDecoration(
                                                        color: AppColors.primary.withValues(alpha: 0.12),
                                                        borderRadius: BorderRadius.circular(8),
                                                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                                                      ),
                                                      child: Text(
                                                        '📩 Vía Solicitud',
                                                        style: AppTypography.micro.copyWith(
                                                          fontWeight: FontWeight.w800,
                                                          color: AppColors.primary,
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                residente,
                                                style: AppTypography.caption.copyWith(
                                                  color: AppColors.textSecondary,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '$dateFormatted • $nroRecibo',
                                                style: AppTypography.small.copyWith(
                                                  color: AppColors.textSecondary.withValues(alpha: 0.8),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          AppCurrency.format(monto),
                                          style: AppTypography.cardValue.copyWith(
                                            fontWeight: FontWeight.w900,
                                            color: AppColors.success,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }

                            final c = _cuotasDb[index];
                            final periodoInicioStr = c['periodoInicio'] as String? ?? DateTime.now().toIso8601String();
                            final date = DateTime.tryParse(periodoInicioStr) ?? DateTime.now();
                            final rawPeriod = DateFormat.yMMMM('es').format(date);
                            final period = rawPeriod[0].toUpperCase() + rawPeriod.substring(1);

                            final monto = (c['monto'] as int? ?? 0) ~/ 100;
                            final montoPagado = (c['montoPagado'] as int? ?? 0) ~/ 100;
                            final cobroItem = CobroItem(
                              id: (c['id'] ?? '').toString(),
                              residenteId: (c['residenteId'] ?? '').toString(),
                              nombre: (c['residenteNombre'] ?? '').toString(),
                              casa: (c['casaDireccion'] ?? '').toString(),
                              manzana: (c['manzanaNombre'] ?? '').toString(),
                              etapa: (c['etapaNombre'] ?? '').toString(),
                              monto: monto.toDouble(),
                              montoPagado: montoPagado.toDouble(),
                              saldo: (monto - montoPagado).toDouble(),
                              estado: c['estado'] == 'PAGADA' ? 'Pagado' : (c['estado'] == 'VENCIDA' ? 'Mora' : 'Pendiente'),
                              modalidad: (c['modalidad'] ?? 'Mensual').toString(),
                              fechaVencimiento: (c['fechaVencimiento'] ?? '').toString(),
                              periodoInicio: (c['periodoInicio'] ?? '').toString(),
                              periodoFin: (c['periodoFin'] ?? '').toString(),
                              concepto: period,
                            );

                            return CobroCard(
                              cobro: cobroItem,
                              onTap: () => _handleCuotaTap(c),
                            );
                          },
                        ),
            ),
          ],
          ),
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
      final rawDate = c['fechaPago'] ?? c['updatedAt'] ?? c['createdAt'];
      final date = (DateTime.tryParse(rawDate?.toString() ?? '') ?? DateTime.now()).toLocal();
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
