import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/format/app_currency.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_feedback.dart';
import '../../core/theme/app_breakpoints.dart';
import '../../core/widgets/lifecycle_observer_mixin.dart';
import '../cartera/models/cartera_models.dart';
import '../cartera/widgets/registrar_pago_bottom_sheet.dart';
import 'dashboard_cobrador_cubit.dart';
import 'casas_cubit.dart';
import 'widgets/cobrador_solicitud_card.dart';
import '../../shared/widgets/screen_header.dart';
import '../../shared/widgets/fading_horizontal_scroll.dart';
import '../../core/widgets/top_toast.dart';

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

class _CasasExplorerView extends StatefulWidget {
  const _CasasExplorerView();

  @override
  State<_CasasExplorerView> createState() => _CasasExplorerViewState();
}

class _CasasExplorerViewState extends State<_CasasExplorerView> with LifecycleObserverMixin {
  String _selectedEtapaId = 'TODAS'; // 'TODAS' o id específico de Etapa
  bool _sentidoInverso = false; // false: Directo, true: Inverso
  String _filtroEstado = 'PENDIENTES'; // PENDIENTES, MORA
  String? _selectedRecorridoFecha; // fecha del recorrido (sábado) seleccionado; null = el actual

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
                    return _buildContent(
                      state.etapas,
                      state.solicitudes,
                      recorridos: state.recorridos,
                      recorridoActualNumero: state.recorridoActualNumero,
                    );
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

