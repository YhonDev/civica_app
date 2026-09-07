import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _loadInitialPreferences();
    _checkAutoBiometrics();
  }

  Future<void> _loadInitialPreferences() async {
    final rememberEnabled = await BiometricAuthService.instance.isRememberUsernameEnabled();
    final savedUsername = await BiometricAuthService.instance.getRememberedUsername();
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
      await authCubit.checkSession(forceRestore: true);
      return;
    }

    final creds = await BiometricAuthService.instance.getBiometricCredentials();
    if (creds != null && creds['username'] != null && creds['password'] != null) {
      await authCubit.login(
        username: creds['username']!,
        password: creds['password']!,
      );
    } else {
      if (mounted) {
        TopToast.showInfo(
          context,
          'Inicia sesión con tu contraseña una vez para sincronizar tu huella',
        );
      }
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: colorScheme.surface,
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppBreakpoints.maxFormWidth,
                  ),
                  child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo / Icon
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.payments_rounded,
                          size: 44,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Título
                      Text(
                        'Cívica Pago',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Inicia sesión para continuar',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.outline,
                        ),
                      ),
                      const SizedBox(height: 36),

                      // Email / Username
                      TextFormField(
                        controller: _emailCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Nombre de usuario',
                          prefixIcon: Icon(Icons.person_outlined),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.text,
                        textCapitalization: TextCapitalization.none,
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
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Ingresa tu contraseña';
                          }
                          return null;
                        },
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _handleLogin(context),
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
                      SizedBox(
                        width: double.infinity,
                        height: 52,
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
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      if (_isBiometricsEnabled) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton.icon(
                            onPressed: _autenticarConHuella,
                            icon: const Icon(Icons.fingerprint_rounded, size: 22),
                            label: const Text('Ingresar con huella dactilar'),
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      if (kDebugMode) ...[
                        const Divider(),
                        const SizedBox(height: 12),
                        Text(
                          'Autocompletado de prueba',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.outline,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            ActionChip(
                              avatar: const Icon(Icons.admin_panel_settings_outlined, size: 16),
                              label: const Text('Admin'),
                              onPressed: () => setState(() {
                                _emailCtrl.text = 'admin';
                                _passwordCtrl.text = 'Admin2026!';
                              }),
                            ),
                            ActionChip(
                              avatar: const Icon(Icons.badge_outlined, size: 16),
                              label: const Text('Cobrador'),
                              onPressed: () => setState(() {
                                _emailCtrl.text = 'ricardoarrietacobrador';
                                _passwordCtrl.text = 'ricardoArrieta2026.';
                              }),
                            ),
                            ActionChip(
                              avatar: const Icon(Icons.home_outlined, size: 16),
                              label: const Text('Residente A'),
                              onPressed: () => setState(() {
                                _emailCtrl.text = 'manzana_a_casa_1_residente';
                                _passwordCtrl.text = 'Casa1ManzanaA..';
                              }),
                            ),
                            ActionChip(
                              avatar: const Icon(Icons.home_outlined, size: 16),
                              label: const Text('Residente B'),
                              onPressed: () => setState(() {
                                _emailCtrl.text = 'manzana_b_casa_1_residente';
                                _passwordCtrl.text = 'Casa1ManzanaB';
                              }),
                            ),
                            ActionChip(
                              avatar: const Icon(Icons.home_outlined, size: 16),
                              label: const Text('Residente C'),
                              onPressed: () => setState(() {
                                _emailCtrl.text = 'manzana_c_casa_1_residente';
                                _passwordCtrl.text = 'Casa1ManzanaC';
                              }),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
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

    // Guardar credenciales cifradas en Keystore para permitir acceso biométrico
    await BiometricAuthService.instance.saveBiometricCredentials(username, password);

    if (!context.mounted) return;
    context.read<AuthCubit>().login(
          username: username,
          password: password,
        );
  }
}
