import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import 'status_badge.dart';

/// Atomic Organism: Territory Hierarchy Card (`TerritoryHierarchyCard`).
///
/// Standardized card representation for physical domain hierarchy:
/// `Etapa → Manzana → Casa`.
/// Respects ubiquitous language: Casa (never "vivienda"), Residente, Etapa, Manzana.
class TerritoryHierarchyCard extends StatelessWidget {
  final String etapa;
  final String manzana;
  final String casaNumero;
  final String? residenteNombre;
  final String? estadoRecaudo;
  final VoidCallback? onTap;

  const TerritoryHierarchyCard({
    super.key,
    required this.etapa,
    required this.manzana,
    required this.casaNumero,
    this.residenteNombre,
    this.estadoRecaudo,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.home_work_outlined,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Etapa $etapa • Manzana $manzana • Casa $casaNumero',
                      style: AppTypography.subtitle.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (residenteNombre != null && residenteNombre!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Residente: $residenteNombre',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (estadoRecaudo != null) ...[
                const SizedBox(width: AppSpacing.sm),
                StatusBadge.fromString(estadoRecaudo!),
              ],
              if (onTap != null)
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textDisabled,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
