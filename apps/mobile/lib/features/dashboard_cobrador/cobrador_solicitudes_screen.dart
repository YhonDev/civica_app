import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_breakpoints.dart';
import '../../shared/widgets/empty_state.dart';
import '../cartera/models/cartera_models.dart';
import '../cartera/widgets/registrar_pago_bottom_sheet.dart';
import 'casas_cubit.dart';
import 'dashboard_cobrador_cubit.dart';
import 'widgets/cobrador_solicitud_card.dart';

/// Pantalla Completa e Independiente de Solicitudes para el Rol Cobrador.
///
/// Filosofía del módulo (AGENTS.md):
/// - Centro de Operaciones específico para todas las solicitudes activas de la ruta.
/// - Orden cronológico estricto FIFO (la más antigua arriba con prioridad).
/// - Filtros rápidos: "Todas", "En espera", "En camino".
/// - Ciclo de vida: 'En camino' -> 'Cobrar' -> Resolución automática al registrar pago.
class CobradorSolicitudesScreen extends StatefulWidget {
  const CobradorSolicitudesScreen({super.key});

  @override
  State<CobradorSolicitudesScreen> createState() => _CobradorSolicitudesScreenState();
}

class _CobradorSolicitudesScreenState extends State<CobradorSolicitudesScreen> {
  String _filtroEstado = 'TODAS'; // 'TODAS', 'EN_ESPERA', 'EN_CAMINO'
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Asegurar carga de datos frescos al entrar a la pantalla
    final cubit = context.read<CasasCubit>();
    if (cubit.state is! ViviendasLoaded) {
      cubit.loadViviendas();
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.screenBackground,
      appBar: AppBar(
        title: const Text('Solicitudes de Cobro'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualizar',
            onPressed: () {
              context.read<CasasCubit>().refresh();
              try {
                context.read<DashboardCobradorCubit>().refresh();
              } catch (_) {}
            },
          ),
        ],
      ),
      body: BlocBuilder<CasasCubit, CasasState>(
        builder: (context, state) {
          if (state is ViviendasLoading && state is! ViviendasLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ViviendasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
                    const SizedBox(height: AppSpacing.md),
                    Text(state.message, style: AppTypography.body, textAlign: TextAlign.center),
                    const SizedBox(height: AppSpacing.md),
                    ElevatedButton(
                      onPressed: () => context.read<CasasCubit>().refresh(),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }

          final allSolicitudes = state is ViviendasLoaded ? state.solicitudes : <Map<String, dynamic>>[];

          // Conteo para chips de filtro
          final totalCount = allSolicitudes.length;
          final enEsperaCount = allSolicitudes.where((s) => (s['estado'] as String? ?? '') != 'EN_CAMINO').length;
          final enCaminoCount = allSolicitudes.where((s) => (s['estado'] as String? ?? '') == 'EN_CAMINO').length;

          // Filtrar lista
          final filtered = allSolicitudes.where((s) {
            final estado = (s['estado'] as String? ?? '').toUpperCase();
            if (_filtroEstado == 'EN_ESPERA' && estado == 'EN_CAMINO') return false;
            if (_filtroEstado == 'EN_CAMINO' && estado != 'EN_CAMINO') return false;

            if (_searchQuery.isNotEmpty) {
              final q = _searchQuery.toLowerCase();
              final nombre = (s['residenteNombre'] as String? ?? '').toLowerCase();
              final casa = (s['casaDireccion'] as String? ?? '').toLowerCase();
              final manzana = (s['manzanaNombre'] as String? ?? '').toLowerCase();
              final nota = (s['descripcion'] as String? ?? '').toLowerCase();
              if (!nombre.contains(q) && !casa.contains(q) && !manzana.contains(q) && !nota.contains(q)) {
                return false;
              }
            }

            return true;
          }).toList();

          return RefreshIndicator(
            onRefresh: () async {
              await context.read<CasasCubit>().refresh();
              if (context.mounted) {
                await context.read<DashboardCobradorCubit>().refresh();
              }
            },
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              children: [
                // Barra de búsqueda rápida
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.cobradorCard,
                    borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (val) => setState(() => _searchQuery = val.trim()),
                    decoration: InputDecoration(
                      hintText: 'Buscar por residente, casa o manzana...',
                      hintStyle: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                      prefixIcon: Icon(Icons.search_rounded, size: 20, color: AppColors.textSecondary),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              tooltip: 'Limpiar búsqueda',
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 12),
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // Filtros por Estado
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('TODAS', 'Todas ($totalCount)'),
                      const SizedBox(width: AppSpacing.xs),
                      _buildFilterChip('EN_ESPERA', 'En espera ($enEsperaCount)'),
                      const SizedBox(width: AppSpacing.xs),
                      _buildFilterChip('EN_CAMINO', 'En camino ($enCaminoCount)'),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // Resumen / Info de la ruta
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${filtered.length} ${filtered.length == 1 ? 'solicitud' : 'solicitudes'} en orden FIFO',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'La más antigua arriba',
                      style: AppTypography.small.copyWith(
                        color: AppColors.primary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.sm),

                if (filtered.isEmpty) ...[
                  const SizedBox(height: AppSpacing.xl),
                  EmptyState(
                    title: totalCount == 0 ? 'Sin solicitudes activas' : 'Sin coincidencias',
                    description: totalCount == 0
                        ? 'No hay solicitudes de residentes pendientes por cobro en tu ruta.'
                        : 'No encontramos solicitudes para el filtro seleccionado.',
                    icon: Icons.mark_email_read_rounded,
                  ),
                ] else if (context.isWideScreen) ...[
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: context.gridColumns,
                      mainAxisExtent: 190,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemBuilder: (context, index) {
                      final solicitud = filtered[index];
                      final id = solicitud['id'] as String? ?? '';
                      return CobradorSolicitudCard(
                        solicitud: solicitud,
                        compact: false,
                        ordenFifo: index + 1,
                        onMarcarEnCamino: () {
                          context.read<CasasCubit>().cambiarEstadoSolicitud(id, 'EN_CAMINO');
                          try {
                            context.read<DashboardCobradorCubit>().cambiarEstadoSolicitud(id, 'EN_CAMINO');
                          } catch (_) {}
                        },
                        onCobrar: () => _abrirCobroBottomSheet(context, solicitud),
                      );
                    },
                  ),
                ] else ...[
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final solicitud = filtered[index];
                      final id = solicitud['id'] as String? ?? '';

                      return CobradorSolicitudCard(
                        solicitud: solicitud,
                        compact: false,
                        ordenFifo: index + 1,
                        onMarcarEnCamino: () {
                          context.read<CasasCubit>().cambiarEstadoSolicitud(id, 'EN_CAMINO');
                          try {
                            context.read<DashboardCobradorCubit>().cambiarEstadoSolicitud(id, 'EN_CAMINO');
                          } catch (_) {}
                        },
                        onCobrar: () => _abrirCobroBottomSheet(context, solicitud),
                      );
                    },
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String filtro, String label) {
    final isSelected = _filtroEstado == filtro;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _filtroEstado = filtro);
      },
      selectedColor: AppColors.primary.withValues(alpha: 0.15),
      labelStyle: AppTypography.caption.copyWith(
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.primary : AppColors.border,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
      visualDensity: VisualDensity.compact,
    );
  }

  void _abrirCobroBottomSheet(BuildContext context, Map<String, dynamic> solicitud) {
    final saldo = (solicitud['saldo'] as num? ?? 20000.0).toDouble();
    final nombreResidente = solicitud['residenteNombre'] as String? ?? 'Residente';

    final cobroItem = CobroItem(
      id: solicitud['cobroId'] as String? ?? solicitud['casaId'] as String? ?? '0',
      concepto: 'Cuota de Recaudo',
      monto: (solicitud['monto'] as num? ?? 20000.0).toDouble(),
      montoPagado: 0,
      saldo: saldo,
      estado: solicitud['cobroEstado'] as String? ?? 'PENDIENTE',
      modalidad: solicitud['modalidadPago'] as String? ?? 'Mensual',
      casa: solicitud['casaDireccion'] as String? ?? '',
      manzana: solicitud['manzanaNombre'] as String? ?? '',
      etapa: solicitud['etapaNombre'] as String? ?? '',
      residenteId: solicitud['residenteId'] as String? ?? '',
      nombre: nombreResidente,
    );

    RegistrarPagoBottomSheet.show(
      context,
      cobro: cobroItem,
      initialQuickMode: true,
      onSuccess: () {
        context.read<CasasCubit>().refresh();
        try {
          context.read<DashboardCobradorCubit>().optimisticRegistrarPago(
                residenteId: cobroItem.residenteId,
                montoPesos: saldo > 0 ? saldo.toInt() : 20000,
              );
          context.read<DashboardCobradorCubit>().refresh(silent: true);
        } catch (_) {}
      },
    );
  }
}
