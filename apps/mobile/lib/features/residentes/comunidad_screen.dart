import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/action_card.dart';
import '../../shared/widgets/screen_header.dart';

class ComunidadScreen extends StatelessWidget {
  const ComunidadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ScreenHeader(title: 'Comunidad'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
              
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
                title: 'Residentes',
                onTap: () => context.go('/comunidad/residentes'),
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
          ],
        ),
      ),
    );
  }
}
