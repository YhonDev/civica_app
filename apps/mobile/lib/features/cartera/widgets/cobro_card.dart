import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../models/cartera_models.dart';

class CobroCard extends StatelessWidget {
  final CobroItem cobro;
  final VoidCallback? onRegistrarPago;
  final VoidCallback? onSolicitarCobro;
  final VoidCallback? onTap;

  const CobroCard({
    super.key,
    required this.cobro,
    this.onRegistrarPago,
    this.onSolicitarCobro,
    this.onTap,
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

    // Formatear dirección / ubicación como Título Principal
    final houseParts = <String>[];
    if (cobro.manzana.isNotEmpty) houseParts.add(cobro.manzana);
    if (cobro.casa.isNotEmpty) houseParts.add(cobro.casa);
    
    final String mainTitle;
    final String? cuotaSubtitle;

    if (cobro.nombre.isNotEmpty && cobro.nombre != 'Residente') {
      mainTitle = cobro.nombre;
      cuotaSubtitle = cobro.tituloCuota.isNotEmpty
          ? (houseParts.isNotEmpty ? '${cobro.tituloCuota} · ${houseParts.join(" — ")}' : cobro.tituloCuota)
          : (houseParts.isNotEmpty ? houseParts.join(' — ') : null);
    } else if (cobro.tituloCuota.isNotEmpty) {
      mainTitle = cobro.tituloCuota;
      cuotaSubtitle = houseParts.isNotEmpty
          ? (cobro.etapa.isNotEmpty ? '${cobro.etapa} — ${houseParts.join(' — ')}' : houseParts.join(' — '))
          : null;
    } else if (houseParts.isNotEmpty) {
      final loc = houseParts.join(' — ');
      mainTitle = cobro.etapa.isNotEmpty ? '$loc (${cobro.etapa})' : loc;
      cuotaSubtitle = null;
    } else {
      mainTitle = 'Cuota de Recaudo';
      cuotaSubtitle = null;
    }

    final isOverdue = cobro.isMora;
    final cardBorderColor = isOverdue
        ? AppColors.error.withValues(alpha: 0.4)
        : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0));

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
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
                          // TÍTULO: Casa / Dirección
                          Text(
                            mainTitle,
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          // DESCRIPCIÓN: Cuota + Vencimiento + Días
                          if (cuotaSubtitle != null && cuotaSubtitle.isNotEmpty)
                            Text(
                              cuotaSubtitle,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 11.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          if (_fechaDetalle.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              _fechaDetalle,
                              style: AppTypography.caption.copyWith(
                                color: (cobro.estado == 'Mora' || cobro.estado == 'VENCIDA')
                                    ? AppColors.error
                                    : AppColors.textSecondary,
                                fontWeight: (cobro.estado == 'Mora' || cobro.estado == 'VENCIDA')
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
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

