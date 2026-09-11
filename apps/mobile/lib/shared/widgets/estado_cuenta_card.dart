import 'package:flutter/material.dart';
import '../../core/format/app_currency.dart';

import '../../core/theme/app_card_styles.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import 'status_badge.dart';

/// Large protagonist card showing the owner's account status.
///
/// Per ROLE_DASHBOARDS.md (Propietario §Tarjeta Principal):
///   - Must show: Estado (Al día / Pendiente / En Mora)
///   - Must occupy the biggest visual prominence
///   - Shows either "Próximo cobro" OR "Último pago" — NEVER both
///
/// Reusable in: Dashboard Propietario, Propietario detail in Cobrador.
///
/// Layout:
/// ┌────────────────────────────────┐
/// │  🟢  AL DÍA                    │
/// │  Saldo actual: $0              │
/// │  Próximo cobro: 01/09/2026     │
/// └────────────────────────────────┘
class EstadoCuentaCard extends StatelessWidget {
  final StatusType status;
  final String saldoLabel;
  final String? proximoCobro;
  final String? ultimoPago;
  final Map<String, dynamic>? tarifaActual;
  final VoidCallback? onTap;

  const EstadoCuentaCard({
    super.key,
    required this.status,
    required this.saldoLabel,
    this.proximoCobro,
    this.ultimoPago,
    this.tarifaActual,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Determine secondary info: próximo cobro OR último pago, never both
    final secondaryLabel = proximoCobro != null
        ? 'Próximo cobro: $proximoCobro'
        : ultimoPago != null
            ? 'Último pago: $ultimoPago'
            : null;

    final secondaryIcon = proximoCobro != null
        ? Icons.event_outlined
        : Icons.receipt_long_outlined;

    return Container(
      width: double.infinity,
      padding: AppSpacing.cardEdgeInsets,
      decoration: AppCardStyles.heroCard(context),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status badge and Tarifa
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  StatusBadge(
                    status: status,
                    iconSize: 16,
                    textStyle: AppTypography.caption,
                  ),
                  if (tarifaActual != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                      decoration: AppCardStyles.metaChip(),
                      child: Text(
                        'Tarifa: ${AppCurrency.formatOrNull((tarifaActual!['cobroMensual'] ?? tarifaActual!['cuotaMensual'] ?? tarifaActual!['montoSegunModalidad'] as num?)?.toInt(), fallback: 40000)}',
                        style: AppCardStyles.metaChipText,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Saldo
              Text(
                saldoLabel,
                style: AppCardStyles.heroValue,
              ),
              if (secondaryLabel != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Icon(
                      secondaryIcon,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        secondaryLabel,
                        style: AppTypography.body.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
