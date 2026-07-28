import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../screens/auth/auth_cubit.dart';
import 'cartera_repository.dart';
import 'models/cartera_models.dart';
import 'widgets/cartera_resumen_header.dart';
import 'widgets/cobro_card.dart';
import 'widgets/registrar_pago_bottom_sheet.dart';
import 'widgets/calendar_view.dart';
import 'bloc/cartera_cubit.dart';
import '../../shared/widgets/ticket_bottom_sheet.dart';
import '../../shared/widgets/empty_state.dart';
import '../dashboard/widgets/skeleton_loading.dart';

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

class _CarteraScreenContent extends StatelessWidget {
  const _CarteraScreenContent();

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthCubit>().state.usuario;
    final rol = user?['rol'] as String?;
    final isResidente = rol == 'RESIDENTE' || rol == 'PROPIETARIO';
    final canRegisterPago = !isResidente;

    String getTitle() {
      if (isResidente) return 'Mis Pagos';
      return 'Gestión de Cartera';
    }

    String getSubtitle() {
      switch (rol) {
        case 'ADMIN':
          return 'Resumen general de tu comunidad';
        case 'COBRADOR':
          return 'Resumen de cobros por ruta';
        case 'PROPIETARIO':
        case 'RESIDENTE':
          return 'Estado de tus cuotas y abonos';
        default:
          return 'Administración de cobros y residentes';
      }
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.lg),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    getTitle(),
                    style: AppTypography.title.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    getSubtitle(),
                    style: AppTypography.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            
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
                        
                        // Toggle View: Lista | Calendario
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                SegmentedButton<bool>(
                                  segments: const [
                                    ButtonSegment(value: false, label: Text('Lista'), icon: Icon(Icons.list_rounded)),
                                    ButtonSegment(value: true, label: Text('Calendario'), icon: Icon(Icons.calendar_month_rounded)),
                                  ],
                                  selected: {state.showCalendar},
                                  onSelectionChanged: (val) {
                                    context.read<CarteraCubit>().toggleView();
                                  },
                                ),
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
                          // Filtros (Chips)
                          SliverToBoxAdapter(
                            child: _buildFilters(context, state.activeFilter),
                          ),
                          
                          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),

                          // Lista
                          if (state.filteredCobros.isEmpty)
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.only(top: AppSpacing.xl),
                                child: EmptyState(
                                  icon: Icons.inbox_rounded,
                                  title: 'Sin registros',
                                  description: 'No hay registros en estado "${state.activeFilter}".',
                                ),
                              ),
                            )
                          else
                            ..._buildGroupedList(context, state.filteredCobros, canRegisterPago),
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
    final Map<String, List<CobroItem>> grouped = {};
    for (final cobro in filteredCobros) {
      final key = '${cobro.etapa} - ${cobro.manzana}';
      grouped.putIfAbsent(key, () => []).add(cobro);
    }
    
    final slivers = <Widget>[];
    for (final entry in grouped.entries) {
      slivers.add(
        SliverPadding(
          padding: const EdgeInsets.only(
            left: AppSpacing.screenPadding,
            right: AppSpacing.screenPadding,
            top: AppSpacing.md,
            bottom: AppSpacing.sm,
          ),
          sliver: SliverToBoxAdapter(
            child: Text(
              entry.key,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      );
      
      slivers.add(
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final cobro = entry.value[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: CobroCard(
                    cobro: cobro,
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
              childCount: entry.value.length,
            ),
          ),
        ),
      );
    }
    return slivers;
  }

  Widget _buildFilters(BuildContext context, String activeFilter) {
    final filters = ['Pendiente', 'Mora', 'Pagado', 'Todos'];
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Row(
        children: filters.map((filter) {
          final isSelected = activeFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: FilterChip(
              label: Text(
                filter,
                style: AppTypography.small.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  context.read<CarteraCubit>().setFilter(filter);
                }
              },
              backgroundColor: AppColors.surface,
              selectedColor: AppColors.primary,
              checkmarkColor: Colors.white,
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
