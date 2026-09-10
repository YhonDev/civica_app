import 'dart:async';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show TextInput;
import 'package:flutter_bloc/flutter_bloc.dart';

import 'auth_cubit.dart';
import '../../core/theme/app_breakpoints.dart';
import '../../core/security/biometric_auth_service.dart';
import '../../core/network/api_client.dart';
import '../../core/widgets/top_toast.dart';

/// Pantalla de inicio de sesión con JWT.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _isBiometricsEnabled = false;
  bool _rememberUser = false;
  Timer? _errorTimer;

  void _onFieldChanged() {
    _errorTimer?.cancel();
    context.read<AuthCubit>().clearError();
  }

  @override
  void initState() {
    super.initState();
    _loadInitialPreferences();
    _checkAutoBiometrics();
  }

  Future<void> _loadInitialPreferences() async {
    final rememberEnabled =
        await BiometricAuthService.instance.isRememberUsernameEnabled();
    final savedUsername =
        await BiometricAuthService.instance.getRememberedUsername();
    if (mounted) {
      setState(() {
        _rememberUser = rememberEnabled;
        if (savedUsername != null && savedUsername.isNotEmpty) {
          _emailCtrl.text = savedUsername;
          _emailCtrl.selection = TextSelection.fromPosition(
            TextPosition(offset: savedUsername.length),
          );
        }
      });
    }
  }

  Future<void> _checkAutoBiometrics() async {
    // La huella dactilar solo aplica a dispositivos móviles físicos (Android / iOS).
    // En Web y Desktop se desactiva para priorizar el login estándar y gestores de contraseñas.
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      return;
    }
    final isSupported =
        await BiometricAuthService.instance.isHardwareSupported();
    if (!isSupported) return;
    final enabled = await BiometricAuthService.instance.isBiometricsEnabled();
    if (mounted) {
      setState(() => _isBiometricsEnabled = enabled);
    }
  }

  Future<void> _autenticarConHuella() async {
    final success = await BiometricAuthService.instance.authenticate(
      localizedReason: 'Inicia sesión con tu huella dactilar',
    );
    if (!success || !mounted) return;

    final authCubit = context.read<AuthCubit>();
    final hasSession = await ApiClient.instance.isLoggedIn();
    if (hasSession) {
      // Desbloqueo passwordless: restaura la sesión con el refresh token.
      await authCubit.checkSession(forceRestore: true);
      return;
    }

    // Ya no se guardan contraseñas (security: nunca persistir la clave real).
    if (mounted) {
      TopToast.showInfo(
        context,
        'Inicia sesión con tu contraseña para activar el desbloqueo con huella',
      );
    }
  }

  @override
  void dispose() {
    _errorTimer?.cancel();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          _errorTimer?.cancel();
          _errorTimer = Timer(const Duration(seconds: 4), () {
            if (mounted) {
              context.read<AuthCubit>().clearError();
            }
          });
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: colorScheme.surface,
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: (constraints.maxHeight - 48).clamp(0.0, double.infinity),
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: AppBreakpoints.maxFormWidth,
                        ),
                        child: IntrinsicHeight(
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Spacer(flex: 1),
                                // Logo / Icon
                                Container(
                                  width: 84,
                                  height: 84,
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surface,
                                    borderRadius: BorderRadius.circular(22),
                                    boxShadow: [
                                      BoxShadow(
                                        color: colorScheme.primary.withValues(alpha: 0.12),
                                        blurRadius: 16,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.asset(
                                      'img/logo.png',
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, _, _) => Icon(
                                        Icons.payments_rounded,
                                        size: 44,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Nombre / Marca
                                Image.asset(
                                  'img/nombre1.png',
                                  height: 38,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, _, _) => Text(
                                    'Cuentiva',
                                    style: theme.textTheme.headlineMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Inicia sesión para continuar',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.outline,
                                  ),
                                ),
                                const SizedBox(height: 36),

                                // Email / Username
                                AutofillGroup(
                                  child: Column(
                                    children: [
                                      TextFormField(
                                        controller: _emailCtrl,
                                        autofillHints: const [AutofillHints.username],
                                        decoration: const InputDecoration(
                                          labelText: 'Nombre de usuario',
                                          prefixIcon: Icon(Icons.person_outlined),
                                          border: OutlineInputBorder(),
                                        ),
                                        keyboardType: TextInputType.text,
                                        textCapitalization: TextCapitalization.none,
                                        onChanged: (_) => _onFieldChanged(),
                                        validator: (v) {
                                          if (v == null || v.trim().isEmpty) {
                                            return 'Ingresa tu usuario';
                                          }
                                          return null;
                                        },
                                        textInputAction: TextInputAction.next,
                                      ),
                                      const SizedBox(height: 16),

                                      // Contraseña
                                      TextFormField(
                                        controller: _passwordCtrl,
                                        autofillHints: const [AutofillHints.password],
                                        onEditingComplete: () {
                                          // Cierra el grupo de autofill al terminar
                                          // (permite al gestor guardar/llenar). El login
                                          // real lo dispara onFieldSubmitted.
                                          TextInput.finishAutofillContext();
                                        },
                                        decoration: InputDecoration(
                                          labelText: 'Contraseña',
                                          prefixIcon: const Icon(Icons.lock_outlined),
                                          border: const OutlineInputBorder(),
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _obscurePassword
                                                  ? Icons.visibility_off_outlined
                                                  : Icons.visibility_outlined,
                                            ),
                                            onPressed: () => setState(
                                                () => _obscurePassword = !_obscurePassword),
                                          ),
                                        ),
                                        obscureText: _obscurePassword,
                                        onChanged: (_) => _onFieldChanged(),
                                        validator: (v) {
                                          if (v == null || v.isEmpty) {
                                            return 'Ingresa tu contraseña';
                                          }
                                          return null;
                                        },
                                        textInputAction: TextInputAction.done,
                                        onFieldSubmitted: (_) => _handleLogin(context),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // Recordar usuario Checkbox
                                Row(
                                  children: [
                                    SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: Checkbox(
                                        value: _rememberUser,
                                        onChanged: (val) {
                                          setState(() => _rememberUser = val ?? false);
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: () => setState(() => _rememberUser = !_rememberUser),
                                      child: Text(
                                        'Recordar usuario',
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // Error message
                                if (state.errorMessage != null)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Text(
                                      state.errorMessage!,
                                      style: TextStyle(color: colorScheme.error),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),

                                const SizedBox(height: 16),

                                // Botón de login
                                ConstrainedBox(
                                  constraints: const BoxConstraints(minHeight: 52),
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: FilledButton.icon(
                                      onPressed: state.status == AuthStatus.loading
                                          ? null
                                          : () => _handleLogin(context),
                                      icon: state.status == AuthStatus.loading
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Icon(Icons.login_rounded),
                                      label: Text(
                                        state.status == AuthStatus.loading
                                            ? 'Iniciando sesión...'
                                            : 'Iniciar sesión',
                                      ),
                                      style: FilledButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                if (_isBiometricsEnabled) ...[
                                  const SizedBox(height: 12),
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(minHeight: 48),
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton.icon(
                                        onPressed: _autenticarConHuella,
                                        icon: const Icon(Icons.fingerprint_rounded, size: 22),
                                        label: const Text('Ingresar con huella dactilar'),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 20,
                                            vertical: 12,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                                const Spacer(flex: 2),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _handleLogin(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    final username = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    // Guardar preferencia de recordar usuario
    await BiometricAuthService.instance.setRememberUsername(
      remember: _rememberUser,
      username: username,
    );

    // Nota de seguridad: la contraseña NUNCA se persiste. El re-login
    // biométrico restaura la sesión con el refresh token almacenado.

    if (!context.mounted) return;
    context.read<AuthCubit>().login(
          username: username,
          password: password,
        );
  }
}
