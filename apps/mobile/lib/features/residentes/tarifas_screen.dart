import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
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
      debugPrint('Error loading tarifas: $e');
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _editarTarifa(String id, String modalidad, int currentMonto) async {
    final controller = TextEditingController(text: currentMonto.toString());
    
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configurar Tarifa Base del Conjunto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Establece la tarifa mensual general. El motor de recaudo del backend calculará y distribuirá automáticamente las cuotas según la modalidad asignada a cada casa.',
              style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Monto mensual base',
                prefixText: '\$',
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
              final val = int.tryParse(controller.text.replaceAll(RegExp(r'[^0-9]'), ''));
              Navigator.pop(context, val);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    
    if (result != null && result > 0) {
      setState(() => _loading = true);
      try {
        await _repository.actualizarTarifa(id, result);
        await _loadTarifas();
      } catch (e) {
        debugPrint('Error updating tarifa: $e');
        setState(() => _loading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al actualizar la tarifa')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tarifaMensual = _tarifas['MENSUAL'];
    final montoMensual = (tarifaMensual != null) ? (tarifaMensual['montoPesos'] as int? ?? 0) : 0;
    
    final montoQuincenalCalculado = (montoMensual / 2).round();
    final montoSemanalCalculado = (montoMensual / 4).round();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tarifas del Conjunto'),
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
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: AppColors.primary),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'El Administrador configura la Tarifa Base General. El motor de recaudo distribuye las cuotas automáticamente según la modalidad física de cada casa.',
                          style: AppTypography.caption.copyWith(color: AppColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                Text(
                  'Tarifa Base Vigente',
                  style: AppTypography.title.copyWith(fontWeight: FontWeight.w700),
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.account_balance_wallet_outlined, color: AppColors.primary),
                                  const SizedBox(width: AppSpacing.sm),
                                  Text(
                                    'Tarifa General Mensual',
                                    style: AppTypography.subtitle.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () => _editarTarifa(tarifaMensual['id'], 'MENSUAL', montoMensual),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            '\$ ${NumberFormat.decimalPattern('es_CO').format(montoMensual)} / mes',
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
                          _buildDesgloseRow('Modalidad Semanal (4 cuotas):', '\$ ${NumberFormat.decimalPattern('es_CO').format(montoSemanalCalculado)} / cuota'),
                          _buildDesgloseRow('Modalidad Quincenal (2 cuotas):', '\$ ${NumberFormat.decimalPattern('es_CO').format(montoQuincenalCalculado)} / cuota'),
                          _buildDesgloseRow('Modalidad Mensual (1 cuota):', '\$ ${NumberFormat.decimalPattern('es_CO').format(montoMensual)} / cuota'),
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
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
          Text(value, style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
