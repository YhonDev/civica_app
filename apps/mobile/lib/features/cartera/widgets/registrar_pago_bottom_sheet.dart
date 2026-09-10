import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/format/app_currency.dart';
import '../../../core/theme/app_breakpoints.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/responsive_builder.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/top_toast.dart';
import '../../auth/auth_cubit.dart';
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
    this.initialQuickMode = true,
    required this.onSuccess,
  });

  static Future<void> show(
    BuildContext context, {
    required CobroItem cobro,
    List<dynamic>? cuotas,
    bool initialQuickMode = true,
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

    final rawCuotas = widget.cuotas ?? (widget.cobro.cuotas.isNotEmpty ? widget.cobro.cuotas : null) ?? [];
    if (rawCuotas.isNotEmpty) {
      _cuotasList = List.from(rawCuotas);
    } else if (widget.cobro.saldo > 0) {
      final modalidadLower = widget.cobro.modalidad.toLowerCase();
      final double singleCuota;
      if (modalidadLower.contains('semanal')) {
        singleCuota = 10000.0;
      } else if (modalidadLower.contains('quincenal')) {
        singleCuota = 20000.0;
      } else {
        singleCuota = 40000.0;
      }
      final int count = (widget.cobro.saldo / singleCuota).clamp(1, 12).round();
      final double valPorCuota = widget.cobro.saldo / count;

      _cuotasList = List.generate(count, (i) => {
        'id': widget.cobro.id,
        'periodo': widget.cobro.concepto.isNotEmpty ? widget.cobro.concepto : 'Cuota ${i + 1}',
        'monto': valPorCuota,
        'estado': i == 0 ? (widget.cobro.estado == 'MORA' || widget.cobro.estado == 'VENCIDA' ? 'VENCIDA' : 'PENDIENTE') : 'PENDIENTE',
      });
    } else {
      _cuotasList = [];
    }

    // Seleccionar por defecto la cuota cliqueada si coincide con alguna de la lista
    int initialIdx = 0;
    for (int i = 0; i < _cuotasList.length; i++) {
      final item = _cuotasList[i];
      if (item is Map && item['id'] == widget.cobro.id) {
        initialIdx = i;
        break;
      }
    }
    _selectedIndices.clear();
    _selectedIndices.add(initialIdx);

    _recalcularMonto();
    // Rebuild en vivo para que los chips 1x/2x/3x/4x/Total reflejen el
    // monto mientras el usuario escribe, no solo al presionar un chip.
    _montoController.addListener(_onMontoChanged);
  }

  void _onMontoChanged() {
    if (mounted) setState(() {});
  }

  void _recalcularMonto() {
    if (_cuotasList.isNotEmpty) {
      int total = 0;
      for (final idx in _selectedIndices) {
        if (idx < _cuotasList.length) {
          total += (_cuotasList[idx]['monto'] as num? ?? 20000).toInt();
        }
      }
      _montoController.text = AppCurrency.formatInput(total);
    } else {
      final suggestedAmount = widget.cobro.monto > 0 ? widget.cobro.monto : widget.cobro.saldo;
      _montoController.text = AppCurrency.formatInput(suggestedAmount.toInt());
    }
  }

  String _formatCuotaTitle(Map<String, dynamic> cuota, int idx) {
    if (cuota['tituloCuota'] != null && (cuota['tituloCuota'] as String).isNotEmpty) {
      final t = cuota['tituloCuota'] as String;
      if (!t.contains('Cuota 1 — Cuota 1')) {
        return t;
      }
    }
    final periodo = cuota['periodo'] as String? ?? '';
    final concepto = cuota['concepto'] as String? ?? '';
    final fechaVenc = cuota['fechaVencimiento'] as String? ?? periodo;

    // Extraer mes y año si fechaVenc contiene formato de fecha
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

    // Fallback: extraer mes de fechaVencimiento o periodoInicio del cobro principal
    if (mesNombre.isEmpty) {
      final cobroDateMatch = RegExp(r'(\d{4})-(\d{2})').firstMatch(widget.cobro.fechaVencimiento);
      if (cobroDateMatch != null) {
        final year = cobroDateMatch.group(1);
        final month = int.tryParse(cobroDateMatch.group(2) ?? '1') ?? 1;
        final meses = [
          'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
          'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
        ];
        mesNombre = '${meses[month - 1]} $year';
      }
    }

    // Extraer número de cuota si viene en concepto (ej. "Septiembre — Cuota 2")
    String tipoPago = 'Cuota ${idx + 1}';
    final cuotaNumMatch = RegExp(r'Cuota\s*(\d+)', caseSensitive: false).firstMatch(concepto.isNotEmpty ? concepto : periodo);
    if (cuotaNumMatch != null) {
      tipoPago = 'Cuota ${cuotaNumMatch.group(1)}';
    } else {
      final modalidad = widget.cobro.modalidad.toLowerCase();
      if (modalidad.contains('mensual')) {
        tipoPago = 'Cuota Única';
      } else if (modalidad.contains('quincenal')) {
        final qNum = (idx % 2) + 1;
        tipoPago = 'Cuota $qNum';
      } else if (modalidad.contains('semanal')) {
        final sNum = (idx % 4) + 1;
        tipoPago = 'Cuota $sNum';
      }
    }

    // Evitar redundancias como "Septiembre — Cuota 1 — Cuota 1"
    if (concepto.isNotEmpty && concepto.contains('—')) {
      final parts = concepto.split('—');
      if (parts.length >= 2) {
        return '${parts[0].trim()} — ${parts[1].trim()}';
      }
    }

    if (mesNombre.isNotEmpty) {
      return '$mesNombre — $tipoPago';
    }

    if (concepto.isNotEmpty && !concepto.toLowerCase().startsWith('cuota')) {
      return '$concepto — $tipoPago';
    }

    return tipoPago;
  }

  @override
  void dispose() {
    _montoController.removeListener(_onMontoChanged);
    _montoController.dispose();
    super.dispose();
  }

  Future<void> _registrarPago() async {
    // El campo muestra "10.000" (agrupado); se parsea quitando separadores.
    final monto = AppCurrency.parse(_montoController.text).round();

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
      final user = context.read<AuthCubit>().state.usuario;
      final rol = (user?['rol'] as String?)?.toUpperCase() ?? '';
      final isCobrador = rol == 'COBRADOR';
      final cobradorId = (user?['id'] as String?) ?? '';
      final tenantId = (user?['tenantId'] as String?) ?? '';

      final res = await _repo.registrarPago(
        residenteId: widget.cobro.residenteId,
        montoCentavos: AppCurrency.pesosToCents(monto),
        cobroId: widget.cobro.id,
        cobradorId: cobradorId,
        tenantId: tenantId,
        isCobrador: isCobrador,
      );

      // Latencia visual suave para confirmar procesamiento completo
      await Future.delayed(const Duration(milliseconds: 600));

      if (mounted) {
        final nav = Navigator.of(context);
        nav.pop();

        // 1. Ejecutar inmediatamente el callback de actualización en el padre
        widget.onSuccess();

        // 2. Mostrar la notificación según el resultado (online vs offline)
        final isOffline = res['offline'] == true;
        TopToast.show(
          context,
          title: isOffline ? 'Recaudo guardado en cola local' : '¡Recaudo registrado con éxito!',
          message: isOffline
              ? (res['message'] as String? ?? 'Pago guardado de forma segura en cola local.')
              : 'Pago de ${AppCurrency.format(monto)} procesado. Cartera actualizada.',
          icon: isOffline ? Icons.cloud_off_rounded : Icons.check_circle_rounded,
          accentColor: isOffline ? AppColors.warning : AppColors.success,
        );
      }
    } catch (e) {
      if (mounted) {
        TopToast.showError(
          context,
          'Error al registrar recaudo: ${e.toString().replaceAll('Exception: ', '')}',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _enviando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double totalAdeudado = 0;
    if (_cuotasList.isNotEmpty) {
      for (final c in _cuotasList) {
        if (c is Map) {
          final m = (c['monto'] as num?)?.toDouble() ?? 0.0;
          totalAdeudado += m;
        }
      }
    }
    if (totalAdeudado <= 0) {
      totalAdeudado = widget.cobro.saldo > 0 ? widget.cobro.saldo : widget.cobro.monto;
    }

    final saldoStr = AppCurrency.format(totalAdeudado.toInt());

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.screenPadding,
        right: AppSpacing.screenPadding,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
        top: AppSpacing.sm,
      ),
      // En tablet/desktop el sheet no debe estirarse a todo el ancho.
      child: ContentConstrainedBox(
        maxWidth: AppBreakpoints.maxFormWidth,
        // Scroll interno: con el teclado abierto el espacio se reduce y el
        // contenido debe desplazarse, no desbordar (alto dinámico).
        child: SingleChildScrollView(
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
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 22),
                color: AppColors.textSecondary,
                tooltip: 'Cerrar',
                onPressed: () => Navigator.of(context).pop(),
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
                        ),                            const SizedBox(width: 6),
                            // Flexible: el label se ajusta sin desbordar el
                            // tab en pantallas estrechas o textos largos.
                            Flexible(
                              child: Text(
                                'Cuota Actual',
                                style: AppTypography.caption.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: _isQuickMode
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                ),
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
                        ),                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Ver Deuda',
                                style: AppTypography.caption.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: !_isQuickMode
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                ),
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
              children: [
                // Expanded: en pantallas estrechas el label envuelve en vez
                // de empujar el monto fuera del Row (contenido dinámico).
                Expanded(
                  child: Text(
                    _isQuickMode ? 'Valor cuota actual' : 'Saldo total adeudado',
                    style: AppTypography.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                Text(
                  _isQuickMode && _cuotasList.isNotEmpty
                      ? AppCurrency.format((_cuotasList.first['monto'] as num? ?? 20000).toInt())
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

                  // Material transparente: el ink splash del tile se pinta
                  // en el Material más cercano; sin esto la decoración del
                  // contenedor lo oculta (warning de ListTile).
                  return Material(
                    type: MaterialType.transparency,
                    child: CheckboxListTile(
                      dense: true,
                      value: isSelected,
                      title: Text(
                        '$titleStr — ${AppCurrency.format(montoCuota)}',
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
                          _montoController.text = AppCurrency.formatInput(sum);
                        });
                      },
                    ),
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
            inputFormatters: [
              // Formato en vivo: el usuario ve $ 10.000 mientras escribe.
              AppCurrencyInputFormatter(),
            ],
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
                              '$n ${n == 1 ? 'Cuota' : 'Cuotas'} (${AppCurrency.format((widget.cobro.monto * n).toInt())})',
                              style: AppTypography.small,
                            ),
                            selected: AppCurrency.parse(_montoController.text) == (widget.cobro.monto * n).toInt(),
                            onSelected: (_) {
                              setState(() {
                                _montoController.text = AppCurrency.formatInput((widget.cobro.monto * n).toInt());
                              });
                            },
                          ),
                        ),
                    ],
                  ],
                  ChoiceChip(
                    label: Text(
                      'Total (${AppCurrency.format(widget.cobro.saldo.toInt())})',
                      style: AppTypography.small,
                    ),
                    selected: AppCurrency.parse(_montoController.text) == widget.cobro.saldo.toInt(),
                    onSelected: (_) {
                      setState(() {
                        _montoController.text = AppCurrency.formatInput(widget.cobro.saldo.toInt());
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
        ),
      ),
    );
  }
}
