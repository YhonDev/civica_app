import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_feedback.dart';
import '../../core/widgets/lifecycle_observer_mixin.dart';
import '../cartera/models/cartera_models.dart';
import '../cartera/widgets/registrar_pago_bottom_sheet.dart';
import 'dashboard_cobrador_cubit.dart';
import 'casas_cubit.dart';
import 'widgets/cobrador_solicitud_card.dart';
import '../../shared/widgets/screen_header.dart';

/// Rutas Explorer — Navegador de Recorrido Continuo de Caminata para Cobrador (P05).
///
/// Principios de Dominio Cívica Pago:
///   - El cobrador no busca casas; recorre un territorio por Etapas y Manzanas.
///   - Pestañas de selección por Sector / Etapa con contadores de cobros en tiempo real.
///   - Toggle de Sentido In Situ que calcula dinámicamente el rango real de manzanas (ej. Mz A ➔ Mz G vs Mz G ➔ Mz A).
///   - Flujo Lineal Continuo sin acordeones plegables obligatorios.
class CasasExplorerScreen extends StatelessWidget {
  final CasasCubit? cubit;

  const CasasExplorerScreen({super.key, this.cubit});

  @override
  Widget build(BuildContext context) {
    if (cubit != null) {
      return BlocProvider<CasasCubit>.value(
        value: cubit!,
        child: const _CasasExplorerView(),
      );
    }
    try {
      context.read<CasasCubit>();
      return const _CasasExplorerView();
    } catch (_) {
      return BlocProvider<CasasCubit>(
        create: (_) => CasasCubit()..loadViviendas(),
        child: const _CasasExplorerView(),
      );
    }
  }
}

sealed class _TerritorioItem {}

class _EtapaItem extends _TerritorioItem {
  final String nombre;
  _EtapaItem(this.nombre);
}

class _ManzanaItem extends _TerritorioItem {
  final String nombre;
  final int count;
  _ManzanaItem(this.nombre, this.count);
}

class _CasaItem extends _TerritorioItem {
  final CasaExplorer casa;
  final String etapaNombre;
  final String manzanaNombre;
  _CasaItem(this.casa, this.etapaNombre, this.manzanaNombre);
}

class _CasasExplorerView extends StatefulWidget {
  const _CasasExplorerView();

  @override
  State<_CasasExplorerView> createState() => _CasasExplorerViewState();
}

class _CasasExplorerViewState extends State<_CasasExplorerView> with LifecycleObserverMixin {
  String _selectedEtapaId = 'TODAS'; // 'TODAS' o id específico de Etapa
  bool _sentidoInverso = false; // false: Directo, true: Inverso
  String _filtroEstado = 'PENDIENTES'; // PENDIENTES, MORA, TODOS

