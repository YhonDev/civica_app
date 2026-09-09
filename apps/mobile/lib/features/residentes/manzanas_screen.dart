import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/top_toast.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/fading_horizontal_scroll.dart';
import 'comunidad_repository.dart';

class ManzanasScreen extends StatefulWidget {
  const ManzanasScreen({super.key});

  @override
  State<ManzanasScreen> createState() => _ManzanasScreenState();
}

class _ManzanasScreenState extends State<ManzanasScreen> {
  final ComunidadRepository _repo = ComunidadRepository();
  bool _isLoading = true;
  bool _isRefreshing = false;
  String _selectedEtapaId = '';
  List<Map<String, dynamic>> _etapas = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData({bool silent = false}) async {
    if (!silent) {
      setState(() => _isLoading = true);
    } else {
      setState(() => _isRefreshing = true);
    }
    try {
      final etapas = await _repo.getEtapasConManzanas();
      if (mounted) {
        setState(() {
          _etapas = etapas;
          if (_etapas.isNotEmpty) {
            final exists = _etapas.any((e) => e['id'] == _selectedEtapaId);
            if (!exists || _selectedEtapaId.isEmpty) {
              _selectedEtapaId = _etapas.first['id'] as String;
            }
          }
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
        TopToast.showError(context, 'Error al cargar manzanas: $e');
      }
    }
  }

  Future<void> _crearManzanaAutomatica(String etapaId, List manzanas) async {
    final maxNumber = _getMaxManzanaNumber(manzanas);
    final nombre = _getManzanaNameByNumber(maxNumber + 1);

    try {
      await _repo.createManzana(nombre, etapaId);
      await _loadData(silent: true);
      if (mounted) {
        TopToast.showSuccess(context, '$nombre creada exitosamente');
      }
    } catch (e) {
      if (mounted) {
        TopToast.showError(context, 'Error al crear manzana: $e');
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
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Gestión de Manzanas'),
          leading: IconButton(
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
          title: const Text('Gestión de Manzanas'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.pop(),
          ),
        ),
        body: const EmptyState(
          icon: Icons.grid_view_rounded,
          title: 'No hay manzanas',
          description: 'Aún no has creado ninguna etapa para organizar las manzanas.',
        ),
      );
    }

    final activeEtapa = _etapas.firstWhere(
      (e) => e['id'] == _selectedEtapaId,
      orElse: () => _etapas.first,
    );
    final activeManzanas = List<Map<String, dynamic>>.from(activeEtapa['manzanas'] as List? ?? [])
      ..sort((a, b) => a['nombre'].toString().compareTo(b['nombre'].toString()));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Manzanas'),
        leading: IconButton(
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
            // Header con etiqueta de etapa activa
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
            const SizedBox(height: AppSpacing.sm),
            // Selector horizontal de ChoiceChips con desvanecimiento elegante
            FadingHorizontalScroll(
              child: Row(
                children: _etapas.map((etapa) {
                  final isSelected = _selectedEtapaId == etapa['id'];
                  final mzs = etapa['manzanas'] as List? ?? [];
                  return Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xs),
                    child: ChoiceChip(
                      label: Text('${etapa['nombre']} (${mzs.length})'),
                      selected: isSelected,
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedEtapaId = etapa['id']);
                        }
                      },
                      selectedColor: AppColors.primary,
                      labelStyle: AppTypography.smallBold.copyWith(
                        color: isSelected ? Colors.white : AppColors.textSecondary,
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
            // Acción fija superior compacta
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.tonalIcon(
                  onPressed: () => _crearManzanaAutomatica(_selectedEtapaId, activeManzanas),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(
                    'Nueva Manzana',
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
                    'Manzanas en ${activeEtapa['nombre']}',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${activeManzanas.length} registradas',
                      style: AppTypography.smallBold.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Lista de tarjetas de manzana
            Expanded(
              child: activeManzanas.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.grid_off_rounded, size: 48, color: AppColors.textDisabled),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'No hay manzanas en ${activeEtapa['nombre']}',
                            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          OutlinedButton.icon(
                            onPressed: () => _crearManzanaAutomatica(_selectedEtapaId, activeManzanas),
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Crear primera manzana'),
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
                      itemCount: activeManzanas.length,
                      itemBuilder: (context, index) {
                        final m = activeManzanas[index];
                        final nombre = m['nombre'].toString();
                        final id = m['id'].toString();
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
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.grid_view_rounded,
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
                            trailing: IconButton(
                              icon: Icon(Icons.delete_rounded, color: AppColors.error, size: 20),
                              tooltip: 'Eliminar Manzana',
                              onPressed: () {
                                _mostrarConfirmacionEliminacionManzana(nombre, id);
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

  void _mostrarConfirmacionEliminacionManzana(String nombreManzana, String id) {
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
              try {
                await _repo.deleteManzana(id);
                await _loadData(silent: true);
                if (mounted) {
                  TopToast.showSuccess(context, '$nombreManzana eliminada correctamente');
                }
              } catch (e) {
                if (mounted) {
                  TopToast.showError(context, 'Error al eliminar: $e');
                }
              }
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
