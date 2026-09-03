import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/top_toast.dart';
import '../../shared/widgets/empty_state.dart';
import 'comunidad_repository.dart';

class EtapasScreen extends StatefulWidget {
  final String proyectoId;

  const EtapasScreen({super.key, this.proyectoId = ''});

  @override
  State<EtapasScreen> createState() => _EtapasScreenState();
}

class _EtapasScreenState extends State<EtapasScreen> {
  final ComunidadRepository _repo = ComunidadRepository();
  bool _isLoading = true;
  List<Map<String, dynamic>> _etapas = [];

  @override
  void initState() {
    super.initState();
    _loadEtapas();
  }

  /// Obtiene el proyecto por defecto si no se proporcionó un proyectoId.
  Future<String> _getProyectoId() async {
    if (widget.proyectoId.isNotEmpty) return widget.proyectoId;
    final proys = await _repo.getProyectos();
    if (proys.isNotEmpty) return proys.first['id'] as String;
    throw Exception('No hay proyectos disponibles');
  }

  Future<void> _loadEtapas() async {
    setState(() => _isLoading = true);
    try {
      final pId = await _getProyectoId();
      final etapas = await _repo.getEtapasPorProyecto(pId);
      setState(() {
        _etapas = etapas;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        TopToast.showError(context, 'Error al cargar etapas: $e');
      }
    }
  }

  Future<void> _crearEtapaAutomatica() async {
    setState(() => _isLoading = true);
    try {
      final pId = await _getProyectoId();
      
      final maxNumber = _getMaxEtapaNumber();
      final nombre = 'Etapa ${maxNumber + 1}';
      
      await _repo.createEtapa(nombre, pId);
      await _loadEtapas();
      if (mounted) {
        TopToast.showSuccess(context, '$nombre creada exitosamente');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        TopToast.showError(context, 'Error al crear etapa: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Etapas'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.library_add_rounded),
            tooltip: 'Crear Múltiples',
            onPressed: () => _mostrarDialogoCreacionMultiple(),
          ),
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _etapas.isEmpty
          ? const EmptyState(
              icon: Icons.account_tree_outlined,
              title: 'No hay etapas',
              description: 'Aún no has creado ninguna etapa para este proyecto.',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              itemCount: _etapas.length,
              itemBuilder: (context, index) {
                final etapa = _etapas[index];
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
                      etapa['nombre'],
                      style: AppTypography.subtitle.copyWith(fontWeight: FontWeight.w600),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit_rounded, color: AppColors.info, size: 20),
                          onPressed: () {
                            TopToast.show(context, message: 'Editar Etapa', icon: Icons.edit_rounded);
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_rounded, color: AppColors.error, size: 20),
                          onPressed: () {
                            _mostrarConfirmacionEliminacion(etapa['nombre'], etapa['id'].toString());
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _crearEtapaAutomatica,
        backgroundColor: AppColors.primary,
        child: Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  void _mostrarConfirmacionEliminacion(String nombreEtapa, String id) {
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
              _mostrarDobleConfirmacion(nombreEtapa, id);
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _mostrarDobleConfirmacion(String nombreEtapa, String id) {
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
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              try {
                await _repo.deleteEtapa(id);
                await _loadEtapas();
                if (mounted) {
                  TopToast.showSuccess(context, '$nombreEtapa eliminada correctamente');
                }
              } catch (e) {
                setState(() => _isLoading = false);
                if (mounted) {
                  TopToast.showError(context, 'Error al eliminar etapa: $e');
                }
              }
            },
            child: const Text('Sí, eliminar definitivamente'),
          ),
        ],
      ),
    );
  }

  int _getMaxEtapaNumber() {
    int max = 0;
    for (var e in _etapas) {
      final name = e['nombre'].toString();
      final match = RegExp(r'Etapa\s+(\d+)').firstMatch(name);
      if (match != null) {
        final num = int.tryParse(match.group(1)!) ?? 0;
        if (num > max) max = num;
      }
    }
    // Si no hay ninguna con formato 'Etapa X', usamos el tamaño de la lista como fallback
    return max == 0 && _etapas.isNotEmpty ? _etapas.length : max;
  }

  void _mostrarDialogoCreacionMultiple() {
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
              const Text('¿Cuántas etapas deseas crear automáticamente?'),
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
                await _crearMultiplesEtapas(cantidad);
              }
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  Future<void> _crearMultiplesEtapas(int cantidad) async {
    setState(() => _isLoading = true);
    try {
      final pId = await _getProyectoId();
      int maxNumber = _getMaxEtapaNumber();
      for (int i = 0; i < cantidad; i++) {
        final nombre = 'Etapa ${maxNumber + i + 1}';
        await _repo.createEtapa(nombre, pId);
      }
      
      await _loadEtapas();
      if (mounted) {
        TopToast.showSuccess(context, '$cantidad etapas creadas con éxito');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        TopToast.showError(context, 'Error al crear etapas: $e');
      }
    }
  }
}
