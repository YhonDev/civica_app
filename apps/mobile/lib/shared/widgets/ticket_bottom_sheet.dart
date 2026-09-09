import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../core/format/app_currency.dart';

import '../../core/theme/app_breakpoints.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/responsive_builder.dart';
import '../../features/auth/auth_cubit.dart';

/// Data model for a ticket / payment receipt.
class TicketData {
  final String numero;
  final DateTime fecha;
  final String residente;
  final String casa;
  final int monto; // in pesos
  final String metodo;
  final String estado;
  final String? cobrador;
  final String? concepto;
  final String? etapa;
  final String? manzana;
  final String? cobroId;
  final String? pagoId;

  const TicketData({
    required this.numero,
    required this.fecha,
    required this.residente,
    required this.casa,
    required this.monto,
    required this.metodo,
    required this.estado,
    this.cobrador,
    this.concepto,
    this.etapa,
    this.manzana,
    this.cobroId,
    this.pagoId,
  });

  /// Cleans redundant year from concept (e.g. 'Septiembre 2026 - Cuota 1' -> 'Septiembre — Cuota 1')
  static String cleanConcepto(String raw) {
    var s = raw.replaceAll(RegExp(r'\s*\b20\d\d\b\s*'), ' ').trim();
    s = s.replaceAll(RegExp(r'\s*-\s*'), ' — ');
    return s.replaceAll(RegExp(r'\s+'), ' ');
  }

  factory TicketData.fromJson(Map<String, dynamic> json) {
    final rawMonto = json['monto'];
    int montoPesos = 0;
    if (rawMonto != null) {
      final numVal = (rawMonto is num) ? rawMonto.toDouble() : double.tryParse(rawMonto.toString()) ?? 0.0;
      // El backend entrega monto en CENTAVOS (ticket.mapper), siempre convertir a pesos.
      // La heurística anterior (>1000000) mostraba $800.000 para un ticket de $8.000.
      montoPesos = (numVal / 100).round();
    }

    final rawFecha = json['fecha'];
    DateTime fecha = DateTime.now();
    if (rawFecha != null) {
      fecha = DateTime.tryParse(rawFecha.toString()) ?? DateTime.now();
    }

    return TicketData(
      numero: json['numero'] as String? ?? 'N/A',
      fecha: fecha,
      residente: json['residenteNombre'] as String? ?? 'Residente',
      casa: json['casaDireccion'] as String? ?? 'Inmueble',
      monto: montoPesos,
      metodo: json['metodo'] as String? ?? 'Efectivo',
      estado: json['estado'] as String? ?? 'EMITIDO',
      cobrador: json['cobradorNombre'] as String?,
      concepto: json['concepto'] as String?,
      etapa: json['etapa'] as String?,
      manzana: json['manzana'] as String?,
      cobroId: json['cobroId'] as String?,
      pagoId: json['pagoId'] as String?,
    );
  }
}

/// Bottom sheet that displays a digital ticket/receipt.
///
/// Per doc/19-dashboard-specification.md (TICKET DIGITAL):
///   - Always opens from a movement, never directly
///   - Must open as Bottom Sheet
///   - Shows: Número, Fecha, Valor, Método, Cobrador, Estado
///   - Button: Cerrar. Future: Compartir, Descargar PDF
///
/// Per doc/20-screen-specifications.md (TICKET DIGITAL):
///   - PDF generated on demand, never stored
///
/// Reusable in: Residente (tap movement), Cobrador (after payment).
class TicketBottomSheet extends StatelessWidget {
  final TicketData ticket;

  const TicketBottomSheet({super.key, required this.ticket});

  /// Convenience method to show the bottom sheet.
  static Future<dynamic> show(BuildContext context, TicketData ticket) {
    return showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      builder: (_) => TicketBottomSheet(ticket: ticket),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userRole = context.watch<AuthCubit>().state.usuario?['rol'] as String?;
    final isResidente = userRole == 'RESIDENTE';

    final localFecha = ticket.fecha.toLocal();
    final dateStr = DateFormat('dd/MM/yyyy').format(localFecha);
    final timeStr = DateFormat('hh:mm a', 'es').format(localFecha);
    final montoStr = AppCurrency.format(ticket.monto);

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.screenPadding,
        right: AppSpacing.screenPadding,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
        top: AppSpacing.sm,
      ),
      // En tablet/desktop el sheet no debe estirarse a todo el ancho.
      child: ContentConstrainedBox(
        maxWidth: AppBreakpoints.maxFormWidth,
        child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header ──────────────────────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.receipt_long_outlined,
                  color: AppColors.success,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recibo Digital',
                      style: AppTypography.subtitle.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'N° ${ticket.numero}',
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

          // ── Amount (protagonist) ────────────────────────────
          Text(
            montoStr,
            style: AppTypography.display,
          ),
          const SizedBox(height: AppSpacing.xs),
          _buildStatusChip(ticket.estado),

          const SizedBox(height: AppSpacing.lg),

          // ── Details ─────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            ),
            child: Column(
              children: [
                _DetailRow(label: 'Fecha', value: dateStr),
                _DetailRow(label: 'Hora', value: timeStr),
                if (ticket.concepto != null && ticket.concepto!.isNotEmpty)
                  _DetailRow(
                    label: 'Concepto',
                    value: TicketData.cleanConcepto(ticket.concepto!),
                  ),
                _DetailRow(label: 'Residente', value: ticket.residente),
                _DetailRow(label: 'Inmueble', value: ticket.casa),
                _DetailRow(label: 'Método', value: ticket.metodo),
                if (ticket.cobrador != null && ticket.cobrador!.isNotEmpty)
                  _DetailRow(
                    label: 'Cobrador',
                    value: ticket.cobrador!,
                    isLast: true,
                  ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // ── Action buttons (Close / Report) ──────────────────
          if (isResidente) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop(ticket);
                    },
                    icon: const Icon(Icons.report_problem_outlined, size: 16),
                    label: const Text('Revisar pago'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: BorderSide(
                        color: AppColors.error.withValues(alpha: 0.3),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Cerrar'),
                  ),
                ),
              ],
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cerrar'),
              ),
            ),
          ],
        ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String estado) {
    final isSuccess = estado.toUpperCase().contains('PAGAD') ||
        estado.toUpperCase().contains('AL DÍA');
    final color = isSuccess ? AppColors.success : AppColors.warning;
    final icon = isSuccess
        ? Icons.check_circle_outlined
        : Icons.schedule_outlined;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            estado,
            style: AppTypography.small.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// A single detail row in the ticket.
class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isLast;

  const _DetailRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Flexible(
                child: Text(
                  value,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(height: 1, color: AppColors.border.withValues(alpha: 0.5)),
      ],
    );
  }
}
