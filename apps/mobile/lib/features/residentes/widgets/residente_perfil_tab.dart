import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../models/residentes_models.dart';
import '../residentes_repository.dart';

class ResidentePerfilTab extends StatefulWidget {
  final ResidenteItem propietario;
  final VoidCallback onUpdate;
  final VoidCallback onDeleteSuccess;

  const ResidentePerfilTab({
    super.key,
    required this.propietario,
    required this.onUpdate,
    required this.onDeleteSuccess,
  });

  @override
  State<ResidentePerfilTab> createState() => _ResidentePerfilTabState();
}

class _ResidentePerfilTabState extends State<ResidentePerfilTab> {
  final ResidentesRepository _repo = ResidentesRepository();
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    final propietario = widget.propietario;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: AppSpacing.lg),

          // Avatar
          CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            child: Text(
              propietario.nombre.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase(),
              style: AppTypography.title.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Name and Role
          Text(
            propietario.nombre,
            style: AppTypography.title.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Residente',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Basic Info
          _SectionCard(
            title: 'Información Básica',
            children: [
              _InfoTile(
                icon: Icons.phone_outlined,
                label: 'Teléfono',
                value: propietario.telefono,
              ),
              const Divider(height: 1, indent: 56),
              _InfoTile(
                icon: Icons.payment_outlined,
                label: 'Modalidad de Pago',
                value: propietario.modalidadPago,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Inmueble Info
          _SectionCard(
            title: 'Inmueble Asignado',
            children: [
              _InfoTile(
                icon: Icons.home_outlined,
                label: 'Casa',
                value: propietario.casa,
              ),
              const Divider(height: 1, indent: 56),
              _InfoTile(
                icon: Icons.location_on_outlined,
                label: 'Etapa / Manzana',
                value: propietario.etapa,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Financial Info
          _SectionCard(
            title: 'Estado Financiero',
            children: [
              _InfoTile(
                icon: Icons.account_balance_wallet_outlined,
                label: 'Estado Actual',
                value: propietario.estadoFinanciero,
              ),
              if (propietario.saldoPendiente > 0) ...[
                const Divider(height: 1, indent: 56),
                _InfoTile(
                  icon: Icons.money_off_csred_outlined,
                  label: 'Deuda Pendiente',
                  value: '\$${propietario.saldoPendiente.toStringAsFixed(2)}',
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          // Botones de Acción
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final result = await context.pushNamed<bool>(
                      'comunidad-propietario-editar',
                      extra: propietario,
                    );
                    if (result == true) {
                      widget.onUpdate();
                    }
                  },
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  label: const Text('Editar Info'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    foregroundColor: AppColors.primary,
                    side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isDeleting ? null : () => _confirmDelete(context, propietario),
                  icon: _isDeleting 
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) 
                    : const Icon(Icons.delete_outline_rounded, size: 18),
                  label: const Text('Eliminar'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    foregroundColor: AppColors.error,
                    side: BorderSide(color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, ResidenteItem propietario) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Propietario'),
        content: Text('¿Está seguro de eliminar a ${propietario.nombre}? Esta acción liberará la casa y no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deletePropietario(propietario.id);
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePropietario(String id) async {
    setState(() => _isDeleting = true);
    final success = await _repo.deletePropietario(id);
    if (mounted) {
      setState(() => _isDeleting = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Propietario eliminado con éxito')),
        );
        widget.onDeleteSuccess();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al eliminar propietario')),
        );
      }
    }
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.sm),
          child: Text(
            title,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Card(child: Column(children: children)),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
      subtitle: Text(
        value,
        style: AppTypography.body.copyWith(fontWeight: FontWeight.w500),
      ),
    );
  }
}
