import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

class UrbanizacionScreen extends StatelessWidget {
  const UrbanizacionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Proyectos'),
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
            Text(
              'Tus Urbanizaciones',
              style: AppTypography.subtitle.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Selecciona un proyecto para gestionar su estructura.',
              style: AppTypography.body.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            
            // Lista de proyectos
            _buildProjectCard(
              context,
              name: 'Urbanización Los Pinos',
              status: 'Activo',
              etapas: 3,
              manzanas: 5,
              casas: 120,
              onTap: () => context.push('/comunidad/urbanizacion/proyecto-detalle'),
            ),
            
            const SizedBox(height: AppSpacing.md),
            
            // Mock de un segundo proyecto para demostrar capacidad multi-proyecto
            _buildProjectCard(
              context,
              name: 'Condominio El Bosque',
              status: 'En configuración',
              etapas: 1,
              manzanas: 2,
              casas: 40,
              isActive: false,
              onTap: () => context.push('/comunidad/urbanizacion/proyecto-detalle'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Crear nuevo proyecto...')),
          );
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Nuevo Proyecto',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildProjectCard(
    BuildContext context, {
    required String name,
    required String status,
    required int etapas,
    required int manzanas,
    required int casas,
    bool isActive = true,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive 
              ? AppColors.primary.withValues(alpha: 0.2) 
              : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isActive ? Colors.white : AppColors.background,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isActive ? AppColors.primary.withValues(alpha: 0.3) : AppColors.border,
                ),
              ),
              child: Icon(
                Icons.location_city_rounded, 
                color: isActive ? AppColors.primary : AppColors.textDisabled, 
                size: 28,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: AppTypography.subtitle.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isActive ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isActive ? AppColors.success.withValues(alpha: 0.2) : AppColors.warning.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          status,
                          style: AppTypography.small.copyWith(
                            color: isActive ? AppColors.success : AppColors.warning,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$etapas Etapas • $manzanas Manzanas • $casas Casas',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isActive ? AppColors.primary : AppColors.textDisabled,
            ),
          ],
        ),
      ),
    );
  }
}
