import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../screens/auth/auth_cubit.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exceptions.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_theme.dart';

class ConfiguracionScreen extends StatefulWidget {
  const ConfiguracionScreen({super.key});

  @override
  State<ConfiguracionScreen> createState() => _ConfiguracionScreenState();
}

class _ConfiguracionScreenState extends State<ConfiguracionScreen> {
  String? _proyectoNombreBackend;
  String _casaDireccion = 'Casa 1';
  String _ubicacion = 'Etapa 1 — Manzana A';
  String _modalidadPago = 'Semanal';

  @override
  void initState() {
    super.initState();
    _cargarDatosBackend();
  }

  Future<void> _cargarDatosBackend() async {
    try {
      final resProj = await ApiClient.instance.get<Map<String, dynamic>>('/proyectos/actual');
      if (mounted && resProj.data != null) {
        final nombreBackend = resProj.data!['nombre'] as String?;
        if (nombreBackend != null && nombreBackend.isNotEmpty) {
          setState(() {
            _proyectoNombreBackend = nombreBackend;
          });
        }
      }
    } catch (_) {}

    try {
      final resProp = await ApiClient.instance.get<Map<String, dynamic>>('/dashboard/propietario');
      if (mounted && resProp.data != null) {
        final resInfo = resProp.data!['residenteInfo'] as Map<String, dynamic>? ?? {};
        final dir = resInfo['casaDireccion'] as String?;
        final etapa = resInfo['etapaNombre'] as String?;
        final manzana = resInfo['manzanaNombre'] as String?;
        final mod = resInfo['modalidadPago'] as String?;

        setState(() {
          if (dir != null && dir.isNotEmpty) _casaDireccion = dir;
          if (etapa != null && manzana != null && etapa.isNotEmpty && manzana.isNotEmpty) {
            _ubicacion = '$etapa — $manzana';
          }
          if (mod != null && mod.isNotEmpty) _modalidadPago = mod;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthCubit>().state.usuario;
    final nombre = user?['nombre'] as String? ?? 'Usuario';
    final email = user?['email'] as String? ?? '';
    final rol = user?['rol'] as String? ?? '';
    final tenantId = user?['tenantId'] as String? ?? '';

    final rolLabel = _rolName(rol);
    final isPropietario = rol == 'PROPIETARIO' || rol == 'RESIDENTE';

    // Obtención dinámica del nombre del proyecto desde el backend
    final proyectoNombre = _proyectoNombreBackend ??
        ((tenantId.isEmpty || tenantId.contains('-'))
            ? 'Urbanización San Sebastián'
            : tenantId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: AppSpacing.xl),

              // Avatar
              CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                child: Text(
                  nombre.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join(),
                  style: AppTypography.title.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Name and Role
              Text(
                nombre,
                style: AppTypography.subtitle.copyWith(
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
                  rolLabel,
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
                    icon: Icons.email_outlined,
                    label: 'Correo registrado',
                    value: email.isNotEmpty ? email : 'No se ha agregado correo',
                  ),
                  const Divider(height: 1, indent: 56),
                  _InfoTile(
                    icon: Icons.business_outlined,
                    label: 'Proyecto / Urbanización',
                    value: proyectoNombre,
                  ),
                ],
              ),

              if (isPropietario) ...[
                const SizedBox(height: AppSpacing.lg),
                _SectionCard(
                  title: 'Mi Casa',
                  children: [
                    _InfoTile(
                      icon: Icons.home_outlined,
                      label: 'Dirección de Inmueble',
                      value: _casaDireccion,
                    ),
                    const Divider(height: 1, indent: 56),
                    _InfoTile(
                      icon: Icons.location_on_outlined,
                      label: 'Ubicación',
                      value: _ubicacion,
                    ),
                    const Divider(height: 1, indent: 56),
                    _InfoTile(
                      icon: Icons.calendar_month_outlined,
                      label: 'Modalidad de Pago',
                      value: _modalidadPago,
                    ),
                  ],
                ),
              ],

              // Herramientas según rol
              if (rol == 'COBRADOR' || rol == 'ADMIN') ...[
                const SizedBox(height: AppSpacing.lg),
                _SectionCard(
                  title: 'Herramientas',
                  children: [
                    if (rol == 'COBRADOR')
                      ListTile(
                        leading: const Icon(Icons.cloud_sync_outlined),
                        title: const Text('Cola de Sincronización'),
                        subtitle: const Text('Ver pagos pendientes de envío'),
                        trailing: Icon(Icons.chevron_right_rounded, color: AppColors.textDisabled),
                        onTap: () => context.push('/sync-queue'),
                      ),
                    if (rol == 'ADMIN')
                      ListTile(
                        leading: const Icon(Icons.mail_lock_outlined),
                        title: const Text('Notificaciones Fallidas'),
                        subtitle: const Text('Revisar correos no entregados'),
                        trailing: Icon(Icons.chevron_right_rounded, color: AppColors.textDisabled),
                        onTap: () => context.push('/notificaciones-fallidas'),
                      ),
                  ],
                ),
              ],

              const SizedBox(height: AppSpacing.lg),

              // Configuration / Settings
              _SectionCard(
                title: 'Ajustes del Sistema',
                children: [
                  ValueListenableBuilder<bool>(
                    valueListenable: darkThemeNotifier,
                    builder: (context, isDark, _) {
                      return ListTile(
                        leading: const Icon(Icons.palette_outlined),
                        title: const Text('Tema oscuro'),
                        trailing: Switch(
                          value: isDark,
                          onChanged: (value) {
                            darkThemeNotifier.value = value;
                          },
                          activeThumbColor: AppColors.primary,
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.lock_outlined),
                    title: const Text('Cambiar contraseña'),
                    subtitle: const Text('Actualiza tu clave de acceso'),
                    trailing: Icon(Icons.chevron_right_rounded, color: AppColors.textDisabled),
                    onTap: () => _mostrarModalCambiarPassword(context),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.xl),

              // Botón rojo para Cerrar Sesión
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    context.read<AuthCubit>().logout();
                  },
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text('Cerrar sesión'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: BorderSide(
                      color: AppColors.error.withValues(alpha: 0.3),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarModalCambiarPassword(BuildContext context) {
    final passActualController = TextEditingController();
    final passNuevaController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool cargando = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateModal) {
          return Padding(
            padding: EdgeInsets.only(
              left: AppSpacing.screenPadding,
              right: AppSpacing.screenPadding,
              top: AppSpacing.lg,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.xl,
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cambiar contraseña',
                    style: AppTypography.subtitle.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Ingresa tu contraseña actual y define la nueva contraseña.',
                    style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  TextFormField(
                    controller: passActualController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Contraseña actual',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? 'Ingresa tu clave actual' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  TextFormField(
                    controller: passNuevaController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Nueva contraseña',
                      prefixIcon: Icon(Icons.lock_reset),
                    ),
                    validator: (v) {
                      if (v == null || v.length < 6) {
                        return 'La clave debe tener al menos 6 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: cargando
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) return;
                              setStateModal(() => cargando = true);

                              try {
                                await ApiClient.instance.patch(
                                  '/auth/credentials',
                                  data: {
                                    'currentPassword': passActualController.text,
                                    'newPassword': passNuevaController.text,
                                  },
                                );

                                if (ctx.mounted) {
                                  Navigator.of(ctx).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text('Contraseña actualizada correctamente.'),
                                      backgroundColor: AppColors.success,
                                    ),
                                  );
                                }
                              } catch (e) {
                                setStateModal(() => cargando = false);
                                final msg = e is ApiException ? e.message : 'Error al actualizar contraseña.';
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(
                                      content: Text(msg),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                }
                              }
                            },
                      child: cargando
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Guardar Contraseña'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _rolName(String rol) {
    switch (rol) {
      case 'ADMIN':
        return 'Administrador';
      case 'COBRADOR':
        return 'Cobrador';
      case 'PROPIETARIO':
      case 'RESIDENTE':
        return 'Residente';
      default:
        return rol;
    }
  }
}

class _SectionCard extends StatelessWidget {
  final String? title;
  final List<Widget> children;

  const _SectionCard({this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.sm),
            child: Text(
              title!,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
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
