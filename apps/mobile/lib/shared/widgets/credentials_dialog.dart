import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/top_toast.dart';

/// Atomic Dialog Component: Credentials Dialog (`CredentialsDialog`).
///
/// Reusable modal dialog for displaying newly generated credentials across Admin, Residente, and Cobrador workflows.
/// Symmetrically aligns 'Copiar' on the left and 'Listo' on the right in a single horizontal row.
class CredentialsDialog extends StatelessWidget {
  final String title;
  final String nombre;
  final String username;
  final String password;
  final VoidCallback onDismiss;

  const CredentialsDialog({
    super.key,
    required this.title,
    required this.nombre,
    required this.username,
    required this.password,
    required this.onDismiss,
  });

  /// Static helper to launch the credentials dialog.
  static Future<void> show({
    required BuildContext context,
    required String title,
    required String nombre,
    required String username,
    required String password,
    required VoidCallback onDismiss,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => CredentialsDialog(
        title: title,
        nombre: nombre,
        username: username,
        password: password,
        onDismiss: onDismiss,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.check_circle_rounded, color: AppColors.success),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              title,
              style: AppTypography.subtitle.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$nombre ha sido registrado correctamente.',
            style: AppTypography.body,
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
              border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.person_outline, size: 16, color: AppColors.info),
                    const SizedBox(width: AppSpacing.sm),
                    Text('Usuario:', style: AppTypography.small.copyWith(fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 4),
                SelectableText(
                  username,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Icon(Icons.lock_outline, size: 16, color: AppColors.info),
                    const SizedBox(width: AppSpacing.sm),
                    Text('Contraseña:', style: AppTypography.small.copyWith(fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 4),
                SelectableText(
                  password,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Guarda estas credenciales. No se mostrarán nuevamente.',
            style: AppTypography.small.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
      actionsPadding: const EdgeInsets.all(AppSpacing.md),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(
                    text: 'Usuario: $username\nContraseña: $password',
                  ));
                  TopToast.showSuccess(context, 'Credenciales copiadas al portapapeles');
                },
                icon: const Icon(Icons.copy_rounded, size: 16),
                label: const Text('Copiar'),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  onDismiss();
                },
                child: const Text('Listo'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
