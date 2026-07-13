import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import 'cartera_repository.dart';
import 'models/cartera_models.dart';
import 'widgets/cartera_resumen_header.dart';
import 'widgets/cobro_card.dart';
import 'widgets/registrar_pago_bottom_sheet.dart';
import '../../shared/widgets/empty_state.dart';
import '../dashboard/widgets/skeleton_loading.dart';

class CarteraScreen extends StatefulWidget {
  const CarteraScreen({super.key});

  @override
  State<CarteraScreen> createState() => _CarteraScreenState();
}

class _CarteraScreenState extends State<CarteraScreen> {
  final CarteraRepository _repository = CarteraRepository();
  
  bool _isLoading = true;
  CarteraResumen? _resumen;
  List<CobroItem> _allCobros = [];
  
  // Filtro activo. Por defecto mostramos 'Pendiente' para que sea información útil inmediata.
  String _activeFilter = 'Pendiente';
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final resumen = await _repository.getCarteraResumen();
      final cobros = await _repository.getCobros();
      
      if (mounted) {
        setState(() {
          _resumen = resumen;
          _allCobros = cobros;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        // Handle error visually if needed
      }
    }
  }

  List<CobroItem> get _filteredCobros {
    if (_activeFilter == 'Todos') {
      return _allCobros;
    }
    return _allCobros.where((c) => c.estado == _activeFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
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
                    'Gestión de Cartera',
                    style: AppTypography.title.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Administración de cobros y propietarios',
                    style: AppTypography.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            
            // Content
            Expanded(
              child: _isLoading
                  ? const _CarteraSkeleton()
                  : _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_resumen == null) {
      return const EmptyState(
        icon: Icons.error_outline,
        title: 'Error de carga',
        description: 'No se pudo cargar la información de la cartera.',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: CustomScrollView(
        slivers: [
          // Resumen
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
              child: CarteraResumenHeader(resumen: _resumen!),
            ),
          ),
          
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
          
          // Filtros (Chips)
          SliverToBoxAdapter(
            child: _buildFilters(),
          ),
          
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),

          // Lista
          _filteredCobros.isEmpty
              ? SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xl),
                    child: EmptyState(
                      icon: Icons.inbox_rounded,
                      title: 'Sin registros',
                      description: 'No hay propietarios en estado "$_activeFilter".',
                    ),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final cobro = _filteredCobros[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: CobroCard(
                            cobro: cobro,
                            onRegistrarPago: cobro.estado != 'Pagado'
                                ? () => RegistrarPagoBottomSheet.show(
                                      context,
                                      cobro: cobro,
                                      onSuccess: _loadData,
                                    )
                                : null,
                          ),
                        );
                      },
                      childCount: _filteredCobros.length,
                    ),
                  ),
                ),
                
          // Espaciado final
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    final filters = ['Pendiente', 'Mora', 'Pagado', 'Todos'];
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Row(
        children: filters.map((filter) {
          final isSelected = _activeFilter == filter;
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
                  setState(() => _activeFilter = filter);
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
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (_, __) => const SkeletonBox(
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
