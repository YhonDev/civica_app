import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// Reusable Card component for Solicitudes in Cobrador views (Jornada, CasasExplorer, SolicitudesScreen).
///
/// Supports:
/// - `compact: true`: streamlined 1-line layout used in previews (Dashboard and Route summary).
/// - `compact: false`: full rich layout for the dedicated Solicitudes screen with badge and full details.
///
/// State flow:
/// - Initial: Shows 'En camino' button.
/// - Once marked 'EN_CAMINO': Shows 'Cobrar' button.
class CobradorSolicitudCard extends StatelessWidget {
  final Map<String, dynamic> solicitud;
  final VoidCallback onMarcarEnCamino;
  final VoidCallback onCobrar;
  final bool compact;
  final int? ordenFifo;

  const CobradorSolicitudCard({
    super.key,
    required this.solicitud,
    required this.onMarcarEnCamino,
    required this.onCobrar,
    this.compact = false,
    this.ordenFifo,
  });

  @override
  Widget build(BuildContext context) {
    final estado = solicitud['estado'] as String? ?? 'EN_ESPERA';
    final enCamino = estado == 'EN_CAMINO';
    final nombreResidente = solicitud['residenteNombre'] as String? ?? 'Residente';
    final manzana = solicitud['manzanaNombre'] as String? ?? '';
    final casa = solicitud['casaDireccion'] as String? ?? '';
    final casaInfo = manzana.isNotEmpty ? '$manzana — $casa' : (casa.isNotEmpty ? casa : 'Casa');
    final nota = (solicitud['descripcion'] as String? ?? '').trim();
    final saldo = (solicitud['saldo'] as num? ?? 20000.0).toDouble();
    final telefono = (solicitud['residenteTelefono'] as String? ?? '').trim();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (compact) {
      return Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: enCamino ? AppColors.info.withValues(alpha: 0.6) : AppColors.border,
            width: enCamino ? 1.4 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: enCamino
                    ? AppColors.info.withValues(alpha: 0.12)
                    : AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                enCamino ? Icons.directions_car_rounded : Icons.home_outlined,
                size: 18,
                color: enCamino ? AppColors.info : AppColors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          nombreResidente,
                          style: AppTypography.body.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: enCamino
                              ? AppColors.info.withValues(alpha: 0.15)
                              : AppColors.warning.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          enCamino ? 'En camino' : 'En espera',
                          style: AppTypography.caption.copyWith(
                            color: enCamino ? AppColors.info : AppColors.warning,
                            fontWeight: FontWeight.w700,
                            fontSize: 9.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 1),
                  Text(
                    casaInfo,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (nota.isNotEmpty) ...[
                    const SizedBox(height: 1),
                    Text(
                      '"$nota"',
                      style: AppTypography.caption.copyWith(
                        fontStyle: FontStyle.italic,
                        color: AppColors.textSecondary,
                        fontSize: 10.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            // Action button: En camino or Cobrar
            if (!enCamino)
              OutlinedButton.icon(
                onPressed: onMarcarEnCamino,
                icon: const Icon(Icons.near_me_rounded, size: 12),
                label: const Text('En camino', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: AppColors.info,
                  side: BorderSide(color: AppColors.info.withValues(alpha: 0.5)),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: onCobrar,
                icon: const Icon(Icons.flash_on_rounded, size: 13),
                label: const Text('Cobrar', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
          ],
        ),
      );
    }

    // Rich layout (for dedicated Solicitudes screen)
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: enCamino ? AppColors.info.withValues(alpha: 0.6) : AppColors.border,
          width: enCamino ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Prioridad / FIFO + Residente + Badge estado
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    if (ordenFifo != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '#$ordenFifo',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                    Flexible(
                      child: Text(
                        nombreResidente,
                        style: AppTypography.subtitle.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: enCamino
                      ? AppColors.info.withValues(alpha: 0.15)
                      : AppColors.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  enCamino ? '🚀 En camino' : '⏳ En espera',
                  style: AppTypography.caption.copyWith(
                    color: enCamino ? AppColors.info : AppColors.warning,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          // Ubicación y Teléfono
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  casaInfo,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (telefono.isNotEmpty) ...[
                const SizedBox(width: AppSpacing.sm),
                Icon(Icons.phone_outlined, size: 13, color: AppColors.textSecondary),
                const SizedBox(width: 3),
                Text(
                  telefono,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),

          if (nota.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? Colors.black.withValues(alpha: 0.2) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
              ),
              child: Text(
                '"$nota"',
                style: AppTypography.caption.copyWith(
                  fontStyle: FontStyle.italic,
                  color: AppColors.textPrimary,
                  fontSize: 11.5,
                ),
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.sm),

          // Barra inferior: Saldo + Botones fluidos
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '\$${NumberFormat('#,###', 'es_CO').format(saldo.toInt())} COP',
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Botón de acción con tamaño óptimo
              if (!enCamino)
                OutlinedButton.icon(
                  onPressed: onMarcarEnCamino,
                  icon: const Icon(Icons.directions_car_rounded, size: 14),
                  label: const Text('En camino'),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: AppColors.info,
                    side: BorderSide(color: AppColors.info.withValues(alpha: 0.6)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                )
              else
                ElevatedButton.icon(
                  onPressed: onCobrar,
                  icon: const Icon(Icons.flash_on_rounded, size: 15),
                  label: const Text('Cobrar'),
                  style: ElevatedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
