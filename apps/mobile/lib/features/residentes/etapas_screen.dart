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
  bool _isRefreshing = false;
  List<Map<String, dynamic>> _etapas = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Obtains the default project ID if none was provided.
  Future<String> _getProyectoId() async {
    if (widget.proyectoId.isNotEmpty) return widget.proyectoId;
    final proys = await _repo.getProyectos();
    if (proys.isNotEmpty) return proys.first['id'] as String;
    throw Exception('No hay proyectos disponibles');
  }

  Future<void> _loadData({bool silent = false}) async {
    if (!silent) {
      setState(() => _isLoading = true);
    } else {
      setState(() => _isRefreshing = true);
    }
    try {
      final pId = await _getProyectoId();
      final etapas = await _repo.getEtapasPorProyecto(pId);
      if (mounted) {
        setState(() {
          _etapas = etapas;
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });
        TopToast.showError(context, 'Error al cargar etapas: $e');
      }
    }
  }

  Future<void> _crearEtapaAutomatica() async {
    try {
      final pId = await _getProyectoId();
      final maxNumber = _getMaxEtapaNumber();
      final nombre = 'Etapa ${maxNumber + 1}';

      await _repo.createEtapa(nombre, pId);
      await _loadData(silent: true);
      if (mounted) {
        TopToast.showSuccess(context, '$nombre creada exitosamente');
      }
    } catch (e) {
      if (mounted) {
        TopToast.showError(context, 'Error al crear etapa: $e');
      }
    }
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
    // If none match 'Etapa X' pattern, fall back to list length
    return max == 0 && _etapas.isNotEmpty ? _etapas.length : max;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Gestión de Etapas'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

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
        bottom: _isRefreshing
            ? const PreferredSize(
                preferredSize: Size.fromHeight(2),
                child: LinearProgressIndicator(minHeight: 2),
              )
            : null,
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => _loadData(silent: true),
        child: _etapas.isEmpty
            ? ListView(
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                  const EmptyState(
                    icon: Icons.account_tree_outlined,
                    title: 'No hay etapas',
                    description:
                        'Aún no has creado ninguna etapa para este proyecto.',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Center(
                    child: OutlinedButton.icon(
                      onPressed: _crearEtapaAutomatica,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Crear primera etapa'),
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.md),
                  // Compact action button
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenPadding,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FilledButton.tonalIcon(
                        onPressed: _crearEtapaAutomatica,
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text(
                          'Nueva Etapa',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppSpacing.buttonRadius),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Divider(height: 1),
                  // List header with counter
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screenPadding,
                      AppSpacing.md,
                      AppSpacing.screenPadding,
                      AppSpacing.sm,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Etapas del Proyecto',
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${_etapas.length} registradas',
                            style: AppTypography.smallBold.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Etapas list
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screenPadding,
                        AppSpacing.xs,
                        AppSpacing.screenPadding,
                        AppSpacing.xl,
                      ),
                      itemCount: _etapas.length,
                      itemBuilder: (context, index) {
                        final etapa = _etapas[index];
                        final nombre = etapa['nombre'].toString();
                        final id = etapa['id'].toString();
                        final manzanaCount =
                            (etapa['manzanas'] as List?)?.length ?? 0;

                        return Card(
                          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                          color: AppColors.card,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppSpacing.cardRadius),
                            side: BorderSide(
                              color: AppColors.border.withValues(alpha: 0.6),
                            ),
                          ),
                          child: ListTile(
                            leading: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color:
                                    AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.folder_rounded,
                                color: AppColors.primary,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              nombre,
                              style: AppTypography.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            subtitle: Text(
                              '$manzanaCount manzana${manzanaCount == 1 ? '' : 's'}',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            trailing: IconButton(
                              icon: Icon(Icons.delete_rounded,
                                  color: AppColors.error, size: 20),
                              tooltip: 'Eliminar Etapa',
                              onPressed: () {
                                _mostrarConfirmacionEliminacion(nombre, id);
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
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
              try {
                await _repo.deleteEtapa(id);
                await _loadData(silent: true);
                if (mounted) {
                  TopToast.showSuccess(
                      context, '$nombreEtapa eliminada correctamente');
                }
              } catch (e) {
                if (mounted) {
                  TopToast.showError(
                      context, 'Error al eliminar etapa: $e');
                }
              }
            },
            child: const Text('Sí, eliminar definitivamente'),
          ),
        ],
      ),
    );
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
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Requerido';
                  final num = int.tryParse(val);
                  if (num == null || num <= 0) {
                    return 'Ingrese un número válido';
                  }
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
    try {
      final pId = await _getProyectoId();
      int maxNumber = _getMaxEtapaNumber();
      for (int i = 0; i < cantidad; i++) {
        final nombre = 'Etapa ${maxNumber + i + 1}';
        await _repo.createEtapa(nombre, pId);
      }

      await _loadData(silent: true);
      if (mounted) {
        TopToast.showSuccess(context, '$cantidad etapas creadas con éxito');
      }
    } catch (e) {
      if (mounted) {
        TopToast.showError(context, 'Error al crear etapas: $e');
      }
    }
  }
}
