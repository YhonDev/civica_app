import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/constants/mock_data.dart';
import '../../shared/widgets/empty_state.dart';

class CasasScreen extends StatefulWidget {
  const CasasScreen({super.key});

  @override
  State<CasasScreen> createState() => _CasasScreenState();
}

class _CasasScreenState extends State<CasasScreen> {
  // Mock data centralizado
  late List<Map<String, dynamic>> _etapas;

  @override
  void initState() {
    super.initState();
    _etapas = MockData.etapas.map((etapa) {
      final manzanasDeEstaEtapa = MockData.manzanasPorEtapa[etapa] ?? [];
      
      final manzanasEstructura = manzanasDeEstaEtapa.map((manzana) {
        return {
          'nombre': manzana,
          'casas': MockData.casasPorManzana[manzana] ?? [],
        };
      }).toList();

      return {
        'nombre': etapa,
        'manzanas': manzanasEstructura,
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Casas / Lotes'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: _etapas.isEmpty
          ? const EmptyState(
              icon: Icons.home_rounded,
              title: 'No hay casas',
              description: 'Aún no has creado ninguna estructura para organizar las casas.',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: _etapas.length,
              itemBuilder: (context, index) {
                final etapa = _etapas[index];
                final manzanas = etapa['manzanas'] as List<Map<String, dynamic>>;
                
                return Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    leading: Icon(Icons.folder_rounded, color: AppColors.primary),
                    title: Text(
                      etapa['nombre'],
                      style: AppTypography.subtitle.copyWith(fontWeight: FontWeight.w600),
                    ),
                    children: manzanas.map((m) => _buildManzanaTile(m)).toList(),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Formulario para Nueva Casa')),
          );
        },
        backgroundColor: AppColors.primary,
        child: Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildManzanaTile(Map<String, dynamic> manzana) {
    final casas = manzana['casas'] as List<String>;
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.xl),
      child: ExpansionTile(
        leading: Icon(Icons.grid_view_rounded, color: AppColors.textSecondary),
        title: Text(
          manzana['nombre'],
          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        children: casas.map((c) => _buildCasaItem(c)).toList(),
      ),
    );
  }

  Widget _buildCasaItem(String nombreCasa) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.xl, right: AppSpacing.md, bottom: AppSpacing.sm),
      child: Card(
        margin: EdgeInsets.zero,
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppColors.border),
        ),
        child: ListTile(
          leading: Icon(Icons.home_rounded, color: AppColors.primary),
          title: Text(
            nombreCasa,
            style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.edit_rounded, color: AppColors.info, size: 20),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Editar Casa')),
                  );
                },
              ),
              IconButton(
                icon: Icon(Icons.delete_rounded, color: AppColors.error, size: 20),
                onPressed: () {
                  _mostrarConfirmacionEliminacionCasa(context, nombreCasa);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarConfirmacionEliminacionCasa(BuildContext context, String nombreCasa) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error),
            const SizedBox(width: AppSpacing.sm),
            const Text('Eliminar Casa'),
          ],
        ),
        content: Text(
          '¿Estás seguro de que deseas eliminar la $nombreCasa?\n\n'
          'Esta acción es definitiva.',
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
                SnackBar(content: Text('$nombreCasa eliminada')),
              );
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
