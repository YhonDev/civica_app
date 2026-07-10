import 'package:flutter/material.dart';

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
    final items = actividad.map((a) {
      final isPago = a.tipo == 'pago' || a.tipo == 'pago_registrado';
      final nro = a.id.hashCode.abs() % 1000;
      final mz = a.id.hashCode % 5 + 1;
      final casa = a.id.hashCode % 50 + 1;
      final contextStr = isPago
          ? 'Pago #$nro - Mz $mz, Casa $casa, 1ra etapa'
          : 'Solicitud - Mz $mz, Casa $casa, 1ra etapa';

      return TimelineItem(
        id: a.id,
        tipo: a.tipo,
        descripcion: '', // Ocultamos la descripción para dejarlo minimalista
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
                'Hoy',
                style: AppTypography.subtitle.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          TimelineWidget(
            items: items,
            onItemTap: (item) {
              final orig = actividad.firstWhere((a) => a.id == item.id);
              final isPago = item.tipo == 'pago' || item.tipo == 'pago_registrado';
              final mz = item.id.hashCode % 5 + 1;
              final casa = item.id.hashCode % 50 + 1;
              final rawCasa = 'Mz $mz, Casa $casa, 1ra etapa';

              if (isPago) {
                TicketBottomSheet.show(
                  context,
                  TicketData(
                    numero: 'TK-${item.id.hashCode.abs().toString().padLeft(6, '0')}',
                    fecha: item.timestamp,
                    propietario: 'Propietario Casa $casa', // Mock owner
                    casa: rawCasa,
                    monto: item.monto ?? 120000,
                    metodo: 'Efectivo',
                    estado: 'Pagado',
                    cobrador: orig.usuario, // orig.usuario holds the cobrador name from backend
                  ),
                );
              } else {
                // Para solicitudes
                SolicitudBottomSheet.show(
                  context,
                  SolicitudData(
                    id: item.id,
                    cuotaId: '',
                    nroRecibo: 'TK-${item.id.hashCode.abs().toString().padLeft(6, '0')}',
                    tipo: orig.descripcion,
                    descripcion: 'Solicito revisión del pago ya que el monto fue diferente.',
                    estado: SolicitudEstado.enRevision,
                    fecha: item.timestamp,
                  ),
                  montoStr: '\$120.000',
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
