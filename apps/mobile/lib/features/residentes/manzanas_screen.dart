import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/top_toast.dart';
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
        TopToast.showError(context, 'Error al cargar manzanas: $e');
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
      if (mounted) {
        TopToast.showSuccess(context, '$nombre creada exitosamente');
      }
    } catch (e) {
      setState(() => _isLoading = false);
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
    final sortedManzanas = List<Map<String, dynamic>>.from(manzanas)
      ..sort((a, b) => a['nombre'].toString().compareTo(b['nombre'].toString()));

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
          ...sortedManzanas.map((m) {
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
                      TopToast.show(context, message: 'Editar Manzana', icon: Icons.edit_rounded);
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
        }),
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
                onPressed: () => _mostrarDialogoCrearManzanaConCasas(etapaId, manzanas),
                icon: const Icon(Icons.library_add_rounded),
                label: const Text('Crear con Casas'),
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
                  TopToast.showSuccess(context, '$nombreManzana eliminada correctamente');
                }
              } catch (e) {
                setState(() => _isLoading = false);
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

  void _mostrarDialogoCrearManzanaConCasas(String etapaId, List manzanas) {
    final nextNum = _getMaxManzanaNumber(manzanas) + 1;
    final nextLetter = (nextNum > 0 && nextNum <= 26) ? String.fromCharCode(64 + nextNum) : 'A';
    
    final letraInicioController = TextEditingController(text: nextLetter);
    final letraFinController = TextEditingController(text: nextLetter);
    final inicioController = TextEditingController(text: '1');
    final finController = TextEditingController(text: '20');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Crear Manzanas y Casas'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: letraInicioController,
                      textCapitalization: TextCapitalization.characters,
                      maxLength: 1,
                      decoration: InputDecoration(
                        labelText: 'Letra Inicio',
                        counterText: '',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Requerido';
                        if (!RegExp(r'^[A-Z]$').hasMatch(val.toUpperCase())) return 'A-Z';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: TextFormField(
                      controller: letraFinController,
                      textCapitalization: TextCapitalization.characters,
                      maxLength: 1,
                      decoration: InputDecoration(
                        labelText: 'Letra Fin',
                        counterText: '',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Requerido';
                        if (!RegExp(r'^[A-Z]$').hasMatch(val.toUpperCase())) return 'A-Z';
                        if (val.toUpperCase().codeUnitAt(0) < letraInicioController.text.toUpperCase().codeUnitAt(0)) {
                          return 'Inválido';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: inicioController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Casa Inicial',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: TextFormField(
                      controller: finController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Casa Final',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Requerido';
                        if (int.parse(val) < int.parse(inicioController.text)) return 'Inválido';
                        return null;
                      },
                    ),
                  ),
                ],
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
                final letraInicio = letraInicioController.text.toUpperCase();
                final letraFin = letraFinController.text.toUpperCase();
                final inicio = int.parse(inicioController.text);
                final fin = int.parse(finController.text);
                Navigator.pop(ctx);
                await _crearRangoManzanasConCasas(etapaId, letraInicio, letraFin, inicio, fin);
              }
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  Future<void> _crearRangoManzanasConCasas(String etapaId, String letraInicio, String letraFin, int inicio, int fin) async {
    setState(() => _isLoading = true);
    try {
      int startCode = letraInicio.codeUnitAt(0);
      int endCode = letraFin.codeUnitAt(0);
      for (int code = startCode; code <= endCode; code++) {
        final letter = String.fromCharCode(code);
        final nombre = 'Manzana $letter';
        final manzana = await _repo.createManzana(nombre, etapaId);
        final manzanaId = manzana['id'];
        for (int i = inicio; i <= fin; i++) {
          await _repo.createCasa('Casa $i', manzanaId);
        }
      }
      
      await _loadData();
      if (mounted) {
        TopToast.showSuccess(context, 'Manzanas ($letraInicio ➔ $letraFin) creadas exitosamente con casas');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        TopToast.showError(context, 'Error al crear manzanas: $e');
      }
    }
  }
}
