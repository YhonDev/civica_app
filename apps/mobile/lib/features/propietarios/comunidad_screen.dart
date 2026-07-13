import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/action_card.dart';

class ComunidadScreen extends StatelessWidget {
  const ComunidadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Comunidad',
                style: AppTypography.title.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Gestión de usuarios y estructura',
                style: AppTypography.body.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.xl),
              
              Text(
                'Gestión de Usuarios',
                style: AppTypography.subtitle.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ActionCard(
                icon: Icons.people_rounded,
                title: 'Propietarios',
                onTap: () => context.go('/comunidad/propietarios'),
              ),
              const SizedBox(height: AppSpacing.sm),
              ActionCard(
                icon: Icons.shield_rounded,
                title: 'Cobradores',
                onTap: () => context.go('/comunidad/cobradores'),
              ),
              
              const SizedBox(height: AppSpacing.xl),
              
              Text(
                'Estructura del Proyecto',
                style: AppTypography.subtitle.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ActionCard(
                icon: Icons.location_city_rounded,
                title: 'Estructura de Urbanización',
                onTap: () => context.go('/comunidad/urbanizacion'),
              ),
              const SizedBox(height: AppSpacing.sm),
              ActionCard(
                icon: Icons.payments_outlined,
                title: 'Configuración de Tarifas',
                onTap: () => context.go('/comunidad/tarifas'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
