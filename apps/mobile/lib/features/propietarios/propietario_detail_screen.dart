import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import 'models/propietarios_models.dart';
import 'propietarios_repository.dart';

class PropietarioDetailScreen extends StatelessWidget {
  final PropietarioItem propietario;

  const PropietarioDetailScreen({super.key, required this.propietario});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Propietario'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(true),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Módulos',
              style: AppTypography.subtitle.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildGrid(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      propietario.nombre,
                      style: AppTypography.title.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${propietario.casa}',
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      propietario.etapa,
                      style: AppTypography.caption.copyWith(color: AppColors.textDisabled),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Deuda Actual', style: AppTypography.caption),
                        const SizedBox(height: 4),
                        Text(
                          '\$${propietario.saldoPendiente.toStringAsFixed(2)}',
                          style: AppTypography.title.copyWith(
                            color: propietario.saldoPendiente > 0 ? AppColors.error : AppColors.success,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Estado', style: AppTypography.caption),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: propietario.saldoPendiente > 0 
                                ? AppColors.error.withValues(alpha: 0.1) 
                                : AppColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            propietario.estadoFinanciero,
                            style: AppTypography.caption.copyWith(
                              color: propietario.saldoPendiente > 0 ? AppColors.error : AppColors.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(height: AppSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Modalidad', style: AppTypography.caption),
                        const SizedBox(height: 4),
                        Text(
                          propietario.modalidadPago,
                          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Próximo Venc.', style: AppTypography.caption),
                        const SizedBox(height: 4),
                        Text(
                          '15 de Mes', // Esto debe venir del backend próximamente
                          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildMiniTimeline(),
        ],
      ),
    );
  }

  Widget _buildMiniTimeline() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Últimos Movimientos', style: AppTypography.caption),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            _buildTimelineNode(true, 'Mayo', isFirst: true),
            Expanded(child: Container(height: 2, color: AppColors.success)),
            _buildTimelineNode(true, 'Junio'),
            Expanded(child: Container(height: 2, color: AppColors.border)),
            _buildTimelineNode(false, 'Julio', isLast: true),
          ],
        ),
      ],
    );
  }

  Widget _buildTimelineNode(bool isPaid, String label, {bool isFirst = false, bool isLast = false}) {
    return Column(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isPaid ? AppColors.success : AppColors.background,
            border: isPaid ? null : Border.all(color: AppColors.border, width: 2),
          ),
          child: isPaid ? Icon(Icons.check, size: 10, color: AppColors.card) : null,
        ),
        const SizedBox(height: 4),
        Text(label, style: AppTypography.small),
      ],
    );
  }

  Widget _buildGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: AppSpacing.md,
      mainAxisSpacing: AppSpacing.md,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildModuleCard(
          context,
          title: 'Finanzas',
          icon: Icons.account_balance_wallet_rounded,
          color: AppColors.primary,
          route: '/comunidad/propietarios/detalle/finanzas',
          extra: propietario,
        ),
        _buildModuleCard(
          context,
          title: 'Historial',
          icon: Icons.receipt_long_rounded,
          color: AppColors.success,
          route: '/comunidad/propietarios/detalle/historial',
          extra: propietario,
        ),
        _buildModuleCard(
          context,
          title: 'Editar',
          icon: Icons.edit_rounded,
          color: AppColors.info,
          routeName: 'comunidad-propietario-editar',
          extra: propietario,
        ),
        _buildModuleCard(
          context,
          title: 'Eliminar',
          icon: Icons.delete_forever_rounded,
          color: AppColors.error,
          onTap: () => _confirmarEliminacion(context),
        ),
      ],
    );
  }

  Widget _buildModuleCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    String? route,
    String? routeName,
    Object? extra,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap ?? () {
        if (routeName != null) {
          context.pushNamed(routeName, extra: extra);
        } else if (route != null) {
          context.push(route, extra: extra);
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: color == AppColors.error ? color : null),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmarEliminacion(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Propietario'),
        content: Text('¿Estás seguro de eliminar a ${propietario.nombre}? Esta acción no se puede deshacer y eliminará sus deudas.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final repo = PropietariosRepository();
      final success = await repo.deletePropietario(propietario.id);
      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Propietario eliminado correctamente')),
        );
        context.pop(true);
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al eliminar el propietario')),
        );
      }
    }
  }
}
