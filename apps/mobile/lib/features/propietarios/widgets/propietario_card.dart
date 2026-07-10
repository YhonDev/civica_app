import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../models/propietarios_models.dart';

class PropietarioCard extends StatelessWidget {
  final PropietarioItem propietario;

  const PropietarioCard({
    super.key,
    required this.propietario,
  });

  Color get _statusColor {
    switch (propietario.estadoFinanciero) {
      case 'Al Día':
        return AppColors.success;
      case 'Mora':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          children: [
            Row(
              children: [
                // Initials avatar
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Text(
                    propietario.nombre.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase(),
                    style: AppTypography.subtitle.copyWith(
                      color: AppColors.primary,
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
                        propietario.nombre,
                        style: AppTypography.subtitle.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${propietario.casa} • ${propietario.etapa}',
                        style: AppTypography.body.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    propietario.estadoFinanciero,
                    style: AppTypography.small.copyWith(
                      color: _statusColor,
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
                    Icon(Icons.phone_android_rounded, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      propietario.telefono,
                      style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.phone_rounded, size: 20),
                      color: AppColors.primary,
                      visualDensity: VisualDensity.compact,
                      onPressed: () {},
                      tooltip: 'Llamar',
                    ),
                    IconButton(
                      icon: const Icon(Icons.chat_rounded, size: 20),
                      color: const Color(0xFF25D366), // WhatsApp green
                      visualDensity: VisualDensity.compact,
                      onPressed: () {},
                      tooltip: 'WhatsApp',
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded, size: 24),
                      color: AppColors.textSecondary,
                      visualDensity: VisualDensity.compact,
                      onPressed: () {},
                      tooltip: 'Ver detalle',
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
