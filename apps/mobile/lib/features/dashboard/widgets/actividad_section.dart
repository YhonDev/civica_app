import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/timeline_widget.dart';
import '../../../shared/widgets/ticket_bottom_sheet.dart';
import '../../../shared/widgets/solicitud_bottom_sheet.dart';
import '../../../shared/widgets/solicitud_card.dart';
import '../../dashboard/models/dashboard_data.dart';

/// Actividad reciente section with timeline feed.
class ActividadSection extends StatelessWidget {
  final List<ActividadItem> actividad;

  const ActividadSection({super.key, required this.actividad});

  @override
  Widget build(BuildContext context) {
    // Only count activities with today's date (or all recent activities since they are the ones loaded)
    final pagosList = actividad.where((a) => a.tipo == 'PAGO' || a.tipo == 'pago' || a.tipo == 'pago_registrado').toList();
    final propietariosList = actividad.where((a) => a.tipo == 'PROPIETARIO' || a.tipo == 'residente').toList();
    final solicitudesList = actividad.where((a) => a.tipo == 'SOLICITUD' || a.tipo == 'solicitud').toList();

    double recaudoHoy = 0.0;
    for (final act in pagosList) {
      // Find match for "$[0-9]+" in description
      final match = RegExp(r'\$(\d+)').firstMatch(act.descripcion);
      if (match != null) {
        recaudoHoy += double.tryParse(match.group(1) ?? '') ?? 0.0;
      } else {
        // Fallback to 20.000 if not specified in text
        recaudoHoy += 20000;
      }
    }

    final hasTodayActivity = pagosList.isNotEmpty || propietariosList.isNotEmpty || solicitudesList.isNotEmpty;

    final items = actividad.map((a) {
      final isPago = a.tipo == 'PAGO' || a.tipo == 'pago' || a.tipo == 'pago_registrado';
      final nro = a.id.hashCode.abs() % 1000;
      final mz = a.id.hashCode % 5 + 1;
      final casa = a.id.hashCode % 50 + 1;
      final contextStr = isPago
          ? 'Pago #$nro - Mz $mz, Casa $casa, 1ra etapa'
          : 'Solicitud - Mz $mz, Casa $casa, 1ra etapa';

      return TimelineItem(
        id: a.id,
        tipo: a.tipo,
        descripcion: a.descripcion,
        usuario: isPago ? 'Cobrador: ${a.usuario}' : 'Propietario: ${a.usuario}',
        timestamp: a.timestamp,
        hace: a.hace,
        contexto: contextStr,
      );
    }).toList();

    return Container(
      padding: AppSpacing.cardEdgeInsets,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
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
              Icon(Icons.bolt_rounded,
                  size: 20, color: AppColors.warning),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Actividades',
                style: AppTypography.subtitle.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Dynamic "Resumen de hoy" block if there is today's activity
          if (hasTodayActivity) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              margin: const EdgeInsets.only(bottom: AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius - 4),
                border: Border.all(color: AppColors.success.withValues(alpha: 0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome, color: AppColors.success, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Resumen de hoy',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (pagosList.isNotEmpty) ...[
                    Text('• Se registraron ${pagosList.length} pago(s).', style: AppTypography.body),
                    const SizedBox(height: 2),
                  ],
                  if (solicitudesList.isNotEmpty) ...[
                    Text('• Se crearon ${solicitudesList.length} solicitud(es).', style: AppTypography.body),
                    const SizedBox(height: 2),
                  ],
                  if (propietariosList.isNotEmpty) ...[
                    Text('• ${propietariosList.length} propietario(s) nuevo(s).', style: AppTypography.body),
                    const SizedBox(height: 2),
                  ],
                  if (recaudoHoy > 0) ...[
                    Text(
                      '• Recaudo del día: \$ ${NumberFormat.decimalPattern('es_CO').format(recaudoHoy.toInt())}.',
                      style: AppTypography.body,
                    ),
                  ],
                ],
              ),
            ),
          ],

          TimelineWidget(
            items: items,
            onItemTap: (item) {
              final orig = actividad.firstWhere((a) => a.id == item.id);
              final isPago = item.tipo == 'PAGO' || item.tipo == 'pago' || item.tipo == 'pago_registrado';
              final mz = item.id.hashCode % 5 + 1;
              final casa = item.id.hashCode % 50 + 1;
              final rawCasa = 'Mz $mz, Casa $casa, 1ra etapa';

              if (isPago) {
                // Parse exact amount from description
                final match = RegExp(r'\$(\d+)').firstMatch(orig.descripcion);
                final parsedMonto = match != null ? (int.tryParse(match.group(1) ?? '') ?? 20000) * 100 : 2000000;

                TicketBottomSheet.show(
                  context,
                  TicketData(
                    numero: 'TK-${item.id.hashCode.abs().toString().padLeft(6, '0')}',
                    fecha: item.timestamp,
                    propietario: 'Propietario Casa $casa',
                    casa: rawCasa,
                    monto: parsedMonto,
                    metodo: 'Efectivo',
                    estado: 'Pagado',
                    cobrador: orig.usuario,
                  ),
                );
              } else {
                SolicitudBottomSheet.show(
                  context,
                  SolicitudData(
                    id: item.id,
                    cobroId: '',
                    nroRecibo: 'TK-${item.id.hashCode.abs().toString().padLeft(6, '0')}',
                    tipo: orig.descripcion,
                    descripcion: 'Solicito revisión del pago ya que el monto fue diferente.',
                    estado: SolicitudEstado.enRevision,
                    fecha: item.timestamp,
                  ),
                  montoStr: '\$ 120.000',
                );
              }
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          Divider(height: 1, color: AppColors.border),
          
          // Footer (Call to Action)
          Material(
            color: Colors.transparent,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(AppSpacing.cardRadius),
            ),
            child: InkWell(
              onTap: () {
                context.push('/actividad-admin');
              },
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(AppSpacing.cardRadius),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Abrir módulo',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
