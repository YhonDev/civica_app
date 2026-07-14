import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/empty_state.dart';
import 'comunidad_repository.dart';

class ManzanasScreen extends StatefulWidget {
  const ManzanasScreen({super.key});

  @override
  State<ManzanasScreen> createState() => _ManzanasScreenState();
}

class _ManzanasScreenState extends State<ManzanasScreen> {
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
      final etapas = await _repo.getEtapasConManzanas();
      setState(() {
        _etapas = etapas.map((e) {
          return {
            'id': e['id'],
            'nombre': e['nombre'],
            'isExpanded': false,
            'manzanas': e['manzanas'] as List,
          };
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar manzanas: $e')),
        );
      }
    }
  }

  Future<void> _crearManzanaAutomatica(String etapaId, List manzanas) async {
    setState(() => _isLoading = true);
    
    final maxNumber = _getMaxManzanaNumber(manzanas);
    final nombre = _getManzanaNameByNumber(maxNumber + 1);
    
    try {
      await _repo.createManzana(nombre, etapaId);
      await _loadData();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear manzana: $e')),
        );
      }
    }
  }

  int _getMaxManzanaNumber(List manzanas) {
    int max = 0;
    const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    for (var m in manzanas) {
      final name = m['nombre'].toString().trim();
      if (name.startsWith('Manzana ')) {
        final suffix = name.substring(8).trim();
        if (suffix.length == 1 && alphabet.contains(suffix)) {
          int val = alphabet.indexOf(suffix) + 1;
          if (val > max) max = val;
        } else {
          final num = int.tryParse(suffix);
          if (num != null && num > max) max = num;
        }
      }
    }
    return max == 0 && manzanas.isNotEmpty ? manzanas.length : max;
  }

  String _getManzanaNameByNumber(int num) {
    const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    if (num <= alphabet.length && num > 0) {
      return 'Manzana ${alphabet[num - 1]}';
    } else {
      return 'Manzana $num';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Manzanas'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _etapas.isEmpty
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
                  final manzanas = etapa['manzanas'] as List;
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
                    body: _buildManzanasList(etapa['id'], manzanas),
                  );
                }).toList(),
              ),
            ),
    );
  }

  Widget _buildManzanasList(String etapaId, List manzanas) {
    return Padding(
      padding: const EdgeInsets.only(left: 56.0, right: AppSpacing.md, bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (manzanas.isEmpty)
            const Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.md),
              child: Text('No hay manzanas en esta etapa', style: TextStyle(color: Colors.grey)),
            ),
          ...manzanas.map((m) {
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
                m['nombre'].toString(),
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
                      _mostrarConfirmacionEliminacionManzana(context, m['nombre'].toString(), m['id'].toString());
                    },
                  ),
                ],
              ),
            ),
          );
        }).toList(),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _crearManzanaAutomatica(etapaId, manzanas),
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
                onPressed: () => _mostrarDialogoCreacionMultiple(etapaId, manzanas),
                icon: const Icon(Icons.library_add_rounded),
                label: const Text('Agregar Varios'),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

  void _mostrarConfirmacionEliminacionManzana(BuildContext context, String nombreManzana, String id) {
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
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              try {
                await _repo.deleteManzana(id);
                await _loadData();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$nombreManzana eliminada')),
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

  void _mostrarDialogoCreacionMultiple(String etapaId, List manzanas) {
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
              const Text('¿Cuántas manzanas deseas crear automáticamente?'),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: controller,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Cantidad',
                  hintText: 'Ej. 5',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Requerido';
                  final num = int.tryParse(val);
                  if (num == null || num <= 0) return 'Ingrese un número válido';
                  if (num > 50) return 'Máximo 50 a la vez';
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
                await _crearMultiplesManzanas(etapaId, manzanas, cantidad);
              }
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  Future<void> _crearMultiplesManzanas(String etapaId, List manzanas, int cantidad) async {
    setState(() => _isLoading = true);
    try {
      final maxNumber = _getMaxManzanaNumber(manzanas);
      for (int i = 0; i < cantidad; i++) {
        final nombre = _getManzanaNameByNumber(maxNumber + i + 1);
        await _repo.createManzana(nombre, etapaId);
      }
      
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$cantidad manzanas creadas con éxito')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear manzanas: $e')),
        );
      }
    }
  }
}
