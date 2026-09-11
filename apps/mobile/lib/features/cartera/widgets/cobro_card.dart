import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/format/app_currency.dart';
import '../../../core/theme/app_card_styles.dart';
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
    final montoRaw = (cobro.isPaid
            ? (cobro.montoPagado > 0 ? cobro.montoPagado : cobro.monto)
            : cobro.saldo)
        .round();
    final montoFormatted = AppCurrency.format(montoRaw);

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
      decoration: AppCardStyles.elevatedCard(
        context,
        borderColor: cardBorderColor,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.cardInnerPadding),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 350;
                final titleText = isCobrador
                    ? (ubicacion.isNotEmpty ? ubicacion : cobro.tituloCuota)
                    : cobro.tituloCuota;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (isCompact) ...[
                      // ── MODO COMPACTO (< 350dp: Poco X7 Pro y pantallas angostas) ──
                      // 1. Cabecera horizontal: Ícono + Título con FittedBox + Badge de Estado
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _buildIconContainer(),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                titleText,
                                style: AppCardStyles.cobroTitle,
                                maxLines: 1,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildStatusBadge(),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // 2. Información secundaria a todo el ancho
                      if (isCobrador) ...[
                        // Concepto (ej. "Septiembre — Cuota 1")
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
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                ),
                                child: Text(
                                  cobro.tituloCuota,
                                  style: AppTypography.label.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),

                        // Residente (ej. "Camilo Silva")
                        if (tieneResidente) ...[
                          Row(
                            children: [
                              Icon(
                                Icons.person_outline_rounded,
                                size: 14.5,
                                color: AppColors.elevatedCardTextSecondary,
                              ),
                              const SizedBox(width: 4.5),
                              Expanded(
                                child: Text(
                                  cobro.nombre,
                                  style: AppTypography.label.copyWith(
                                    color: AppColors.elevatedCardText,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                        ],

                        // Detalle de fecha
                        if (_fechaDetalle.isNotEmpty) ...[
                          Text(
                            _fechaDetalle,
                            style: AppTypography.smallBold.copyWith(
                              color: (cobro.estado == 'Mora' || cobro.estado == 'VENCIDA')
                                  ? AppColors.error
                                  : AppColors.textSecondary.withValues(alpha: 0.9),
                              fontWeight: (cobro.estado == 'Mora' || cobro.estado == 'VENCIDA')
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ] else ...[
                        // VISTA RESIDENTE COMPACTA
                        if (ubicacion.isNotEmpty) ...[
                          Row(
                            children: [
                              Icon(
                                Icons.home_outlined,
                                size: 14.5,
                                color: AppColors.elevatedCardTextSecondary,
                              ),
                              const SizedBox(width: 4.5),
                              Expanded(
                                child: Text(
                                  ubicacion,
                                  style: AppTypography.label.copyWith(
                                    color: AppColors.elevatedCardTextSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                        ],
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
                                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                  ),
                                  child: Text(
                                    _fechaDetalle,
                                    style: AppTypography.smallBold.copyWith(
                                      color: cobro.isMora
                                          ? AppColors.error
                                          : (cobro.isPaid
                                              ? AppColors.success
                                              : AppColors.primary),
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
                    ] else ...[
                      // ── MODO ESTÁNDAR (>= 350dp: Poco X3 Pro, Tablets, Web) ──
                      // 3 columnas simétricas: [Ícono] | [Columna Central] | [Badge]
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildIconContainer(),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (isCobrador) ...[
                                  Text(
                                    titleText,
                                    style: AppCardStyles.cobroTitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 3),
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
                                            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                          ),
                                          child: Text(
                                            cobro.tituloCuota,
                                            style: AppTypography.label.copyWith(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.w700,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  if (tieneResidente) ...[
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.person_outline_rounded,
                                          size: 14.5,
                                          color: AppColors.elevatedCardTextSecondary,
                                        ),
                                        const SizedBox(width: 4.5),
                                        Expanded(
                                          child: Text(
                                            cobro.nombre,
                                            style: AppTypography.label.copyWith(
                                              color: AppColors.elevatedCardText,
                                              fontWeight: FontWeight.w700,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                  ],
                                  if (_fechaDetalle.isNotEmpty) ...[
                                    Text(
                                      _fechaDetalle,
                                      style: AppTypography.smallBold.copyWith(
                                        color: (cobro.estado == 'Mora' || cobro.estado == 'VENCIDA')
                                            ? AppColors.error
                                            : AppColors.textSecondary.withValues(alpha: 0.9),
                                        fontWeight: (cobro.estado == 'Mora' || cobro.estado == 'VENCIDA')
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ] else ...[
                                  // VISTA RESIDENTE ESTÁNDAR
                                  Text(
                                    cobro.tituloCuota,
                                    style: AppCardStyles.cobroTitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  if (ubicacion.isNotEmpty) ...[
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.home_outlined,
                                          size: 14.5,
                                          color: AppColors.elevatedCardTextSecondary,
                                        ),
                                        const SizedBox(width: 4.5),
                                        Expanded(
                                          child: Text(
                                            ubicacion,
                                            style: AppTypography.label.copyWith(
                                              color: AppColors.elevatedCardTextSecondary,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                  ],
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
                                              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                            ),
                                            child: Text(
                                              _fechaDetalle,
                                              style: AppTypography.smallBold.copyWith(
                                                color: cobro.isMora
                                                    ? AppColors.error
                                                    : (cobro.isPaid
                                                        ? AppColors.success
                                                        : AppColors.primary),
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
                          _buildStatusBadge(),
                        ],
                      ),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    _buildBottomRow(montoFormatted),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconContainer() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Icon(
        _icon,
        color: _color,
        size: 18,
      ),
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 3.5,
      ),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
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
            style: AppTypography.micro.copyWith(color: _color),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomRow(String montoFormatted) {
    return Row(
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
                style: AppTypography.smallBold.copyWith(
                  color: AppColors.textSecondary,
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
                  style: AppCardStyles.cobroValue(
                    color: cobro.isMora ? AppColors.error : AppColors.elevatedCardText,
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
                style: AppTypography.smallBold.copyWith(
                  color: AppColors.primary,
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
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
            ),
            label: const Text(
              'Cobrar',
              style: AppTypography.smallBold,
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
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
            ),
            label: const Text(
              'Solicitar',
              style: AppTypography.smallBold,
            ),
          ),
      ],
    );
  }
}


