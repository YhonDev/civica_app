import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/empty_state.dart';
import 'comunidad_repository.dart';

class CasasScreen extends StatefulWidget {
  const CasasScreen({super.key});

  @override
  State<CasasScreen> createState() => _CasasScreenState();
}

class _CasasScreenState extends State<CasasScreen> {
  final ComunidadRepository _repo = ComunidadRepository();
  bool _isLoading = true;
  late List<Map<String, dynamic>> _etapas = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final etapas = await _repo.getArbolCompleto();
      setState(() {
        _etapas = etapas.map((etapa) {
          final manzanasEstructura = (etapa['manzanas'] as List).map((manzana) {
            final casasList = (manzana['casas'] as List).map((c) {
              return {
                'id': c['id'],
                'nombre': c['nombre'],
              };
            }).toList();
            return {
              'id': manzana['id'],
              'nombre': manzana['nombre'],
              'casas': casasList,
            };
          }).toList();

          return {
            'id': etapa['id'],
            'nombre': etapa['nombre'],
            'manzanas': manzanasEstructura,
          };
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar casas: $e')),
        );
      }
    }
  }

  Future<void> _crearCasaAutomatica(String manzanaId, List casas) async {
    setState(() => _isLoading = true);
    
    final maxNumber = _getMaxCasaNumber(casas);
    final nombre = 'Casa ${maxNumber + 1}';
    
    try {
      await _repo.createCasa(nombre, manzanaId);
      await _loadData();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear casa: $e')),
        );
      }
    }
  }

  int _getMaxCasaNumber(List casas) {
    int max = 0;
    for (var c in casas) {
      final name = c['nombre'].toString();
      final match = RegExp(r'Casa\s+(\d+)').firstMatch(name);
      if (match != null) {
        final num = int.tryParse(match.group(1)!) ?? 0;
        if (num > max) max = num;
      }
    }
    return max == 0 && casas.isNotEmpty ? casas.length : max;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Casas / Lotes'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _etapas.isEmpty
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
                final manzanas = etapa['manzanas'] as List;
                
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
    );
  }

  Widget _buildManzanaTile(Map<String, dynamic> manzana) {
    final casas = manzana['casas'] as List;
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.xl),
      child: ExpansionTile(
        leading: Icon(Icons.grid_view_rounded, color: AppColors.textSecondary),
        title: Text(
          manzana['nombre'],
          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        children: [
          if (casas.isEmpty)
            const Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.md),
              child: Text('No hay casas en esta manzana', style: TextStyle(color: Colors.grey)),
            ),
          ...casas.map((c) => _buildCasaItem(c)),
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.xl, right: AppSpacing.md, bottom: AppSpacing.md, top: AppSpacing.sm),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _crearCasaAutomatica(manzana['id'], casas),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Agregar 1'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: () => _mostrarDialogoCreacionMultiple(manzana['id'], casas),
                    icon: const Icon(Icons.library_add_rounded),
                    label: const Text('Agregar Varios'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCasaItem(Map<String, dynamic> casa) {
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
            casa['nombre'].toString(),
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
                  _mostrarConfirmacionEliminacionCasa(context, casa['nombre'].toString(), casa['id'].toString());
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarConfirmacionEliminacionCasa(BuildContext context, String nombreCasa, String id) {
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
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              try {
                await _repo.deleteCasa(id);
                await _loadData();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$nombreCasa eliminada')),
                  );
                }
              } catch (e) {
                setState(() => _isLoading = false);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al eliminar: $e')),
                  );
                }
              }
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoCreacionMultiple(String manzanaId, List casas) {
    final TextEditingController controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Creación en Bloque'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('¿Cuántas casas deseas crear automáticamente?'),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: controller,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Cantidad',
                  hintText: 'Ej. 10',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Requerido';
                  final num = int.tryParse(val);
                  if (num == null || num <= 0) return 'Ingrese un número válido';
                  if (num > 100) return 'Máximo 100 a la vez';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final cantidad = int.parse(controller.text);
                Navigator.pop(ctx);
                await _crearMultiplesCasas(manzanaId, casas, cantidad);
              }
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  Future<void> _crearMultiplesCasas(String manzanaId, List casas, int cantidad) async {
    setState(() => _isLoading = true);
    try {
      final maxNumber = _getMaxCasaNumber(casas);
      for (int i = 0; i < cantidad; i++) {
        final nombre = 'Casa ${maxNumber + i + 1}';
        await _repo.createCasa(nombre, manzanaId);
      }
      
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$cantidad casas creadas con éxito')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear casas: $e')),
        );
      }
    }
  }
}
