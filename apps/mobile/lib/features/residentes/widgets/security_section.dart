import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/network/api_client.dart';

/// Sección de Seguridad reutilizable para residentes y cobradores.
///
/// Admin puede editar cualquier usuario (pasa [usuarioId]).
/// Residente/Cobrador edita sus propias credenciales (sin [usuarioId]).
class SecuritySection extends StatefulWidget {
  final String usuarioId;
  final String nombre;
  final String? initialUsername;
  final bool isAdmin;
  final VoidCallback? onCredentialsUpdated;

  const SecuritySection({
    super.key,
    required this.usuarioId,
    required this.nombre,
    this.initialUsername,
    this.isAdmin = false,
    this.onCredentialsUpdated,
  });

  @override
  State<SecuritySection> createState() => _SecuritySectionState();
}

class _SecuritySectionState extends State<SecuritySection> {
  final ApiClient _api = ApiClient.instance;
  
  bool _isEditingUsername = false;
  bool _isChangingPassword = false;
  bool _isLoading = false;

  late TextEditingController _usernameCtrl;
  final _currentPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _usernameCtrl = TextEditingController(text: widget.initialUsername ?? '');
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _currentPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _updateUsername() async {
    if (_usernameCtrl.text.trim().isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final payload = <String, dynamic>{
        'newUsername': _usernameCtrl.text.trim(),
      };
      if (widget.isAdmin) {
        payload['usuarioId'] = widget.usuarioId;
      }

      await _api.patch('/auth/credentials', data: payload);

      if (mounted) {
        setState(() => _isEditingUsername = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Usuario actualizado correctamente'),
            backgroundColor: AppColors.success,
          ),
        );
        widget.onCredentialsUpdated?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updatePassword() async {
    final newPass = _newPasswordCtrl.text;
    final confirmPass = _confirmPasswordCtrl.text;

    if (newPass.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La contraseña debe tener al menos 6 caracteres')),
      );
      return;
    }
    if (newPass != confirmPass) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Las contraseñas no coinciden')),
      );
      return;
    }

    // Si no es admin, pedir contraseña actual
    if (!widget.isAdmin && _currentPasswordCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa tu contraseña actual')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final payload = <String, dynamic>{
        'newPassword': newPass,
      };
      if (widget.isAdmin) {
        payload['usuarioId'] = widget.usuarioId;
      } else {
        payload['currentPassword'] = _currentPasswordCtrl.text;
      }

      await _api.patch('/auth/credentials', data: payload);

      if (mounted) {
        setState(() => _isChangingPassword = false);
        _currentPasswordCtrl.clear();
        _newPasswordCtrl.clear();
        _confirmPasswordCtrl.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Contraseña actualizada correctamente'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.shield_rounded, size: 20, color: AppColors.warning),
              const SizedBox(width: 8),
              Text(
                'Seguridad',
                style: AppTypography.subtitle.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Username section
          _buildUsernameSection(),
          const SizedBox(height: AppSpacing.md),

          // Password section
          _buildPasswordSection(),
        ],
      ),
    );
  }

  Widget _buildUsernameSection() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person_outline, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text('Usuario', style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600)),
              const Spacer(),
              if (!_isEditingUsername) ...[
                if (widget.initialUsername != null && widget.initialUsername!.isNotEmpty)
                  IconButton(
                    icon: Icon(Icons.copy_rounded, size: 18, color: AppColors.textSecondary),
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Copiar usuario',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: widget.initialUsername!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Usuario copiado al portapapeles'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                const SizedBox(width: 4),
                IconButton(
                  icon: Icon(Icons.edit_rounded, size: 18, color: AppColors.info),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => setState(() => _isEditingUsername = true),
                  tooltip: 'Editar usuario',
                ),
              ],
            ],
          ),
          if (_isEditingUsername) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _usernameCtrl,
                    decoration: InputDecoration(
                      hintText: 'Nuevo usuario',
                      hintStyle: AppTypography.body.copyWith(color: AppColors.textDisabled),
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      filled: true,
                      fillColor: AppColors.surface,
                    ),
                    style: AppTypography.bodyMedium,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.check_rounded, color: AppColors.success, size: 22),
                  visualDensity: VisualDensity.compact,
                  onPressed: _isLoading ? null : _updateUsername,
                  tooltip: 'Guardar',
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: AppColors.error, size: 22),
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    setState(() {
                      _isEditingUsername = false;
                      _usernameCtrl.text = widget.initialUsername ?? '';
                    });
                  },
                  tooltip: 'Cancelar',
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 4),
            Text(
              widget.initialUsername ?? 'Sin usuario',
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.info,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPasswordSection() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lock_outline, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text('Contraseña', style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600)),
              const Spacer(),
              if (!_isChangingPassword) ...[

                TextButton.icon(
                  icon: Icon(Icons.key_rounded, size: 18),
                  label: Text('Cambiar', style: AppTypography.small),
                  onPressed: () => setState(() => _isChangingPassword = true),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ],
            ],
          ),
          if (_isChangingPassword) ...[
            const SizedBox(height: 8),
            if (!widget.isAdmin) ...[
              TextField(
                controller: _currentPasswordCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Contraseña actual',
                  hintStyle: AppTypography.body.copyWith(color: AppColors.textDisabled),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                ),
                style: AppTypography.bodyMedium,
              ),
              const SizedBox(height: 8),
            ],
            TextField(
              controller: _newPasswordCtrl,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'Nueva contraseña (mín. 6 caracteres)',
                hintStyle: AppTypography.body.copyWith(color: AppColors.textDisabled),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                filled: true,
                fillColor: AppColors.surface,
              ),
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _confirmPasswordCtrl,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'Confirmar nueva contraseña',
                hintStyle: AppTypography.body.copyWith(color: AppColors.textDisabled),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                filled: true,
                fillColor: AppColors.surface,
              ),
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() => _isChangingPassword = false);
                    _currentPasswordCtrl.clear();
                    _newPasswordCtrl.clear();
                    _confirmPasswordCtrl.clear();
                  },
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _isLoading ? null : _updatePassword,
                  icon: _isLoading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.save_rounded, size: 18),
                  label: const Text('Guardar'),
                  style: FilledButton.styleFrom(backgroundColor: AppColors.warning),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 4),
            Text(
              '••••••••',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textDisabled,
                letterSpacing: 4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
