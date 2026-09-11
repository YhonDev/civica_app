import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/top_toast.dart';
import 'comunidad_repository.dart';
import '../../shared/widgets/empty_state.dart';

class UrbanizacionScreen extends StatefulWidget {
  const UrbanizacionScreen({super.key});

  @override
  State<UrbanizacionScreen> createState() => _UrbanizacionScreenState();
}

class _UrbanizacionScreenState extends State<UrbanizacionScreen> {
  final ComunidadRepository _comunidadRepo = ComunidadRepository();
  bool _isLoading = true;
  List<Map<String, dynamic>> _proyectos = [];

  @override
  void initState() {
    super.initState();
    _loadProyectos();
  }

  Future<void> _loadProyectos() async {
    setState(() => _isLoading = true);
    try {
      final proyectos = await _comunidadRepo.getProyectos();
      setState(() {
        _proyectos = proyectos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        TopToast.showError(context, e, prefix: 'Error al cargar proyectos');
      }
    }
  }

  void _mostrarCrearProyecto() {
    final formKey = GlobalKey<FormState>();
    final nombreController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.chipRadius)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: AppSpacing.screenPadding,
          right: AppSpacing.screenPadding,
          top: AppSpacing.xl,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Nuevo Proyecto', style: AppTypography.subtitle),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: nombreController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Nombre del Proyecto',
                  hintText: 'Ej. Urbanización Los Pinos',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.buttonRadius)),
                ),
                validator: (val) => val == null || val.isEmpty ? 'El nombre es requerido' : null,
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      final name = nombreController.text;
                      Navigator.pop(ctx);
                      setState(() => _isLoading = true);
                      try {
                        await _comunidadRepo.createProyecto(name);
                        await _loadProyectos();
                        if (mounted) {
                          TopToast.showSuccess(context, 'Proyecto "$name" creado exitosamente');
                        }
                      } catch (e) {
                        setState(() => _isLoading = false);
                        if (mounted) {
                          TopToast.showError(context, e, prefix: 'Error al crear proyecto');
                        }
                      }
                    }
                  },
                  child: const Text('Crear Proyecto'),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Proyectos'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _proyectos.isEmpty 
              ? EmptyState(
                  icon: Icons.domain_disabled_rounded,
                  title: 'Aún no hay proyectos',
                  description: 'Crea tu primera urbanización para comenzar a gestionar la comunidad.',
                  actionLabel: 'Crear Proyecto',
                  onAction: _mostrarCrearProyecto,
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.screenPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tus Urbanizaciones',
                        style: AppTypography.subtitle.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Selecciona un proyecto para gestionar su estructura.',
                        style: AppTypography.body.copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      
                      ..._proyectos.map((proyecto) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: _buildProjectCard(
                          context,
                          name: proyecto['nombre'],
                          status: proyecto['estado'],
                          etapas: proyecto['etapas'] ?? 0,
                          manzanas: proyecto['manzanas'] ?? 0,
                          casas: proyecto['casas'] ?? 0,
                          isActive: proyecto['estado'] == 'Activo',
                          onTap: () async {
                            await context.push('/comunidad/urbanizacion/proyecto-detalle', extra: proyecto);
                            if (mounted) _loadProyectos();
                          },
                        ),
                      )),
                    ],
                  ),
                ),
      floatingActionButton: _proyectos.isEmpty ? null : FloatingActionButton.extended(
        onPressed: _mostrarCrearProyecto,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Nuevo Proyecto',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildProjectCard(
    BuildContext context, {
    required String name,
    required String status,
    required int etapas,
    required int manzanas,
    required int casas,
    bool isActive = true,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(
            color: isActive 
              ? AppColors.primary.withValues(alpha: 0.2) 
              : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isActive ? Colors.white : AppColors.background,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isActive ? AppColors.primary.withValues(alpha: 0.3) : AppColors.border,
                ),
              ),
              child: Icon(
                Icons.location_city_rounded, 
                color: isActive ? AppColors.primary : AppColors.textDisabled, 
                size: 28,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: AppTypography.subtitle.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isActive ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isActive ? AppColors.success.withValues(alpha: 0.2) : AppColors.warning.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                        child: Text(
                          status,
                          style: AppTypography.small.copyWith(
                            color: isActive ? AppColors.success : AppColors.warning,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        '$etapas Etapas • $manzanas Mz • $casas Lotes',
                        style: AppTypography.small.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
