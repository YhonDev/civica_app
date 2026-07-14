import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import 'status_badge.dart';

/// A card representing a single cuota/instalment period.
///
/// Per DESIGN_SYSTEM.md — Cards are the main component.
/// All important information lives inside Cards.
///
/// Reusable in: Historial (Propietario), Cartera (Cobrador with "Cobrar" button),
/// Cartera (Admin with detail actions).
class CobroCard extends StatelessWidget {
  final String periodo;
  final int monto; // pesos enteros
  final int montoPagado; // pesos enteros
  final StatusType status;
  final DateTime? fechaPago;
  final String? cobrador;
  final VoidCallback? onTap;

  /// Pagos parciales dentro del mes (ej. 2 de 4 para semanal)
  final int? pagosEsperados;
  final int? pagosRegistrados;

  /// Optional action button (e.g., "Cobrar" for Cobrador role)
  final Widget? actionButton;

  const CobroCard({
    super.key,
    required this.periodo,
    required this.monto,
    required this.status,
    this.montoPagado = 0,
    this.fechaPago,
    this.cobrador,
    this.pagosEsperados,
    this.pagosRegistrados,
    this.onTap,
    this.actionButton,
  });

  @override
  Widget build(BuildContext context) {
    final montoStr = NumberFormat.currency(
      locale: 'es_CO',
      symbol: r'$',
      decimalDigits: 0,
    ).format(monto);

    final saldo = monto - montoPagado;
    final saldoStr = NumberFormat.currency(
      locale: 'es_CO',
      symbol: r'$',
      decimalDigits: 0,
    ).format(saldo);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header row: periodo + badge ──────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        periodo,
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    StatusBadge(status: status),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),

                // ── Amount row ───────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      montoStr,
                      style: AppTypography.subtitle.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (saldo > 0 && status != StatusType.alDia)
                      Text(
                        'Saldo: $saldoStr',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),

                if (pagosEsperados != null &&
                    pagosEsperados! > 1 &&
                    pagosRegistrados != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '$pagosRegistrados de $pagosEsperados abonos · Pagado: ${NumberFormat.currency(locale: 'es_CO', symbol: r'$', decimalDigits: 0).format(montoPagado)}',
                    style: AppTypography.small.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],

                // ── Payment info (if paid) ───────────────────────
                if (fechaPago != null || cobrador != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      if (fechaPago != null) ...[
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 13,
                          color: AppColors.textDisabled,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('dd/MM/yyyy').format(fechaPago!),
                          style: AppTypography.small.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                      if (fechaPago != null && cobrador != null)
                        const SizedBox(width: AppSpacing.md),
                      if (cobrador != null) ...[
                        Icon(
                          Icons.person_outline_rounded,
                          size: 13,
                          color: AppColors.textDisabled,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          cobrador!,
                          style: AppTypography.small.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],

                // ── Action button (optional, e.g. "Cobrar") ──────
                if (actionButton != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Align(
                    alignment: Alignment.centerRight,
                    child: actionButton!,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
