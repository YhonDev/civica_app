import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import 'models/residentes_models.dart';

class ResidenteInmuebleScreen extends StatelessWidget {
  final ResidenteItem residente;

  const ResidenteInmuebleScreen({super.key, required this.residente});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Información del Inmueble'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.home_work_rounded, size: 64, color: AppColors.textDisabled),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Gestión de Inmueble\n(Próximamente)',
              textAlign: TextAlign.center,
              style: AppTypography.title.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Casa actual: ${residente.casa}\n${residente.etapa}',
              textAlign: TextAlign.center,
              style: AppTypography.body,
            ),
          ],
        ),
      ),
    );
  }
}
