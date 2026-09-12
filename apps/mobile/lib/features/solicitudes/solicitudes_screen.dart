import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_breakpoints.dart';
import '../../shared/widgets/solicitud_card.dart';
import '../../shared/widgets/solicitud_bottom_sheet.dart';
import '../../shared/widgets/mini_stat_card.dart';
import '../../shared/widgets/empty_state.dart';
import '../../features/auth/auth_cubit.dart';
import '../../core/network/local_cache_repository.dart';
import 'solicitudes_repository.dart';

/// Pantalla de Solicitudes — Módulo completo.
///
/// Filosofía (AGENTS.md):
///   1. Resumen (Hero) — indicadores arriba
///   2. Filtros — después del resumen
///   3. Listado — información principal
///   4. Detalle — BottomSheet con acciones de admin
///   5. Estado inicial inteligente — Pendientes para admin
class SolicitudesScreen extends StatefulWidget {
  final String? solicitudId;
  /// Optional pre-configured repository (for testing).
  /// If null, a default [SolicitudesRepository] is created.
  final SolicitudesRepository? repository;

  const SolicitudesScreen({super.key, this.solicitudId, this.repository});

  @override
  State<SolicitudesScreen> createState() => _SolicitudesScreenState();
}

class _SolicitudesScreenState extends State<SolicitudesScreen>
    with TickerProviderStateMixin {
  List<SolicitudData> _solicitudes = [];
  bool _loading = true;
  late String _filtroActivo;
  bool _isAdmin = false;

  late final SolicitudesRepository _repo;

  // Stagger animations — same pattern as dashboard (250ms, 80ms delay)
  static const _sectionCount = 3; // hero, filters, list
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _fadeAnimations;
  late final List<Animation<Offset>> _slideAnimations;

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? SolicitudesRepository();
    _detectRole();
    _initAnimations();
    _loadSolicitudes();
  }

  void _detectRole() {
    final user = context.read<AuthCubit>().state.usuario;
    final rol = user?['rol'] as String? ?? '';
    _isAdmin = rol == 'ADMIN';
    // Smart default: admin sees pending first, residente sees all
    _filtroActivo = _isAdmin ? 'PENDIENTES' : 'TODAS';
  }

  void _initAnimations() {
    _controllers = List.generate(
      _sectionCount,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 250),
      ),
    );

    _fadeAnimations = _controllers
        .map((c) => CurvedAnimation(parent: c, curve: Curves.easeOutCubic))
        .map((c) => Tween<double>(begin: 0.0, end: 1.0).animate(c))
        .toList();

    _slideAnimations = _controllers
        .map((c) => CurvedAnimation(parent: c, curve: Curves.easeOutCubic))
        .map((c) =>
            Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
                .animate(c))
        .toList();

    _startStagger();
  }

  Future<void> _startStagger() async {
    for (var i = 0; i < _controllers.length; i++) {
      await Future.delayed(const Duration(milliseconds: 80));
      if (mounted) _controllers[i].forward();
    }
  }

  void _restartAnimations() {
    for (var c in _controllers) {
      c.reset();
    }
    _startStagger();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadSolicitudes() async {
    try {
      final list = _isAdmin
          ? await _repo.getSolicitudes(tipo: 'revision')
          : await _repo.getMisSolicitudes();
      if (mounted) {
        setState(() {
          _solicitudes = list;
          _loading = false;
        });
        _restartAnimations();

        if (widget.solicitudId != null) {
          SolicitudData? target;
          for (final s in list) {
            if (s.id == widget.solicitudId) {
              target = s;
              break;
            }
          }
          if (target != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _mostrarDetalle(target!);
            });
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading solicitudes: $e');
      }
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  // ── Computed stats ──────────────────────────────────────
  int get _pendientes => _solicitudes
      .where((s) =>
          s.estado == SolicitudEstado.pendiente ||
          s.estado == SolicitudEstado.enRevision ||
          s.estado == SolicitudEstado.enEspera)
      .length;
  int get _resueltas =>
      _solicitudes.where((s) => s.estado == SolicitudEstado.resuelta).length;
  int get _rechazadas =>
      _solicitudes.where((s) => s.estado == SolicitudEstado.rechazada).length;

  List<SolicitudData> get _solicitudesFiltradas {
    switch (_filtroActivo) {
      case 'PENDIENTES':
        return _solicitudes
            .where((s) =>
                s.estado == SolicitudEstado.pendiente ||
                s.estado == SolicitudEstado.enRevision ||
                s.estado == SolicitudEstado.enEspera)
            .toList();
      case 'RESUELTAS':
        return _solicitudes
            .where((s) => s.estado == SolicitudEstado.resuelta)
            .toList();
      case 'RECHAZADAS':
        return _solicitudes
            .where((s) => s.estado == SolicitudEstado.rechazada)
            .toList();
      case 'TODAS':
      default:
        return _solicitudes;
    }
  }

  Widget _buildAnimatedSection({required int index, required Widget child}) {
    if (index >= _controllers.length) return child;
    return FadeTransition(
      opacity: _fadeAnimations[index],
      child: SlideTransition(
        position: _slideAnimations[index],
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final listado = _solicitudesFiltradas;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isAdmin ? 'Gestión de Solicitudes' : 'Mis Solicitudes'),
        leading: IconButton(
          tooltip: 'Volver',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                color: AppColors.primary,
                onRefresh: _loadSolicitudes,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // 1. Hero — Resumen con MiniStatCards
                    SliverToBoxAdapter(
                      child: _buildAnimatedSection(
                        index: 0,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.screenPadding,
                            AppSpacing.md,
                            AppSpacing.screenPadding,
                            0,
                          ),
                          child: Row(
                            children: [
                              MiniStatCard(
                                icon: Icons.schedule_outlined,
                                label: 'Pendientes',
                                value: _pendientes.toString(),
                                color: AppColors.warning,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              MiniStatCard(
                                icon: Icons.check_circle_outlined,
                                label: 'Resueltas',
                                value: _resueltas.toString(),
                                color: AppColors.success,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              MiniStatCard(
                                icon: Icons.cancel_outlined,
                                label: 'Rechazadas',
                                value: _rechazadas.toString(),
                                color: AppColors.error,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // 2. Filtros (ChoiceChips)
                    SliverToBoxAdapter(
                      child: _buildAnimatedSection(
                        index: 1,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.screenPadding,
                            vertical: AppSpacing.md,
                          ),
                          child: Row(
                            children: [
                              _buildFilterChip('Todas', 'TODAS'),
                              const SizedBox(width: AppSpacing.sm),
                              _buildFilterChip('Pendientes', 'PENDIENTES'),
                              const SizedBox(width: AppSpacing.sm),
                              _buildFilterChip('Resueltas', 'RESUELTAS'),
                              const SizedBox(width: AppSpacing.sm),
                              _buildFilterChip('Rechazadas', 'RECHAZADAS'),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // 3. Listado
                    if (listado.isEmpty)
                      SliverToBoxAdapter(
                        child: _buildAnimatedSection(
                          index: 2,
                          child: const Padding(
                            padding: EdgeInsets.only(top: AppSpacing.xl),
                            child: Center(
                              child: EmptyState(
                                icon: Icons.description_outlined,
                                title: 'No hay solicitudes',
                                description:
                                    'No se encontraron solicitudes con este filtro.',
                              ),
                            ),
                          ),
                        ),
                      )
                    else if (context.isWideScreen)
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.screenPadding,
                        ),
                        sliver: SliverGrid(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: context.gridColumns,
                            mainAxisExtent: 115,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final solicitud = listado[index];
                              return SolicitudCard(
                                solicitud: solicitud,
                                onTap: () => _mostrarDetalle(solicitud),
                              );
                            },
                            childCount: listado.length,
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.screenPadding,
                        ),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final solicitud = listado[index];
                              return Padding(
                                padding: const EdgeInsets.only(
                                    bottom: AppSpacing.sm),
                                child: SolicitudCard(
                                  solicitud: solicitud,
                                  onTap: () => _mostrarDetalle(solicitud),
                                ),
                              );
                            },
                            childCount: listado.length,
                          ),
                        ),
                      ),

                    // Bottom spacing
                    const SliverToBoxAdapter(
                        child: SizedBox(height: AppSpacing.xl * 2)),
                  ],
                ),
              ),
      ),
      floatingActionButton: _isAdmin
          ? null
          : FloatingActionButton(
              onPressed: () async {
                final result = await context.push('/solicitud-nueva');
                if (result == true) _loadSolicitudes();
              },
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              shape: const CircleBorder(),
              child: const Icon(Icons.add_rounded, size: 24),
            ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filtroActivo == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _filtroActivo = value;
          });
        }
      },
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.onPrimary : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
      ),
      backgroundColor: AppColors.surface,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
      ),
    );
  }

  void _mostrarDetalle(SolicitudData solicitud) {
    SolicitudBottomSheet.show(
      context,
      solicitud,
      isAdmin: _isAdmin,
      onResolve: _isAdmin
          ? (estado, respuesta) async {
              await _repo.resolverSolicitud(
                id: solicitud.id,
                estado: estado,
                respuesta: respuesta,
              );
              await _loadSolicitudes();
            }
          : null,
      onDelete: () async {
        await _repo.eliminarSolicitud(solicitud.id);
        LocalCacheRepository.instance.invalidate('dashboard:residente');
        LocalCacheRepository.instance.invalidate('dashboard:cobrador');
        LocalCacheRepository.instance.invalidate('dashboard:administrador');
        await _loadSolicitudes();
      },
      onActionCompleted: () => _loadSolicitudes(),
    );
  }
}
