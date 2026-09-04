import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'auth_cubit.dart';
import '../../core/security/biometric_auth_service.dart';
import '../../core/network/api_client.dart';

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

  @override
  void initState() {
    super.initState();
    _checkAutoBiometrics();
  }

  Future<void> _checkAutoBiometrics() async {
    final enabled = await BiometricAuthService.instance.isBiometricsEnabled();
    if (mounted) {
      setState(() => _isBiometricsEnabled = enabled);
      if (enabled) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _autenticarConHuella();
        });
      }
    }
  }

  Future<void> _autenticarConHuella() async {
    final success = await BiometricAuthService.instance.authenticate(
      localizedReason: 'Inicia sesión con tu huella dactilar o Face ID',
    );
    if (success && mounted) {
      final authCubit = context.read<AuthCubit>();
      final hasSession = await ApiClient.instance.isLoggedIn();
      if (mounted && hasSession) {
        await authCubit.checkSession();
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
                padding: const EdgeInsets.symmetric(horizontal: 32),
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
                            label: const Text('Ingresar con Huella dactilar / Face ID'),
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
        );
      },
    );
  }

  void _handleLogin(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;

    context.read<AuthCubit>().login(
          username: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
        );
  }
}
