import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/action_card.dart';

/// Acciones rápidas section with ActionCards.
class AccionesRapidasSection extends StatelessWidget {
  const AccionesRapidasSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.flash_on_rounded,
                size: 20, color: AppColors.primary),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Acciones rápidas',
              style: AppTypography.subtitle.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        ActionCard(
          icon: Icons.person_add_rounded,
          title: 'Nuevo Residente',
          onTap: () async {
            await context.push('/nuevo-residente');
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        ActionCard(
          icon: Icons.payments_rounded,
          title: 'Registrar Pago',
          onTap: () {},
        ),
        const SizedBox(height: AppSpacing.sm),
        ActionCard(
          icon: Icons.shield_rounded,
          title: 'Crear Cobrador',
          onTap: () async {
            await context.push('/nuevo-cobrador');
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        ActionCard(
          icon: Icons.holiday_village_rounded,
          title: 'Nueva Vivienda',
          onTap: () {},
        ),
      ],
    );
  }
}
