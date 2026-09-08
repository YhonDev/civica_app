import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../auth/auth_cubit.dart';
import '../models/cartera_models.dart';

class CobroCard extends StatelessWidget {
  final CobroItem cobro;
  final VoidCallback? onRegistrarPago;
  final VoidCallback? onSolicitarCobro;
  final VoidCallback? onTap;
  final bool? isCobradorView;

  const CobroCard({
    super.key,
    required this.cobro,
    this.onRegistrarPago,
    this.onSolicitarCobro,
    this.onTap,
    this.isCobradorView,
  });

  Color get _color {
    if (cobro.isPaid) return AppColors.success;
    if (cobro.isMora) return AppColors.error;
    return AppColors.warning;
  }

  IconData get _icon {
    if (cobro.isPaid) return Icons.check_circle_rounded;
    if (cobro.isMora) return Icons.error_outline_rounded;
    return Icons.schedule_rounded;
  }

  String get _fechaDetalle {
    DateTime? date;
    if (cobro.isPaid && cobro.fechaPago.isNotEmpty) {
      date = DateTime.tryParse(cobro.fechaPago)?.toLocal();
    } else if (cobro.fechaVencimiento.isNotEmpty) {
      date = DateTime.tryParse(cobro.fechaVencimiento)?.toLocal();
    }
    if (date == null) return '';

    final fechaFormat = DateFormat("d 'de' MMMM", 'es').format(date);

    if (cobro.isPaid) {
      final hora = (cobro.fechaPago.isNotEmpty)
          ? ' · ${DateFormat("hh:mm a", 'es').format(date)}'
          : '';
      return 'Pagado el $fechaFormat$hora';
    } else if (cobro.isMora) {
      final diffDays = DateTime.now().difference(date).inDays;
      final diasText = diffDays > 0 ? ' · Hace $diffDays días' : '';
      return 'Vencido el $fechaFormat$diasText';
    } else {
      return 'Vence el $fechaFormat';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final montoRaw = (cobro.isPaid
            ? (cobro.montoPagado > 0 ? cobro.montoPagado : cobro.monto)
            : cobro.saldo)
        .round();
    final montoFormatted = r'$ ' + NumberFormat('#,##0', 'es_CO').format(montoRaw);

    final ubicacion = cobro.ubicacionNombre;
    final bool tieneResidente = cobro.nombre.isNotEmpty && cobro.nombre != 'Residente';
    final bool isCobrador = isCobradorView ?? () {
      final user = context.read<AuthCubit>().state.usuario;
      final rol = user?['rol'] as String?;
      return rol != 'RESIDENTE' && rol != 'PROPIETARIO';
    }();

    final isOverdue = cobro.isMora;
    final cardBorderColor = isOverdue
        ? AppColors.error.withValues(alpha: 0.4)
        : AppColors.elevatedCardBorder;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.elevatedCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cardBorderColor,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.cardInnerPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Contenedor de ícono
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _icon,
                        color: _color,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isCobrador) ...[
                            // ══════════════════════════════════════════════
                            // VISTA COBRADOR / ADMIN (Foco: Dirección de visita)
                            // ══════════════════════════════════════════════
                            // 1. CELDA SUPERIOR: DIRECCIÓN / INMUEBLE (ej. "Manzana B · Casa 4")
                            Text(
                              ubicacion.isNotEmpty ? ubicacion : cobro.tituloCuota,
                              style: AppTypography.bodyMedium.copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: 15.5,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),

                            // 2. CELDA INTERMEDIA: CUOTA / CONCEPTO (ej. "Septiembre — Cuota 1")
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      cobro.tituloCuota,
                                      style: AppTypography.caption.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),

                            // 3. CELDA INFERIOR: RESIDENTE (ej. "Camilo Silva")
                            if (tieneResidente) ...[
                              Row(
                                children: [
                                  Icon(
                                    Icons.person_outline_rounded,
                                    size: 14.5,
                                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                                  ),
                                  const SizedBox(width: 4.5),
                                  Expanded(
                                    child: Text(
                                      cobro.nombre,
                                      style: AppTypography.caption.copyWith(
                                        color: isDark ? Colors.white : AppColors.elevatedCardText,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12.5,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                            ],

                            // 4. DETALLE DE FECHA (Vence / Pagado)
                            if (_fechaDetalle.isNotEmpty) ...[
                              Text(
                                _fechaDetalle,
                                style: AppTypography.caption.copyWith(
                                  color: (cobro.estado == 'Mora' || cobro.estado == 'VENCIDA')
                                      ? AppColors.error
                                      : AppColors.textSecondary.withValues(alpha: 0.9),
                                  fontWeight: (cobro.estado == 'Mora' || cobro.estado == 'VENCIDA')
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ] else ...[
                            // ══════════════════════════════════════════════
                            // VISTA RESIDENTE (Foco: Periodo / Cuota a pagar)
                            // ══════════════════════════════════════════════
                            // 1. CELDA SUPERIOR: CUOTA Y PERIODO (ej. "Septiembre — Cuota 1")
                            Text(
                              cobro.tituloCuota,
                              style: AppTypography.bodyMedium.copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: 15.5,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),

                            // 2. CELDA INTERMEDIA: UBICACIÓN / DIRECCIÓN (ej. "Manzana B · Casa 4")
                            if (ubicacion.isNotEmpty) ...[
                              Row(
                                children: [
                                  Icon(
                                    Icons.home_outlined,
                                    size: 14.5,
                                    color: AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 4.5),
                                  Expanded(
                                    child: Text(
                                      ubicacion,
                                      style: AppTypography.caption.copyWith(
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                            ],

                            // 3. DETALLE DE FECHA (Vence / Pagado) EN BADGE DESTACADO
                            if (_fechaDetalle.isNotEmpty) ...[
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7.5,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: (cobro.isMora
                                                ? AppColors.error
                                                : (cobro.isPaid
                                                    ? AppColors.success
                                                    : AppColors.primary))
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        _fechaDetalle,
                                        style: AppTypography.caption.copyWith(
                                          color: cobro.isMora
                                              ? AppColors.error
                                              : (cobro.isPaid
                                                  ? AppColors.success
                                                  : AppColors.primary),
                                          fontWeight: FontWeight.w700,
                                          fontSize: 11,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Badge de estado
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3.5,
                      ),
                      decoration: BoxDecoration(
                        color: _color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _color.withValues(alpha: 0.5),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_icon, color: _color, size: 11),
                          const SizedBox(width: 3),
                          Text(
                            cobro.isMora ? 'En Mora' : (cobro.isPaid ? 'Pagada' : 'Pendiente'),
                            style: AppTypography.small.copyWith(
                              color: _color,
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            cobro.isPaid ? 'Monto Pagado' : 'Saldo Pendiente',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 1),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              montoFormatted,
                              style: AppTypography.title.copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                                color: cobro.isMora
                                    ? AppColors.error
                                    : (isDark ? Colors.white : const Color(0xFF0F172A)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (cobro.isPaid)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Ver ticket',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.primary,
                            size: 16,
                          ),
                        ],
                      )
                    else if (onRegistrarPago != null)
                      FilledButton.icon(
                        onPressed: onRegistrarPago,
                        icon: const Icon(Icons.payments_rounded, size: 14),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.success,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        label: const Text(
                          'Cobrar',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      )
                    else if (onSolicitarCobro != null)
                      FilledButton.icon(
                        onPressed: onSolicitarCobro,
                        icon: const Icon(Icons.notifications_active_rounded, size: 14),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        label: const Text(
                          'Solicitar',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

