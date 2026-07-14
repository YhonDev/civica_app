import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/action_card.dart';
import 'residentes_repository.dart';
import 'models/residentes_models.dart';

class ProyectoDetailScreen extends StatefulWidget {
  final Map<String, dynamic> proyecto;

  const ProyectoDetailScreen({super.key, required this.proyecto});

  @override
  State<ProyectoDetailScreen> createState() => _ProyectoDetailScreenState();
}

class _ProyectoDetailScreenState extends State<ProyectoDetailScreen> {
  final ResidentesRepository _repo = ResidentesRepository();
  ResidenteResumen? _resumen;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final res = await _repo.getResumen();
      if (mounted) {
        setState(() {
          _resumen = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String nombre = widget.proyecto['nombre'] ?? 'Sin nombre';
    final int etapas = widget.proyecto['etapas'] ?? 0;
    final int manzanas = widget.proyecto['manzanas'] ?? 0;
    final int casas = widget.proyecto['casas'] ?? 0;
    final String id = widget.proyecto['id'] ?? '';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Proyecto'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Resumen superior
            Container(
              padding: const EdgeInsets.all(AppSpacing.cardPadding),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.location_city_rounded, color: AppColors.primary, size: 36),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nombre,
                          style: AppTypography.subtitle.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$etapas Etapas • $manzanas Manzanas • $casas Casas',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_rounded),
                    color: AppColors.primary,
                    tooltip: 'Editar Proyecto',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Editar detalles del proyecto')),
                      );
                    },
                  )
                ],
              ),
            ),
            
            const SizedBox(height: AppSpacing.md),
            
            // Resumen Ocupadas / Vacantes
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_resumen != null)
              _buildResumenHeader(_resumen!),
            
            const SizedBox(height: AppSpacing.xl),
            
            Text(
              'Configuración',
              style: AppTypography.subtitle.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            
            // Opciones de gestión
            ActionCard(
              icon: Icons.account_tree_rounded,
              title: 'Gestión de Etapas',
              onTap: () => context.push('/comunidad/urbanizacion/proyecto-detalle/etapas', extra: id),
            ),
            const SizedBox(height: AppSpacing.sm),
            ActionCard(
              icon: Icons.grid_view_rounded,
              title: 'Gestión de Manzanas',
              onTap: () => context.push('/comunidad/urbanizacion/proyecto-detalle/manzanas', extra: id),
            ),
            const SizedBox(height: AppSpacing.sm),
            ActionCard(
              icon: Icons.home_rounded,
              title: 'Gestión de Casas / Lotes',
              onTap: () => context.push('/comunidad/urbanizacion/proyecto-detalle/casas', extra: id),
            ),
            const SizedBox(height: AppSpacing.sm),
            ActionCard(
              icon: Icons.settings_rounded,
              title: 'Ajustes Generales del Proyecto',
              onTap: () => context.push('/comunidad/urbanizacion/proyecto-detalle/ajustes', extra: id),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumenHeader(ResidenteResumen resumen) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Text(
            'Casas',
            style: AppTypography.subtitle.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildResumenMetric('Ocupadas', resumen.ocupadas, AppColors.success),
              Container(width: 1, height: 30, color: AppColors.border),
              _buildResumenMetric('Vacantes', resumen.vacantes, AppColors.textSecondary),
              Container(width: 1, height: 30, color: AppColors.border),
              _buildResumenMetric('Total', resumen.totalPropiedades, AppColors.primary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResumenMetric(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: AppTypography.title.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
