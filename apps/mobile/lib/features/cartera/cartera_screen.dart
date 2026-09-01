import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
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
import '../dashboard/widgets/skeleton_loading.dart';
import '../solicitudes/solicitudes_repository.dart';

import '../../shared/widgets/screen_header.dart';

class CarteraScreen extends StatelessWidget {
  /// Optional pre-configured repository (for testing).
  final CarteraRepository? repository;

  const CarteraScreen({super.key, this.repository});

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

  @override
  void onAppResumed() {
    context.read<CarteraCubit>().loadCobros(silent: true);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildFilterChip(String key, String label, Color activeColor) {
    final isSelected = _selectedStatusFilter == key;
    return FilterChip(
      selected: isSelected,
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      labelPadding: EdgeInsets.zero,
      label: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: AppTypography.caption.copyWith(
              color: isSelected ? Colors.white : AppColors.textPrimary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 11.5,
            ),
          ),
        ),
      ),
      selectedColor: activeColor,
      backgroundColor: AppColors.card,
      side: BorderSide(
        color: isSelected ? activeColor : AppColors.border.withValues(alpha: 0.5),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onSelected: (_) {
        setState(() {
          _selectedStatusFilter = key;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthCubit>().state.usuario;
    final rol = user?['rol'] as String?;
    final isResidente = rol == 'RESIDENTE' || rol == 'PROPIETARIO';
    final canRegisterPago = !isResidente;

    String getTitle() {
      if (isResidente) return 'Gestión de Pago';
      return 'Gestión de Cobro';
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

                  // Aplicar filtro de búsqueda y de estado (1-Tap)
                  final searchLower = _searchQuery.trim().toLowerCase();
                  final List<CobroItem> displayCobros = state.filteredCobros.where((c) {
                    final target = '${c.etapa} ${c.manzana} ${c.casa} ${c.nombre} ${c.concepto} ${c.tituloCuota}'.toLowerCase();
                    final matchSearch = searchLower.isEmpty || target.contains(searchLower);
                    if (!matchSearch) return false;

                    if (_selectedStatusFilter == 'PENDIENTE') {
                      return c.estado == 'Pendiente' || c.estado == 'PENDIENTE';
                    } else if (_selectedStatusFilter == 'MORA') {
                      return c.estado == 'Mora' || c.estado == 'MORA' || c.estado == 'VENCIDA';
                    } else if (_selectedStatusFilter == 'PAGADO') {
                      return c.estado == 'Pagado' || c.estado == 'PAGADO';
                    }
                    return true;
                  }).toList();

                  return RefreshIndicator(
                    onRefresh: () => context.read<CarteraCubit>().loadCobros(),
                    child: CustomScrollView(
                      slivers: [
                        // Resumen
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
                            child: CarteraResumenHeader(resumen: state.resumen),
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
                                    controller: _searchController,
                                    onChanged: (value) {
                                      setState(() {
                                        _searchQuery = value;
                                      });
                                    },
                                    decoration: InputDecoration(
                                      hintText: isResidente ? 'Buscar por mes o concepto (ej. Agosto)...' : 'Buscar por mes, casa o residente...',
                                      hintStyle: AppTypography.caption.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                                      suffixIcon: _searchQuery.isNotEmpty
                                          ? IconButton(
                                              icon: const Icon(Icons.clear_rounded, size: 18),
                                              onPressed: () {
                                                _searchController.clear();
                                                setState(() {
                                                  _searchQuery = '';
                                                });
                                              },
                                            )
                                          : null,
                                      filled: true,
                                      fillColor: Theme.of(context).brightness == Brightness.dark
                                          ? const Color(0xFF1E293B)
                                          : const Color(0xFFF1F5F9),
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
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? const Color(0xFF1E293B)
                                        : const Color(0xFFF1F5F9),
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

                        // Chips de Filtro Rápido en 1-Tap (4 en 1 sola fila sin desplazamiento)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
                            child: Row(
                              children: [
                                Expanded(child: _buildFilterChip('TODOS', 'Todas (${state.cobros.length})', AppColors.primary)),
                                const SizedBox(width: 4),
                                Expanded(child: _buildFilterChip('PENDIENTE', 'Pendientes (${state.resumen.cantidadPendientes})', AppColors.warning)),
                                const SizedBox(width: 4),
                                Expanded(child: _buildFilterChip('MORA', 'Mora (${state.resumen.cantidadMora})', AppColors.error)),
                                const SizedBox(width: 4),
                                Expanded(child: _buildFilterChip('PAGADO', 'Pagadas (${state.resumen.cantidadPagados})', AppColors.success)),
                              ],
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
                                    final cobro = dayCobros.first;
                                    TicketBottomSheet.show(
                                      context,
                                      TicketData(
                                        numero: cobro.id,
                                        fecha: DateTime.tryParse(cobro.fechaVencimiento) ?? DateTime.now(),
                                        residente: cobro.nombre,
                                        casa: '${cobro.etapa} - ${cobro.manzana} - Casa ${cobro.casa}',
                                        monto: cobro.saldo.round(),
                                        metodo: 'Efectivo',
                                        estado: cobro.estado,
                                        cobrador: 'Sistema Cívica',
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('No hay cobros registrados para esta fecha')),
                                    );
                                  }
                                },
                              ),
                            ),
                          )
                        else ...[
                          // Lista de Registros
                          if (displayCobros.isEmpty)
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.only(top: AppSpacing.xl),
                                child: EmptyState(
                                  icon: Icons.inbox_rounded,
                                  title: 'Sin registros',
                                  description: _searchQuery.isNotEmpty
                                      ? 'No se encontraron resultados para "$_searchQuery".'
                                      : 'No hay registros para la categoría seleccionada.',
                                ),
                              ),
                            )
                          else
                            ..._buildGroupedList(context, displayCobros, canRegisterPago),
                        ],
                              
                        // Espaciado final
                        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildGroupedList(BuildContext context, List<CobroItem> filteredCobros, bool canRegisterPago) {
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
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final cobro = filteredCobros[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: CobroCard(
                  cobro: cobro,
                  onTap: () {
                    if (cobro.estado == 'Pagado') {
                      final fecha = DateTime.tryParse(cobro.fechaVencimiento) ?? DateTime.now();
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
                          metodo: 'Efectivo',
                          estado: 'PAGADO',
                          concepto: cobro.concepto,
                          cobrador: cobro.cobradorNombre.isNotEmpty ? cobro.cobradorNombre : 'Administración',
                          etapa: cobro.etapa,
                          manzana: cobro.manzana,
                        ),
                      );
                    } else if (canRegisterPago) {
                      RegistrarPagoBottomSheet.show(
                        context,
                        cobro: cobro,
                        onSuccess: () => context.read<CarteraCubit>().loadCobros(),
                      );
                    }
                  },
                  onSolicitarCobro: !canRegisterPago && cobro.estado != 'Pagado'
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
                  onRegistrarPago: canRegisterPago && cobro.estado != 'Pagado'
                      ? () => RegistrarPagoBottomSheet.show(
                            context,
                            cobro: cobro,
                            onSuccess: () => context.read<CarteraCubit>().loadCobros(),
                          )
                      : null,
                ),
              );
            },
            childCount: filteredCobros.length,
          ),
        ),
      ),
    ];
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
