import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/constants/mock_data.dart';
import '../../shared/widgets/empty_state.dart';

class EtapasScreen extends StatelessWidget {
  const EtapasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Usar datos centralizados
    final List<String> etapas = MockData.etapas;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Etapas'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: etapas.isEmpty
          ? const EmptyState(
              icon: Icons.account_tree_outlined,
              title: 'No hay etapas',
              description: 'Aún no has creado ninguna etapa para este proyecto.',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              itemCount: etapas.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  color: AppColors.surface,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: AppColors.border),
                  ),
                  child: ListTile(
                    leading: Icon(Icons.folder_rounded, color: AppColors.primary),
                    title: Text(
                      etapas[index],
                      style: AppTypography.subtitle.copyWith(fontWeight: FontWeight.w600),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit_rounded, color: AppColors.info, size: 20),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Editar Etapa')),
                            );
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_rounded, color: AppColors.error, size: 20),
                          onPressed: () {
                            _mostrarConfirmacionEliminacion(context, etapas[index]);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Formulario para Nueva Etapa')),
          );
        },
        backgroundColor: AppColors.primary,
        child: Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  void _mostrarConfirmacionEliminacion(BuildContext context, String nombreEtapa) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error),
            const SizedBox(width: AppSpacing.sm),
            const Text('Eliminar Etapa'),
          ],
        ),
        content: Text(
          '¿Estás seguro de que deseas eliminar la $nombreEtapa?\n\n'
          'Esta es una acción destructiva en bloque. Al eliminar esta etapa, '
          'se eliminarán también TODAS las manzanas y casas asociadas a ella.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(ctx);
              _mostrarDobleConfirmacion(context, nombreEtapa);
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _mostrarDobleConfirmacion(BuildContext context, String nombreEtapa) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Doble Confirmación'),
        content: Text(
          'Por favor, confirma nuevamente que deseas destruir la $nombreEtapa y todo su contenido. Esta acción no se puede deshacer.',
          style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$nombreEtapa y todo su contenido ha sido eliminado')),
              );
            },
            child: const Text('Sí, eliminar definitivamente'),
          ),
        ],
      ),
    );
  }
}
