import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
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
  final VoidCallback onSuccess;

  const RegistrarPagoBottomSheet({
    super.key,
    required this.cobro,
    required this.onSuccess,
  });

  static Future<void> show(
    BuildContext context, {
    required CobroItem cobro,
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
        onSuccess: onSuccess,
      ),
    );
  }

  @override
  State<RegistrarPagoBottomSheet> createState() =>
      _RegistrarPagoBottomSheetState();
}

class _RegistrarPagoBottomSheetState extends State<RegistrarPagoBottomSheet> {
  late final TextEditingController _montoController;
  bool _enviando = false;
  final _repo = CarteraRepository();

  @override
  void initState() {
    super.initState();
    // Pre-fill with the full pending amount
    _montoController = TextEditingController(
      text: widget.cobro.saldo.toStringAsFixed(0),
    );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Ingresa un monto válido.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _enviando = true);

    try {
      await _repo.registrarPago(
        residenteId: widget.cobro.residenteId,
        montoCentavos: monto * 100, // Convert to centavos
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Pago de \$${NumberFormat.decimalPattern('es_CO').format(monto)} registrado exitosamente.',
            ),
            backgroundColor: AppColors.success,
          ),
        );
        widget.onSuccess();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _enviando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al registrar pago: $e'),
            backgroundColor: AppColors.error,
          ),
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
          const SizedBox(height: AppSpacing.lg),

          // Saldo info
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
                  'Saldo pendiente',
                  style: AppTypography.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  saldoStr,
                  style: AppTypography.subtitle.copyWith(
                    fontWeight: FontWeight.w700,
                    color: widget.cobro.estado == 'Mora'
                        ? AppColors.error
                        : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

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
                  : const Icon(Icons.payments_outlined),
              label: const Text('Registrar Pago'),
            ),
          ),
        ],
      ),
    );
  }
}
