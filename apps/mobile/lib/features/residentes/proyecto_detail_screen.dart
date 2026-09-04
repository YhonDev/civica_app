import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/top_toast.dart';
import '../../shared/widgets/action_card.dart';
import 'residentes_repository.dart';
import 'comunidad_repository.dart';
import 'models/residentes_models.dart';

class ProyectoDetailScreen extends StatefulWidget {
  final Map<String, dynamic> proyecto;

  const ProyectoDetailScreen({super.key, required this.proyecto});

  @override
  State<ProyectoDetailScreen> createState() => _ProyectoDetailScreenState();
}

class _ProyectoDetailScreenState extends State<ProyectoDetailScreen> {
  final ResidentesRepository _repo = ResidentesRepository();
  final ComunidadRepository _comunidadRepo = ComunidadRepository();
  ResidenteResumen? _resumen;
  late Map<String, dynamic> _proyecto;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _proyecto = widget.proyecto;
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        _repo.getResumen(),
        _comunidadRepo.getProyectos(),
      ]);
      final res = results[0] as ResidenteResumen;
      final proyectos = results[1] as List<Map<String, dynamic>>;
      final refreshed = proyectos.where((p) => p['id'] == _proyecto['id']).toList();
      if (mounted) {
        setState(() {
          _resumen = res;
          if (refreshed.isNotEmpty) _proyecto = refreshed.first;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String nombre = _proyecto['nombre'] ?? 'Sin nombre';
    final int etapas = _proyecto['etapas'] ?? 0;
    final int manzanas = _proyecto['manzanas'] ?? 0;
    final int casas = _proyecto['casas'] ?? 0;
    final String id = _proyecto['id'] ?? '';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Proyecto'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Resumen superior
            Container(
              padding: const EdgeInsets.all(AppSpacing.cardPadding),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.location_city_rounded, color: AppColors.primary, size: 36),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nombre,
                          style: AppTypography.subtitle.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$etapas Etapas • $manzanas Manzanas • $casas Casas',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_rounded),
                    color: AppColors.primary,
                    tooltip: 'Editar Proyecto',
                    onPressed: () {
                      TopToast.show(context, message: 'Editar detalles del proyecto', icon: Icons.edit_rounded);
                    },
                  )
                ],
              ),
            ),
            
            const SizedBox(height: AppSpacing.md),
            
            // Resumen Ocupadas / Vacantes
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_resumen != null)
              _buildResumenHeader(_resumen!),
            
            const SizedBox(height: AppSpacing.xl),
            
            Text(
              'Configuración',
              style: AppTypography.subtitle.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            
            // Opciones de gestión
            ActionCard(
              icon: Icons.account_tree_rounded,
              title: 'Gestión de Etapas',
              onTap: () async {
                await context.push('/comunidad/urbanizacion/proyecto-detalle/etapas', extra: id);
                if (mounted) _loadData();
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            ActionCard(
              icon: Icons.grid_view_rounded,
              title: 'Gestión de Manzanas',
              onTap: () async {
                await context.push('/comunidad/urbanizacion/proyecto-detalle/manzanas', extra: id);
                if (mounted) _loadData();
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            ActionCard(
              icon: Icons.home_rounded,
              title: 'Gestión de Casas / Lotes',
              onTap: () async {
                await context.push('/comunidad/urbanizacion/proyecto-detalle/casas', extra: id);
                if (mounted) _loadData();
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            ActionCard(
              icon: Icons.auto_awesome_rounded,
              title: 'Generador de Estructura Rápida',
              onTap: () => _mostrarGeneradorEstructura(id),
            ),
            const SizedBox(height: AppSpacing.sm),
            ActionCard(
              icon: Icons.settings_rounded,
              title: 'Ajustes Generales del Proyecto',
              onTap: () => context.push('/comunidad/urbanizacion/proyecto-detalle/ajustes', extra: id),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarGeneradorEstructura(String proyectoId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _GeneradorEstructuraSheet(
        proyectoId: proyectoId,
        onSuccess: () {
          if (mounted) _loadData();
        },
      ),
    );
  }

  Widget _buildResumenHeader(ResidenteResumen resumen) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Text(
            'Casas',
            style: AppTypography.subtitle.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildResumenMetric('Ocupadas', resumen.ocupadas, AppColors.success),
              Container(width: 1, height: 30, color: AppColors.border),
              _buildResumenMetric('Vacantes', resumen.vacantes, AppColors.textSecondary),
              Container(width: 1, height: 30, color: AppColors.border),
              _buildResumenMetric('Total', resumen.totalPropiedades, AppColors.primary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResumenMetric(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: AppTypography.title.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _GeneradorEstructuraSheet extends StatefulWidget {
  final String proyectoId;
  final VoidCallback onSuccess;

  const _GeneradorEstructuraSheet({
    required this.proyectoId,
    required this.onSuccess,
  });

  @override
  State<_GeneradorEstructuraSheet> createState() => _GeneradorEstructuraSheetState();
}

class _GeneradorEstructuraSheetState extends State<_GeneradorEstructuraSheet> {
  final ComunidadRepository _repo = ComunidadRepository();
  final _formKey = GlobalKey<FormState>();

  final _letraInicioController = TextEditingController(text: 'A');
  final _letraFinController = TextEditingController(text: 'C');
  final _casaInicioController = TextEditingController(text: '1');
  final _casaFinController = TextEditingController(text: '20');
  final _nuevaEtapaController = TextEditingController();

  bool _isLoadingEtapas = true;
  bool _isSubmitting = false;
  String _progresoTexto = '';
  List<Map<String, dynamic>> _etapas = [];
  String _selectedEtapaId = '';

  @override
  void initState() {
    super.initState();
    _cargarEtapas();
    _letraInicioController.addListener(() => setState(() {}));
    _letraFinController.addListener(() => setState(() {}));
    _casaInicioController.addListener(() => setState(() {}));
    _casaFinController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _letraInicioController.dispose();
    _letraFinController.dispose();
    _casaInicioController.dispose();
    _casaFinController.dispose();
    _nuevaEtapaController.dispose();
    super.dispose();
  }

  Future<void> _cargarEtapas() async {
    try {
      final etapas = await _repo.getEtapasPorProyecto(widget.proyectoId);
      if (mounted) {
        setState(() {
          _etapas = etapas;
          if (_etapas.isNotEmpty) {
            _selectedEtapaId = _etapas.first['id'] as String;
          } else {
            _selectedEtapaId = '__NEW__';
            _nuevaEtapaController.text = 'Etapa 1';
          }
          _isLoadingEtapas = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingEtapas = false;
          _selectedEtapaId = '__NEW__';
          _nuevaEtapaController.text = 'Etapa 1';
        });
      }
    }
  }

  int get _numManzanas {
    final start = _letraInicioController.text.trim().toUpperCase();
    final end = _letraFinController.text.trim().toUpperCase();
    if (start.length == 1 && end.length == 1) {
      final startCode = start.codeUnitAt(0);
      final endCode = end.codeUnitAt(0);
      if (startCode >= 65 && endCode <= 90 && endCode >= startCode) {
        return endCode - startCode + 1;
      }
    }
    return 0;
  }

  int get _numCasasPorManzana {
    final start = int.tryParse(_casaInicioController.text.trim()) ?? 0;
    final end = int.tryParse(_casaFinController.text.trim()) ?? 0;
    if (start > 0 && end >= start) {
      return end - start + 1;
    }
    return 0;
  }

  int get _totalCasas => _numManzanas * _numCasasPorManzana;

  Future<void> _ejecutarGeneracion() async {
    if (!_formKey.currentState!.validate()) return;
    if (_totalCasas == 0) return;

    if (_totalCasas > 200) {
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Cantidad Alta de Unidades'),
          content: Text(
            'Estás a punto de crear $_totalCasas casas en $_numManzanas manzanas. '
            'Esta operación puede tomar unos segundos. ¿Deseas continuar?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Continuar'),
            ),
          ],
        ),
      );
      if (confirmar != true) return;
    }

    setState(() {
      _isSubmitting = true;
      _progresoTexto = 'Preparando generación...';
    });

    try {
      String targetEtapaId;
      if (_selectedEtapaId == '__NEW__') {
        final nombreEtapa = _nuevaEtapaController.text.trim().isNotEmpty
            ? _nuevaEtapaController.text.trim()
            : 'Etapa ${_etapas.length + 1}';
        setState(() => _progresoTexto = 'Creando $nombreEtapa...');
        final nueva = await _repo.createEtapa(nombreEtapa, widget.proyectoId);
        targetEtapaId = nueva['id'].toString();
      } else {
        targetEtapaId = _selectedEtapaId;
      }

      final startCode = _letraInicioController.text.trim().toUpperCase().codeUnitAt(0);
      final endCode = _letraFinController.text.trim().toUpperCase().codeUnitAt(0);
      final casaInicio = int.parse(_casaInicioController.text.trim());
      final casaFin = int.parse(_casaFinController.text.trim());

      for (int code = startCode; code <= endCode; code++) {
        final letter = String.fromCharCode(code);
        final nombreManzana = 'Manzana $letter';
        setState(() => _progresoTexto = 'Creando $nombreManzana...');

        final manzana = await _repo.createManzana(nombreManzana, targetEtapaId);
        final manzanaId = manzana['id'].toString();

        for (int i = casaInicio; i <= casaFin; i++) {
          await _repo.createCasa('Casa $i', manzanaId);
        }
      }

      if (mounted) {
        Navigator.pop(context);
        TopToast.showSuccess(
          context,
          'Estructura generada: $_totalCasas casas en $_numManzanas manzanas',
        );
        widget.onSuccess();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _progresoTexto = '';
        });
        TopToast.showError(context, 'Error al generar estructura: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.bottomSheetRadius),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 22),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Generador de Estructura',
                          style: AppTypography.subtitle.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                    ),
                  ],
                ),
                Text(
                  'Crea en bloque etapas, manzanas y lotes para inicializar el proyecto.',
                  style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Selector de Etapa
                if (_isLoadingEtapas)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else ...[
                  Text(
                    'Etapa de Destino',
                    style: AppTypography.smallBold.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedEtapaId,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),
                    items: [
                      ..._etapas.map((e) => DropdownMenuItem(
                        value: e['id'].toString(),
                        child: Text(e['nombre'].toString()),
                      )),
                      const DropdownMenuItem(
                        value: '__NEW__',
                        child: Row(
                          children: [
                            Icon(Icons.add_circle_outline_rounded, size: 18, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('+ Crear Nueva Etapa', style: TextStyle(color: Colors.blue)),
                          ],
                        ),
                      ),
                    ],
                    onChanged: _isSubmitting ? null : (val) {
                      if (val != null) setState(() => _selectedEtapaId = val);
                    },
                  ),
                  if (_selectedEtapaId == '__NEW__') ...[
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _nuevaEtapaController,
                      decoration: InputDecoration(
                        labelText: 'Nombre de la Nueva Etapa',
                        hintText: 'Ej. Etapa ${_etapas.length + 1}',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                        ),
                      ),
                      validator: (val) {
                        if (_selectedEtapaId == '__NEW__' && (val == null || val.trim().isEmpty)) {
                          return 'Ingresa el nombre de la etapa';
                        }
                        return null;
                      },
                    ),
                  ],
                ],

                const SizedBox(height: AppSpacing.md),

                // Rango de Manzanas
                Text(
                  'Rango de Manzanas (Letras A-Z)',
                  style: AppTypography.smallBold.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _letraInicioController,
                        textCapitalization: TextCapitalization.characters,
                        maxLength: 1,
                        decoration: InputDecoration(
                          labelText: 'Desde',
                          counterText: '',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Requerido';
                          if (!RegExp(r'^[A-Z]$').hasMatch(val.trim().toUpperCase())) return 'A-Z';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: TextFormField(
                        controller: _letraFinController,
                        textCapitalization: TextCapitalization.characters,
                        maxLength: 1,
                        decoration: InputDecoration(
                          labelText: 'Hasta',
                          counterText: '',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Requerido';
                          final upper = val.trim().toUpperCase();
                          if (!RegExp(r'^[A-Z]$').hasMatch(upper)) return 'A-Z';
                          final start = _letraInicioController.text.trim().toUpperCase();
                          if (start.isNotEmpty && upper.codeUnitAt(0) < start.codeUnitAt(0)) {
                            return 'Posterior a inicio';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.md),

                // Rango de Casas por Manzana
                Text(
                  'Casas por cada Manzana (Numeración)',
                  style: AppTypography.smallBold.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _casaInicioController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Casa Inicial',
                          hintText: 'Ej. 1',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Requerido';
                          final n = int.tryParse(val.trim());
                          if (n == null || n <= 0) return 'Mayor a 0';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: TextFormField(
                        controller: _casaFinController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Casa Final',
                          hintText: 'Ej. 20',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Requerido';
                          final n = int.tryParse(val.trim());
                          final start = int.tryParse(_casaInicioController.text.trim()) ?? 0;
                          if (n == null || n < start) return 'Mayor o igual a inicial';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.md),

                // Resumen previo visual
                Container(
                  padding: const EdgeInsets.all(AppSpacing.cardPadding),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 24),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Resumen de Generación',
                              style: AppTypography.caption.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _totalCasas > 0
                                  ? 'Se crearán $_numManzanas manzanas (${_letraInicioController.text.trim().toUpperCase()} ➔ ${_letraFinController.text.trim().toUpperCase()}) y $_totalCasas casas ($_numCasasPorManzana por manzana).'
                                  : 'Completa los rangos para calcular el total a generar.',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Progreso o Botón
                if (_isSubmitting) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Text(
                        _progresoTexto,
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                ] else ...[
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: _totalCasas == 0 ? null : _ejecutarGeneracion,
                      icon: const Icon(Icons.bolt_rounded, size: 20),
                      label: Text(
                        _totalCasas > 0
                            ? 'Generar $_totalCasas Casas en $_numManzanas Manzanas'
                            : 'Generar Estructura',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
