import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_breakpoints.dart';
import '../../features/auth/auth_cubit.dart';
import 'cartera_repository.dart';
import 'models/cartera_models.dart';
import 'widgets/cartera_resumen_header.dart';
import 'widgets/cobro_card.dart';
import 'widgets/registrar_pago_bottom_sheet.dart';
import 'widgets/calendar_view.dart';
import 'bloc/cartera_cubit.dart';
import '../../shared/widgets/ticket_bottom_sheet.dart';
import '../../shared/widgets/empty_state.dart';
import '../../core/widgets/lifecycle_observer_mixin.dart';
import '../../core/search/cartera_search_index.dart';
import 'dart:async';
import '../dashboard/widgets/skeleton_loading.dart';
import '../solicitudes/solicitudes_repository.dart';
import '../../shared/widgets/fading_horizontal_scroll.dart';

import '../../shared/widgets/screen_header.dart';

class CarteraScreen extends StatelessWidget {
  /// Optional pre-configured repository (for testing).
  final CarteraRepository? repository;

  const CarteraScreen({super.key, this.repository});

  /// Evaluates whether a [CobroItem] matches [query] using intelligent tokenized search.
  static bool matchesSearch(CobroItem cobro, String query) =>
      _CarteraScreenContentState.matchesSearch(cobro, query);

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthCubit>().state.usuario;
    final rol = user?['rol'] as String?;
    final propietarioId = user?['residenteId'] as String?;
    
    final resolvedRepository = repository ??
        CarteraRepository(role: rol, residenteId: propietarioId);

    return BlocProvider(
      create: (context) => CarteraCubit(resolvedRepository)..loadCobros(),
      child: const _CarteraScreenContent(),
    );
  }
}

class _CarteraScreenContent extends StatefulWidget {
  const _CarteraScreenContent();

  @override
  State<_CarteraScreenContent> createState() => _CarteraScreenContentState();
}

