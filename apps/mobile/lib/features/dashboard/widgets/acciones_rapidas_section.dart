import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/square_action_card.dart';

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
        Row(
          children: [
            Expanded(
              child: SquareActionCard(
                icon: Icons.person_add_rounded,
                title: 'Nuevo Propietario',
                subtitle: 'Agregar a la comunidad',
                onTap: () {},
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: SquareActionCard(
                icon: Icons.payments_rounded,
                title: 'Registrar Pago',
                subtitle: 'Ingreso manual',
                onTap: () {},
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: SquareActionCard(
                icon: Icons.shield_rounded,
                title: 'Crear Cobrador',
                subtitle: 'Asignar zona',
                onTap: () {},
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: SquareActionCard(
                icon: Icons.holiday_village_rounded,
                title: 'Nueva Vivienda',
                subtitle: 'Registrar inmueble',
                onTap: () {},
              ),
            ),
          ],
        ),
      ],
    );
  }
}
