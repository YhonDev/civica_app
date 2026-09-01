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
    switch (cobro.estado) {
      case 'Pagado':
        return AppColors.success;
      case 'Mora':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  IconData get _icon {
    switch (cobro.estado) {
      case 'Pagado':
        return Icons.check_circle_rounded;
      case 'Mora':
        return Icons.error_outline_rounded;
      default:
        return Icons.schedule_rounded;
    }
  }

  String get _fechaDetalle {
    if (cobro.fechaVencimiento.isEmpty) return '';
    final date = DateTime.tryParse(cobro.fechaVencimiento);
    if (date == null) return '';

    final fechaFormat = DateFormat("d 'de' MMMM", 'es').format(date);

    if (cobro.estado == 'Pagado') {
      return 'Pagado el $fechaFormat';
    } else if (cobro.estado == 'Mora') {
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
    final montoRaw = (cobro.estado == 'Pagado' ? cobro.monto : cobro.saldo).round();
    final montoFormatted = r'$ ' + NumberFormat('#,##0', 'es_CO').format(montoRaw);

    // Formatear dirección / ubicación como Título Principal
    final houseParts = <String>[];
    if (cobro.manzana.isNotEmpty) houseParts.add(cobro.manzana);
    if (cobro.casa.isNotEmpty) houseParts.add(cobro.casa);
    
    final String mainTitle;
    final String? cuotaSubtitle;

    if (cobro.tituloCuota.isNotEmpty) {
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

    final isOverdue = cobro.estado == 'Mora' || cobro.estado == 'VENCIDA';
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
                    padding: const EdgeInsets.all(AppSpacing.cardPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Contenedor de ícono
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: _color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                _icon,
                                color: _color,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // TÍTULO: Casa / Dirección
                                  Text(
                                    mainTitle,
                                    style: AppTypography.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  // DESCRIPCIÓN: Cuota + Vencimiento + Días
                                  if (cuotaSubtitle != null && cuotaSubtitle.isNotEmpty)
                                    Text(
                                      cuotaSubtitle,
                                      style: AppTypography.caption.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
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
                                        fontSize: 11.5,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Badge de estado
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: _color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _color.withValues(alpha: 0.5),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(_icon, color: _color, size: 12),
                                  const SizedBox(width: 4),
                                  Text(
                                    cobro.estado == 'Mora' ? 'En Mora' : cobro.estado,
                                    style: AppTypography.small.copyWith(
                                      color: _color,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  cobro.estado == 'Pagado' ? 'Monto Pagado' : 'Saldo Pendiente',
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  montoFormatted,
                                  style: AppTypography.title.copyWith(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 19,
                                    color: (cobro.estado == 'Mora' || cobro.estado == 'VENCIDA')
                                        ? AppColors.error
                                        : (isDark ? Colors.white : const Color(0xFF0F172A)),
                                  ),
                                ),
                              ],
                            ),
                            if (cobro.estado == 'Pagado')
                              Row(
                                children: [
                                  Text(
                                    'Ver ticket',
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    color: AppColors.primary,
                                    size: 18,
                                  ),
                                ],
                              )
                            else if (onRegistrarPago != null)
                              FilledButton.icon(
                                onPressed: onRegistrarPago,
                                icon: const Icon(Icons.payments_rounded, size: 16),
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.success,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                ),
                                label: const Text('Registrar Cobro'),
                              )
                            else if (onSolicitarCobro != null)
                              FilledButton.icon(
                                onPressed: onSolicitarCobro,
                                icon: const Icon(Icons.notifications_active_rounded, size: 16),
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                ),
                                label: const Text('Solicitar Cobro'),
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

