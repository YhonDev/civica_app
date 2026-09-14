import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/top_toast.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/fading_horizontal_scroll.dart';
import 'comunidad_repository.dart';

class CasasScreen extends StatefulWidget {
  const CasasScreen({super.key});

  @override
  State<CasasScreen> createState() => _CasasScreenState();
}

class _CasasScreenState extends State<CasasScreen> {
  final ComunidadRepository _repo = ComunidadRepository();
  bool _isLoading = true;
  bool _isRefreshing = false;
  List<Map<String, dynamic>> _etapas = [];
  String? _selectedEtapaId;
  String? _selectedManzanaId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData({bool silent = false}) async {
    if (silent) {
      setState(() => _isRefreshing = true);
    } else {
      setState(() => _isLoading = true);
    }

    try {
      final etapas = await _repo.getArbolCompleto(includeOccupied: true);

      final List<Map<String, dynamic>> processedEtapas = etapas.map<Map<String, dynamic>>((etapa) {
        final List<Map<String, dynamic>> manzanasEstructura = ((etapa['manzanas'] as List?) ?? []).map<Map<String, dynamic>>((manzana) {
          final List<Map<String, dynamic>> casasList = ((manzana['casas'] as List?) ?? []).map<Map<String, dynamic>>((c) {
            return <String, dynamic>{
              'id': c['id'].toString(),
              'nombre': c['nombre'].toString(),
              'ocupada': c['ocupada'] == true,
            };
          }).toList();

          // Natural sort for houses (e.g. Casa 2 before Casa 10)
          casasList.sort((a, b) {
            final aName = a['nombre'].toString();
            final bName = b['nombre'].toString();
            final aMatch = RegExp(r'\d+').firstMatch(aName);
            final bMatch = RegExp(r'\d+').firstMatch(bName);
            if (aMatch != null && bMatch != null) {
              final aNum = int.tryParse(aMatch.group(0)!) ?? 0;
              final bNum = int.tryParse(bMatch.group(0)!) ?? 0;
              return aNum.compareTo(bNum);
            }
            return aName.compareTo(bName);
          });

          return <String, dynamic>{
            'id': manzana['id'].toString(),
            'nombre': manzana['nombre'].toString(),
            'casas': casasList,
          };
        }).toList();

        // Alphabetical sort for manzanas
        manzanasEstructura.sort(
          (a, b) => a['nombre'].toString().compareTo(b['nombre'].toString()),
        );

        return <String, dynamic>{
          'id': etapa['id'].toString(),
          'nombre': etapa['nombre'].toString(),
          'manzanas': manzanasEstructura,
        };
      }).toList();

      if (mounted) {
        setState(() {
          _etapas = processedEtapas;
          _isLoading = false;
          _isRefreshing = false;

          // Preservar o seleccionar la primera etapa
          if (_etapas.isNotEmpty) {
            if (_selectedEtapaId == null ||
                !_etapas.any((e) => e['id'] == _selectedEtapaId)) {
              _selectedEtapaId = _etapas.first['id'];
            }
          } else {
            _selectedEtapaId = null;
          }

          // Sincronizar la manzana seleccionada en la etapa activa
          _syncSelectedManzana();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });
        TopToast.showError(context, e, prefix: 'Error al cargar casas');
      }
    }
  }

  void _syncSelectedManzana() {
    if (_selectedEtapaId == null || _etapas.isEmpty) {
      _selectedManzanaId = null;
      return;
    }

    final activeEtapa = _etapas.firstWhere(
      (e) => e['id'] == _selectedEtapaId,
      orElse: () => _etapas.first,
    );
    final manzanas = activeEtapa['manzanas'] as List? ?? [];

    if (manzanas.isNotEmpty) {
      if (_selectedManzanaId == null ||
          !manzanas.any((m) => m['id'] == _selectedManzanaId)) {
        _selectedManzanaId = manzanas.first['id'];
      }
    } else {
      _selectedManzanaId = null;
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

  Future<void> _crearCasaAutomatica(String manzanaId, List casas) async {
    final maxNumber = _getMaxCasaNumber(casas);
    final nombre = 'Casa ${maxNumber + 1}';

    setState(() => _isRefreshing = true);
    try {
      await _repo.createCasa(nombre, manzanaId);
      await _loadData(silent: true);
      if (mounted) {
        TopToast.showSuccess(context, '$nombre creada exitosamente');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isRefreshing = false);
        TopToast.showError(context, e, prefix: 'Error al crear casa');
      }
    }
  }

  Future<void> _crearMultiplesCasas(String manzanaId, List casas, int cantidad) async {
    setState(() => _isRefreshing = true);
    try {
      final maxNumber = _getMaxCasaNumber(casas);
      for (int i = 0; i < cantidad; i++) {
        final nombre = 'Casa ${maxNumber + i + 1}';
        await _repo.createCasa(nombre, manzanaId);
      }
      await _loadData(silent: true);
      if (mounted) {
        TopToast.showSuccess(context, '$cantidad casas creadas con éxito');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isRefreshing = false);
        TopToast.showError(context, e, prefix: 'Error al crear casas');
      }
    }
  }

