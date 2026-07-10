import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/action_card.dart';

class ProyectoDetailScreen extends StatelessWidget {
  const ProyectoDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Proyecto'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Resumen superior
            Container(
              padding: const EdgeInsets.all(AppSpacing.cardPadding),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.location_city_rounded, color: AppColors.primary, size: 36),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Urbanización Los Pinos',
                          style: AppTypography.subtitle.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '3 Etapas • 5 Manzanas • 120 Casas',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_rounded),
                    color: AppColors.primary,
                    tooltip: 'Editar Proyecto',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Editar detalles del proyecto')),
                      );
                    },
                  )
                ],
              ),
            ),
            
            const SizedBox(height: AppSpacing.xl),
            
            Text(
              'Configuración',
              style: AppTypography.subtitle.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            
            // Opciones de gestión
            ActionCard(
              icon: Icons.account_tree_rounded,
              title: 'Gestión de Etapas',
              onTap: () => context.push('/comunidad/urbanizacion/proyecto-detalle/etapas'),
            ),
            const SizedBox(height: AppSpacing.sm),
            ActionCard(
              icon: Icons.grid_view_rounded,
              title: 'Gestión de Manzanas',
              onTap: () => context.push('/comunidad/urbanizacion/proyecto-detalle/manzanas'),
            ),
            const SizedBox(height: AppSpacing.sm),
            ActionCard(
              icon: Icons.home_rounded,
              title: 'Gestión de Casas / Lotes',
              onTap: () => context.push('/comunidad/urbanizacion/proyecto-detalle/casas'),
            ),
            const SizedBox(height: AppSpacing.sm),
            ActionCard(
              icon: Icons.settings_rounded,
              title: 'Ajustes Generales del Proyecto',
              onTap: () => context.push('/comunidad/urbanizacion/proyecto-detalle/ajustes'),
            ),
          ],
        ),
      ),
    );
  }
}
