import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../screens/auth/auth_cubit.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

class MasScreen extends StatelessWidget {
  const MasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthCubit>().state.usuario;
    final nombre = user?['nombre'] as String? ?? 'Usuario';
    final rol = user?['rol'] as String? ?? '';
    final rolLabel = _rolName(rol);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Más opciones'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header del usuario rápido
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                    child: Text(
                      nombre.split(' ').map((w) => w[0]).take(2).join(),
                      style: AppTypography.title.copyWith(
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
                          nombre,
                          style: AppTypography.subtitle.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          rolLabel,
                          style: AppTypography.body.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              // Menú de opciones
              Text(
                'General',
                style: AppTypography.subtitle.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.settings_outlined),
                      title: const Text('Configuración'),
                      trailing: Icon(Icons.chevron_right_rounded, color: AppColors.textDisabled),
                      onTap: () => context.push('/mas/configuracion'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _rolName(String rol) {
    switch (rol) {
      case 'ADMIN':
        return 'Administrador';
      case 'COBRADOR':
        return 'Cobrador';
      case 'PROPIETARIO':
        return 'Propietario';
      default:
        return rol;
    }
  }
}