class _CarteraScreenContentState extends State<_CarteraScreenContent> with LifecycleObserverMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedStatusFilter = 'TODOS';
  String? _selectedEtapa; // Filtro por etapa
  String? _selectedManzana; // Filtro por manzana
  Timer? _searchDebounce;
  CarteraSearchIndex? _searchIndex;
  String? _searchIndexSource; // firma de la lista con la que se construyó el índice

  @override
  void onAppResumed() {
    context.read<CarteraCubit>().loadCobros(silent: true);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  /// Comprueba si un [CobroItem] satisface la consulta de búsqueda multi-término.
  /// Mantenido para compatibilidad con tests: delega al índice precomputado.
  static bool matchesSearch(CobroItem c, String query) {
    final index = CarteraSearchIndex.build([c]);
    return index.matches(c.id, query);
  }

  /// Obtiene (y cachea) el índice de búsqueda para la lista actual de cobros.
  /// Se reconstruye solo cuando cambia la identidad de la lista (nueva carga).
  CarteraSearchIndex _ensureSearchIndex(List<CobroItem> cobros) {
    final source = cobros.map((c) => c.id).join('|');
    if (_searchIndex == null || _searchIndexSource != source) {
      _searchIndex = CarteraSearchIndex.build(cobros);
      _searchIndexSource = source;
    }
    return _searchIndex!;
  }

  /// Debounce de 200ms: evita re-filtrar la lista en cada tecla.
  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 200), () {
      if (mounted) setState(() => _searchQuery = value);
    });
  }

  /// Etapas distintas presentes en los cobros cargados (orden alfabético).
  Set<String> _etapasDisponibles(List<CobroItem> cobros) {
    return cobros.map((c) => c.etapa).where((e) => e.isNotEmpty).toSet();
  }

  /// Manzanas distintas presentes según la etapa seleccionada (o todas si no hay etapa).
  Set<String> _manzanasDisponibles(List<CobroItem> cobros) {
    var filtered = cobros;
    if (_selectedEtapa != null) {
      filtered = filtered.where((c) => c.etapa == _selectedEtapa).toList();
    }
    return filtered.map((c) => c.manzana).where((m) => m.isNotEmpty).toSet();
  }

  Widget _buildEtapaChips(List<CobroItem> cobros) {
    final etapas = _etapasDisponibles(cobros).toList()..sort();
    if (etapas.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 34,
      child: FadingHorizontalScroll(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ChoiceChip(
                label: const Text('Todas las etapas'),
                selected: _selectedEtapa == null,
                onSelected: (_) => setState(() {
                  _selectedEtapa = null;
                  _selectedManzana = null;
                }),
                selectedColor: AppColors.primary,
                labelStyle: AppTypography.smallBold.copyWith(
                  color: _selectedEtapa == null ? Colors.white : AppColors.textSecondary,
                ),
                backgroundColor: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: _selectedEtapa == null ? AppColors.primary : AppColors.border,
                  ),
                ),
              ),
            ),
            ...etapas.map((etapa) {
              final isSelected = _selectedEtapa == etapa;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: Text(etapa),
                  selected: isSelected,
                  onSelected: (_) => setState(() {
                    _selectedEtapa = etapa;
                    _selectedManzana = null; // Reinicia manzana al alternar etapa
                  }),
                  selectedColor: AppColors.primary,
                  labelStyle: AppTypography.smallBold.copyWith(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
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
      ),
    );
  }

  Widget _buildManzanaChips(List<CobroItem> cobros) {
    final manzanas = _manzanasDisponibles(cobros).toList()..sort();
    if (manzanas.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 32,
      child: FadingHorizontalScroll(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ChoiceChip(
                label: const Text('Todas las manzanas'),
                selected: _selectedManzana == null,
                onSelected: (_) => setState(() => _selectedManzana = null),
                selectedColor: AppColors.accentTeal,
                labelStyle: AppTypography.smallBold.copyWith(
                  color: _selectedManzana == null ? Colors.white : AppColors.textSecondary,
                ),
                backgroundColor: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: _selectedManzana == null ? AppColors.accentTeal : AppColors.border,
                  ),
                ),
              ),
            ),
            ...manzanas.map((manzana) {
              final isSelected = _selectedManzana == manzana;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: Text(manzana),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _selectedManzana = manzana),
                  selectedColor: AppColors.accentTeal,
                  labelStyle: AppTypography.smallBold.copyWith(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                  backgroundColor: AppColors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected ? AppColors.accentTeal : AppColors.border,
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String key, String label, Color activeColor) {
    final isSelected = _selectedStatusFilter == key;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        key: Key('filter_chip_$key'),
        label: Text(label),
        selected: isSelected,
        showCheckmark: false,
        onSelected: (_) {
          setState(() {
            _selectedStatusFilter = key;
          });
        },
        selectedColor: activeColor,
        labelStyle: AppTypography.smallBold.copyWith(
          color: isSelected ? Colors.white : AppColors.textSecondary,
        ),
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? activeColor : AppColors.border,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthCubit>().state.usuario;
    final rol = user?['rol'] as String?;
    final isResidente = rol == 'RESIDENTE' || rol == 'PROPIETARIO';
    final isCobrador = rol == 'COBRADOR';

    String getTitle() {
      if (isResidente) return 'Gestión de Pago';
      if (isCobrador) return 'Gestión de Cobro';
      return 'Gestión de Cobro'; // Admin / Fallback
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScreenHeader(title: getTitle()),
            Expanded(
              child: BlocBuilder<CarteraCubit, CarteraState>(
                builder: (context, state) {
                  if (state.isLoading) {
                    return const _CarteraSkeleton();
                  }

                  if (state.error != null) {
                    return RefreshIndicator(
                      onRefresh: () => context.read<CarteraCubit>().loadCobros(),
                      child: CustomScrollView(
                        slivers: [
                          SliverFillRemaining(
                            child: EmptyState(
                              icon: Icons.error_outline,
                              title: 'Error de carga',
                              description: state.error!,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // 1. Filtrar por etapa y manzana seleccionadas (ámbito de sector)
                  final List<CobroItem> sectorCobros = state.cobros.where((c) {
                    if (_selectedEtapa != null && c.etapa != _selectedEtapa) {
                      return false;
                    }
                    if (_selectedManzana != null && c.manzana != _selectedManzana) {
                      return false;
                    }
                    return true;
                  }).toList();

                  // 2. Resumen dinámico y contadores dependientes del sector activo
                  final dynamicResumen = CarteraResumen.fromCobros(sectorCobros);
                  final totalSectorCount = sectorCobros.length;

                  // 3. Aplicar filtro de búsqueda (índice precomputado) y filtro de estado (1-Tap)
                  final searchIndex = _ensureSearchIndex(sectorCobros);
                  final List<CobroItem> displayCobros = sectorCobros.where((c) {
                    final matchSearch = searchIndex.matches(c.id, _searchQuery);
                    if (!matchSearch) return false;

                    if (_selectedStatusFilter == 'PENDIENTE') {
                      return c.isPendiente;
                    } else if (_selectedStatusFilter == 'MORA') {
                      return c.isMora;
                    } else if (_selectedStatusFilter == 'PAGADO') {
                      return c.isPaid;
                    }
                    return true;
                  }).toList()
                    ..sort(CobroItem.comparePorVisitaYCobro);

                  if (isResidente) {
                    return _ResidenteCarteraView(
                      state: state,
                      displayCobros: displayCobros,
                      dynamicResumen: dynamicResumen,
                      totalSectorCount: totalSectorCount,
                      searchController: _searchController,
                      searchQuery: _searchQuery,
                      selectedStatusFilter: _selectedStatusFilter,
                      onSearchChanged: _onSearchChanged,
                      onStatusFilterChanged: (key) => setState(() => _selectedStatusFilter = key),
                      buildFilterChip: _buildFilterChip,
                      buildGroupedList: _buildGroupedList,
                    );
                  } else if (isCobrador) {
                    return _CobradorCarteraView(
                      state: state,
                      displayCobros: displayCobros,
                      dynamicResumen: dynamicResumen,
                      totalSectorCount: totalSectorCount,
                      searchController: _searchController,
                      searchQuery: _searchQuery,
                      selectedStatusFilter: _selectedStatusFilter,
                      onSearchChanged: _onSearchChanged,
                      onStatusFilterChanged: (key) => setState(() => _selectedStatusFilter = key),
                      buildFilterChip: _buildFilterChip,
                      buildGroupedList: _buildGroupedList,
                      etapaChips: _buildEtapaChips(state.cobros),
                      manzanaChips: _buildManzanaChips(state.cobros),
                    );
                  }

                  return _AdminCarteraView(
                    state: state,
                    displayCobros: displayCobros,
                    dynamicResumen: dynamicResumen,
                    totalSectorCount: totalSectorCount,
                    searchController: _searchController,
                    searchQuery: _searchQuery,
                    selectedStatusFilter: _selectedStatusFilter,
                    onSearchChanged: _onSearchChanged,
                    onStatusFilterChanged: (key) => setState(() => _selectedStatusFilter = key),
                    buildFilterChip: _buildFilterChip,
                    buildGroupedList: _buildGroupedList,
                    etapaChips: _buildEtapaChips(state.cobros),
                    manzanaChips: _buildManzanaChips(state.cobros),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildGroupedList(BuildContext context, List<CobroItem> filteredCobros, bool canRegisterPago, {required CarteraState state}) {
    final user = context.read<AuthCubit>().state.usuario;
    final userName = (user?['nombre'] as String?) ?? 'Residente';

    return [
      SliverPadding(
        padding: const EdgeInsets.only(
          left: AppSpacing.screenPadding,
          right: AppSpacing.screenPadding,
          top: AppSpacing.md,
          bottom: AppSpacing.sm,
        ),
        sliver: SliverToBoxAdapter(
          child: Text(
            'Cuotas de Recaudo',
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
        sliver: Builder(
          builder: (context) {
            final isWide = context.isWideScreen;

            Widget buildCobroItem(int index) {
              final cobro = filteredCobros[index];
              return CobroCard(
                cobro: cobro,
                onTap: () {
                  if (cobro.isPaid) {
                    DateTime fecha = DateTime.now();
                    if (cobro.fechaPago.isNotEmpty) {
                      fecha = DateTime.tryParse(cobro.fechaPago)?.toLocal() ?? DateTime.now();
                    } else if (cobro.fechaVencimiento.isNotEmpty) {
                      fecha = DateTime.tryParse(cobro.fechaVencimiento)?.toLocal() ?? DateTime.now();
                    }
                    final ticketNum = cobro.nroRecibo.isNotEmpty
                        ? cobro.nroRecibo
                        : 'TK-${cobro.id.replaceAll("-", "").substring(0, 6).toUpperCase()}';
                    TicketBottomSheet.show(
                      context,
                      TicketData(
                        numero: ticketNum,
                        fecha: fecha,
                        residente: cobro.nombre.isNotEmpty && cobro.nombre != 'Residente'
                            ? cobro.nombre
                            : userName,
                        casa: '${cobro.casa} · ${cobro.manzana}',
                        monto: (cobro.monto > 0 ? cobro.monto : cobro.montoPagado).round(),
                        metodo: cobro.metodoPago.isNotEmpty ? cobro.metodoPago : 'Efectivo',
                        estado: 'PAGADO',
                        concepto: cobro.concepto,
                        cobrador: cobro.cobradorNombre.isNotEmpty ? cobro.cobradorNombre : 'Administración',
                        etapa: cobro.etapa,
                        manzana: cobro.manzana,
                      ),
                    );
                  } else if (canRegisterPago) {
                    final cuotasDelResidente = state.cobros
                        .where((c) => c.residenteId == cobro.residenteId && !c.isPaid)
                        .map((c) => {
                          'id': c.id,
                          'periodo': c.concepto,
                          'tituloCuota': c.tituloCuota,
                          'concepto': c.concepto,
                          'fechaVencimiento': c.fechaVencimiento,
                          'monto': c.saldo > 0 ? c.saldo : c.monto,
                          'estado': c.estado,
                        })
                        .toList();

                    RegistrarPagoBottomSheet.show(
                      context,
                      cobro: cobro,
                      cuotas: cuotasDelResidente.isNotEmpty ? cuotasDelResidente : null,
                      initialQuickMode: true,
                      onSuccess: () => context.read<CarteraCubit>().loadCobros(),
                    );
                  }
                },
                onSolicitarCobro: !canRegisterPago && !cobro.isPaid
                    ? () async {
                        try {
                          final repo = SolicitudesRepository();
                          final resId = (user?['residenteId'] as String?) ?? (user?['id'] as String?) ?? '';
                          await repo.crearSolicitud(
                            cobroId: cobro.id,
                            tipo: 'Solicitud de cobro',
                            descripcion: 'El residente solicita cobro presencial en domicilio para ${cobro.tituloCuota}',
                            residenteId: resId,
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Solicitud enviada'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error al solicitar cobro: $e'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        }
                      }
                    : null,
                onRegistrarPago: canRegisterPago && !cobro.isPaid
                    ? () {
                        final cuotasDelResidente = state.cobros
                            .where((c) => c.residenteId == cobro.residenteId && !c.isPaid)
                            .map((c) => {
                              'id': c.id,
                              'periodo': c.concepto,
                              'tituloCuota': c.tituloCuota,
                              'concepto': c.concepto,
                              'fechaVencimiento': c.fechaVencimiento,
                              'monto': c.saldo > 0 ? c.saldo : c.monto,
                              'estado': c.estado,
                            })
                            .toList();

                        RegistrarPagoBottomSheet.show(
                          context,
                          cobro: cobro,
                          cuotas: cuotasDelResidente.isNotEmpty ? cuotasDelResidente : null,
                          initialQuickMode: true,
                          onSuccess: () => context.read<CarteraCubit>().loadCobros(),
                        );
                      }
                    : null,
              );
            }

            if (isWide) {
              final cols = context.gridColumns;
              return SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  mainAxisExtent: 195,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => buildCobroItem(index),
                  childCount: filteredCobros.length,
                ),
              );
            }

            return SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: buildCobroItem(index),
                  );
                },
                childCount: filteredCobros.length,
              ),
            );
          },
        ),
      ),
    ];
  }
}

// ── VISTA MODULAR: Residente (Gestión de Pago) ────────────────────────
class _ResidenteCarteraView extends StatelessWidget {
  final CarteraState state;
  final List<CobroItem> displayCobros;
  final CarteraResumen dynamicResumen;
  final int totalSectorCount;
  final TextEditingController searchController;
  final String searchQuery;
  final String selectedStatusFilter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onStatusFilterChanged;
  final Widget Function(String key, String label, Color activeColor) buildFilterChip;
  final List<Widget> Function(
    BuildContext context,
    List<CobroItem> filteredCobros,
    bool canRegisterPago, {
    required CarteraState state,
  }) buildGroupedList;

  const _ResidenteCarteraView({
    required this.state,
    required this.displayCobros,
    required this.dynamicResumen,
    required this.totalSectorCount,
    required this.searchController,
    required this.searchQuery,
    required this.selectedStatusFilter,
    required this.onSearchChanged,
    required this.onStatusFilterChanged,
    required this.buildFilterChip,
    required this.buildGroupedList,
  });

  @override
  Widget build(BuildContext context) {
    return _CarteraSharedLayout(
      state: state,
      displayCobros: displayCobros,
      dynamicResumen: dynamicResumen,
      totalSectorCount: totalSectorCount,
      searchController: searchController,
      searchQuery: searchQuery,
      selectedStatusFilter: selectedStatusFilter,
      onSearchChanged: onSearchChanged,
      onStatusFilterChanged: onStatusFilterChanged,
      buildFilterChip: buildFilterChip,
      buildGroupedList: buildGroupedList,
      searchHint: 'Buscar por mes o concepto (ej. Agosto)...',
      canRegisterPago: false,
    );
  }
}

// ── VISTA MODULAR: Cobrador (Gestión de Cobro) ────────────────────────
class _CobradorCarteraView extends StatelessWidget {
  final CarteraState state;
  final List<CobroItem> displayCobros;
  final CarteraResumen dynamicResumen;
  final int totalSectorCount;
  final TextEditingController searchController;
  final String searchQuery;
  final String selectedStatusFilter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onStatusFilterChanged;
  final Widget Function(String key, String label, Color activeColor) buildFilterChip;
  final List<Widget> Function(
    BuildContext context,
    List<CobroItem> filteredCobros,
    bool canRegisterPago, {
    required CarteraState state,
  }) buildGroupedList;
  final Widget? etapaChips;
  final Widget? manzanaChips;

  const _CobradorCarteraView({
    required this.state,
    required this.displayCobros,
    required this.dynamicResumen,
    required this.totalSectorCount,
    required this.searchController,
    required this.searchQuery,
    required this.selectedStatusFilter,
    required this.onSearchChanged,
    required this.onStatusFilterChanged,
    required this.buildFilterChip,
    required this.buildGroupedList,
    this.etapaChips,
    this.manzanaChips,
  });

  @override
  Widget build(BuildContext context) {
    return _CarteraSharedLayout(
      state: state,
      displayCobros: displayCobros,
      dynamicResumen: dynamicResumen,
      totalSectorCount: totalSectorCount,
      searchController: searchController,
      searchQuery: searchQuery,
      selectedStatusFilter: selectedStatusFilter,
      onSearchChanged: onSearchChanged,
      onStatusFilterChanged: onStatusFilterChanged,
      buildFilterChip: buildFilterChip,
      buildGroupedList: buildGroupedList,
      searchHint: 'Buscar por mes, casa o residente...',
      canRegisterPago: true,
      etapaChips: etapaChips,
      manzanaChips: manzanaChips,
    );
  }
}

// ── VISTA MODULAR: Administrador (Supervisión de Cartera) ─────────────
class _AdminCarteraView extends StatelessWidget {
  final CarteraState state;
  final List<CobroItem> displayCobros;
  final CarteraResumen dynamicResumen;
  final int totalSectorCount;
  final TextEditingController searchController;
  final String searchQuery;
  final String selectedStatusFilter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onStatusFilterChanged;
  final Widget Function(String key, String label, Color activeColor) buildFilterChip;
  final List<Widget> Function(
    BuildContext context,
    List<CobroItem> filteredCobros,
    bool canRegisterPago, {
    required CarteraState state,
  }) buildGroupedList;
  final Widget? etapaChips;
  final Widget? manzanaChips;

  const _AdminCarteraView({
    required this.state,
    required this.displayCobros,
    required this.dynamicResumen,
    required this.totalSectorCount,
    required this.searchController,
    required this.searchQuery,
    required this.selectedStatusFilter,
    required this.onSearchChanged,
    required this.onStatusFilterChanged,
    required this.buildFilterChip,
    required this.buildGroupedList,
    this.etapaChips,
    this.manzanaChips,
  });

  @override
  Widget build(BuildContext context) {
    return _CarteraSharedLayout(
      state: state,
      displayCobros: displayCobros,
      dynamicResumen: dynamicResumen,
      totalSectorCount: totalSectorCount,
      searchController: searchController,
      searchQuery: searchQuery,
      selectedStatusFilter: selectedStatusFilter,
      onSearchChanged: onSearchChanged,
      onStatusFilterChanged: onStatusFilterChanged,
      buildFilterChip: buildFilterChip,
      buildGroupedList: buildGroupedList,
      searchHint: 'Buscar por mes, casa o residente...',
      canRegisterPago: true,
      etapaChips: etapaChips,
      manzanaChips: manzanaChips,
    );
  }
}

// ── LAYOUT COMPARTIDO DE CARTERA ─────────────────────────────────────
class _CarteraSharedLayout extends StatelessWidget {
  final CarteraState state;
  final List<CobroItem> displayCobros;
  final CarteraResumen dynamicResumen;
  final int totalSectorCount;
  final TextEditingController searchController;
  final String searchQuery;
  final String selectedStatusFilter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onStatusFilterChanged;
  final Widget Function(String key, String label, Color activeColor) buildFilterChip;
  final String searchHint;
  final bool canRegisterPago;

  /// Constructor de la lista agrupada de cobros, provisto por el estado padre
  /// (reemplaza a findAncestorStateOfType, frágil y costoso en rebuilds).
  final List<Widget> Function(
    BuildContext context,
    List<CobroItem> filteredCobros,
    bool canRegisterPago, {
    required CarteraState state,
  }) buildGroupedList;

  /// Chips de filtro por etapa; null en otros roles.
  final Widget? etapaChips;

  /// Chips de filtro por manzana; null si no aplica.
  final Widget? manzanaChips;

  const _CarteraSharedLayout({
    required this.state,
    required this.displayCobros,
    required this.dynamicResumen,
    required this.totalSectorCount,
    required this.searchController,
    required this.searchQuery,
    required this.selectedStatusFilter,
    required this.onSearchChanged,
    required this.onStatusFilterChanged,
    required this.buildFilterChip,
    required this.searchHint,
    required this.canRegisterPago,
    required this.buildGroupedList,
    this.etapaChips,
    this.manzanaChips,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => context.read<CarteraCubit>().loadCobros(),
      child: CustomScrollView(
        slivers: [
          // Resumen Dinámico del Sector Seleccionado
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
              child: CarteraResumenHeader(resumen: dynamicResumen),
            ),
          ),
          
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
          
          // Fila Unificada: Buscador + Selector de Vista (Lista / Calendario)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      onChanged: onSearchChanged,
                      decoration: InputDecoration(
                        hintText: searchHint,
                        hintStyle: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        suffixIcon: searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () {
                                  searchController.clear();
                                  onSearchChanged('');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: AppColors.searchField,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.searchField,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      tooltip: state.showCalendar ? 'Ver Lista' : 'Ver Calendario',
                      icon: Icon(
                        state.showCalendar ? Icons.list_rounded : Icons.calendar_month_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                      onPressed: () {
                        context.read<CarteraCubit>().toggleView();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.sm)),

          // Chips de Etapa: filtro por etapa
          if (etapaChips != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: etapaChips,
              ),
            ),

          // Chips de Manzana: filtro por manzana
          if (manzanaChips != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: manzanaChips,
              ),
            ),

          // Chips de Filtro de Estado: horizontal unificado con scroll suave y bordes desvanecidos
          SliverToBoxAdapter(
            child: SizedBox(
              height: 32,
              child: FadingHorizontalScroll(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
                child: Row(
                  children: [
                    buildFilterChip('TODOS', 'Todas ($totalSectorCount)', AppColors.primary),
                    buildFilterChip('PENDIENTE', 'Pendientes (${dynamicResumen.cantidadPendientes})', AppColors.warning),
                    buildFilterChip('MORA', 'Mora (${dynamicResumen.cantidadMora})', AppColors.error),
                    buildFilterChip('PAGADO', 'Pagadas (${dynamicResumen.cantidadPagados})', AppColors.success),
                  ],
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),

          if (state.showCalendar)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
                child: CalendarView(
                  cobros: state.cobros,
                  onDaySelected: (date, dayCobros) {
                    if (dayCobros.isNotEmpty) {
                      final primerCobro = dayCobros.first;
                      final fechaStr = DateFormat('d MMMM yyyy', 'es_CO').format(date);
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: AppColors.card,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(AppSpacing.bottomSheetRadius),
                          ),
                        ),
                        builder: (_) => Padding(
                          padding: const EdgeInsets.all(AppSpacing.screenPadding),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Cobros para el $fechaStr',
                                style: AppTypography.subtitle.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                '${dayCobros.length} cobro(s) programado(s)',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              if (canRegisterPago && !primerCobro.isPaid)
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      final cuotasDelResidente = state.cobros
                                          .where((c) => c.residenteId == primerCobro.residenteId && !c.isPaid)
                                          .map((c) => {
                                            'id': c.id,
                                            'periodo': c.concepto,
                                            'tituloCuota': c.tituloCuota,
                                            'concepto': c.concepto,
                                            'fechaVencimiento': c.fechaVencimiento,
                                            'monto': c.saldo > 0 ? c.saldo : c.monto,
                                            'estado': c.estado,
                                          })
                                          .toList();
                                      RegistrarPagoBottomSheet.show(
                                        context,
                                        cobro: primerCobro,
                                        cuotas: cuotasDelResidente.isNotEmpty ? cuotasDelResidente : null,
                                        initialQuickMode: true,
                                        onSuccess: () => context.read<CarteraCubit>().loadCobros(),
                                      );
                                    },
                                    icon: const Icon(Icons.payment_rounded),
                                    label: Text('Cobrar ${primerCobro.casa}'),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
            )
          else ...[
            if (displayCobros.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: EmptyState(
                    icon: Icons.inbox_rounded,
                    title: 'Sin registros',
                    description: searchQuery.isNotEmpty
                        ? 'No se encontraron resultados para "$searchQuery".'
                        : 'No hay registros para la categoría seleccionada.',
                    actionLabel: 'Limpiar filtros',
                    onAction: () {
                      searchController.clear();
                      onSearchChanged('');
                      onStatusFilterChanged('TODOS');
                    },
                  ),
                ),
              )
            else
              ...buildGroupedList(context, displayCobros, canRegisterPago, state: state),
          ],
                
          // Espaciado final
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
        ],
      ),
    );
  }
}

class _CarteraSkeleton extends StatelessWidget {
  const _CarteraSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonBox(width: double.infinity, height: 100, borderRadius: 16),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: List.generate(
              4,
              (index) => const Padding(
                padding: EdgeInsets.only(right: 8.0),
                child: SkeletonBox(width: 80, height: 32, borderRadius: 16),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: ListView.separated(
              itemCount: 4,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (_, _) => const SkeletonBox(
                width: double.infinity,
                height: 140,
                borderRadius: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
