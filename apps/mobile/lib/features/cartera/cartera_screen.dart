import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// Cartera screen — listado de cuentas de propietarios con saldos.
///
/// Per doc/20-screen-specifications.md (Propietario / Gestión):
/// Debe mostrar: nombre, casa, modalidad, estado, saldo.
/// Acciones: llamar, WhatsApp, registrar pago.
class CarteraScreen extends StatelessWidget {
  const CarteraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.lg),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cartera',
                    style: AppTypography.title.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Propietarios con cuenta activa',
                    style: AppTypography.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // Search
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Buscar propietario...',
                  hintStyle: AppTypography.body.copyWith(
                    color: AppColors.textDisabled,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: AppColors.textDisabled,
                  ),
                  filled: true,
                  fillColor: AppColors.card,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // List
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding,
                ),
                itemCount: 3, // TODO: real data
                separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                itemBuilder: (_, i) {
                  return _PropietarioCard(
                    nombre: ['Juan Pérez', 'María García', 'Carlos López'][i],
                    casa: ['Casa 101', 'Casa 102', 'Casa 103'][i],
                    etapa: 'Etapa 1',
                    saldo: [40000, 0, 80000][i],
                    estado: ['Pendiente', 'Al día', 'Mora'][i],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PropietarioCard extends StatelessWidget {
  final String nombre;
  final String casa;
  final String etapa;
  final int saldo;
  final String estado;

  const _PropietarioCard({
    required this.nombre,
    required this.casa,
    required this.etapa,
    required this.saldo,
    required this.estado,
  });

  Color get _color {
    switch (estado) {
      case 'Al día':
        return AppColors.success;
      case 'Mora':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  IconData get _icon {
    switch (estado) {
      case 'Al día':
        return Icons.check_circle_rounded;
      case 'Mora':
        return Icons.error_outline_rounded;
      default:
        return Icons.schedule_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Avatar with initials
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.surface,
                  child: Text(
                    nombre.split(' ').map((w) => w[0]).take(2).join(),
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nombre,
                        style: AppTypography.body.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '$casa · $etapa',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Estado badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_icon, color: _color, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        estado,
                        style: AppTypography.small.copyWith(
                          color: _color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Saldo: ',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  r'$' + (saldo / 100).toStringAsFixed(0),
                  style: AppTypography.subtitle.copyWith(
                    fontWeight: FontWeight.w700,
                    color: saldo > 0 ? AppColors.error : AppColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.phone_rounded, size: 20),
                  color: AppColors.textSecondary,
                  onPressed: () {},
                  tooltip: 'Llamar',
                ),
                IconButton(
                  icon: const Icon(Icons.chat_rounded, size: 20),
                  color: AppColors.textSecondary,
                  onPressed: () {},
                  tooltip: 'WhatsApp',
                ),
                const SizedBox(width: AppSpacing.sm),
                FilledButton(
                  onPressed: () {},
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  child: const Text('Cobrar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
