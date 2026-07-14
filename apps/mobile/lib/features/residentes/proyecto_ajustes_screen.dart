import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

class ProyectoAjustesScreen extends StatefulWidget {
  const ProyectoAjustesScreen({super.key});

  @override
  State<ProyectoAjustesScreen> createState() => _ProyectoAjustesScreenState();
}

class _ProyectoAjustesScreenState extends State<ProyectoAjustesScreen> {
  bool _recordatoriosAutomaticos = true;
  bool _permitirPagosParciales = false;
  bool _modoMantenimiento = false;

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Información Básica'),
            _buildSettingCard(
              icon: Icons.edit_document,
              title: 'Nombre y Descripción',
              subtitle: 'Modifica los datos principales de la urbanización',
              onTap: () => _showNotImplemented(context),
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
                    title: Text('Recordatorios Automáticos', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                    subtitle: Text('Enviar alertas a los propietarios antes de la fecha límite.', style: AppTypography.caption),
                    activeColor: AppColors.primary,
                    value: _recordatoriosAutomaticos,
                    onChanged: (val) => setState(() => _recordatoriosAutomaticos = val),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: Text('Pagos Parciales', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                    subtitle: Text('Permitir a los residentes abonar una parte de su cuota mensual.', style: AppTypography.caption),
                    activeColor: AppColors.primary,
                    value: _permitirPagosParciales,
                    onChanged: (val) => setState(() => _permitirPagosParciales = val),
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
                    Icon(Icons.build_circle_rounded, color: AppColors.warning, size: 20),
                    const SizedBox(width: AppSpacing.xs),
                    Text('Modo Mantenimiento', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                  ],
                ),
                subtitle: Text('(Próximamente) Bloquea el acceso a Propietarios y Cobradores temporalmente mostrando una pantalla de mantenimiento.', style: AppTypography.caption),
                activeColor: AppColors.warning,
                value: _modoMantenimiento,
                onChanged: (val) => setState(() => _modoMantenimiento = val),
              ),
            ),

            const SizedBox(height: AppSpacing.xl),
            _buildSectionTitle('Zona de Peligro'),
            _buildDangerCard(
              icon: Icons.delete_forever_rounded,
              title: 'Eliminar Proyecto',
              subtitle: 'Elimina permanentemente esta urbanización y todos sus datos asociados.',
              onTap: () => _mostrarConfirmacionEliminacion(context),
            ),
          ],
        ),
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

  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.border),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(title, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: AppTypography.caption),
        trailing: Icon(Icons.chevron_right_rounded, color: AppColors.textDisabled),
        onTap: onTap,
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
        title: Text(title, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: AppColors.error)),
        subtitle: Text(subtitle, style: AppTypography.caption),
        trailing: Icon(Icons.chevron_right_rounded, color: AppColors.error),
        onTap: onTap,
      ),
    );
  }

  void _showNotImplemented(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Función en desarrollo')),
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Proyecto eliminado exitosamente')),
              );
              // Navigate back to community hub
              context.go('/comunidad');
            },
            child: const Text('Sí, eliminar definitivamente'),
          ),
        ],
      ),
    );
  }
}
