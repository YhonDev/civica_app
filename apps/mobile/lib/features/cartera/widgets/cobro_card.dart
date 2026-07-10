import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../models/cartera_models.dart';

class CobroCard extends StatelessWidget {
  final CobroItem cobro;

  const CobroCard({
    super.key,
    required this.cobro,
  });

  Color get _color {
    switch (cobro.estado) {
      case 'Pagado':
        return AppColors.success;
      case 'Mora':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  IconData get _icon {
    switch (cobro.estado) {
      case 'Pagado':
        return Icons.check_circle_rounded;
      case 'Mora':
        return Icons.error_outline_rounded;
      default:
        return Icons.schedule_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Avatar with initials
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.surface,
                  child: Text(
                    cobro.nombre.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase(),
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cobro.nombre,
                        style: AppTypography.body.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${cobro.casa} · ${cobro.etapa} · ${cobro.modalidad}',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Estado badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_icon, color: _color, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        cobro.estado,
                        style: AppTypography.small.copyWith(
                          color: _color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (cobro.estado != 'Pagado') ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Saldo Pendiente: ',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    r'$' + cobro.saldo.toStringAsFixed(0),
                    style: AppTypography.subtitle.copyWith(
                      fontWeight: FontWeight.w700,
                      color: cobro.estado == 'Mora' ? AppColors.error : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.phone_rounded, size: 20),
                  color: AppColors.textSecondary,
                  onPressed: () {},
                  tooltip: 'Llamar',
                ),
                IconButton(
                  icon: const Icon(Icons.chat_rounded, size: 20),
                  color: AppColors.textSecondary,
                  onPressed: () {},
                  tooltip: 'WhatsApp',
                ),
                if (cobro.estado != 'Pagado') ...[
                  const SizedBox(width: AppSpacing.sm),
                  FilledButton(
                    onPressed: () {},
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    child: const Text('Registrar Pago'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
