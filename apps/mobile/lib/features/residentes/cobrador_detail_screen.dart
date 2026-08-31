import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/top_toast.dart';
import 'models/cobradores_models.dart';
import 'widgets/security_section.dart';

class CobradorDetailScreen extends StatefulWidget {
  final CobradorItem cobrador;

  const CobradorDetailScreen({super.key, required this.cobrador});

  @override
  State<CobradorDetailScreen> createState() => _CobradorDetailScreenState();
}

class _CobradorDetailScreenState extends State<CobradorDetailScreen> {
  bool _isDeleting = false;
  List<String> _zonas = [];
  bool _isLoadingZonas = true;

  @override
  void initState() {
    super.initState();
    _zonas = List.from(widget.cobrador.zonas);
    _cargarZonas();
  }

  Future<void> _cargarZonas() async {
    final cobradorId = widget.cobrador.usuarioId ?? widget.cobrador.id;
    try {
      final resEtapas = await ApiClient.instance.get('/proyectos/etapas');
      final etapas = List<Map<String, dynamic>>.from(resEtapas.data as List? ?? []);

      final resAsignadas = await ApiClient.instance.get('/usuarios/$cobradorId/etapas');
      final asignadas = List<Map<String, dynamic>>.from(resAsignadas.data as List? ?? []);
      final asignadasIds = asignadas.map((a) => a['etapaId'] as String).toSet();

      final nombres = etapas
          .where((e) => asignadasIds.contains(e['id']))
          .map((e) => (e['nombre'] as String?) ?? 'Etapa')
          .toList();

      if (mounted) {
        setState(() {
          _zonas = nombres;
          _isLoadingZonas = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingZonas = false);
      }
    }
  }

  Future<void> _confirmarEliminar(BuildContext context) async {
    final cobradorId = widget.cobrador.usuarioId ?? widget.cobrador.id;

    final seguro = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: AppSpacing.sm),
            Text('Eliminar Cobrador'),
          ],
        ),
        content: Text(
          '¿Estás seguro de que deseas eliminar a "${widget.cobrador.nombre}"? Esta acción eliminará su usuario y sus asignaciones de zona de forma permanente.',
          style: AppTypography.body,
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (seguro != true || !mounted) return;

    setState(() => _isDeleting = true);

    try {
      await ApiClient.instance.delete('/usuarios/$cobradorId');
      if (mounted) {
        TopToast.showSuccess(context, 'Cobrador eliminado correctamente');
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        TopToast.showError(context, 'Error al eliminar cobrador: $e');
        setState(() => _isDeleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Cobrador'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: _isDeleting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red),
                  )
                : const Icon(Icons.delete_forever_rounded, color: Colors.red, size: 26),
            tooltip: 'Eliminar cobrador',
            onPressed: _isDeleting ? null : () => _confirmarEliminar(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Info del cobrador ──
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.info.withValues(alpha: 0.1),
                    child: Text(
                      widget.cobrador.nombre
                          .split(' ')
                          .map((w) => w.isNotEmpty ? w[0] : '')
                          .take(2)
                          .join()
                          .toUpperCase(),
                      style: AppTypography.subtitle.copyWith(
                        color: AppColors.info,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.cobrador.nombre,
                          style: AppTypography.title.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _isLoadingZonas
                            ? const SizedBox(
                                height: 14,
                                width: 14,
                                child: CircularProgressIndicator(strokeWidth: 1.5),
                              )
                            : Text(
                                'Zonas: ${_zonas.isEmpty ? "Sin asignación" : _zonas.join(", ")}',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: AppColors.border),
              ),
              child: ListTile(
                leading: Icon(Icons.domain_add_rounded, color: AppColors.primary),
                title: const Text('Asignar Etapas al Cobrador'),
                subtitle: Text(
                  _zonas.isEmpty
                      ? 'Sin etapas asignadas actualmente'
                      : 'Asignadas: ${_zonas.join(", ")}',
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () async {
                  final res = await context.push('/asignar-etapas', extra: {
                    'cobradorId': widget.cobrador.usuarioId ?? widget.cobrador.id,
                    'cobradorNombre': widget.cobrador.nombre,
                  });
                  if (res == true && mounted) {
                    _cargarZonas();
                  }
                },
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── Módulo de Seguridad ──
            SecuritySection(
              usuarioId: widget.cobrador.usuarioId ?? widget.cobrador.id,
              nombre: widget.cobrador.nombre,
              initialUsername: widget.cobrador.username,
              isAdmin: true,
              onCredentialsUpdated: () {
                TopToast.showSuccess(context, 'Credenciales actualizadas');
              },
            ),

            const SizedBox(height: AppSpacing.lg),

            // ── Zona de Peligro (Eliminar Cobrador) ──
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.red),
                      const SizedBox(width: 8),
                      Text(
                        'Zona de Peligro',
                        style: AppTypography.subtitle.copyWith(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Eliminar este cobrador removerá permanentemente su usuario y sus asignaciones de zona.',
                    style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _isDeleting ? null : () => _confirmarEliminar(context),
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                      label: const Text(
                        'Eliminar Cobrador',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
