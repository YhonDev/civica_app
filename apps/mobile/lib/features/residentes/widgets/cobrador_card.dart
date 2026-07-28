import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../models/cobradores_models.dart';

class CobradorCard extends StatelessWidget {
  final CobradorItem cobrador;

  const CobradorCard({
    super.key,
    required this.cobrador,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: InkWell(
        onTap: () {
          context.push('/cobrador-detalle', extra: cobrador);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          child: Column(
            children: [
              Row(
                children: [
                  // Initials avatar
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.info.withValues(alpha: 0.1),
                    child: Text(
                      cobrador.nombre.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase(),
                      style: AppTypography.subtitle.copyWith(
                        color: AppColors.info,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cobrador.nombre,
                          style: AppTypography.subtitle.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Zonas: ${cobrador.zonas.join(', ')}',
                          style: AppTypography.body.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Status indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (cobrador.activo ? AppColors.success : AppColors.textDisabled).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      cobrador.activo ? 'Activo' : 'Inactivo',
                      style: AppTypography.small.copyWith(
                        color: cobrador.activo ? AppColors.success : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              const Divider(height: 1),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.payments_rounded, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        '${cobrador.pagosRegistradosSemana} pagos esta sem.',
                        style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  Icon(Icons.chevron_right_rounded, color: AppColors.textDisabled),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
