import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/top_toast.dart';
import '../../shared/widgets/action_card.dart';
import 'residentes_repository.dart';
import 'comunidad_repository.dart';
import 'models/residentes_models.dart';

class ProyectoDetailScreen extends StatefulWidget {
  final Map<String, dynamic> proyecto;

  const ProyectoDetailScreen({super.key, required this.proyecto});

  @override
  State<ProyectoDetailScreen> createState() => _ProyectoDetailScreenState();
}

class _ProyectoDetailScreenState extends State<ProyectoDetailScreen> {
  final ResidentesRepository _repo = ResidentesRepository();
  final ComunidadRepository _comunidadRepo = ComunidadRepository();
  ResidenteResumen? _resumen;
  late Map<String, dynamic> _proyecto;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _proyecto = widget.proyecto;
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        _repo.getResumen(),
        _comunidadRepo.getProyectos(),
      ]);
      final res = results[0] as ResidenteResumen;
      final proyectos = results[1] as List<Map<String, dynamic>>;
      final refreshed = proyectos.where((p) => p['id'] == _proyecto['id']).toList();
      if (mounted) {
        setState(() {
          _resumen = res;
          if (refreshed.isNotEmpty) _proyecto = refreshed.first;
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
    final String nombre = _proyecto['nombre'] ?? 'Sin nombre';
    final int etapas = _proyecto['etapas'] ?? 0;
    final int manzanas = _proyecto['manzanas'] ?? 0;
    final int casas = _proyecto['casas'] ?? 0;
    final String id = _proyecto['id'] ?? '';
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
                      TopToast.show(context, message: 'Editar detalles del proyecto', icon: Icons.edit_rounded);
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
              onTap: () async {
                await context.push('/comunidad/urbanizacion/proyecto-detalle/etapas', extra: id);
                if (mounted) _loadData();
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            ActionCard(
              icon: Icons.grid_view_rounded,
              title: 'Gestión de Manzanas',
              onTap: () async {
                await context.push('/comunidad/urbanizacion/proyecto-detalle/manzanas', extra: id);
                if (mounted) _loadData();
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            ActionCard(
              icon: Icons.home_rounded,
              title: 'Gestión de Casas / Lotes',
              onTap: () async {
                await context.push('/comunidad/urbanizacion/proyecto-detalle/casas', extra: id);
                if (mounted) _loadData();
              },
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