  Future<void> _eliminarCasa(String id, String nombre) async {
    setState(() => _isRefreshing = true);
    try {
      await _repo.deleteCasa(id);
      await _loadData(silent: true);
      if (mounted) {
        TopToast.showSuccess(context, '$nombre eliminada correctamente');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isRefreshing = false);
        TopToast.showError(context, e, prefix: 'Error al eliminar casa');
      }
    }
  }

  void _mostrarConfirmacionEliminacionCasa(String nombreCasa, String id) {
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
              _eliminarCasa(id, nombreCasa);
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
              const Text('¿Cuántas casas deseas agregar a esta manzana?'),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: controller,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Cantidad de Casas',
                  hintText: 'Ej. 10',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.buttonRadius)),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Requerido';
                  final num = int.tryParse(val.trim());
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
                final cantidad = int.parse(controller.text.trim());
                Navigator.pop(ctx);
                await _crearMultiplesCasas(manzanaId, casas, cantidad);
              }
            },
            child: const Text('Crear Casas'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Gestión de Casas / Lotes'),
          leading: IconButton(
            tooltip: 'Volver',
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_etapas.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Gestión de Casas / Lotes'),
          leading: IconButton(
            tooltip: 'Volver',
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.pop(),
          ),
        ),
        body: const EmptyState(
          icon: Icons.home_rounded,
          title: 'No hay etapas',
          description: 'Aún no has creado ninguna etapa ni estructura en el proyecto.',
        ),
      );
    }

    final activeEtapa = _etapas.firstWhere(
      (e) => e['id'] == _selectedEtapaId,
      orElse: () => _etapas.first,
    );
    final activeManzanas = List<Map<String, dynamic>>.from(activeEtapa['manzanas'] as List? ?? []);

    Map<String, dynamic>? activeManzana;
    if (activeManzanas.isNotEmpty) {
      activeManzana = activeManzanas.firstWhere(
        (m) => m['id'] == _selectedManzanaId,
        orElse: () => activeManzanas.first,
      );
    }

    final activeCasas = List<Map<String, dynamic>>.from(activeManzana?['casas'] as List? ?? []);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Casas / Lotes'),
        leading: IconButton(
          tooltip: 'Volver',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.md),

            // Fila 1: Selector de Etapa activa
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
              child: Text(
                'ETAPA ACTIVA',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            // Fila 1: Selector de Etapa activa con desvanecimiento elegante
            FadingHorizontalScroll(
              child: Row(
                children: _etapas.map((etapa) {
                  final isSelected = _selectedEtapaId == etapa['id'];
                  final mzs = etapa['manzanas'] as List? ?? [];
                  int totalCasas = 0;
                  for (var m in mzs) {
                    totalCasas += (m['casas'] as List? ?? []).length;
                  }

                  return Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xs),
                    child: ChoiceChip(
                      label: Text('${etapa['nombre']} ($totalCasas)'),
                      selected: isSelected,
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedEtapaId = etapa['id'];
                            _syncSelectedManzana();
                          });
                        }
                      },
                      selectedColor: AppColors.primary,
                      labelStyle: AppTypography.smallBold.copyWith(
                        color: isSelected ? AppColors.onPrimary : AppColors.textSecondary,
                      ),
                      backgroundColor: AppColors.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
                        side: BorderSide(
                          color: isSelected ? AppColors.primary : AppColors.border,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Fila 2: Selector de Manzana activa dentro de la etapa
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
              child: Text(
                'MANZANA ACTIVA',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            if (activeManzanas.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding,
                  vertical: AppSpacing.sm,
                ),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded, size: 18, color: AppColors.textSecondary),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'No hay manzanas en esta etapa. Crea manzanas primero.',
                          style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              FadingHorizontalScroll(
                child: Row(
                  children: activeManzanas.map((manzana) {
                    final isSelected = _selectedManzanaId == manzana['id'];
                    final numCasas = (manzana['casas'] as List? ?? []).length;

                    return Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.xs),
                      child: ChoiceChip(
                        label: Text('${manzana['nombre']} ($numCasas)'),
                        selected: isSelected,
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedManzanaId = manzana['id']);
                          }
                        },
                        selectedColor: AppColors.accentTeal,
                        labelStyle: AppTypography.smallBold.copyWith(
                          color: isSelected ? AppColors.onPrimary : AppColors.textSecondary,
                        ),
                        backgroundColor: AppColors.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
                          side: BorderSide(
                            color: isSelected ? AppColors.accentTeal : AppColors.border,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

            const SizedBox(height: AppSpacing.md),

            // Acciones fijas superiores de la Manzana activa (simétricas con Manzanas)
            if (activeManzana != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
                child: Row(
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: () => _crearCasaAutomatica(
                        activeManzana!['id'],
                        activeCasas,
                      ),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: Text(
                        'Nueva Casa',
                        style: AppTypography.smallBold,
                      ),
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    OutlinedButton.icon(
                      onPressed: () => _mostrarDialogoCreacionMultiple(
                        activeManzana!['id'],
                        activeCasas,
                      ),
                      icon: const Icon(Icons.library_add_rounded, size: 16),
                      label: Text(
                        'Agregar Varias',
                        style: AppTypography.smallBold,
                      ),
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        side: BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1),

            // Encabezado del listado con contador
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
                    activeManzana != null
                        ? 'Casas en ${activeManzana['nombre']}'
                        : 'Casas',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    ),
                    child: Text(
                      '${activeCasas.length} registradas',
                      style: AppTypography.smallBold.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Listado de casas de la manzana activa
            Expanded(
              child: activeManzana == null
                  ? Center(
                      child: Text(
                        'Selecciona o crea una manzana para ver sus casas.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : activeCasas.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.home_work_outlined, size: 48, color: AppColors.textDisabled),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                'No hay casas en ${activeManzana['nombre']}',
                                style: AppTypography.body.copyWith(color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              OutlinedButton.icon(
                                onPressed: () => _crearCasaAutomatica(activeManzana!['id'], activeCasas),
                                icon: const Icon(Icons.add_rounded),
                                label: const Text('Crear primera casa'),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.screenPadding,
                            AppSpacing.xs,
                            AppSpacing.screenPadding,
                            AppSpacing.xl,
                          ),
                          itemCount: activeCasas.length,
                          itemBuilder: (context, index) {
                            final casa = activeCasas[index];
                            final bool isOcupada = casa['ocupada'] == true;

                            return Card(
                              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                              color: AppColors.card,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                                side: BorderSide(
                                  color: AppColors.border.withValues(alpha: 0.6),
                                ),
                              ),
                              child: ListTile(
                                leading: Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: (isOcupada ? AppColors.success : AppColors.primary)
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                                  ),
                                  child: Icon(
                                    Icons.home_rounded,
                                    color: isOcupada ? AppColors.success : AppColors.primary,
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  casa['nombre'].toString(),
                                  style: AppTypography.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                        decoration: BoxDecoration(
                                          color: isOcupada
                                              ? AppColors.success.withValues(alpha: 0.12)
                                              : AppColors.surface,
                                          borderRadius: BorderRadius.circular(AppSpacing.radiusProgress),
                                          border: Border.all(
                                            color: isOcupada
                                                ? AppColors.success.withValues(alpha: 0.3)
                                                : AppColors.border,
                                          ),
                                        ),
                                        child: Text(
                                          isOcupada ? 'Ocupada' : 'Disponible',
                                          style: AppTypography.micro.copyWith(
                                            fontWeight: isOcupada ? FontWeight.w700 : FontWeight.w500,
                                            color: isOcupada ? AppColors.success : AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                trailing: isOcupada
                                    ? Tooltip(
                                        message: 'Casa ocupada por residente',
                                        child: Icon(
                                          Icons.person_rounded,
                                          color: AppColors.success,
                                          size: 20,
                                        ),
                                      )
                                    : IconButton(
                                        icon: Icon(
                                          Icons.delete_rounded,
                                          color: AppColors.error,
                                          size: 20,
                                        ),
                                        tooltip: 'Eliminar Casa',
                                        onPressed: () => _mostrarConfirmacionEliminacionCasa(
                                          casa['nombre'].toString(),
                                          casa['id'].toString(),
                                        ),
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
}
