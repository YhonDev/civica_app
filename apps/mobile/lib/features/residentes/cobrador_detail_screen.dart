import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../screens/auth/auth_cubit.dart';
import 'models/cobradores_models.dart';
import 'widgets/security_section.dart';

class CobradorDetailScreen extends StatelessWidget {
  final CobradorItem cobrador;

  const CobradorDetailScreen({super.key, required this.cobrador});

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.read<AuthCubit>().state.usuario?['rol'] == 'ADMIN';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Cobrador'),
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
            // ── Info del cobrador ──
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.info.withValues(alpha: 0.1),
                    child: Text(
                      cobrador.nombre
                          .split(' ')
                          .map((w) => w.isNotEmpty ? w[0] : '')
                          .take(2)
                          .join()
                          .toUpperCase(),
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
                          style: AppTypography.title.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        const SizedBox(height: 4),
                        Text(
                          'Zonas: ${cobrador.zonas.join(', ')}',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            if (isAdmin) ...[
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: AppColors.border),
                ),
                child: ListTile(
                  leading: Icon(Icons.domain_add_rounded, color: AppColors.primary),
                  title: const Text('Asignar Etapas al Cobrador'),
                  subtitle: const Text('Configura el alcance operativo de este cobrador'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    context.push('/asignar-etapas', extra: {
                      'cobradorId': cobrador.usuarioId ?? cobrador.id,
                      'cobradorNombre': cobrador.nombre,
                    });
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],

            // ── Módulo de Seguridad ──
            SecuritySection(
              usuarioId: cobrador.usuarioId ?? cobrador.id,
              nombre: cobrador.nombre,
              initialUsername: cobrador.username,
              isAdmin: isAdmin,
              onCredentialsUpdated: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Credenciales actualizadas'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
