import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/top_toast.dart';
import 'bloc/asignacion_etapa_cubit.dart';

class AsignarEtapasScreen extends StatelessWidget {
  final String cobradorId;
  final String cobradorNombre;

  const AsignarEtapasScreen({
    super.key,
    required this.cobradorId,
    required this.cobradorNombre,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AsignacionEtapaCubit()..load(cobradorId),
      child: Scaffold(
        appBar: AppBar(
          title: Text('Asignar Etapas — $cobradorNombre'),
          centerTitle: false,
        ),
        body: BlocConsumer<AsignacionEtapaCubit, AsignacionEtapaState>(
          listener: (context, state) {
            if (state.isSuccess) {
              TopToast.showSuccess(context, 'Asignación de zonas actualizada');
              Navigator.pop(context, true);
            } else if (state.errorMessage != null) {
              TopToast.showError(context, state.errorMessage!);
            }
          },
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Text(
                    'Selecciona las etapas del conjunto que este cobrador tendrá a su cargo en la jornada de cobro.',
                    style: AppTypography.body.copyWith(color: AppColors.textSecondary),
                  ),
                ),
                Expanded(
                  child: state.allEtapas.isEmpty
                      ? const Center(child: Text('No hay etapas registradas'))
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                          itemCount: state.allEtapas.length,
                          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xs),
                          itemBuilder: (context, index) {
                            final etapa = state.allEtapas[index];
                            final id = etapa['id'] as String;
                            final nombre = etapa['nombre'] ?? 'Etapa ${index + 1}';
                            final isChecked = state.selectedIds.contains(id);

                            return Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                                side: BorderSide(
                                  color: isChecked ? AppColors.primary : AppColors.border,
                                  width: isChecked ? 2 : 1,
                                ),
                              ),
                              child: CheckboxListTile(
                                value: isChecked,
                                title: Text(
                                  nombre,
                                  style: AppTypography.subtitle.copyWith(
                                    fontWeight: isChecked ? FontWeight.w700 : FontWeight.w500,
                                  ),
                                ),
                                subtitle: Text(
                                  isChecked ? 'Zona asignada a cobrador' : 'Disponible para asignar',
                                  style: AppTypography.caption.copyWith(
                                    color: isChecked ? AppColors.primary : AppColors.textSecondary,
                                  ),
                                ),
                                activeColor: AppColors.primary,
                                onChanged: (val) {
                                  context.read<AsignacionEtapaCubit>().toggle(id);
                                },
                              ),
                            );
                          },
                        ),
                ),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: state.isSaving
                        ? null
                        : () => context.read<AsignacionEtapaCubit>().save(),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                      ),
                    ),
                    child: state.isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: AppColors.onPrimary, strokeWidth: 2),
                          )
                        : const Text(
                            'Guardar Asignación',
                            style: TextStyle(color: AppColors.onPrimary, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
