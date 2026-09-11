import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import 'status_badge.dart';

/// Atomic Organism: Territory Hierarchy Card (`TerritoryHierarchyCard`).
///
/// Standardized card representation for physical domain hierarchy:
/// `Etapa X • Manzana Y • Casa Z`.
/// Intelligently sanitizes duplicate prefix words ("Etapa Etapa 1" -> "Etapa 1").
class TerritoryHierarchyCard extends StatelessWidget {
  final String etapa;
  final String manzana;
  final String casaNumero;
  final String? residenteNombre;
  final String? estadoRecaudo;
  final bool showResidenteName;
  final VoidCallback? onTap;

  const TerritoryHierarchyCard({
    super.key,
    required this.etapa,
    required this.manzana,
    required this.casaNumero,
    this.residenteNombre,
    this.estadoRecaudo,
    this.showResidenteName = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cleanEtapa = _cleanValue(etapa, 'Etapa');
    final cleanManzana = _cleanValue(manzana, 'Manzana');
    final cleanCasa = _cleanValue(casaNumero, 'Casa');

    final parts = <String>[];
    if (cleanEtapa.isNotEmpty) parts.add('Etapa $cleanEtapa');
    if (cleanManzana.isNotEmpty) parts.add('Manzana $cleanManzana');
    if (cleanCasa.isNotEmpty) parts.add('Casa $cleanCasa');

    final hierarchyLabel = parts.join(' • ');

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
                  borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
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
                      hierarchyLabel.isNotEmpty ? hierarchyLabel : 'Inmueble Asignado',
                      style: AppTypography.subtitle.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (showResidenteName && residenteNombre != null && residenteNombre!.isNotEmpty) ...[
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

  String _cleanValue(String val, String prefix) {
    final trimmed = val.trim();
    if (trimmed.isEmpty) return '';
    final reg = RegExp('^$prefix\\s*', caseSensitive: false);
    return trimmed.replaceAll(reg, '').trim();
  }
}
