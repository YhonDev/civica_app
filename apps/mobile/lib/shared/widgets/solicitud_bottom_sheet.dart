import 'package:flutter/material.dart';
import '../../core/network/error_messages.dart';
import '../../core/format/app_currency.dart';
import 'package:intl/intl.dart';

import '../../core/network/local_cache_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_feedback.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/top_toast.dart';
import '../../features/solicitudes/solicitudes_repository.dart';
import 'solicitud_card.dart';

/// Bottom sheet for viewing solicitud details and active admin resolution.
///
/// Implements domain-first Cívica Pago Recaudo Engine resolution:
/// - Admin does NOT just reply with text; admin resolves.
/// - Fetches associated payment, cuota, and digital ticket.
/// - Active actions: Corregir Valor, Revertir / Eliminar Pago, Rechazar.
/// - Tactile haptic feedback via AppFeedback.
class SolicitudBottomSheet extends StatefulWidget {
  final SolicitudData solicitud;
  final String? montoStr;
  final bool isAdmin;
  final Future<void> Function(String estado, String respuesta)? onResolve;
  final Future<void> Function()? onDelete;
  final VoidCallback? onActionCompleted;

  const SolicitudBottomSheet({
    super.key,
    required this.solicitud,
    this.montoStr,
    this.isAdmin = false,
    this.onResolve,
    this.onDelete,
    this.onActionCompleted,
  });

  static Future<void> show(
    BuildContext context,
    SolicitudData solicitud, {
    String? montoStr,
    bool isAdmin = false,
    Future<void> Function(String estado, String respuesta)? onResolve,
    Future<void> Function()? onDelete,
    VoidCallback? onActionCompleted,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.bottomSheetRadius),
        ),
      ),
      builder: (_) => SolicitudBottomSheet(
        solicitud: solicitud,
        montoStr: montoStr,
        isAdmin: isAdmin,
        onResolve: onResolve,
        onDelete: onDelete,
        onActionCompleted: onActionCompleted,
      ),
    );
  }

  @override
  State<SolicitudBottomSheet> createState() => _SolicitudBottomSheetState();
}

class _SolicitudBottomSheetState extends State<SolicitudBottomSheet> {
  final _respuestaController = TextEditingController();
  final _solicitudesRepo = SolicitudesRepository();

  bool _enviando = false;
  bool _loadingDetalle = false;
  Map<String, dynamic>? _detalleResolucion;

  @override
  void initState() {
    super.initState();
    if (widget.isAdmin) {
      _loadDetalle();
    }
  }

  Future<void> _loadDetalle() async {
    setState(() => _loadingDetalle = true);
    try {
      final data = await _solicitudesRepo.getDetalleResolucion(
        widget.solicitud.id,
      );
      if (mounted) {
        setState(() {
          _detalleResolucion = data;
          _loadingDetalle = false;
        });
      }
    } catch (e) {
      debugPrint('Error cargando detalle resolución: ${sanitizeApiError(e)}');
      if (mounted) {
        setState(() => _loadingDetalle = false);
      }
    }
  }

  @override
  void dispose() {
    _respuestaController.dispose();
    super.dispose();
  }

  bool get _canResolve =>
      widget.isAdmin &&
      widget.solicitud.estado != SolicitudEstado.resuelta &&
      widget.solicitud.estado != SolicitudEstado.rechazada &&
      widget.solicitud.estado != SolicitudEstado.aprobada;

  bool get _isReviewRequest {
    final t = widget.solicitud.tipo.toLowerCase();
    return t.contains('revision') ||
        t.contains('revisión') ||
        widget.solicitud.estado == SolicitudEstado.enRevision;
  }

  Color get _statusColor => switch (widget.solicitud.estado) {
    SolicitudEstado.pendiente => AppColors.warning,
    SolicitudEstado.enEspera => AppColors.warning,
    SolicitudEstado.enCamino => AppColors.info,
    SolicitudEstado.cobrada => AppColors.success,
    SolicitudEstado.enRevision => AppColors.info,
    SolicitudEstado.resuelta => AppColors.success,
    SolicitudEstado.aprobada => AppColors.success,
    SolicitudEstado.rechazada => AppColors.error,
    SolicitudEstado.vencida => AppColors.error,
  };

