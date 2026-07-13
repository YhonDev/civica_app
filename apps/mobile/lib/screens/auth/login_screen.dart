import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'auth_cubit.dart';

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

    // Usamos BlocBuilder en vez de BlocConsumer porque _AuthGate
    // en main.dart ya maneja la transición login → home mediante BlocBuilder.
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

                      // Email
                      TextFormField(
                        controller: _emailCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Correo electrónico',
                          prefixIcon: Icon(Icons.email_outlined),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        textCapitalization: TextCapitalization.none,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Ingresa tu correo';
                          }
                          if (!v.contains('@')) {
                            return 'Correo inválido';
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
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 12),
                      Text(
                        'Usuarios de prueba (Autocompletar)',
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
                            onPressed: () {
                              _emailCtrl.text = 'admin@civica.test';
                              _passwordCtrl.text = 'admin123';
                            },
                          ),
                          ActionChip(
                            avatar: const Icon(Icons.engineering_outlined, size: 16),
                            label: const Text('Cobrador (Juan)'),
                            onPressed: () {
                              _emailCtrl.text = 'juan.cobrador@test.com';
                              _passwordCtrl.text = 'admin123';
                            },
                          ),
                          ActionChip(
                            avatar: const Icon(Icons.home_outlined, size: 16),
                            label: const Text('Propietario (Juan)'),
                            onPressed: () {
                              _emailCtrl.text = 'juan@email.com';
                              _passwordCtrl.text = 'admin123';
                            },
                          ),
                        ],
                      ),
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
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
        );
  }
}
