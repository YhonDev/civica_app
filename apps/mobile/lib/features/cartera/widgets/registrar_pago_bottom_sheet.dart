import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/top_toast.dart';
import '../models/cartera_models.dart';
import '../cartera_repository.dart';

/// Bottom sheet for registering an online payment from Cartera.
///
/// Consistent with the existing design system:
/// - bottomSheetRadius: 20
/// - screenPadding: 20
/// - inputRadius: 12
/// - FilledButton
class RegistrarPagoBottomSheet extends StatefulWidget {
  final CobroItem cobro;
  final List<dynamic>? cuotas;
  final bool initialQuickMode;
  final VoidCallback onSuccess;

  const RegistrarPagoBottomSheet({
    super.key,
    required this.cobro,
    this.cuotas,
    this.initialQuickMode = false,
    required this.onSuccess,
  });

  static Future<void> show(
    BuildContext context, {
    required CobroItem cobro,
    List<dynamic>? cuotas,
    bool initialQuickMode = false,
    required VoidCallback onSuccess,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.bottomSheetRadius),
        ),
      ),
      builder: (_) => RegistrarPagoBottomSheet(
        cobro: cobro,
        cuotas: cuotas,
        initialQuickMode: initialQuickMode,
        onSuccess: onSuccess,
      ),
    );
  }

  @override
  State<RegistrarPagoBottomSheet> createState() =>
      _RegistrarPagoBottomSheetState();
}

class _RegistrarPagoBottomSheetState extends State<RegistrarPagoBottomSheet> {
  late TextEditingController _montoController;
  bool _enviando = false;
  late bool _isQuickMode;
  final _repo = CarteraRepository();
  late final List<dynamic> _cuotasList;
  final Set<int> _selectedIndices = {0};

  @override
  void initState() {
    super.initState();
    _montoController = TextEditingController();
    _isQuickMode = widget.initialQuickMode;

    final rawCuotas = widget.cuotas ?? [];
    if (rawCuotas.isNotEmpty) {
      _cuotasList = List.from(rawCuotas);
    } else if (widget.cobro.saldo > 0) {
      // Si no vienen cuotas explícitas, dividimos el saldo total en cuotas individuales según el valor base
      final double singleCuota = (widget.cobro.monto > 0 && widget.cobro.monto < widget.cobro.saldo)
          ? widget.cobro.monto
          : 30000.0;
      final int count = (widget.cobro.saldo / singleCuota).clamp(1, 12).round();
      final double valPorCuota = widget.cobro.saldo / count;

      _cuotasList = List.generate(count, (i) => {
        'periodo': 'Mes ${i + 1}',
        'monto': valPorCuota,
        'estado': i == 0 ? 'VENCIDA' : 'PENDIENTE',
      });
    } else {
      _cuotasList = [];
    }

    _recalcularMonto();
  }

  void _recalcularMonto() {
    if (_cuotasList.isNotEmpty) {
      int total = 0;
      for (final idx in _selectedIndices) {
        if (idx < _cuotasList.length) {
          total += (_cuotasList[idx]['monto'] as num? ?? 20000).toInt();
        }
      }
      _montoController.text = total.toString();
    } else {
      final suggestedAmount = widget.cobro.monto > 0 ? widget.cobro.monto : widget.cobro.saldo;
      _montoController.text = suggestedAmount.toInt().toString();
    }
  }

  String _formatCuotaTitle(Map<String, dynamic> cuota, int idx) {
    final periodo = cuota['periodo'] as String? ?? '';
    final concepto = cuota['concepto'] as String? ?? '';
    final fechaVenc = cuota['fechaVencimiento'] as String? ?? periodo;

    // Extraer mes y año
    String mesNombre = '';
    final dateMatch = RegExp(r'(\d{4})-(\d{2})').firstMatch(fechaVenc);
    if (dateMatch != null) {
      final year = dateMatch.group(1);
      final month = int.tryParse(dateMatch.group(2) ?? '1') ?? 1;
      final meses = [
        'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
        'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
      ];
      mesNombre = '${meses[month - 1]} $year';
    }

    if (mesNombre.isEmpty) {
      mesNombre = concepto.isNotEmpty ? concepto : (periodo.isNotEmpty ? periodo : 'Cuota ${idx + 1}');
    }

    final modalidad = widget.cobro.modalidad.toLowerCase();
    String tipoPago = 'Pago ${idx + 1}';
    if (modalidad.contains('mensual')) {
      tipoPago = 'Cuota Única';
    } else if (modalidad.contains('quincenal')) {
      final qNum = (idx % 2) + 1;
      tipoPago = 'Pago $qNum';
    } else if (modalidad.contains('semanal')) {
      final sNum = (idx % 4) + 1;
      tipoPago = 'Pago $sNum';
    }

    return '$mesNombre — $tipoPago';
  }

