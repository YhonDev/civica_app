import 'package:flutter/material.dart';
import '../../core/network/error_messages.dart';
import '../../core/format/app_currency.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/top_toast.dart';
import 'comunidad_repository.dart';
import 'tarifas_repository.dart';

class TarifasScreen extends StatefulWidget {
  const TarifasScreen({super.key});

  @override
  State<TarifasScreen> createState() => _TarifasScreenState();
}

class _TarifasScreenState extends State<TarifasScreen> {
  final _repository = TarifasRepository();
  final _comunidadRepo = ComunidadRepository();
  bool _loading = true;
  Map<String, dynamic> _tarifas = {};
  String? _proyectoId;

  @override
  void initState() {
    super.initState();
    _loadTarifas();
  }

  Future<void> _loadTarifas() async {
    try {
      final proyectos = await _comunidadRepo.getProyectos();
      if (proyectos.isNotEmpty) {
        _proyectoId = proyectos.first['id'];
        final response = await _repository.getTarifasVigentes(_proyectoId!);

        if (mounted) {
          setState(() {
            _tarifas = response['tarifas'] ?? {};
            _loading = false;
          });
        }
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (e) {
      debugPrint('Error loading tarifas: ${sanitizeApiError(e)}');
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _crearOEditarTarifaDialog({
    String? tarifaId,
    int currentMonto = 40000,
  }) async {
    if (_proyectoId == null) {
      TopToast.showError(context, 'Primero crea una Urbanización/Proyecto');
      return;
    }

    final isEdit = tarifaId != null;
    final controller = TextEditingController(
      text: AppCurrency.formatInput(currentMonto),
    );

    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        // El diálogo se desplaza internamente cuando el teclado reduce
        // el alto útil (pantallas cortas, fuentes grandes).
        scrollable: true,
        title: Text(
          isEdit ? 'Editar Tarifa Vigente' : 'Crear Tarifa del Conjunto',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Establece el monto mensual base del conjunto. El motor de recaudo distribuirá automáticamente las cuotas según la modalidad asignada.',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              // Formato en vivo: el admin ve $ 40.000 mientras escribe.
              inputFormatters: [const AppCurrencyInputFormatter()],
              decoration: const InputDecoration(
                labelText: 'Monto mensual base (\$ COP)',
                prefixText: '\$ ',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final val = AppCurrency.parse(controller.text).toInt();
              Navigator.pop(context, val > 0 ? val : null);
            },
            child: Text(isEdit ? 'Guardar Cambios' : 'Crear Tarifa'),
          ),
        ],
      ),
    );

    if (result != null && result > 0) {
      setState(() => _loading = true);
      try {
        if (isEdit) {
          await _repository.actualizarTarifa(tarifaId, result);
        } else {
          await _repository.crearTarifa(
            proyectoId: _proyectoId!,
            modalidad: 'MENSUAL',
            montoPesos: result,
          );
        }
        await _loadTarifas();
        if (mounted) {
          TopToast.showSuccess(
            context,
            isEdit
                ? 'Tarifa actualizada correctamente'
                : 'Tarifa creada exitosamente',
          );
        }
      } catch (e) {
        debugPrint('Error guardando tarifa: ${sanitizeApiError(e)}');
        setState(() => _loading = false);
        if (mounted) {
          TopToast.showError(context, e, prefix: 'Error al guardar la tarifa');
        }
      }
    }
  }

  Future<void> _eliminarTarifa(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Desactivar Tarifa?'),
        content: const Text(
          'Esta tarifa dejará de estar vigente para los nuevos cobros del conjunto.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Desactivar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _loading = true);
      try {
        await _repository.desactivarTarifa(id);
        await _loadTarifas();
        if (mounted) {
          TopToast.showSuccess(context, 'Tarifa desactivada correctamente');
        }
      } catch (e) {
        debugPrint('Error desactivando tarifa: ${sanitizeApiError(e)}');
        setState(() => _loading = false);
        if (mounted) {
          TopToast.showError(context, e, prefix: 'Error al eliminar tarifa');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tarifaMensual = _tarifas['MENSUAL'];
    final tarifaId = tarifaMensual != null
        ? (tarifaMensual['id'] as String?)
        : null;
    final montoMensual = (tarifaMensual != null)
        ? (tarifaMensual['montoPesos'] as int? ?? 0)
        : 0;

    final montoQuincenalCalculado = (montoMensual / 2).round();
    final montoSemanalCalculado = (montoMensual / 4).round();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tarifas del Conjunto'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            tooltip: 'Crear/Configurar Tarifa',
            onPressed: () => _crearOEditarTarifaDialog(
              tarifaId: tarifaId,
              currentMonto: montoMensual > 0 ? montoMensual : 40000,
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              children: [
                // Explanatory Banner Card
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'El Administrador configura la Tarifa Base General. El motor de recaudo distribuye las cuotas automáticamente según la modalidad física de cada casa.',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                Text(
                  'Tarifa Base Vigente',
                  style: AppTypography.title.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                if (tarifaMensual != null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.account_balance_wallet_outlined,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Flexible(
                                      child: Text(
                                        'Tarifa General Mensual',
                                        style: AppTypography.subtitle.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    icon: const Icon(Icons.edit_outlined),
                                    tooltip: 'Editar Tarifa',
                                    onPressed: () => _crearOEditarTarifaDialog(
                                      tarifaId: tarifaId,
                                      currentMonto: montoMensual,
                                    ),
                                  ),
                                  if (tarifaId != null)
                                    IconButton(
                                      visualDensity: VisualDensity.compact,
                                      icon: Icon(
                                        Icons.delete_outline_rounded,
                                        color: AppColors.error,
                                      ),
                                      tooltip: 'Desactivar Tarifa',
                                      onPressed: () =>
                                          _eliminarTarifa(tarifaId),
                                    ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            '${AppCurrency.format(montoMensual)} / mes',
                            style: AppTypography.title.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const Divider(height: 24),

                          Text(
                            'Distribución automática del Motor de Recaudo:',
                            style: AppTypography.caption.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          _buildDesgloseRow(
                            'Modalidad Semanal (4 cuotas):',
                            '${AppCurrency.format(montoSemanalCalculado)} / cuota',
                          ),
                          _buildDesgloseRow(
                            'Modalidad Quincenal (2 cuotas):',
                            '${AppCurrency.format(montoQuincenalCalculado)} / cuota',
                          ),
                          _buildDesgloseRow(
                            'Modalidad Mensual (1 cuota):',
                            '${AppCurrency.format(montoMensual)} / cuota',
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Card(
                    color: AppColors.surface,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 36,
                        horizontal: 20,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.price_change_outlined,
                            size: 48,
                            color: AppColors.textSecondary.withValues(
                              alpha: 0.5,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'No hay tarifa configurada',
                            style: AppTypography.subtitle.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Crea la tarifa base inicial para que el motor de recaudo calcule los cobros de las casas.',
                            textAlign: TextAlign.center,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          ElevatedButton.icon(
                            onPressed: () => _crearOEditarTarifaDialog(),
                            icon: const Icon(Icons.add),
                            label: const Text('Configurar Tarifa Base'),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildDesgloseRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
