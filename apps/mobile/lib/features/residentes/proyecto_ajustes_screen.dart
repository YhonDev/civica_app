import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/network/api_exceptions.dart';
import 'comunidad_repository.dart';

class ProyectoAjustesScreen extends StatefulWidget {
  final String proyectoId;

  const ProyectoAjustesScreen({super.key, required this.proyectoId});

  @override
  State<ProyectoAjustesScreen> createState() => _ProyectoAjustesScreenState();
}

class _ProyectoAjustesScreenState extends State<ProyectoAjustesScreen> {
  final ComunidadRepository _repo = ComunidadRepository();

  bool _isLoading = true;
  String? _error;
  String _nombreProyecto = '';

  late bool _recordatoriosAutomaticos;
  late bool _permitirPagosParciales;
  late bool _modoMantenimiento;

  @override
  void initState() {
    super.initState();
    _loadAjustes();
  }

  Future<void> _loadAjustes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final ajustes = await _repo.getAjustesProyecto(widget.proyectoId);
      if (mounted) {
        setState(() {
          _nombreProyecto = ajustes['nombre'] as String? ?? '';
          _recordatoriosAutomaticos =
              ajustes['recordatoriosAutomaticos'] as bool? ?? true;
          _permitirPagosParciales =
              ajustes['permitePagosParciales'] as bool? ?? false;
          _modoMantenimiento = ajustes['modoMantenimiento'] as bool? ?? false;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'No se pudieron cargar los ajustes';
        });
      }
    }
  }

  Future<void> _actualizarToggle({
    required bool? recordatoriosAutomaticos,
    required bool? permitePagosParciales,
    required bool? modoMantenimiento,
  }) async {
    final data = <String, dynamic>{};
    if (recordatoriosAutomaticos != null) {
      data['recordatoriosAutomaticos'] = recordatoriosAutomaticos;
    }
    if (permitePagosParciales != null) {
      data['permitePagosParciales'] = permitePagosParciales;
    }
    if (modoMantenimiento != null) {
      data['modoMantenimiento'] = modoMantenimiento;
    }

    try {
      final result =
          await _repo.actualizarAjustesProyecto(widget.proyectoId, data);
      if (mounted) {
        setState(() {
          _recordatoriosAutomaticos =
              result['recordatoriosAutomaticos'] as bool? ??
                  _recordatoriosAutomaticos;
          _permitirPagosParciales =
              result['permitePagosParciales'] as bool? ??
                  _permitirPagosParciales;
          _modoMantenimiento =
              result['modoMantenimiento'] as bool? ?? _modoMantenimiento;
        });
        _mostrarSnackExito(modoMantenimiento != null
            ? 'Modo mantenimiento ${_modoMantenimiento ? "activado" : "desactivado"}'
            : 'Ajuste guardado correctamente');
      }
    } catch (e) {
      if (mounted) {
        final msg = e is ApiException
            ? e.message
            : 'Error al guardar el ajuste';
        _mostrarSnackError(msg);
        // Revertir el toggle al valor anterior
        setState(() {
          if (recordatoriosAutomaticos != null) {
            _recordatoriosAutomaticos = !recordatoriosAutomaticos;
          }
          if (permitePagosParciales != null) {
            _permitirPagosParciales = !permitePagosParciales;
          }
          if (modoMantenimiento != null) {
            _modoMantenimiento = !modoMantenimiento;
          }
        });
      }
    }
  }

  void _mostrarSnackExito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _mostrarSnackError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes del Proyecto'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorView()
              : _buildContent(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded,
                size: 64, color: AppColors.textDisabled),
            const SizedBox(height: AppSpacing.md),
            Text(
              _error!,
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.tonalIcon(
              onPressed: _loadAjustes,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nombre del proyecto
          if (_nombreProyecto.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(AppSpacing.cardPadding),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.location_city_rounded,
                      color: AppColors.primary, size: 28),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      _nombreProyecto,
                      style: AppTypography.subtitle.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: AppSpacing.xl),
          _buildSectionTitle('Reglas de Cobro'),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: Text('Recordatorios Automáticos',
                      style: AppTypography.bodyMedium
                          .copyWith(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                      'Enviar alertas a los propietarios antes de la fecha límite.',
                      style: AppTypography.caption),
                  activeTrackColor: AppColors.primary,
                  value: _recordatoriosAutomaticos,
                  onChanged: (val) {
                    setState(() => _recordatoriosAutomaticos = val);
                    _actualizarToggle(
                      recordatoriosAutomaticos: val,
                      permitePagosParciales: null,
                      modoMantenimiento: null,
                    );
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: Text('Pagos Parciales',
                      style: AppTypography.bodyMedium
                          .copyWith(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                      'Permitir a los residentes abonar una parte de su cuota mensual.',
                      style: AppTypography.caption),
                  activeTrackColor: AppColors.primary,
                  value: _permitirPagosParciales,
                  onChanged: (val) {
                    setState(() => _permitirPagosParciales = val);
                    _actualizarToggle(
                      recordatoriosAutomaticos: null,
                      permitePagosParciales: val,
                      modoMantenimiento: null,
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xl),
          _buildSectionTitle('Sistema'),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: SwitchListTile(
              title: Row(
                children: [
                  Icon(Icons.build_circle_rounded,
                      color: AppColors.warning, size: 20),
                  const SizedBox(width: AppSpacing.xs),
                  Text('Modo Mantenimiento',
                      style: AppTypography.bodyMedium
                          .copyWith(fontWeight: FontWeight.w600)),
                ],
              ),
              subtitle: Text(
                _modoMantenimiento
                    ? 'Activo — Los residentes y cobradores verán una pantalla de mantenimiento al intentar acceder.'
                    : 'Bloquea el acceso a Propietarios y Cobradores temporalmente.',
                style: AppTypography.caption,
              ),
              activeTrackColor: AppColors.warning,
              value: _modoMantenimiento,
              onChanged: (val) {
                if (val) {
                  _mostrarConfirmacionMantenimiento(context);
                } else {
                  setState(() => _modoMantenimiento = val);
                  _actualizarToggle(
                    recordatoriosAutomaticos: null,
                    permitePagosParciales: null,
                    modoMantenimiento: val,
                  );
                }
              },
            ),
          ),

          const SizedBox(height: AppSpacing.xl),
          _buildSectionTitle('Zona de Peligro'),
          _buildDangerCard(
            icon: Icons.delete_forever_rounded,
            title: 'Eliminar Proyecto',
            subtitle:
                'Elimina permanentemente esta urbanización y todos sus datos asociados.',
            onTap: () => _mostrarConfirmacionEliminacion(context),
          ),
        ],
      ),
    );
  }

  void _mostrarConfirmacionMantenimiento(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.build_circle_rounded,
                color: AppColors.warning, size: 24),
            const SizedBox(width: AppSpacing.sm),
            const Text('Activar Modo Mantenimiento'),
          ],
        ),
        content: const Text(
          'Al activar el modo mantenimiento, los residentes y cobradores '
          'no podrán acceder al sistema hasta que lo desactives.\n\n'
          '¿Deseas continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              // Revertir toggle en UI
              setState(() => _modoMantenimiento = false);
            },
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.warning),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _modoMantenimiento = true);
              _actualizarToggle(
                recordatoriosAutomaticos: null,
                permitePagosParciales: null,
                modoMantenimiento: true,
              );
            },
            child: const Text('Activar'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Text(
        title,
        style: AppTypography.subtitle.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildDangerCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: AppColors.error.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.error),
        ),
        title: Text(title,
            style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600, color: AppColors.error)),
        subtitle: Text(subtitle, style: AppTypography.caption),
        trailing: Icon(Icons.chevron_right_rounded, color: AppColors.error),
        onTap: onTap,
      ),
    );
  }

  void _mostrarConfirmacionEliminacion(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error),
            const SizedBox(width: AppSpacing.sm),
            const Text('Eliminar Proyecto'),
          ],
        ),
        content: const Text(
          '¿Estás seguro de que deseas eliminar este proyecto completo?\n\n'
          'Esta es una acción destructiva. Se eliminarán todas las etapas, '
          'manzanas, casas y demás configuraciones de esta urbanización.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(ctx);
              _mostrarDobleConfirmacion(context);
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _mostrarDobleConfirmacion(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Doble Confirmación'),
        content: Text(
          'Por favor, confirma nuevamente que deseas destruir este proyecto y todo su contenido. Esta acción no se puede deshacer.',
          style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(ctx);
              _mostrarSnackExito('Proyecto eliminado exitosamente');
              context.go('/comunidad');
            },
            child: const Text('Sí, eliminar definitivamente'),
          ),
        ],
      ),
    );
  }
}
