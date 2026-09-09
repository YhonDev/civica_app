import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/local_cache_repository.dart';
import '../../../core/security/biometric_auth_service.dart';
import '../../../core/widgets/top_toast.dart';
import '../../../features/auth/auth_cubit.dart';

/// Sección de Seguridad reutilizable para residentes y cobradores.
///
/// Admin puede editar cualquier usuario (pasa [usuarioId]).
/// Residente/Cobrador edita sus propias credenciales (sin [usuarioId]).
class SecuritySection extends StatefulWidget {
  final String usuarioId;
  final String nombre;
  final String? initialUsername;
  final bool isAdmin;
  final bool autoExpandPassword;
  final VoidCallback? onCredentialsUpdated;
  final VoidCallback? onCancel;

  const SecuritySection({
    super.key,
    required this.usuarioId,
    required this.nombre,
    this.initialUsername,
    this.isAdmin = false,
    this.autoExpandPassword = false,
    this.onCredentialsUpdated,
    this.onCancel,
  });

  @override
  State<SecuritySection> createState() => _SecuritySectionState();
}

class _SecuritySectionState extends State<SecuritySection> {
  final ApiClient _api = ApiClient.instance;

  bool _isEditingUsername = false;
  late bool _isChangingPassword;
  bool _isLoading = false;

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  late TextEditingController _usernameCtrl;
  final _currentPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _isChangingPassword = widget.autoExpandPassword;
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
    final newUsername = _usernameCtrl.text.trim();
    if (newUsername.isEmpty) {
      TopToast.showError(context, 'El nombre de usuario no puede estar vacío');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final payload = <String, dynamic>{
        'newUsername': newUsername,
      };
      if (widget.isAdmin) {
        payload['usuarioId'] = widget.usuarioId;
      }

      await _api.patch('/auth/credentials', data: payload);

      if (mounted) {
        setState(() => _isEditingUsername = false);
        if (!widget.isAdmin) {
          await BiometricAuthService.instance.setBiometricsEnabled(false);
          LocalCacheRepository.instance.invalidateAll();
          if (mounted) {
            TopToast.showSuccess(context, 'Usuario actualizado. Inicia sesión nuevamente.');
            context.read<AuthCubit>().logout();
          }
        } else {
          TopToast.showSuccess(context, 'Usuario actualizado correctamente');
          widget.onCredentialsUpdated?.call();
        }
      }
    } catch (e) {
      if (mounted) {
        TopToast.showError(context, 'Error al actualizar usuario: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String? _validarPasswordSegura(String pass) {
    if (pass.length < 8) {
      return 'La contraseña debe tener al menos 8 caracteres';
    }
    if (!pass.contains(RegExp(r'[A-Z]'))) {
      return 'Debe incluir al menos una letra mayúscula';
    }
    if (!pass.contains(RegExp(r'[a-z]'))) {
      return 'Debe incluir al menos una letra minúscula';
    }
    if (!pass.contains(RegExp(r'[0-9]'))) {
      return 'Debe incluir al menos un número';
    }
    if (!pass.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Debe incluir al menos un símbolo (!@#\$%^&*)';
    }
    return null;
  }

  Future<void> _updatePassword() async {
    final newPass = _newPasswordCtrl.text;
    final confirmPass = _confirmPasswordCtrl.text;

    final errorValidacion = _validarPasswordSegura(newPass);
    if (errorValidacion != null) {
      TopToast.showError(context, errorValidacion);
      return;
    }

    if (newPass != confirmPass) {
      TopToast.showError(context, 'Las contraseñas no coinciden');
      return;
    }

    if (!widget.isAdmin && _currentPasswordCtrl.text.isEmpty) {
      TopToast.showError(context, 'Ingresa tu contraseña actual');
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
        
        if (!widget.isAdmin) {
          await BiometricAuthService.instance.setBiometricsEnabled(false);
          LocalCacheRepository.instance.invalidateAll();
          if (mounted) {
            TopToast.showSuccess(context, 'Contraseña actualizada. Inicia sesión con tu nueva contraseña.');
            context.read<AuthCubit>().logout();
          }
        } else {
          TopToast.showSuccess(context, 'Contraseña actualizada correctamente');
        }
      }
    } catch (e) {
      if (mounted) {
        TopToast.showError(context, 'Error al actualizar contraseña: $e');
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
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield_rounded, size: 20, color: AppColors.warning),
              const SizedBox(width: 8),
              Text(
                'Seguridad & Credenciales',
                style: AppTypography.subtitle.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          _buildUsernameSection(),
          const SizedBox(height: AppSpacing.md),

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
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
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
                    icon: Icon(Icons.copy_rounded, size: 18, color: AppColors.primary),
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Copiar usuario',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: widget.initialUsername!));
                      TopToast.showSuccess(context, 'Usuario copiado al portapapeles');
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
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
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
                  icon: Icon(Icons.key_rounded, size: 18, color: AppColors.primary),
                  label: Text('Cambiar', style: AppTypography.small.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                  onPressed: () => setState(() => _isChangingPassword = true),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
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
                obscureText: _obscureCurrent,
                decoration: InputDecoration(
                  hintText: 'Contraseña actual',
                  hintStyle: AppTypography.body.copyWith(color: AppColors.textDisabled),
                  isDense: true,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureCurrent ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                  ),
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
              obscureText: _obscureNew,
              decoration: InputDecoration(
                hintText: 'Nueva contraseña (mín. 8 chars, 1 Mayús, 1 Núm, 1 Símbolo)',
                hintStyle: AppTypography.label.copyWith(color: AppColors.textDisabled, fontWeight: FontWeight.w400),
                isDense: true,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscureNew = !_obscureNew),
                ),
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
              obscureText: _obscureConfirm,
              decoration: InputDecoration(
                hintText: 'Confirmar nueva contraseña',
                hintStyle: AppTypography.label.copyWith(color: AppColors.textDisabled, fontWeight: FontWeight.w400),
                isDense: true,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                ),
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
                    if (widget.onCancel != null) {
                      widget.onCancel!();
                    } else {
                      setState(() => _isChangingPassword = false);
                      _currentPasswordCtrl.clear();
                      _newPasswordCtrl.clear();
                      _confirmPasswordCtrl.clear();
                    }
                  },
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _isLoading ? null : _updatePassword,
                  icon: _isLoading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save_rounded, size: 18),
                  label: const Text('Guardar'),
                  style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
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
