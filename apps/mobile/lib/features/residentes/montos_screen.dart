import 'package:flutter/material.dart';
import '../../core/widgets/top_toast.dart';
import '../../core/format/app_currency.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/network/api_client.dart';
import '../../shared/widgets/empty_state.dart';

class MontosScreen extends StatefulWidget {
  const MontosScreen({super.key});

  @override
  State<MontosScreen> createState() => _MontosScreenState();
}

class _MontosScreenState extends State<MontosScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _montos = [];
  @override
  void initState() {
    super.initState();
    _loadMontos();
  }

  Future<void> _loadMontos() async {
    setState(() => _loading = true);
    try {
      final response = await ApiClient.instance.get('/montos-predefinidos');
      final list = List<Map<String, dynamic>>.from(
        response.data as List? ?? [],
      );
      if (mounted) {
        setState(() {
          _montos = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _agregarMontoDialog() async {
    if (_montos.length >= 5) {
      TopToast.showWarning(
        context,
        'Máximo 5 montos predefinidos permitidos.',
      );
      return;
    }

    final controller = TextEditingController();
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        // El diálogo se desplaza internamente cuando el teclado reduce
        // el alto útil (pantallas cortas, fuentes grandes).
        scrollable: true,
        title: const Text('Nuevo Monto Predefinido'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          // Formato en vivo: el usuario ve $ 10.000 mientras escribe.
          inputFormatters: [AppCurrencyInputFormatter()],
          decoration: const InputDecoration(
            labelText: 'Monto en COP',
            prefixText: '\$ ',
            hintText: 'Ej: 10.000',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = AppCurrency.parse(controller.text).toInt();
              if (val > 0) {
                Navigator.pop(ctx, val);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        await ApiClient.instance.post(
          '/montos-predefinidos',
          data: {
            'monto': AppCurrency.pesosToCents(result), // a centavos
          },
        );
        _loadMontos();
      } catch (e) {
        if (mounted) {
          TopToast.showError(
            context,
            e,
            prefix: 'Error al crear monto',
          );
        }
      }
    }
  }

  Future<void> _eliminarMonto(String id) async {
    try {
      await ApiClient.instance.delete('/montos-predefinidos/$id');
      _loadMontos();
    } catch (e) {
      if (mounted) {
        TopToast.showError(
          context,
          e,
          prefix: 'Error al eliminar',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Montos Predefinidos'),
        centerTitle: false,
      ),
      floatingActionButton: _montos.length < 5
          ? FloatingActionButton.extended(
              onPressed: _agregarMontoDialog,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Nuevo Monto'),
              backgroundColor: AppColors.primary,
            )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
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
                            'Configura hasta 5 montos rápidos de pago para facilitar el registro en campo sin digitar números.',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Montos Activos',
                        style: AppTypography.subtitle.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_montos.length} / 5',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  if (_montos.isEmpty)
                    const EmptyState(
                      icon: Icons.payments_outlined,
                      title: 'Sin montos configurados',
                      description:
                          'Toca el botón + para agregar el primer monto predefinido.',
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _montos.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.xs),
                      itemBuilder: (context, index) {
                        final item = _montos[index];
                        final id = item['id'] as String;
                        final montoCents =
                            (item['monto'] as num?)?.toInt() ?? 0;
                        final montoCop = AppCurrency.centsToPesos(montoCents);

                        return Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                            side: BorderSide(color: AppColors.border),
                          ),
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(AppSpacing.sm),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.attach_money_rounded,
                                color: AppColors.success,
                              ),
                            ),
                            title: Text(
                              AppCurrency.format(montoCop),
                              style: AppTypography.subtitle.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            trailing: IconButton(
                              tooltip: 'Eliminar monto',
                              icon: Icon(
                                Icons.delete_outline_rounded,
                                color: AppColors.error,
                              ),
                              onPressed: () => _eliminarMonto(id),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
    );
  }
}