  String get _statusText {
    final tipoLower = widget.solicitud.tipo.toLowerCase();
    final isCobro =
        tipoLower.contains('cobro') || tipoLower.contains('solicitud_cobro');

    return switch (widget.solicitud.estado) {
      SolicitudEstado.pendiente => isCobro ? 'Esperando cobrador' : 'Pendiente',
      SolicitudEstado.enEspera => isCobro ? 'Esperando cobrador' : 'En espera',
      SolicitudEstado.enCamino => 'Cobrador en camino',
      SolicitudEstado.cobrada => 'Cobrado',
      SolicitudEstado.enRevision => 'Pago en revisión',
      SolicitudEstado.resuelta => 'Resuelta',
      SolicitudEstado.aprobada => 'Pago verificado',
      SolicitudEstado.rechazada => 'Rechazada',
      SolicitudEstado.vencida => 'Vencida',
    };
  }

  void _invalidateCaches() {
    LocalCacheRepository.instance.invalidate('dashboard:residente');
    LocalCacheRepository.instance.invalidate('dashboard:administrador');
    LocalCacheRepository.instance.invalidate('dashboard:cobrador');
  }

  // ── Action: Corregir Valor ──────────────────────────────────────────────
  Future<void> _dialogCorregirValor() async {
    AppFeedback.selection();
    final pagoMap = _detalleResolucion?['pago'] as Map<String, dynamic>?;
    final int pagoActualPesos = pagoMap != null
        ? AppCurrency.centsFromJson(pagoMap['monto'])
        : 0;

    final montoCtrl = TextEditingController(
      text: pagoActualPesos > 0 ? AppCurrency.formatInput(pagoActualPesos) : '',
    );
    final motivoCtrl = TextEditingController(
      text: 'Corrección de valor por solicitud de revisión',
    );

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        // El contenido se desplaza internamente cuando el teclado reduce
        // el alto útil (pantallas cortas, fuentes grandes).
        scrollable: true,
        title: Row(
          children: [
            Icon(Icons.edit_note_rounded, color: AppColors.primary),
            const SizedBox(width: 8),
            const Expanded(child: Text('Corregir Valor de Pago')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ajusta el monto del pago. El sistema regenerará el recibo digital con el nuevo valor y resolverá la solicitud.',
              style: AppTypography.small.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Nuevo Valor (COP)',
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: montoCtrl,
              keyboardType: TextInputType.number,
              // Formato en vivo: el admin ve $ 10.000 mientras escribe.
              inputFormatters: [AppCurrencyInputFormatter()],
              decoration: const InputDecoration(
                prefixText: r'$ ',
                hintText: 'Ej. 20.000',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Motivo / Justificación',
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: motivoCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Explica el motivo de la corrección...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final val = AppCurrency.parse(montoCtrl.text).toInt();
              if (val <= 0) {
                TopToast.showError(ctx, 'Ingresa un monto válido mayor a 0');
                return;
              }
              Navigator.pop(ctx, true);
            },
            child: const Text('Guardar Corrección'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final nuevoMontoPesos = AppCurrency.parse(montoCtrl.text).toInt();
      final nuevoMontoCentavos = AppCurrency.pesosToCents(nuevoMontoPesos);
      final motivo = motivoCtrl.text.trim().isNotEmpty
          ? motivoCtrl.text.trim()
          : 'Corrección de valor aprobada por administración.';

      setState(() => _enviando = true);
      AppFeedback.medium();

      try {
        await _solicitudesRepo.corregirPagoDesdeSolicitud(
          id: widget.solicitud.id,
          nuevoMonto: nuevoMontoCentavos,
          motivo: motivo,
        );
        _invalidateCaches();
        AppFeedback.success();

        if (mounted) {
          Navigator.pop(context);
          TopToast.showSuccess(
            context,
            'Pago corregido a ${AppCurrency.formatCOP(nuevoMontoPesos)} exitosamente.',
          );
          widget.onActionCompleted?.call();
        }
      } catch (e) {
        AppFeedback.error();
        if (mounted) {
          setState(() => _enviando = false);
          TopToast.showError(context, 'Error al corregir pago: ${sanitizeApiError(e)}');
        }
      }
    }
  }

  // ── Action: Revertir / Eliminar Pago ─────────────────────────────────────
  Future<void> _dialogRevertirPago() async {
    AppFeedback.selection();
    final motivoCtrl = TextEditingController(
      text: 'Pago revertido por solicitud del residente.',
    );

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        // El contenido se desplaza internamente cuando el teclado reduce
        // el alto útil (pantallas cortas, fuentes grandes).
        scrollable: true,
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error),
            const SizedBox(width: 8),
            const Expanded(child: Text('Revertir Pago')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Esta acción anulará el pago registrado y su recibo digital.\n\n'
              'La cuota volverá al estado Pendiente o Vencida para permitir su cobro correcto, '
              'manteniendo intacta la obligación en el motor de recaudo.',
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Motivo de reversión',
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: motivoCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Justificación de la reversión...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Volver'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Confirmar Reversión'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final motivo = motivoCtrl.text.trim().isNotEmpty
          ? motivoCtrl.text.trim()
          : 'Pago revertido y cuota liberada por la administración.';

      setState(() => _enviando = true);
      AppFeedback.medium();

      try {
        await _solicitudesRepo.revertirPagoDesdeSolicitud(
          id: widget.solicitud.id,
          motivo: motivo,
        );
        _invalidateCaches();
        AppFeedback.success();

        if (mounted) {
          Navigator.pop(context);
          TopToast.showSuccess(
            context,
            'Pago revertido y cuota liberada exitosamente.',
          );
          widget.onActionCompleted?.call();
        }
      } catch (e) {
        AppFeedback.error();
        if (mounted) {
          setState(() => _enviando = false);
          TopToast.showError(context, 'Error al revertir pago: ${sanitizeApiError(e)}');
        }
      }
    }
  }

  // ── Action: Rechazar Solicitud ──────────────────────────────────────────
  Future<void> _dialogRechazar() async {
    AppFeedback.selection();
    final respuesta = _respuestaController.text.trim();
    if (respuesta.isEmpty) {
      TopToast.showError(
        context,
        'Escribe una justificación antes de rechazar.',
      );
      return;
    }

    setState(() => _enviando = true);
    AppFeedback.medium();

    try {
      if (widget.onResolve != null) {
        await widget.onResolve!('RECHAZADA', respuesta);
      } else {
        await _solicitudesRepo.resolverSolicitud(
          id: widget.solicitud.id,
          estado: 'RECHAZADA',
          respuesta: respuesta,
        );
      }
      _invalidateCaches();
      AppFeedback.warning();

      if (mounted) {
        Navigator.pop(context);
        TopToast.show(
          context,
          message: 'Solicitud rechazada con respuesta.',
          type: ToastType.warning,
        );
        widget.onActionCompleted?.call();
      }
    } catch (e) {
      AppFeedback.error();
      if (mounted) {
        setState(() => _enviando = false);
        TopToast.showError(context, 'Error al rechazar solicitud: ${sanitizeApiError(e)}');
      }
    }
  }

  // ── Action: Resolver genérica (para solicitudes de cobro) ───────────────
  Future<void> _resolverGenerica(String estado) async {
    final respuesta = _respuestaController.text.trim();
    if (respuesta.isEmpty) {
      TopToast.showError(context, 'Escribe una respuesta antes de continuar.');
      return;
    }

    setState(() => _enviando = true);
    AppFeedback.medium();

    try {
      if (widget.onResolve != null) {
        await widget.onResolve!(estado, respuesta);
      } else {
        await _solicitudesRepo.resolverSolicitud(
          id: widget.solicitud.id,
          estado: estado,
          respuesta: respuesta,
        );
      }
      _invalidateCaches();
      AppFeedback.success();

      if (mounted) {
        Navigator.pop(context);
        TopToast.showSuccess(
          context,
          estado == 'RESUELTA'
              ? 'Solicitud resuelta exitosamente.'
              : 'Solicitud rechazada.',
        );
        widget.onActionCompleted?.call();
      }
    } catch (e) {
      AppFeedback.error();
      if (mounted) {
        setState(() => _enviando = false);
        TopToast.showError(context, 'Error: ${sanitizeApiError(e)}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat(
      "dd/MM/yyyy · hh:mm a",
      'es',
    ).format(widget.solicitud.fecha);

    final isPago =
        _isReviewRequest ||
        widget.solicitud.tipo.toLowerCase().contains('pago') ||
        widget.solicitud.tipo.toLowerCase().contains('pagad');

    final cobroData = _detalleResolucion?['cobro'] as Map<String, dynamic>?;
    final pagoData = _detalleResolucion?['pago'] as Map<String, dynamic>?;
    final ticketData = _detalleResolucion?['ticket'] as Map<String, dynamic>?;

    final String? conceptoCuota = cobroData?['concepto'] != null
        ? SolicitudData.cleanConcepto(cobroData!['concepto'] as String)
        : widget.solicitud.displaySubtitulo;

    final int? montoPagoPesos = pagoData?['monto'] != null
        ? AppCurrency.centsFromJson(pagoData!['monto'])
        : null;

    final String montoFormateado = montoPagoPesos != null
        ? AppCurrency.format(montoPagoPesos)
        : (widget.montoStr ?? '—');

    final String nroTicket =
        ticketData?['numero'] as String? ??
        (widget.solicitud.nroRecibo.isNotEmpty
            ? widget.solicitud.nroRecibo
            : 'Sin recibo');

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.screenPadding,
        right: AppSpacing.screenPadding,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
        top: AppSpacing.sm,
      ),
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
                  borderRadius: BorderRadius.circular(AppSpacing.radiusProgress),
                ),
              ),
            ),

            // Header: Icon + Clean 2-line title + date
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                  ),
                  child: Icon(
                    Icons.description_outlined,
                    color: _statusColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.solicitud.displayTitle,
                        style: AppTypography.subtitle.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (conceptoCuota != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          conceptoCuota,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      if (widget.solicitud.residenteNombre != null &&
                          widget.isAdmin) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Residente: ${widget.solicitud.residenteNombre!}',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      const SizedBox(height: 2),
                      Text(
                        'Fecha reporte: $dateStr',
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

            // Status indicator
            Text(
              'Estado de la solicitud',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.lens, color: _statusColor, size: 10),
                const SizedBox(width: 6),
                Text(
                  _statusText,
                  style: AppTypography.bodyMedium.copyWith(
                    color: _statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Resident description / reason
            Text(
              'Observación del residente',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.cardInnerPadding),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
              ),
              child: Text(
                widget.solicitud.descripcion,
                style: AppTypography.body,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Associated payment information card
            if (isPago) ...[
              Text(
                'Información del pago asociado',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(AppSpacing.cardInnerPadding),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Recibo Digital', style: AppTypography.caption),
                        Flexible(
                          child: Text(
                            nroTicket,
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Valor registrado', style: AppTypography.caption),
                        Flexible(
                          child: Text(
                            montoFormateado,
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (pagoData?['metodo'] != null) ...[
                      const Divider(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Método', style: AppTypography.caption),
                          Flexible(
                            child: Text(
                              pagoData!['metodo'] as String,
                              style: AppTypography.bodyMedium.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (_loadingDetalle) ...[
                      const SizedBox(height: 8),
                      const LinearProgressIndicator(minHeight: 2),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            // Admin response display if already resolved
            if (widget.solicitud.respuesta != null &&
                widget.solicitud.respuesta!.isNotEmpty) ...[
              Text(
                'Resolución de la Administración',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.cardInnerPadding),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.15),
                  ),
                  borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                ),
                child: Text(
                  widget.solicitud.respuesta!,
                  style: AppTypography.body,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            // ── Active Admin Resolution Section ───────────────────────────
            if (_canResolve) ...[
              const Divider(height: 1),
              const SizedBox(height: AppSpacing.md),

              if (_isReviewRequest) ...[
                // For review requests: Active administrative actions
                Text(
                  'Gestión del Pago Asociado',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Selecciona una acción operativa para resolver la inconsistencia en el motor de recaudo:',
                  style: AppTypography.small.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Button: Corregir Valor
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _enviando ? null : _dialogCorregirValor,
                    icon: const Icon(Icons.edit_note_rounded),
                    label: const Text('Corregir Valor del Pago'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.buttonRadius,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // Button: Revertir / Eliminar Pago
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _enviando ? null : _dialogRevertirPago,
                    icon: Icon(Icons.undo_rounded, color: AppColors.error),
                    label: Text(
                      'Revertir Pago (Liberar Cuota)',
                      style: TextStyle(color: AppColors.error),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.buttonRadius,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Or reject with explanation
                Text(
                  'O rechazar solicitud sin modificaciones',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _respuestaController,
                  maxLines: 2,
                  style: AppTypography.body,
                  decoration: const InputDecoration(
                    hintText: 'Motivo del rechazo para el residente...',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _enviando ? null : _dialogRechazar,
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Rechazar Solicitud'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.buttonRadius,
                        ),
                      ),
                    ),
                  ),
                ),
              ] else ...[
                // For non-payment solicitudes (e.g. collection requests): Standard response
                Text(
                  'Responder solicitud',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _respuestaController,
                  maxLines: 3,
                  style: AppTypography.body,
                  decoration: const InputDecoration(
                    hintText: 'Escribe tu respuesta...',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _enviando
                            ? null
                            : () => _resolverGenerica('RECHAZADA'),
                        icon: _enviando
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                Icons.cancel_outlined,
                                color: AppColors.error,
                              ),
                        label: Text(
                          'Rechazar',
                          style: TextStyle(color: AppColors.error),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.error),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppSpacing.buttonRadius,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _enviando
                            ? null
                            : () => _resolverGenerica('RESUELTA'),
                        icon: _enviando
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.check_circle_outlined),
                        label: const Text('Resolver'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.success,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppSpacing.buttonRadius,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],

            // Close & Cancel buttons (non-admin or already resolved)
            if (!_canResolve) ...[
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  if (widget.onDelete != null &&
                      widget.solicitud.estado != SolicitudEstado.cobrada &&
                      widget.solicitud.estado != SolicitudEstado.aprobada) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _enviando
                            ? null
                            : () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (dlgContext) => AlertDialog(
                                    title: const Text('Cancelar Solicitud'),
                                    content: const Text(
                                      '¿Estás seguro de que deseas cancelar esta solicitud?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(dlgContext, false),
                                        child: const Text('Volver'),
                                      ),
                                      FilledButton(
                                        onPressed: () =>
                                            Navigator.pop(dlgContext, true),
                                        style: FilledButton.styleFrom(
                                          backgroundColor: AppColors.error,
                                        ),
                                        child: const Text('Cancelar Solicitud'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  if (!context.mounted) return;
                                  final nav = Navigator.of(context);
                                  setState(() => _enviando = true);
                                  try {
                                    await widget.onDelete!();
                                    if (mounted) {
                                      nav.pop();
                                    }
                                  } finally {
                                    if (mounted) {
                                      setState(() => _enviando = false);
                                    }
                                  }
                                }
                              },
                        icon: _enviando
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                Icons.delete_outline_rounded,
                                color: AppColors.error,
                              ),
                        label: Text(
                          'Cancelar',
                          style: TextStyle(color: AppColors.error),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.error),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppSpacing.buttonRadius,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                  ],
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cerrar'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
