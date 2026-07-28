import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../screens/auth/auth_cubit.dart';
import '../../shared/widgets/status_badge.dart';

class MiCasaScreen extends StatefulWidget {
  const MiCasaScreen({super.key});

  @override
  State<MiCasaScreen> createState() => _MiCasaScreenState();
}

class _MiCasaScreenState extends State<MiCasaScreen> {
  bool _loading = true;
  String _casaDireccion = 'Casa 1';
  String _etapaNombre = 'Etapa 1';
  String _manzanaNombre = 'Manzana A';
  String _modalidadPago = 'Semanal';
  String _proyectoNombre = 'Urbanización San Sebastián';
  StatusType _status = StatusType.alDia;

  @override
  void initState() {
    super.initState();
    _cargarDatosInmueble();
  }

  Future<void> _cargarDatosInmueble() async {
    try {
      final response = await ApiClient.instance.get<Map<String, dynamic>>('/dashboard/propietario');
      if (mounted && response.data != null) {
        final data = response.data!;
        final resInfo = data['residenteInfo'] as Map<String, dynamic>? ?? {};

        final statusStr = data['status'] as String? ?? 'AL_DIA';
        final statusEnum = switch (statusStr) {
          'AL_DIA' => StatusType.alDia,
          'PENDIENTE' => StatusType.pendiente,
          'MORA' => StatusType.mora,
          _ => StatusType.alDia,
        };

        setState(() {
          if ((resInfo['casaDireccion'] as String?)?.isNotEmpty ?? false) {
            _casaDireccion = resInfo['casaDireccion'] as String;
          }
          if ((resInfo['etapaNombre'] as String?)?.isNotEmpty ?? false) {
            _etapaNombre = resInfo['etapaNombre'] as String;
          }
          if ((resInfo['manzanaNombre'] as String?)?.isNotEmpty ?? false) {
            _manzanaNombre = resInfo['manzanaNombre'] as String;
          }
          if ((resInfo['modalidadPago'] as String?)?.isNotEmpty ?? false) {
            _modalidadPago = resInfo['modalidadPago'] as String;
          }
          _status = statusEnum;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }

    // Cargar nombre del proyecto real
    try {
      final resProj = await ApiClient.instance.get<Map<String, dynamic>>('/proyectos/actual');
      if (mounted && resProj.data != null && (resProj.data!['nombre'] as String?)?.isNotEmpty == true) {
        setState(() {
          _proyectoNombre = resProj.data!['nombre'] as String;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.watch<AuthCubit>().state.usuario;

    final nombre = user?['nombre'] ?? 'Residente';
    final email = user?['email'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Casa'),
        centerTitle: false,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryDark.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.home_rounded, color: Colors.white, size: 28),
                            ),
                            StatusBadge(status: _status),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          _proyectoNombre,
                          style: AppTypography.subtitle.copyWith(color: Colors.white.withValues(alpha: 0.9)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$_casaDireccion — $_etapaNombre',
                          style: AppTypography.title.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Resident Info Section
                  Text('Información de Ocupación', style: AppTypography.subtitle.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: AppSpacing.sm),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.person_outline_rounded),
                          title: const Text('Titular / Residente'),
                          subtitle: Text(nombre),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.alternate_email_rounded),
                          title: const Text('Correo registrado'),
                          subtitle: Text(email.isNotEmpty ? email : 'No se ha agregado correo'),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.badge_outlined),
                          title: const Text('Modalidad de Pago'),
                          subtitle: Text(_modalidadPago),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // History of tenancy / info
                  Text('Detalles del Inmueble', style: AppTypography.subtitle.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: AppSpacing.sm),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.location_on_outlined),
                          title: const Text('Etapa'),
                          subtitle: Text(_etapaNombre),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.apartment_rounded),
                          title: const Text('Manzana'),
                          subtitle: Text(_manzanaNombre),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.home_outlined),
                          title: const Text('Dirección de Inmueble'),
                          subtitle: Text(_casaDireccion),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
