import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/constants/mock_data.dart';
import '../../shared/widgets/empty_state.dart';

class ManzanasScreen extends StatefulWidget {
  const ManzanasScreen({super.key});

  @override
  State<ManzanasScreen> createState() => _ManzanasScreenState();
}

class _ManzanasScreenState extends State<ManzanasScreen> {
  // Mock data centralizado
  late List<Map<String, dynamic>> _etapas;

  @override
  void initState() {
    super.initState();
    _etapas = MockData.manzanasPorEtapa.entries.map((entry) {
      return {
        'nombre': entry.key,
        'isExpanded': false,
        'manzanas': List<String>.from(entry.value),
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Manzanas'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: _etapas.isEmpty
          ? const EmptyState(
              icon: Icons.grid_view_rounded,
              title: 'No hay manzanas',
              description: 'Aún no has creado ninguna etapa para organizar las manzanas.',
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: ExpansionPanelList(
                elevation: 0,
                dividerColor: Colors.transparent,
                expansionCallback: (int index, bool isExpanded) {
                  setState(() {
                    _etapas[index]['isExpanded'] = isExpanded;
                  });
                },
                children: _etapas.map<ExpansionPanel>((etapa) {
                  final manzanas = etapa['manzanas'] as List<String>;
                  return ExpansionPanel(
                    backgroundColor: Colors.transparent,
                    canTapOnHeader: true,
                    isExpanded: etapa['isExpanded'],
                    headerBuilder: (context, isExpanded) {
                      return ListTile(
                        leading: Icon(
                          isExpanded ? Icons.folder_open_rounded : Icons.folder_rounded,
                          color: AppColors.primary,
                        ),
                        title: Text(
                          etapa['nombre'],
                          style: AppTypography.subtitle.copyWith(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text('${manzanas.length} manzanas'),
                      );
                    },
                    body: _buildManzanasList(manzanas),
                  );
                }).toList(),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Formulario para Nueva Manzana')),
          );
        },
        backgroundColor: AppColors.primary,
        child: Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildManzanasList(List<String> manzanas) {
    if (manzanas.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Text('No hay manzanas en esta etapa'),
      );
    }
    
    return Padding(
      padding: const EdgeInsets.only(left: 56.0, right: AppSpacing.md, bottom: AppSpacing.sm),
      child: Column(
        children: manzanas.map((m) {
          return Card(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            color: AppColors.surface,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: AppColors.border),
            ),
            child: ListTile(
              leading: Icon(Icons.grid_view_rounded, color: AppColors.primary),
              title: Text(
                m,
                style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit_rounded, color: AppColors.info, size: 20),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Editar Manzana')),
                      );
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_rounded, color: AppColors.error, size: 20),
                    onPressed: () {
                      _mostrarConfirmacionEliminacionManzana(context, m);
                    },
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _mostrarConfirmacionEliminacionManzana(BuildContext context, String nombreManzana) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error),
            const SizedBox(width: AppSpacing.sm),
            const Text('Eliminar Manzana'),
          ],
        ),
        content: Text(
          '¿Estás seguro de que deseas eliminar la $nombreManzana?\n\n'
          'Al eliminar esta manzana, se eliminarán también TODAS las casas asociadas a ella.',
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
                SnackBar(content: Text('$nombreManzana eliminada')),
              );
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
