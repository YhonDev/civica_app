import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import 'solicitud_card.dart';

/// Bottom sheet for viewing solicitud details and admin actions.
///
/// Extends the original design with:
/// - StatusBadge for consistent status display
/// - Admin resolve/reject actions with response field
/// - Consistent with the existing design system
class SolicitudBottomSheet extends StatefulWidget {
  final SolicitudData solicitud;
  final String? montoStr;
  final bool isAdmin;
  final Future<void> Function(String estado, String respuesta)? onResolve;
  final Future<void> Function()? onDelete;

  const SolicitudBottomSheet({
    super.key,
    required this.solicitud,
    this.montoStr,
    this.isAdmin = false,
    this.onResolve,
    this.onDelete,
  });

  static Future<void> show(
    BuildContext context,
    SolicitudData solicitud, {
    String? montoStr,
    bool isAdmin = false,
    Future<void> Function(String estado, String respuesta)? onResolve,
    Future<void> Function()? onDelete,
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
      ),
    );
  }

  @override
  State<SolicitudBottomSheet> createState() => _SolicitudBottomSheetState();
}

class _SolicitudBottomSheetState extends State<SolicitudBottomSheet> {
  final _respuestaController = TextEditingController();
  bool _enviando = false;

  @override
  void dispose() {
    _respuestaController.dispose();
    super.dispose();
  }

  bool get _canResolve =>
      widget.isAdmin &&
      widget.onResolve != null &&
      widget.solicitud.estado != SolicitudEstado.resuelta &&
      widget.solicitud.estado != SolicitudEstado.rechazada;

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
    final isCobro = tipoLower.contains('cobro') || tipoLower.contains('solicitud_cobro');

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

  Future<void> _resolver(String estado) async {
    final respuesta = _respuestaController.text.trim();
    if (respuesta.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Escribe una respuesta antes de continuar.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _enviando = true);

    try {
      await widget.onResolve!(estado, respuesta);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              estado == 'RESUELTA'
                  ? 'Solicitud resuelta exitosamente.'
                  : 'Solicitud rechazada.',
            ),
            backgroundColor:
                estado == 'RESUELTA' ? AppColors.success : AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _enviando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat("dd/MM/yyyy · hh:mm a", 'es').format(widget.solicitud.fecha);

    final isPago = widget.solicitud.tipo.toLowerCase().contains('pago') ||
        widget.solicitud.tipo.toLowerCase().contains('pagad');

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
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header: icon + title + date
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
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
                        widget.solicitud.tipo,
                        style: AppTypography.subtitle.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (widget.solicitud.residenteNombre != null &&
                          widget.isAdmin)
                        Text(
                          widget.solicitud.residenteNombre!,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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

            // Status
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

            // Description
            Text(
              'Observación',
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
                borderRadius:
                    BorderRadius.circular(AppSpacing.inputRadius),
              ),
              child: Text(
                widget.solicitud.descripcion,
                style: AppTypography.body,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Receipt info for payment solicitudes
            if (isPago) ...[
              Text(
                'Recibo digital reportado',
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
                  borderRadius:
                      BorderRadius.circular(AppSpacing.cardRadius),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('N° Recibo', style: AppTypography.caption),
                        Text(
                          widget.solicitud.nroRecibo,
                          style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    if (widget.montoStr != null) ...[
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Valor', style: AppTypography.caption),
                          Text(
                            widget.montoStr!,
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            // Admin response (if already answered)
            if (widget.solicitud.respuesta != null) ...[
              Text(
                'Respuesta del Administrador',
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
                  borderRadius:
                      BorderRadius.circular(AppSpacing.inputRadius),
                ),
                child: Text(
                  widget.solicitud.respuesta!,
                  style: AppTypography.body,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            // Admin actions — resolve/reject
            if (_canResolve) ...[
              const Divider(height: 1),
              const SizedBox(height: AppSpacing.md),
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
                          : () => _resolver('RECHAZADA'),
                      icon: _enviando
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2),
                            )
                          : Icon(Icons.cancel_outlined,
                              color: AppColors.error),
                      label: Text(
                        'Rechazar',
                        style: TextStyle(color: AppColors.error),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.error),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              AppSpacing.buttonRadius),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _enviando
                          ? null
                          : () => _resolver('RESUELTA'),
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
                              AppSpacing.buttonRadius),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
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
                                      '¿Estás seguro de que deseas cancelar esta solicitud de cobro?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(dlgContext, false),
                                        child: const Text('Volver'),
                                      ),
                                      FilledButton(
                                        onPressed: () => Navigator.pop(dlgContext, true),
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
                                    if (mounted) setState(() => _enviando = false);
                                  }
                                }
                              },
                        icon: _enviando
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Icon(Icons.delete_outline_rounded, color: AppColors.error),
                        label: Text(
                          'Cancelar Solicitud',
                          style: TextStyle(color: AppColors.error),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.error),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
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