  @override
  void dispose() {
    _montoController.dispose();
    super.dispose();
  }

  Future<void> _registrarPago() async {
    final montoText = _montoController.text.trim().replaceAll(',', '').replaceAll('.', '');
    final monto = int.tryParse(montoText) ?? 0;

    if (monto <= 0) {
      TopToast.show(
        context,
        title: 'Monto inválido',
        message: 'Por favor ingresa un valor de cuota mayor a cero.',
        icon: Icons.warning_amber_rounded,
        accentColor: AppColors.warning,
      );
      return;
    }

    setState(() => _enviando = true);

    try {
      await _repo.registrarPago(
        residenteId: widget.cobro.residenteId,
        montoCentavos: monto * 100, // Convert to centavos
      );

      // Latencia visual suave para confirmar procesamiento completo en backend
      await Future.delayed(const Duration(milliseconds: 600));

      if (mounted) {
        final nav = Navigator.of(context);
        nav.pop();

        // 1. Ejecutar inmediatamente el callback de actualización en el padre
        widget.onSuccess();

        // 2. Mostrar la notificación flotante estilo Isla Dinámica en la parte superior
        TopToast.show(
          context,
          title: '¡Recaudo registrado con éxito!',
          message: 'Pago de \$${NumberFormat.decimalPattern('es_CO').format(monto)} procesado. Cartera actualizada.',
          icon: Icons.check_circle_rounded,
          accentColor: AppColors.success,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _enviando = false);
        TopToast.show(
          context,
          title: 'Error al registrar el pago',
          message: e.toString().replaceAll('Exception: ', ''),
          icon: Icons.error_outline_rounded,
          accentColor: AppColors.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final saldoStr =
        '\$ ${NumberFormat.decimalPattern('es_CO').format(widget.cobro.saldo.toInt())}';

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.screenPadding,
        right: AppSpacing.screenPadding,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
        top: AppSpacing.sm,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                child: Text(
                  widget.cobro.nombre
                      .split(' ')
                      .map((w) => w.isNotEmpty ? w[0] : '')
                      .take(2)
                      .join()
                      .toUpperCase(),
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.cobro.nombre,
                      style: AppTypography.subtitle.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${widget.cobro.casa} · ${widget.cobro.etapa}',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Segmented Tabs Header: [ Cuota Actual ]  [ Ver Deuda ]
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {
                    if (!_isQuickMode) {
                      setState(() {
                        _isQuickMode = true;
                        _selectedIndices.clear();
                        _selectedIndices.add(0);
                        _recalcularMonto();
                      });
                    }
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _isQuickMode ? AppColors.primary : AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _isQuickMode ? AppColors.primary : AppColors.border,
                        width: 1.2,
                      ),
                      boxShadow: _isQuickMode
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.22),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              )
                            ]
                          : [],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bolt_rounded,
                          size: 16,
                          color: _isQuickMode ? Colors.white : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Cuota Actual',
                          style: AppTypography.caption.copyWith(
                            fontWeight: FontWeight.w700,
                            color: _isQuickMode ? Colors.white : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: InkWell(
                  onTap: () {
                    if (_isQuickMode) {
                      setState(() {
                        _isQuickMode = false;
                        _recalcularMonto();
                      });
                    }
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: !_isQuickMode ? AppColors.primaryDark : AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: !_isQuickMode ? AppColors.primaryDark : AppColors.border,
                        width: 1.2,
                      ),
                      boxShadow: !_isQuickMode
                          ? [
                              BoxShadow(
                                color: AppColors.primaryDark.withValues(alpha: 0.22),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              )
                            ]
                          : [],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.account_balance_wallet_rounded,
                          size: 16,
                          color: !_isQuickMode ? Colors.white : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Ver Deuda',
                          style: AppTypography.caption.copyWith(
                            fontWeight: FontWeight.w700,
                            color: !_isQuickMode ? Colors.white : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Saldo info (Información visual estática)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.cardInnerPadding),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isQuickMode ? 'Valor cuota actual' : 'Saldo total adeudado',
                  style: AppTypography.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  _isQuickMode && _cuotasList.isNotEmpty
                      ? '\$ ${NumberFormat.decimalPattern('es_CO').format((_cuotasList.first['monto'] as num? ?? 20000).toInt())}'
                      : saldoStr,
                  style: AppTypography.subtitle.copyWith(
                    fontWeight: FontWeight.w700,
                    color: widget.cobro.estado == 'Mora' && !_isQuickMode
                        ? AppColors.error
                        : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // VISTA MULTI-CUOTA (Cuando _isQuickMode es false)
          if (!_isQuickMode && _cuotasList.isNotEmpty) ...[
            Text(
              'Seleccionar cuotas a liquidar',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Container(
              constraints: const BoxConstraints(maxHeight: 160),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                border: Border.all(color: AppColors.border),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _cuotasList.length,
                itemBuilder: (context, idx) {
                  final cuota = _cuotasList[idx];
                  final isSelected = _selectedIndices.contains(idx);
                  final montoCuota = (cuota['monto'] as num? ?? 20000).toInt();
                  final estadoCuota = cuota['estado'] as String? ?? 'PENDIENTE';

                  final titleStr = _formatCuotaTitle(Map<String, dynamic>.from(cuota as Map), idx);

                  return CheckboxListTile(
                    dense: true,
                    value: isSelected,
                    title: Text(
                      '$titleStr — \$${NumberFormat.decimalPattern('es_CO').format(montoCuota)}',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isSelected ? AppColors.primary : AppColors.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      'Estado: $estadoCuota',
                      style: AppTypography.small.copyWith(
                        color: estadoCuota == 'VENCIDA' ? AppColors.error : AppColors.textSecondary,
                      ),
                    ),
                    activeColor: AppColors.primary,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _selectedIndices.add(idx);
                        } else {
                          if (_selectedIndices.length > 1) {
                            _selectedIndices.remove(idx);
                          }
                        }
                        int sum = 0;
                        for (final i in _selectedIndices) {
                          sum += (_cuotasList[i]['monto'] as num? ?? 20000).toInt();
                        }
                        _montoController.text = sum.toString();
                      });
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // Monto input
          Text(
            'Monto a registrar',
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            controller: _montoController,
            keyboardType: TextInputType.number,
            style: AppTypography.subtitle.copyWith(
              fontWeight: FontWeight.w700,
            ),
            decoration: InputDecoration(
              prefixText: '\$ ',
              prefixStyle: AppTypography.subtitle.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
              hintText: '0',
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Botones de selección dinámica de cuotas (1x, 2x, 3x, 4x, Total)
          if (!_isQuickMode) ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (widget.cobro.monto > 0) ...[
                    for (int n in [1, 2, 3, 4]) ...[
                      if ((widget.cobro.monto * n) <= (widget.cobro.saldo * 1.5))
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(
                              '$n ${n == 1 ? 'Cuota' : 'Cuotas'} (\$${NumberFormat.decimalPattern('es_CO').format((widget.cobro.monto * n).toInt())})',
                              style: AppTypography.small.copyWith(fontSize: 11),
                            ),
                            selected: _montoController.text == (widget.cobro.monto * n).toInt().toString(),
                            onSelected: (_) {
                              setState(() {
                                _montoController.text = (widget.cobro.monto * n).toInt().toString();
                              });
                            },
                          ),
                        ),
                    ],
                  ],
                  ChoiceChip(
                    label: Text(
                      'Total (\$${NumberFormat.decimalPattern('es_CO').format(widget.cobro.saldo.toInt())})',
                      style: AppTypography.small.copyWith(fontSize: 11),
                    ),
                    selected: _montoController.text == widget.cobro.saldo.toInt().toString(),
                    onSelected: (_) {
                      setState(() {
                        _montoController.text = widget.cobro.saldo.toInt().toString();
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
          ],

          // Helper note explicativa sobre orden FIFO
          Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 14, color: AppColors.primary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _isQuickMode
                      ? 'Registro inmediato de la cuota programada del día.'
                      : 'El dinero ingresado se aplicará primero a la cuota más antigua en mora para sanearla.',
                  style: AppTypography.small.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          // Action button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _enviando ? null : _registrarPago,
              icon: _enviando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.account_balance_wallet_rounded),
              label: Text(
                _enviando ? 'Procesando recaudo...' : 'Registrar Cobro',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