  Widget _buildContent(
    List<EtapaExplorer> etapas,
    List<Map<String, dynamic>> solicitudes, {
    List<RecorridoExplorer> recorridos = const [],
    int recorridoActualNumero = 1,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // El backend ya entrega el selector rodante (sábados pasados fuera).
    // En MORA el selector se oculta: la mora no está ligada a ningún sábado.
    final recorridosVisibles = _filtroEstado == 'MORA' ? const <RecorridoExplorer>[] : recorridos;
    final recorridoSeleccionado =
        _recorridoSeleccionadoDe(recorridosVisibles, recorridoActualNumero);
    final fechaCorte = recorridoSeleccionado?.fecha;
    final processedEtapas = _procesarRutaCaminata(etapas, fechaCorte);

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
                  _buildRecorridoHeader(etapas, solicitudes, recorridoSeleccionado),

                  const SizedBox(height: AppSpacing.sm),

                  // Selector por Sector / Etapa
                  _buildEtapaFilterChips(etapas, fechaCorte),

                  const SizedBox(height: AppSpacing.sm),

                  // Selector de Recorrido (sábados vigentes; oculto en Mora)
                  if (recorridosVisibles.isNotEmpty) ...[
                    _buildRecorridoSelector(recorridosVisibles, recorridoSeleccionado),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  if (_filtroEstado == 'PENDIENTES' &&
                      recorridosVisibles.isEmpty) ...[
                    _buildRecorridosAgotadosBanner(),
                    const SizedBox(height: AppSpacing.sm),
                  ],

                  // Toggle Dinámico de Sentido de Caminata (calculado según DB)
                  _buildSentidoToggle(etapas, isDark),

                  const SizedBox(height: AppSpacing.sm),

                  // Filtros Rápidos de Cobro (Pendientes, Mora)
                  _buildFiltroEstadoChips(),

                  const SizedBox(height: AppSpacing.md),
                ],
              ),
            ),
          ),

          // Lista o Cuadrícula Responsiva por Territorio
          ..._buildTerritorioSlivers(
            context,
            processedEtapas,
            context.isWideScreen,
            fechaCorte: fechaCorte,
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
        color: AppColors.cobradorHighlight,
        borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
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
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Text(
              'Ruta activa',
              style: AppTypography.smallBold.copyWith(
                color: AppColors.primary,
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
        color: AppColors.cobradorCard,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(
          color: count > 0
              ? AppColors.warning.withValues(alpha: 0.5)
              : AppColors.border,
          width: count > 0 ? 1.4 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.04),
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
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: count > 0
                              ? AppColors.warning.withValues(alpha: 0.12)
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
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
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: count > 0
                        ? AppColors.warning.withValues(alpha: 0.15)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$count activas',
                        style: AppTypography.smallBold.copyWith(
                          color: count > 0 ? AppColors.warning : AppColors.textSecondary,
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
            if (context.isWideScreen)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: count > 4 ? 4 : count,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: context.gridColumns,
                  mainAxisExtent: 82,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemBuilder: (context, idx) {
                  final solicitud = solicitudes[idx];
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
                },
              )
            else
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
            if (count > (context.isWideScreen ? 4 : 2)) ...[
              const SizedBox(height: 2),
              InkWell(
                onTap: () => context.push('/cobrador-solicitudes'),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
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

  Widget _buildRecorridoHeader(
    List<EtapaExplorer> etapas,
    List<dynamic> solicitudes,
    RecorridoExplorer? recorridoSeleccionado,
  ) {
    final bloqueado = _inicioDeRutaBloqueado(recorridoSeleccionado);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ruta a Cobrar',
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                _subtituloRuta(recorridoSeleccionado),
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor:
                bloqueado ? AppColors.border : AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
          ),
          onPressed: () {
            if (bloqueado) {
              TopToast.show(
                context,
                type: ToastType.warning,
                title: 'Ruta no disponible',
                message:
                    'La ruta de pendientes solo puede iniciarse el ${recorridoSeleccionado?.fechaLegible.toLowerCase() ?? 'sábado'}. La mora puedes cobrarla cualquier día.',
              );
              return;
            }
            AppFeedback.medium();
            context.push(
              '/modo-inmersivo-ruta',
              extra: {
                'etapas': etapas,
                'solicitudes': solicitudes,
                'selectedEtapaId': _selectedEtapaId,
                'selectedEstadoFiltro': _filtroEstado,
                'sentidoInverso': _sentidoInverso,
                if (recorridoSeleccionado != null)
                  'selectedRecorrido': {
                    'numero': recorridoSeleccionado.numero,
                    'fecha': recorridoSeleccionado.fecha,
                    'fechaLegible': recorridoSeleccionado.fechaLegible,
                  },
              },
            );
          },
          icon: const Icon(Icons.play_arrow_rounded, size: 16),
          label: Text(
            'Iniciar Recorrido',
            style: AppTypography.caption.copyWith(
              color: AppColors.onPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  /// La ruta de PENDIENTES solo puede iniciarse el sábado exacto del
  /// recorrido seleccionado. MORA no tiene restricción de día.
  bool _inicioDeRutaBloqueado(RecorridoExplorer? recorridoSeleccionado) {
    if (_filtroEstado != 'PENDIENTES') return false;
    final fecha = recorridoSeleccionado?.fecha;
    if (fecha == null || fecha.isEmpty) return true; // fin de mes: sin ciclo
    return _fechaLocalHoy() != fecha;
  }

  String _subtituloRuta(RecorridoExplorer? recorridoSeleccionado) {
    if (_filtroEstado == 'MORA') {
      return 'Cobro de mora · cualquier día';
    }
    if (recorridoSeleccionado == null) {
      return 'Los recorridos de este mes terminaron';
    }
    final hoy = _fechaLocalHoy();
    if (hoy == recorridoSeleccionado.fecha) {
      return 'Hoy · ${recorridoSeleccionado.nombre} · ${recorridoSeleccionado.fechaLegible}';
    }
    return '${recorridoSeleccionado.nombre} · ${recorridoSeleccionado.fechaLegible}';
  }

  /// Fecha local YYYY-MM-DD (mismas reglas que el backend).
  String _fechaLocalHoy() {
    final ahora = DateTime.now();
    final mm = ahora.month.toString().padLeft(2, '0');
    final dd = ahora.day.toString().padLeft(2, '0');
    return '${ahora.year}-$mm-$dd';
  }

  Widget _buildRecorridosAgotadosBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.event_busy_rounded, size: 18, color: AppColors.warning),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Los recorridos de este mes terminaron. Los pendientes del próximo ciclo se activan el día 1; la mora puedes cobrarla cualquier día.',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Selector de Recorrido (4 sábados de cobro del mes) ────────────

  RecorridoExplorer? _recorridoSeleccionadoDe(
    List<RecorridoExplorer> recorridos,
    int numeroPorDefecto,
  ) {
    if (recorridos.isEmpty) return null;
    if (_selectedRecorridoFecha != null) {
      for (final r in recorridos) {
        if (r.fecha == _selectedRecorridoFecha) return r;
      }
    }
    for (final r in recorridos) {
      if (r.numero == numeroPorDefecto) return r;
    }
    return recorridos.first;
  }

  Widget _buildRecorridoSelector(
    List<RecorridoExplorer> recorridos,
    RecorridoExplorer? recorridoSeleccionado,
  ) {
    return FadingHorizontalScroll(
      padding: EdgeInsets.zero,
      child: Row(
        children: recorridos.map((rec) {
          final isSelected = recorridoSeleccionado?.fecha == rec.fecha;
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xs),
            child: ChoiceChip(
              label: Text('${rec.fechaLegible} · R${rec.numero}'),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  AppFeedback.selection();
                  setState(() => _selectedRecorridoFecha = rec.fecha);
                }
              },
              selectedColor: AppColors.primary,
              labelStyle: AppTypography.label.copyWith(
                color: isSelected ? AppColors.onPrimary : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
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

  /// Formatea 'YYYY-MM-DD' → 'd MMM yyyy' sin depender de locales de intl.
  String _formatFechaCorta(String? iso) {
    if (iso == null || iso.length < 10) return '';
    const meses = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
    ];
    final mes = int.tryParse(iso.substring(5, 7));
    final dia = int.tryParse(iso.substring(8, 10));
    if (mes == null || dia == null || mes < 1 || mes > 12) return iso;
    return '$dia ${meses[mes - 1]} ${iso.substring(0, 4)}';
  }

  // ── Selector de Sector / Etapa con Contadores en Tiempo Real ─────────

  Widget _buildEtapaFilterChips(List<EtapaExplorer> etapas, String? fechaCorte) {
    final totalCount = _calcularTotalCasasPendientes(etapas, fechaCorte);

    return FadingHorizontalScroll(
      padding: EdgeInsets.zero,
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
              labelStyle: AppTypography.label.copyWith(
                color: _selectedEtapaId == 'TODAS' ? AppColors.onPrimary : AppColors.textSecondary,
                fontWeight: _selectedEtapaId == 'TODAS' ? FontWeight.w700 : FontWeight.w500,
              ),
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
                side: BorderSide(
                  color: _selectedEtapaId == 'TODAS' ? AppColors.primary : AppColors.border,
                ),
              ),
            ),
          ),

          // Chips por Etapa Individual
          ...etapas.map((etapa) {
            final isSelected = _selectedEtapaId == etapa.id;
            final etapaCount = _calcularTotalCasasPendientes([etapa], fechaCorte);

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
                labelStyle: AppTypography.label.copyWith(
                  color: isSelected ? AppColors.onPrimary : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
                backgroundColor: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
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
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.cobradorSubcard,
        borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
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
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: !_sentidoInverso ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.arrow_downward_rounded,
                      size: 15,
                      color: !_sentidoInverso ? AppColors.onPrimary : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          labelDirecto,
                          style: AppTypography.smallBold.copyWith(
                            color: !_sentidoInverso ? AppColors.onPrimary : AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
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
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: _sentidoInverso ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.arrow_upward_rounded,
                      size: 15,
                      color: _sentidoInverso ? AppColors.onPrimary : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          labelInverso,
                          style: AppTypography.smallBold.copyWith(
                            color: _sentidoInverso ? AppColors.onPrimary : AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
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
    ];

    return FadingHorizontalScroll(
      padding: EdgeInsets.zero,
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
              labelStyle: AppTypography.label.copyWith(
                color: isSelected ? AppColors.onPrimary : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
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
              _filtroEstado == 'MORA'
                  ? 'No hay casas con mora en esta ruta'
                  : 'No hay pendientes para este recorrido',
              style: AppTypography.subtitle.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _filtroEstado == 'MORA'
                  ? 'Cuando el sistema marque cuotas vencidas aparecerán aquí, ordenadas de la más vieja a la más reciente.'
                  : 'Cambia al filtro En Mora para recuperar cartera, o usa Gestión de Cobro para cobros puntuales.',
              style: AppTypography.body.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ── Cálculo de Contadores de Casas Pendientes ──────────────────────

  int _calcularTotalCasasPendientes(List<EtapaExplorer> etapas, String? fechaCorte) {
    int total = 0;
    for (final e in etapas) {
      for (final m in e.manzanas) {
        for (final c in m.casas) {
          if (evaluarCasaParaRecorrido(c, _filtroEstado, fechaCorte) ==
              CasaFiltroVeredicto.incluir) {
            total++;
          }
        }
      }
    }
    return total;
  }

  // ── Procesador de Orden y Filtro de Ruta de Caminata ─────────────

  List<EtapaExplorer> _procesarRutaCaminata(
    List<EtapaExplorer> etapasInput,
    String? fechaCorte,
  ) {
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
          return evaluarCasaParaRecorrido(casa, _filtroEstado, fechaCorte) ==
              CasaFiltroVeredicto.incluir;
        }).toList();

        // En MORA el orden es por deuda más antigua (fechaVencimiento más vieja primero).
        // En PENDIENTES se respeta el orden secuencial de caminata de la manzana.
        resultCasas.sort((a, b) {
          if (_filtroEstado == 'MORA') {
            return compararCasasPorMoraAntigua(a, b);
          }
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

  List<Widget> _buildTerritorioSlivers(
    BuildContext context,
    List<EtapaExplorer> etapas,
    bool isWide, {
    String? fechaCorte,
  }) {
    if (etapas.isEmpty) {
      return [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
          sliver: SliverToBoxAdapter(
            child: _buildEmptyTerritorioState(),
          ),
        ),
      ];
    }

    final List<Widget> slivers = [];
    final cols = context.gridColumns;

    for (final etapa in etapas) {
      slivers.add(
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
          sliver: SliverToBoxAdapter(
            child: _buildEtapaHeader(etapa.nombre),
          ),
        ),
      );

      for (final manzana in etapa.manzanas) {
        slivers.add(
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
            sliver: SliverToBoxAdapter(
              child: _buildManzanaHeader(manzana.nombre, manzana.casas.length),
            ),
          ),
        );

        if (isWide) {
          slivers.add(
            SliverPadding(
              padding: const EdgeInsets.only(
                left: AppSpacing.screenPadding,
                right: AppSpacing.screenPadding,
                top: AppSpacing.xs,
                bottom: AppSpacing.sm,
              ),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  mainAxisExtent: 135,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) =>
                      _buildCasaItem(manzana.casas[index], etapa.nombre, manzana.nombre, fechaCorte: fechaCorte),
                  childCount: manzana.casas.length,
                ),
              ),
            ),
          );
        } else {
          slivers.add(
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
              sliver: SliverList.builder(
                itemCount: manzana.casas.length,
                itemBuilder: (context, index) =>
                    _buildCasaItem(manzana.casas[index], etapa.nombre, manzana.nombre, fechaCorte: fechaCorte),
              ),
            ),
          );
        }
      }
    }

    return slivers;
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
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
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
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
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

  Widget _buildCasaItem(
    CasaExplorer casa,
    String etapaNombre,
    String manzanaNombre, {
    String? fechaCorte,
  }) {
    final cuotaInfo = obtenerCuotaParaRecorrido(casa, _filtroEstado, fechaCorte);
    final estadoEfectivo = _filtroEstado == 'MORA' ? 'VENCIDA' : cuotaInfo.estado;

    final (Color color, String label, String emoji) = switch (estadoEfectivo) {
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
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          side: BorderSide(color: AppColors.border),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          onTap: () {
            AppFeedback.light();
            final defaultMonto = cuotaInfo.monto > 0
                ? cuotaInfo.monto.toDouble()
                : (casa.saldo > 0 ? (casa.saldo > 50000 ? 10000.0 : casa.saldo.toDouble()) : 20000.0);

            final cobroItem = CobroItem(
              id: cuotaInfo.id ?? casa.proximaCuotaId ?? casa.id,
              concepto: cuotaInfo.nombre != null && cuotaInfo.nombre!.isNotEmpty
                  ? '${cuotaInfo.nombre} — $direccionCompleta'
                  : (casa.proximaCuotaNombre != null
                      ? '${casa.proximaCuotaNombre} — $direccionCompleta'
                      : 'Cuota de Recaudo — $direccionCompleta'),
              monto: defaultMonto,
              montoPagado: 0,
              saldo: casa.saldo.toDouble(),
              estado: estadoEfectivo,
              modalidad: casa.modalidad,
              casa: casa.direccion,
              manzana: manzanaNombre,
              etapa: etapaNombre,
              residenteId: casa.residenteId.isNotEmpty ? casa.residenteId : casa.id,
              nombre: casa.residenteNombre,
              cuotas: casa.cuotas,
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 350;

                if (isCompact) {
                  // ── MODO COMPACTO (< 350dp: Poco X7 Pro y pantallas angostas) ──
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Fila de Cabecera: Semáforo + Dirección (Etapa + Mz/Casa) + Badge de Estado
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                            ),
                            child: Center(child: Text(emoji, style: AppTypography.emoji)),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  margin: const EdgeInsets.only(right: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                  ),
                                  child: Text(
                                    etapaNombre,
                                    style: AppTypography.micro.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      direccionCompleta,
                                      style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                                      maxLines: 1,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
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
                      const SizedBox(height: 5),

                      // 2. Residente (a todo lo ancho)
                      Text(
                        casa.residenteNombre,
                        style: AppTypography.small.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      // 3. Cuota (a todo lo ancho)
                      if (cuotaInfo.nombre != null && cuotaInfo.nombre!.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          cuotaInfo.nombre!,
                          style: AppTypography.small.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],

                      // 4. Pie de tarjeta: Vence a la izquierda, Saldo a la derecha
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (cuotaInfo.fechaVencimiento != null &&
                              cuotaInfo.fechaVencimiento!.isNotEmpty)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.event_rounded, size: 13, color: AppColors.textSecondary),
                                const SizedBox(width: 4),
                                Text(
                                  'Vence: ${_formatFechaCorta(cuotaInfo.fechaVencimiento)}',
                                  style: AppTypography.small.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            )
                          else
                            const SizedBox.shrink(),
                          if (casa.saldo > 0)
                            Text(
                              _formatPesos(casa.saldo),
                              style: AppTypography.bodyMedium.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                        ],
                      ),
                    ],
                  );
                } else {
                  // ── MODO ESTÁNDAR (>= 350dp: Poco X3 Pro, Tablets, Web) ──
                  return Row(
                    children: [
                      // Semáforo Indicator
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                        ),
                        child: Center(child: Text(emoji, style: AppTypography.emoji)),
                      ),
                      const SizedBox(width: AppSpacing.md),

                      // Info de Casa y Residente — 4 filas estructuradas
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Fila 1: Etapa badge + Manzana — Casa
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  margin: const EdgeInsets.only(right: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                  ),
                                  child: Text(
                                    etapaNombre,
                                    style: AppTypography.micro.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    direccionCompleta,
                                    style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            // Fila 2: Residente
                            Text(
                              casa.residenteNombre,
                              style: AppTypography.small.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            // Fila 3: Cuota (según el sábado seleccionado o mora)
                            if (cuotaInfo.nombre != null && cuotaInfo.nombre!.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                cuotaInfo.nombre!,
                                style: AppTypography.small.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            // Fila 4: Fecha de vencimiento (según el sábado seleccionado o mora)
                            if (cuotaInfo.fechaVencimiento != null &&
                                cuotaInfo.fechaVencimiento!.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.event_rounded, size: 12, color: AppColors.textSecondary),
                                  const SizedBox(width: 3),
                                  Text(
                                    'Vence: ${_formatFechaCorta(cuotaInfo.fechaVencimiento)}',
                                    style: AppTypography.small.copyWith(
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
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
                              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
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
                  );
                }
              },
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

String _formatPesos(int pesos) => AppCurrency.formatCompact(pesos);
