import 'package:flutter/material.dart';
import '../../core/network/error_messages.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/format/app_currency.dart';
import 'package:intl/intl.dart';

import '../../core/network/api_client.dart';
import '../../core/network/local_cache_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/top_toast.dart';
import '../../features/auth/auth_cubit.dart';
import 'solicitudes_repository.dart';

/// Pantalla para crear una solicitud de revisión (P07)
///
/// Permite al propietario reportar una inconsistencia sobre una cuota o período.
class NuevaSolicitudScreen extends StatefulWidget {
  final String? initialCobroId;
  final String? initialPagoId;
  final String? initialConcepto;

  const NuevaSolicitudScreen({
    super.key,
    this.initialCobroId,
    this.initialPagoId,
    this.initialConcepto,
  });

  @override
  State<NuevaSolicitudScreen> createState() => _NuevaSolicitudScreenState();
}

class _NuevaSolicitudScreenState extends State<NuevaSolicitudScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descripcionController = TextEditingController();

  List<Map<String, dynamic>> _cuotas = [];
  bool _loadingCuotas = true;
  String? _cobroIdSeleccionada;
  String? _motivoSeleccionado;
  bool _enviando = false;

  static const List<String> _motivosPredefinidos = [
    'Monto de pago incorrecto',
    'Fecha de registro equivocada',
    'Asignación de vivienda errónea',
    'Otro motivo',
  ];

  @override
  void initState() {
    super.initState();
    _cobroIdSeleccionada = widget.initialCobroId;
    _motivoSeleccionado = _motivosPredefinidos.first;
    _descripcionController.text =
        '${_motivosPredefinidos.first}: Se solicita revisión por inconsistencia en el registro.';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCuotas();
    });
  }

  Future<void> _loadCuotas() async {
    try {
      final user = context.read<AuthCubit>().state.usuario;
      final propietarioId =
          (user?['residenteId'] as String?) ?? (user?['id'] as String?);
      if (propietarioId == null) {
        setState(() {
          _loadingCuotas = false;
        });
        return;
      }

      final response = await ApiClient.instance
          .get<List<dynamic>>('/cobros/residente/$propietarioId');
      if (mounted) {
        final list = response.data!
            .map((item) => item as Map<String, dynamic>)
            .toList();

        if (widget.initialCobroId != null &&
            !list.any((c) => c['id'] == widget.initialCobroId)) {
          list.insert(0, {
            'id': widget.initialCobroId,
            'concepto': widget.initialConcepto ?? 'Cuota seleccionada',
            'monto': 0,
            'estado': 'PAGADA',
            'periodoInicio': DateTime.now().toIso8601String(),
          });
        }

        setState(() {
          _cuotas = list;
          _cobroIdSeleccionada ??= widget.initialCobroId ??
              (_cuotas.isNotEmpty ? _cuotas.first['id'] as String : null);
          _loadingCuotas = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading cuotas: ${sanitizeApiError(e)}');
      if (mounted) {
        setState(() {
          _loadingCuotas = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _descripcionController.dispose();
    super.dispose();
  }

  String _formatCuotaLabel(Map<String, dynamic> cuota) {
    final rawConcepto = cuota['concepto'] as String?;
    String conceptoClean;
    if (rawConcepto != null && rawConcepto.trim().isNotEmpty) {
      conceptoClean = rawConcepto
          .replaceAll(RegExp(r'\s*\b20\d\d\b\s*'), ' ')
          .replaceAll(RegExp(r'\s*-\s*'), ' — ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
    } else {
      final periodoInicioStr = cuota['periodoInicio'] as String? ?? '';
      final date = DateTime.tryParse(periodoInicioStr) ?? DateTime.now();
      final periodName = DateFormat('MMMM', 'es').format(date);
      conceptoClean = periodName[0].toUpperCase() + periodName.substring(1);
    }

    final estado = cuota['estado'] as String? ?? 'PENDIENTE';
    final monto = cuota['monto'] as int? ?? 0;
    final amount = AppCurrency.centsToPesos(monto);
    final estadoStr = estado == 'PAGADA' ? 'Pagada' : 'Pendiente';
    return '$conceptoClean ($estadoStr · ${AppCurrency.format(amount)})';
  }

  void _enviarSolicitud() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_formKey.currentState!.validate() || _cobroIdSeleccionada == null) {
      TopToast.showError(
        context,
        'Por favor, selecciona una cuota y completa el reporte.',
      );
      return;
    }

    setState(() {
      _enviando = true;
    });

    try {
      final selectedCuota = _cuotas.firstWhere(
        (c) => c['id'] == _cobroIdSeleccionada,
        orElse: () => {'estado': 'PAGADA', 'concepto': widget.initialConcepto},
      );
      final isPagada = selectedCuota['estado'] == 'PAGADA';
      final tipo = isPagada ? 'Revisión de pago' : 'Solicitud de cobro';

      final user = context.read<AuthCubit>().state.usuario;
      final propietarioId = (user?['residenteId'] as String?) ??
          user?['id'] as String? ??
          '00000000-0000-0000-0000-000000000000';

      final repo = SolicitudesRepository();
      await repo.crearSolicitud(
        cobroId: _cobroIdSeleccionada!,
        pagoId: widget.initialPagoId,
        tipo: tipo,
        descripcion: _descripcionController.text.trim(),
        residenteId: propietarioId,
      );

      // Invalidate relevant caches across dashboards
      LocalCacheRepository.instance.invalidate('dashboard:residente');
      LocalCacheRepository.instance.invalidate('dashboard:administrador');
      LocalCacheRepository.instance.invalidate('dashboard:cobrador');

      if (mounted) {
        setState(() {
          _enviando = false;
        });

        TopToast.showSuccess(
          context,
          'Solicitud de revisión registrada con éxito.',
        );
        context.pop(true); // Return true to indicate a reload is needed
      }
    } catch (e) {
      debugPrint('Error sending solicitud: ${sanitizeApiError(e)}');
      if (mounted) {
        setState(() {
          _enviando = false;
        });
        TopToast.showError(context, e, prefix: 'Error al enviar la solicitud');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOtroMotivo = _motivoSeleccionado == 'Otro motivo';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Solicitud'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Solicitar revisión de cuota',
                  style: AppTypography.subtitle.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Si consideras que hay un error en los cobros o registros de algún mes, selecciona la cuota y reporta la novedad.',
                  style: AppTypography.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── Selector de Cuota/Período ─────────────────────────
                Text(
                  'Período o Cuota',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                _loadingCuotas
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 12),
                            Text('Cargando cuotas disponibles...'),
                          ],
                        ),
                      )
                    : DropdownButtonFormField<String>(
                        initialValue: _cobroIdSeleccionada,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          hintText: 'Selecciona una cuota',
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: 14,
                          ),
                        ),
                        items: _cuotas.map((cuota) {
                          return DropdownMenuItem(
                            value: cuota['id'] as String,
                            child: Text(
                              _formatCuotaLabel(cuota),
                              style: AppTypography.body,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _cobroIdSeleccionada = value;
                          });
                        },
                        validator: (value) =>
                            value == null ? 'Este campo es obligatorio' : null,
                      ),
                const SizedBox(height: AppSpacing.lg),

                // ── Motivos comunes ─────────────────────────────────
                Text(
                  'Motivos comunes',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _motivosPredefinidos.map((motivo) {
                    final isSelected = _motivoSeleccionado == motivo;
                    return ChoiceChip(
                      avatar: isSelected
                          ? const Icon(
                              Icons.check_rounded,
                              size: 16,
                              color: Colors.white,
                            )
                          : null,
                      label: Text(motivo),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.surface,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _motivoSeleccionado = motivo;
                            if (motivo == 'Otro motivo') {
                              _descripcionController.text = '';
                            } else {
                              _descripcionController.text =
                                  '$motivo: Se solicita revisión por inconsistencia en el registro.';
                            }
                          });
                        }
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── Detalle o Motivo (Animated smooth collapse / expand) ──
                Text(
                  'Detalle o Motivo',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOutCubic,
                  child: isOtroMotivo
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              controller: _descripcionController,
                              maxLines: 4,
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              style: AppTypography.body,
                              decoration: InputDecoration(
                                hintText:
                                    'Explica detalladamente la inconsistencia...',
                                alignLabelWithHint: true,
                                helperText:
                                    '${_descripcionController.text.trim().length}/10 caracteres mínimo',
                                helperStyle: TextStyle(
                                  color: _descripcionController.text
                                              .trim()
                                              .length >=
                                          10
                                      ? AppColors.success
                                      : AppColors.textSecondary,
                                ),
                              ),
                              onChanged: (_) {
                                setState(() {});
                              },
                              validator: (value) {
                                if (isOtroMotivo) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'La descripción es obligatoria';
                                  }
                                  if (value.trim().length < 10) {
                                    return 'Describe con mayor detalle (mínimo 10 caracteres)';
                                  }
                                }
                                return null;
                              },
                            ),
                          ],
                        )
                      : Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.05),
                            borderRadius:
                                BorderRadius.circular(AppSpacing.inputRadius),
                            border: Border.all(
                              color:
                                  AppColors.primary.withValues(alpha: 0.18),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.check_circle_outline_rounded,
                                size: 18,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _descripcionController.text,
                                  style: AppTypography.small.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w500,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // ── Botón de Acción ──────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _enviando ? null : _enviarSolicitud,
                    child: _enviando
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Enviar Solicitud'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
