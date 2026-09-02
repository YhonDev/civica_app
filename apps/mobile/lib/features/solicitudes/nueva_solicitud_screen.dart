import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../features/auth/auth_cubit.dart';
import '../../core/network/api_client.dart';
import 'solicitudes_repository.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/top_toast.dart';

/// Pantalla para crear una solicitud de revisión (P07)
///
/// Permite al propietario reportar una inconsistencia sobre una cuota o período.
class NuevaSolicitudScreen extends StatefulWidget {
  const NuevaSolicitudScreen({super.key});

  @override
  State<NuevaSolicitudScreen> createState() => _NuevaSolicitudScreenState();
}

class _NuevaSolicitudScreenState extends State<NuevaSolicitudScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descripcionController = TextEditingController();

  List<Map<String, dynamic>> _cuotas = [];
  bool _loadingCuotas = true;
  String? _cobroIdSeleccionada;
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCuotas();
    });
  }

  Future<void> _loadCuotas() async {
    try {
      final user = context.read<AuthCubit>().state.usuario;
      final propietarioId = (user?['residenteId'] as String?) ?? (user?['id'] as String?);
      if (propietarioId == null) {
        setState(() {
          _loadingCuotas = false;
        });
        return;
      }

      final response = await ApiClient.instance.get<List<dynamic>>('/cobros/residente/$propietarioId');
      if (mounted) {
        setState(() {
          _cuotas = response.data!.map((item) => item as Map<String, dynamic>).toList();
          _loadingCuotas = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading cuotas: $e');
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
    final periodoInicioStr = cuota['periodoInicio'] as String;
    final date = DateTime.parse(periodoInicioStr);
    final periodName = DateFormat('MMMM yyyy', 'es').format(date);
    final capitalized = periodName[0].toUpperCase() + periodName.substring(1);

    final estado = cuota['estado'] as String;
    final monto = cuota['monto'] as int;
    final amount = (monto / 100).round();
    
    final estadoStr = estado == 'PAGADA' ? 'Pagado' : 'Pendiente';
    return '$capitalized ($estadoStr - \$$amount)';
  }

  void _enviarSolicitud() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_formKey.currentState!.validate() || _cobroIdSeleccionada == null) {
      TopToast.showError(context, 'Por favor, selecciona un período y escribe la descripción.');
      return;
    }

    setState(() {
      _enviando = true;
    });

    try {
      final selectedCuota = _cuotas.firstWhere((c) => c['id'] == _cobroIdSeleccionada);
      final isPagada = selectedCuota['estado'] == 'PAGADA';
      final date = DateTime.parse(selectedCuota['periodoInicio'] as String);
      final periodName = DateFormat('MMMM yyyy', 'es').format(date);
      final capitalizedPeriod = periodName[0].toUpperCase() + periodName.substring(1);
      
      final prefix = isPagada ? 'Revisión pago de' : 'Revisión cargo de';
      final tipo = '$prefix $capitalizedPeriod';

      final user = context.read<AuthCubit>().state.usuario;
      final propietarioId = user?['residenteId'] as String? ?? '00000000-0000-0000-0000-000000000000'; // fallback temporal
      
      final repo = SolicitudesRepository();
      await repo.crearSolicitud(
        cobroId: _cobroIdSeleccionada!,
        tipo: tipo,
        descripcion: _descripcionController.text.trim(),
        residenteId: propietarioId,
      );

      if (mounted) {
        setState(() {
          _enviando = false;
        });

        TopToast.showSuccess(context, 'Solicitud de revisión registrada con éxito.');
        context.pop(true); // Return true to indicate a reload is needed
      }
    } catch (e) {
      debugPrint('Error sending solicitud: $e');
      if (mounted) {
        setState(() {
          _enviando = false;
        });
        TopToast.showError(context, 'Error al enviar la solicitud: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  'Si consideras que hay un error en los cobros o registros de algún mes, detalla tu reporte a continuación.',
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

                // ── Motivos predefinidos ────────────────────────────
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
                  children: [
                    'Monto de pago incorrecto',
                    'Fecha de registro equivocada',
                    'Asignación de vivienda errónea',
                    'Otro motivo',
                  ].map((motivo) {
                    final isSelected = _descripcionController.text.startsWith(motivo);
                    return ChoiceChip(
                      label: Text(motivo),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            if (motivo == 'Otro motivo') {
                              _descripcionController.text = '';
                            } else {
                              _descripcionController.text = '$motivo: Se solicita revisión por inconsistencia en el registro.';
                            }
                          });
                        }
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── Descripción del reporte ───────────────────────────
                Text(
                  'Detalle o Motivo',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _descripcionController,
                  maxLines: 4,
                  style: AppTypography.body,
                  decoration: const InputDecoration(
                    hintText: 'Explica detalladamente la inconsistencia...',
                    alignLabelWithHint: true,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'La descripción es obligatoria';
                    }
                    if (value.trim().length < 10) {
                      return 'Describe con mayor detalle (mínimo 10 caracteres)';
                    }
                    return null;
                  },
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
