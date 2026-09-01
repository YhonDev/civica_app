import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/network/api_client.dart';
import '../../core/network/local_cache_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../features/auth/auth_cubit.dart';
import '../../shared/widgets/basic_information_section.dart';
import '../../shared/widgets/status_badge.dart';

import '../../core/widgets/lifecycle_observer_mixin.dart';

class MiCasaScreen extends StatefulWidget {
  const MiCasaScreen({super.key});

  @override
  State<MiCasaScreen> createState() => _MiCasaScreenState();
}

class _MiCasaScreenState extends State<MiCasaScreen> with LifecycleObserverMixin {
  bool _loading = true;
  String _casaDireccion = 'Casa 1';
  String _etapaNombre = 'Etapa 1';
  String _manzanaNombre = 'Manzana A';
  String _modalidadPago = '';
  String _proyectoNombre = 'Urbanización San Sebastián';
  StatusType _status = StatusType.alDia;

  @override
  void onAppResumed() {
    _cargarDatosInmueble();
  }

  @override
  void initState() {
    super.initState();
    _cargarDatosInmueble();
  }

  Future<void> _cargarDatosInmueble() async {
    if (LocalCacheRepository.instance.getCached('dashboard:residente') == null) {
      setState(() => _loading = true);
    }

    await LocalCacheRepository.instance.executeSWR<Map<String, dynamic>>(
      key: 'dashboard:residente',
      fetcher: () async {
        final response = await ApiClient.instance.get<Map<String, dynamic>>('/dashboard/residente');
        return response.data!;
      },
      onData: (data, isStale) {
        if (!mounted) return;
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
      },
      onError: (_) {
        if (mounted && LocalCacheRepository.instance.getCached('dashboard:residente') == null) {
          setState(() => _loading = false);
        }
      },
    );

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
    final usuarioId = user?['id'] ?? '';
    final username = user?['username'] ?? user?['email'] ?? '';

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
                  // Header Card (Soft Tinted Modern Style)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                      border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
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
                                color: AppColors.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.home_work_rounded, color: AppColors.primary, size: 26),
                            ),
                            StatusBadge(status: _status),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          _proyectoNombre,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          [
                            if (_manzanaNombre.isNotEmpty) _manzanaNombre,
                            if (_casaDireccion.isNotEmpty) _casaDireccion,
                            if (_etapaNombre.isNotEmpty) _etapaNombre,
                          ].join(' — '),
                          style: AppTypography.title.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // ── Módulo Atómico: Información de Ocupación ──
                  InformacionOcupacionSection(
                    nombre: nombre,
                    username: username,
                    modalidadPago: _modalidadPago,
                    email: email.isNotEmpty ? email : null,
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // ── Módulo Atómico: Detalles del Inmueble ──
                  DetalleInmuebleSection(
                    proyectoNombre: _proyectoNombre,
                    etapaNombre: _etapaNombre,
                    manzanaNombre: _manzanaNombre,
                    casaDireccion: _casaDireccion,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
    );
  }
}
