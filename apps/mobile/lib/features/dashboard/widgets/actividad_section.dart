import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format/app_currency.dart';
import '../../../core/network/api_client.dart';
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

  /// Formatea la descripción secundaria de la actividad evitando redundancias.
  /// Para pagos, expone únicamente la cifra neta formateada (ej. `$ 10.000`),
  /// omitiendo sufijos "COP", repetición de "Pago registrado" o mención de "cuotas".
  static String formatDescripcion(ActividadItem a) {
    final isPago = a.tipo.toLowerCase().contains('pago') || a.tipo.toLowerCase().contains('cobro');
    if (isPago) {
      if (a.metadata['monto'] != null) {
        return AppCurrency.format(AppCurrency.centsFromJson(a.metadata['monto']));
      }
      final match = RegExp(r'(?:\$\s*|de\s+)?([\d\.,]{4,})(?:\s*COP)?', caseSensitive: false)
          .firstMatch(a.descripcion);
      if (match != null) {
        final digits = match.group(1)!.replaceAll(RegExp(r'[^0-9]'), '');
        final val = num.tryParse(digits);
        if (val != null && val > 0) {
          return AppCurrency.format(val);
        }
      }
    }
    return a.descripcion
        .replaceAll(': undefined', '')
        .replaceAll(': null', '')
        .replaceAll(' COP', '')
        .trim();
  }

  /// Formatea la ubicación física (Manzana, Casa, Etapa) en un texto conciso,
  /// por ejemplo: "Mz A Casa 4 (1era etapa)".
  static String formatInmueble(Map<String, dynamic> metadata) {
    final etapa = metadata['etapa'] as String?;
    final manzana = metadata['manzana'] as String?;
    final casa = metadata['casa'] as String? ?? metadata['inmueble'] as String?;

    final parts = <String>[];
    if (manzana != null && manzana.isNotEmpty) {
      parts.add(manzana.startsWith('Manzana ')
          ? manzana.replaceFirst('Manzana ', 'Mz ')
          : (manzana.startsWith('Mz') ? manzana : 'Mz $manzana'));
    }
    if (casa != null && casa.isNotEmpty) {
      parts.add(casa.startsWith('Casa ') ? casa : 'Casa $casa');
    }
    String base = parts.join(' ');
    if (etapa != null && etapa.isNotEmpty) {
      base = base.isNotEmpty ? '$base ($etapa)' : etapa;
    }
    return base;
  }

  /// Abre el recibo digital de pago configurando con precisión los datos:
  /// monto normalizado (de centavos a pesos), residente real, ubicación formateada
  /// y cobrador real. Si falta información detallada y existe pagoId, consulta
  /// el ticket canónico al backend.
  static Future<void> showPagoTicket(BuildContext context, ActividadItem orig, {String? itemId}) async {
    final effectiveId = itemId ?? orig.id;
    final pagoId = orig.metadata['pagoId'] as String?;

    // Si el nombre del residente no viene en la actividad pero tenemos pagoId,
    // consultamos el ticket canónico directo a la API (idéntico a cartera).
    if ((orig.metadata['residenteNombre'] == null || orig.metadata['residenteNombre'] == 'Residente') && pagoId != null) {
      try {
        final resp = await ApiClient.instance.get('/tickets', queryParameters: {'pagoId': pagoId});
        if (resp.data != null && resp.data is Map<String, dynamic> && context.mounted) {
          final realTicket = TicketData.fromJson(resp.data as Map<String, dynamic>);
          TicketBottomSheet.show(context, realTicket);
          return;
        }
      } catch (_) {
        // Fallback resiliente a metadata local
      }
    }

    if (!context.mounted) return;

    final montoRaw = orig.metadata['monto'];
    int montoVal;
    if (montoRaw != null) {
      montoVal = AppCurrency.centsFromJson(montoRaw);
    } else {
      final match = RegExp(r'(?:\$\s*|de\s+)?([\d\.,]{4,})(?:\s*COP)?', caseSensitive: false)
          .firstMatch(orig.descripcion);
      if (match != null) {
        final digits = match.group(1)!.replaceAll(RegExp(r'[^0-9]'), '');
        montoVal = int.tryParse(digits) ?? 10000;
      } else {
        montoVal = 10000;
      }
    }

    final cobradorVal = orig.metadata['cobradorNombre'] as String? ?? orig.usuario;
    final residenteVal = orig.metadata['residenteNombre'] as String? ??
        orig.metadata['residente'] as String? ??
        'Residente';
    final etapa = orig.metadata['etapa'] as String?;
    final manzana = orig.metadata['manzana'] as String?;
    final casa = orig.metadata['casa'] as String? ?? orig.metadata['inmueble'] as String?;
    final ubicacion = [
      if (etapa != null && etapa.isNotEmpty) etapa,
      if (manzana != null && manzana.isNotEmpty) manzana,
      if (casa != null && casa.isNotEmpty) casa,
    ].join(' · ');
    final casaVal = ubicacion.isNotEmpty ? ubicacion : 'Inmueble';

    TicketBottomSheet.show(
      context,
      TicketData(
        numero: orig.metadata['nroRecibo'] as String? ??
            orig.metadata['clientPaymentId'] as String? ??
            'REC-${effectiveId.substring(0, effectiveId.length >= 8 ? 8 : effectiveId.length).toUpperCase()}',
        fecha: orig.timestamp,
        residente: residenteVal,
        casa: casaVal,
        monto: montoVal,
        metodo: orig.metadata['metodo'] as String? ?? 'Efectivo',
        estado: 'PAGADO',
        concepto: orig.metadata['concepto'] as String?,
        cobrador: cobradorVal,
        etapa: etapa,
        manzana: manzana,
        pagoId: pagoId,
        cobroId: orig.metadata['cobroId'] as String?,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Rule: If there are no real activities, do not show the section at all.
    if (actividad.isEmpty) {
      return const SizedBox.shrink();
    }

    // Display the top 2 most recent real activities from the database
    final items = actividad.take(2).map((a) {
      final isPago = a.tipo.toLowerCase().contains('pago') || a.tipo.toLowerCase().contains('cobro');
      final isSolicitud = a.tipo.toLowerCase().contains('solicitud');
      final isResidente = a.tipo.toLowerCase().contains('residente');

      final contextTitle = isPago
          ? 'Pago realizado'
          : (isSolicitud
              ? 'Solicitud de Revisión'
              : (isResidente ? 'Residente Actualizado' : 'Jornada / Sistema'));

      String? montoStr;
      int? montoInt;
      if (isPago) {
        if (a.metadata['monto'] != null) {
          montoInt = AppCurrency.centsFromJson(a.metadata['monto']);
          montoStr = AppCurrency.format(montoInt);
        } else {
          montoStr = formatDescripcion(a);
        }
      }

      final residente = a.metadata['residenteNombre'] as String? ??
          a.metadata['residente'] as String? ??
          (isPago ? null : a.usuario);
      final inmueble = formatInmueble(a.metadata);

      return TimelineItem(
        id: a.id,
        tipo: a.tipo,
        descripcion: formatDescripcion(a),
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

          TimelineWidget(
            items: items,
            onItemTap: (item) {
              final orig = actividad.firstWhere((a) => a.id == item.id);
              final isPago = item.tipo.toLowerCase().contains('pago') || item.tipo.toLowerCase().contains('cobro');
              final isJornada = item.tipo.toLowerCase().contains('jornada') || item.tipo.toLowerCase().contains('ruta');

              if (isJornada) {
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
                                color: AppColors.primary.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.alt_route_rounded,
                                color: AppColors.primary,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Resumen de Jornada de Cobro',                                        style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
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
                        // Summary cards for Jornada / Ruta (dynamic from metadata)
                        Builder(
                          builder: (context) {
                            final meta = orig.metadata;
                            final rec = meta['totalRecaudado'] as num?;
                            final recStr = rec != null ? AppCurrency.format((rec / 100).round()) : 'Recaudo de Jornada';
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
                                      child: _buildTile('Horario Ruta', horarioStr, Icons.schedule_rounded, AppColors.primary),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: _buildTile('Casas Visitadas', cobradasStr, Icons.home_rounded, AppColors.success),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildTile('Casas Pendientes', pendientesStr, Icons.pending_actions_rounded, AppColors.warning),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: _buildTile('Casas en Mora', moraStr, Icons.warning_rounded, AppColors.error),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                    ),
                  ),
                );
              } else if (isPago) {
                showPagoTicket(context, orig, itemId: item.id);
              } else {
                // Real solicitud bottom sheet
                SolicitudBottomSheet.show(
                  context,
                  SolicitudData(
                    id: item.id,
                    cobroId: '',
                    nroRecibo: 'SOL-${item.id.substring(0, 8).toUpperCase()}',
                    tipo: orig.tipo,
                    descripcion: orig.descripcion.replaceAll(': undefined', ''),
                    estado: SolicitudEstado.enRevision,
                    fecha: item.timestamp,
                  ),
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
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 20,
                      color: AppColors.primary,
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

  Widget _buildTile(String title, String value, IconData icon, Color color) {
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
                  title,
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