  @override
  void onAppResumed() {
    context.read<CasasCubit>().loadViviendas(silent: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ScreenHeader(title: 'Rutas y Solicitudes'),
            Expanded(
              child: BlocBuilder<CasasCubit, CasasState>(
                builder: (context, state) {
                  if (state is ViviendasLoading || state is ViviendasInitial) {
                    return _buildSkeletonLoading();
                  } else if (state is ViviendasLoaded) {
                    return _buildContent(state.etapas, state.solicitudes);
                  }
                  return _buildError((state as ViviendasError).message);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Skeleton Loading ──────────────────────────────────────────────

  Widget _buildSkeletonLoading() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          children: List.generate(4, (i) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Container(
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              ),
            ),
          )),
        ),
      ),
    );
  }

  // ── Content ───────────────────────────────────────────────────────

  Widget _buildContent(List<EtapaExplorer> etapas, List<Map<String, dynamic>> solicitudes) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final processedEtapas = _procesarRutaCaminata(etapas);
    final territorioItems = _flattenTerritorioItems(processedEtapas);

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => context.read<CasasCubit>().refresh(),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPadding,
              AppSpacing.screenPadding,
              AppSpacing.screenPadding,
              0,
            ),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Contexto Temporal: Semana Actual ────────────────────
                  _buildWeekContextBanner(isDark),

                  const SizedBox(height: AppSpacing.lg),

                  // ── SECCIÓN 1: Solicitudes de Cobro ──────────────────────
                  _buildSolicitudesSection(solicitudes, isDark),

                  const SizedBox(height: AppSpacing.lg),

                  // ── SECCIÓN 2: Recorrido Programado por Territorio ───────
                  _buildRecorridoHeader(etapas, solicitudes),

                  const SizedBox(height: AppSpacing.sm),

                  // Selector por Sector / Etapa
                  _buildEtapaFilterChips(etapas),

                  const SizedBox(height: AppSpacing.sm),

                  // Toggle Dinámico de Sentido de Caminata (calculado según DB)
                  _buildSentidoToggle(etapas, isDark),

                  const SizedBox(height: AppSpacing.sm),

                  // Filtros Rápidos de Cobro (Pendientes, Mora, Todos)
                  _buildFiltroEstadoChips(),

                  const SizedBox(height: AppSpacing.md),
                ],
              ),
            ),
          ),

          // Lista Lineal Continua de Caminata Virtualizada
          if (territorioItems.isEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
              sliver: SliverToBoxAdapter(
                child: _buildEmptyTerritorioState(),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
              sliver: SliverList.builder(
                itemCount: territorioItems.length,
                itemBuilder: (context, index) {
                  final item = territorioItems[index];
                  return switch (item) {
                    _EtapaItem(:final nombre) => _buildEtapaHeader(nombre),
                    _ManzanaItem(:final nombre, :final count) => _buildManzanaHeader(nombre, count),
                    _CasaItem(:final casa, :final etapaNombre, :final manzanaNombre) =>
                      _buildCasaItem(casa, etapaNombre, manzanaNombre),
                  };
                },
              ),
            ),

          const SliverToBoxAdapter(
            child: SizedBox(height: AppSpacing.xl),
          ),
        ],
      ),
    );
  }

  // ── Contexto Temporal (Semana Corriendo) ───────────────────────────

  Widget _buildWeekContextBanner(bool isDark) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    final startStr = DateFormat("d 'de' MMM", 'es').format(startOfWeek);
    final endStr = DateFormat("d 'de' MMM", 'es').format(endOfWeek);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_month_rounded, size: 18, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Semana Actual de Cobro',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '$startStr — $endStr',
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Ruta activa',
              style: AppTypography.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── SECCIÓN 1: Solicitudes de Cobro ────────────────────────────────

  Widget _buildSolicitudesSection(List<Map<String, dynamic>> solicitudes, bool isDark) {
    final count = solicitudes.length;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(
          color: count > 0
              ? AppColors.warning.withValues(alpha: 0.5)
              : AppColors.border,
          width: count > 0 ? 1.4 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con Contador y navegación a pantalla completa de solicitudes
          InkWell(
            onTap: () => context.push('/cobrador-solicitudes'),
            borderRadius: BorderRadius.circular(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: count > 0
                              ? AppColors.warning.withValues(alpha: 0.12)
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.mark_email_unread_rounded,
                          color: count > 0 ? AppColors.warning : AppColors.textSecondary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Solicitudes de Cobro',
                          style: AppTypography.subtitle.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: count > 0
                        ? AppColors.warning.withValues(alpha: 0.15)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$count activas',
                        style: AppTypography.caption.copyWith(
                          color: count > 0 ? AppColors.warning : AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 10,
                        color: count > 0 ? AppColors.warning : AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (count > 0) ...[
            const SizedBox(height: AppSpacing.md),
            // Muestra máximo 2 solicitudes compactas en orden FIFO
            ...solicitudes.take(2).map((solicitud) {
              final id = solicitud['id'] as String? ?? '';
              return CobradorSolicitudCard(
                solicitud: solicitud,
                compact: true,
                onMarcarEnCamino: () {
                  AppFeedback.medium();
                  context.read<CasasCubit>().cambiarEstadoSolicitud(id, 'EN_CAMINO');
                  try {
                    context.read<DashboardCobradorCubit>().cambiarEstadoSolicitud(id, 'EN_CAMINO');
                  } catch (_) {}
                },
                onCobrar: () => _abrirCobroDesdeCasas(context, solicitud),
              );
            }),
            if (count > 2) ...[
              const SizedBox(height: 2),
              InkWell(
                onTap: () => context.push('/cobrador-solicitudes'),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Ver todas las solicitudes ($count)',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.primary),
                    ],
                  ),
                ),
              ),
            ],
          ] else ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Sin solicitudes pendientes en tu ruta.',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _abrirCobroDesdeCasas(BuildContext context, Map<String, dynamic> solicitud) {
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

  // ── SECCIÓN 2: Recorrido Programado ────────────────────────────────

  Widget _buildRecorridoHeader(List<EtapaExplorer> etapas, List<dynamic> solicitudes) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Ruta a Cobrar',
          style: AppTypography.title.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () {
            AppFeedback.medium();
            context.push(
              '/modo-inmersivo-ruta',
              extra: {
                'etapas': etapas,
                'solicitudes': solicitudes,
                'selectedEtapaId': _selectedEtapaId,
                'selectedEstadoFiltro': _filtroEstado,
                'sentidoInverso': _sentidoInverso,
              },
            );
          },
          icon: const Icon(Icons.play_arrow_rounded, size: 18),
          label: const Text(
            'Modo Focus',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          ),
        ),
      ],
    );
  }

  // ── Selector de Sector / Etapa con Contadores en Tiempo Real ─────────

  Widget _buildEtapaFilterChips(List<EtapaExplorer> etapas) {
    final totalCount = _calcularTotalCasasPendientes(etapas);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // Chip "Todas"
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xs),
            child: ChoiceChip(
              label: Text('🌐 Todas ($totalCount)'),
              selected: _selectedEtapaId == 'TODAS',
              onSelected: (selected) {
                if (selected) {
                  AppFeedback.selection();
                  setState(() => _selectedEtapaId = 'TODAS');
                }
              },
              selectedColor: AppColors.primary,
              labelStyle: AppTypography.caption.copyWith(
                color: _selectedEtapaId == 'TODAS' ? Colors.white : AppColors.textSecondary,
                fontWeight: _selectedEtapaId == 'TODAS' ? FontWeight.w700 : FontWeight.w500,
                fontSize: 12,
              ),
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: _selectedEtapaId == 'TODAS' ? AppColors.primary : AppColors.border,
                ),
              ),
            ),
          ),

          // Chips por Etapa Individual
          ...etapas.map((etapa) {
            final isSelected = _selectedEtapaId == etapa.id;
            final etapaCount = _calcularTotalCasasPendientes([etapa]);

            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xs),
              child: ChoiceChip(
                label: Text('${etapa.nombre} ($etapaCount)'),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    AppFeedback.selection();
                    setState(() => _selectedEtapaId = etapa.id);
                  }
                },
                selectedColor: AppColors.primary,
                labelStyle: AppTypography.caption.copyWith(
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 12,
                ),
                backgroundColor: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected ? AppColors.primary : AppColors.border,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  String _formatManzanaAbbr(String nombreFull) {
    final clean = nombreFull
        .replaceAll('Manzana', '')
        .replaceAll('manzana', '')
        .replaceAll('MZ', '')
        .replaceAll('mz', '')
        .trim();
    if (clean.isNotEmpty) {
      return 'Mz$clean';
    }
    return nombreFull;
  }

  // ── Rango Real de Manzanas extraído dinámicamente de la DB ─────────

  (String, String) _obtenerRangoManzanasReal(List<EtapaExplorer> etapas) {
    List<EtapaExplorer> targetEtapas = etapas;
    if (_selectedEtapaId != 'TODAS') {
      targetEtapas = etapas.where((e) => e.id == _selectedEtapaId).toList();
    }

    if (targetEtapas.isEmpty) return ('MzA', 'MzZ');

    final Set<String> uniqueManzanas = {};
    for (final e in targetEtapas) {
      for (final m in e.manzanas) {
        if (m.nombre.isNotEmpty) {
          uniqueManzanas.add(_formatManzanaAbbr(m.nombre));
        }
      }
    }

    if (uniqueManzanas.isEmpty) return ('MzA', 'MzZ');

    final sortedList = uniqueManzanas.toList()..sort((a, b) => a.compareTo(b));

    final minMz = sortedList.first;
    final maxMz = sortedList.last;
    return (minMz, maxMz);
  }

  // ── Toggle Dinámico de Sentido ─────────────────────────────────────

  Widget _buildSentidoToggle(List<EtapaExplorer> etapas, bool isDark) {
    String labelDirecto;
    String labelInverso;

    if (_selectedEtapaId == 'TODAS') {
      // Cuando se seleccionan TODAS las Etapas, el rango expresa el recorrido entre Etapas
      final etapaNombres = etapas.map((e) => e.nombre).toList()
        ..sort((a, b) => a.compareTo(b));

      if (etapaNombres.isEmpty) {
        labelDirecto = 'Directo';
        labelInverso = 'Inverso';
      } else {
        final firstEtapa = etapaNombres.first;
        final lastEtapa = etapaNombres.last;
        final rangeStr = firstEtapa == lastEtapa ? firstEtapa : '$firstEtapa ➔ $lastEtapa';
        final rangeInvStr = firstEtapa == lastEtapa ? firstEtapa : '$lastEtapa ➔ $firstEtapa';
        labelDirecto = 'Directo ($rangeStr)';
        labelInverso = 'Inverso ($rangeInvStr)';
      }
    } else {
      // Cuando se selecciona una Etapa específica, el rango expresa el recorrido entre Manzanas
      final (firstMz, lastMz) = _obtenerRangoManzanasReal(etapas);
      final rangeStr = firstMz == lastMz ? firstMz : '$firstMz ➔ $lastMz';
      final rangeInvStr = firstMz == lastMz ? firstMz : '$lastMz ➔ $firstMz';
      labelDirecto = 'Directo ($rangeStr)';
      labelInverso = 'Inverso ($rangeInvStr)';
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () {
                if (_sentidoInverso) {
                  AppFeedback.selection();
                  setState(() => _sentidoInverso = false);
                }
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: !_sentidoInverso ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.arrow_downward_rounded,
                      size: 15,
                      color: !_sentidoInverso ? Colors.white : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        labelDirecto,
                        style: AppTypography.caption.copyWith(
                          color: !_sentidoInverso ? Colors.white : AppColors.textSecondary,
                          fontWeight: !_sentidoInverso ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: InkWell(
              onTap: () {
                if (!_sentidoInverso) {
                  AppFeedback.selection();
                  setState(() => _sentidoInverso = true);
                }
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _sentidoInverso ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.arrow_upward_rounded,
                      size: 15,
                      color: _sentidoInverso ? Colors.white : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        labelInverso,
                        style: AppTypography.caption.copyWith(
                          color: _sentidoInverso ? Colors.white : AppColors.textSecondary,
                          fontWeight: _sentidoInverso ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltroEstadoChips() {
    final opciones = [
      ('PENDIENTES', '🟠 Pendientes'),
      ('MORA', '🔴 En Mora'),
      ('TODOS', '🔘 Todas las Casas'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: opciones.map((opt) {
          final isSelected = _filtroEstado == opt.$1;
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xs),
            child: ChoiceChip(
              label: Text(opt.$2),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  AppFeedback.selection();
                  setState(() => _filtroEstado = opt.$1);
                }
              },
              selectedColor: AppColors.primary,
              labelStyle: AppTypography.caption.copyWith(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 12,
              ),
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? AppColors.primary : AppColors.border,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyTerritorioState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            Icon(Icons.map_outlined, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No hay casas con saldo pendiente en esta ruta',
              style: AppTypography.subtitle.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Selecciona "Todas las Casas" para explorar el territorio completo.',
              style: AppTypography.body.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ── Cálculo de Contadores de Casas Pendientes ──────────────────────

  int _calcularTotalCasasPendientes(List<EtapaExplorer> etapas) {
    int total = 0;
    for (final e in etapas) {
      for (final m in e.manzanas) {
        for (final c in m.casas) {
          if (_filtroEstado == 'PENDIENTES' && (c.estado == 'PENDIENTE' || c.estado == 'PARCIAL' || c.estado == 'VENCIDA') && c.saldo > 0) {
            total++;
          } else if (_filtroEstado == 'MORA' && (c.estado == 'VENCIDA' || c.estado == 'MORA' || c.estado == 'EN_MORA')) {
            total++;
          } else if (_filtroEstado == 'TODOS' && (c.estado != 'AL_DIA' && c.estado != 'PAGADA' || c.saldo > 0)) {
            total++;
          }
        }
      }
    }
    return total;
  }

  // ── Procesador de Orden y Filtro de Ruta de Caminata ─────────────

  List<EtapaExplorer> _procesarRutaCaminata(List<EtapaExplorer> etapasInput) {
    List<EtapaExplorer> scopedEtapas = etapasInput;
    if (_selectedEtapaId != 'TODAS') {
      scopedEtapas = etapasInput.where((e) => e.id == _selectedEtapaId).toList();
    }

    List<EtapaExplorer> resultEtapas = scopedEtapas.map((etapa) {
      final List<ManzanaExplorer> manzanasOrdenadas = List.from(etapa.manzanas)
        ..sort((a, b) {
          final comp = a.nombre.compareTo(b.nombre);
          return _sentidoInverso ? -comp : comp;
        });

      List<ManzanaExplorer> resultManzanas = manzanasOrdenadas.map((manzana) {
        List<CasaExplorer> resultCasas = manzana.casas.where((casa) {
          if (_filtroEstado == 'PENDIENTES') {
            return (casa.estado == 'PENDIENTE' || casa.estado == 'PARCIAL' || casa.estado == 'VENCIDA') && casa.saldo > 0;
          } else if (_filtroEstado == 'MORA') {
            return casa.estado == 'VENCIDA' || casa.estado == 'MORA' || casa.estado == 'EN_MORA';
          }
          // 'TODOS': Exclude houses that are fully paid / AL_DIA with 0 debt from active collection route
          return (casa.estado != 'AL_DIA' && casa.estado != 'PAGADA') || casa.saldo > 0;
        }).toList();

        resultCasas.sort((a, b) {
          final comp = a.direccion.compareTo(b.direccion);
          return _sentidoInverso ? -comp : comp;
        });

        return ManzanaExplorer(
          id: manzana.id,
          nombre: manzana.nombre,
          casas: resultCasas,
        );
      }).where((m) => m.casas.isNotEmpty).toList();

      return EtapaExplorer(
        id: etapa.id,
        nombre: etapa.nombre,
        manzanas: resultManzanas,
      );
    }).where((e) => e.manzanas.isNotEmpty).toList();

    if (_sentidoInverso && _selectedEtapaId == 'TODAS') {
      resultEtapas = resultEtapas.reversed.toList();
    }

    return resultEtapas;
  }

  // ── Flattening y Headers de Ruta Virtualizada ─────────────────────

  List<_TerritorioItem> _flattenTerritorioItems(List<EtapaExplorer> etapas) {
    final List<_TerritorioItem> items = [];
    for (final etapa in etapas) {
      items.add(_EtapaItem(etapa.nombre));
      for (final manzana in etapa.manzanas) {
        items.add(_ManzanaItem(manzana.nombre, manzana.casas.length));
        for (final casa in manzana.casas) {
          items.add(_CasaItem(casa, etapa.nombre, manzana.nombre));
        }
      }
    }
    return items;
  }

  Widget _buildEtapaHeader(String nombre) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.xs),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.terrain_rounded, size: 14, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(
                  nombre.toUpperCase(),
                  style: AppTypography.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 1,
              color: AppColors.primary.withValues(alpha: 0.15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManzanaHeader(String nombre, int count) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.xs),
      child: Row(
        children: [
          Icon(Icons.location_city_rounded, size: 15, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            nombre,
            style: AppTypography.body.copyWith(
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '· $count ${count == 1 ? 'casa en tramo' : 'casas en tramo'}',
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ── Casa Item — con semáforo 🟢🟠🔴🔵 ───────────────────────────

  Widget _buildCasaItem(CasaExplorer casa, String etapaNombre, String manzanaNombre) {
    final (Color color, String label, String emoji) = switch (casa.estado) {
      'VENCIDA' => (AppColors.error, 'En mora', '🔴'),
      'PARCIAL' => (AppColors.info, 'Parcial', '🔵'),
      'PENDIENTE' => (AppColors.warning, 'Pendiente', '🟠'),
      _ => (AppColors.success, 'Al día', '🟢'),
    };

    final mzPrefix = manzanaNombre.isNotEmpty ? _formatManzanaAbbr(manzanaNombre) : '';
    final direccionCompleta = mzPrefix.isNotEmpty
        ? '$mzPrefix — ${casa.direccion}'
        : casa.direccion;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppColors.border),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            AppFeedback.light();
            final cobroItem = CobroItem(
              id: casa.id,
              concepto: 'Cuota de Recaudo — $direccionCompleta',
              monto: casa.saldo > 0 ? (casa.saldo / 2).clamp(10000, 50000).toDouble() : 20000.0,
              montoPagado: 0,
              saldo: casa.saldo.toDouble(),
              estado: casa.estado,
              modalidad: 'Semanal',
              casa: casa.direccion,
              manzana: manzanaNombre,
              etapa: etapaNombre,
              residenteId: casa.id,
              nombre: casa.residenteNombre,
            );

            final casasCubit = context.read<CasasCubit>();
            RegistrarPagoBottomSheet.show(
              context,
              cobro: cobroItem,
              initialQuickMode: true,
              onSuccess: () {
                casasCubit.loadViviendas();
                try {
                  context.read<DashboardCobradorCubit>().refresh(silent: true);
                } catch (_) {}
              },
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.cardInnerPadding),
            child: Row(
              children: [
                // Semáforo Indicator
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Center(child: Text(emoji, style: const TextStyle(fontSize: 18))),
                ),
                const SizedBox(width: AppSpacing.md),

                // Info de Casa y Residente
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        direccionCompleta,
                        style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.person_rounded, size: 13, color: AppColors.textSecondary),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              casa.residenteNombre,
                              style: AppTypography.small.copyWith(color: AppColors.textSecondary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (casa.residenteTelefono.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Icon(Icons.call_rounded, size: 12, color: AppColors.textSecondary),
                            const SizedBox(width: 2),
                            Text(
                              casa.residenteTelefono,
                              style: AppTypography.small.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Estado + Saldo
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (casa.saldo > 0)
                      Text(
                        _formatPesos(casa.saldo),
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        label,
                        style: AppTypography.small.copyWith(
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Error ─────────────────────────────────────────────────────────

  Widget _buildError(String message) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.error),
              const SizedBox(height: AppSpacing.md),
              Text(
                'No se pudieron cargar las casas de la ruta',
                style: AppTypography.subtitle.copyWith(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton.icon(
                onPressed: () => context.read<CasasCubit>().loadViviendas(),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Helpers ─────────────────────────────────────────────────────────

String _formatPesos(int pesos) {
  if (pesos >= 1000000) return '\$${(pesos / 1000000).toStringAsFixed(1)}M';
  if (pesos >= 1000) return '\$${(pesos / 1000).toStringAsFixed(0)}K';
  return '\$$pesos';
}
