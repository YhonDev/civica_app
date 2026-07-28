import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import 'residentes_repository.dart';
import 'models/residentes_models.dart';
import 'widgets/residente_card.dart';
import '../../shared/widgets/empty_state.dart';
import '../dashboard/widgets/skeleton_loading.dart';
class ResidentesScreen extends StatefulWidget {
  const ResidentesScreen({super.key});

  @override
  State<ResidentesScreen> createState() => _ResidentesScreenState();
}

class _ResidentesScreenState extends State<ResidentesScreen> {
  final ResidentesRepository _repository = ResidentesRepository();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  List<ResidenteItem> _allPropietarios = [];
  
  String _activeFilter = 'Todos';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final propietarios = await _repository.getPropietarios();
      
      if (mounted) {
        setState(() {
          _allPropietarios = propietarios;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<ResidenteItem> get _filteredPropietarios {
    return _allPropietarios.where((p) {
      final matchesFilter = _activeFilter == 'Todos' || p.estadoFinanciero == _activeFilter;
      final matchesSearch = _searchQuery.isEmpty ||
          p.nombre.toLowerCase().contains(_searchQuery) ||
          p.casa.toLowerCase().contains(_searchQuery) ||
          (p.username?.toLowerCase().contains(_searchQuery) ?? false);
      return matchesFilter && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Residentes'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const _PropietariosSkeleton();
    }

    final filteredList = _filteredPropietarios;
    
    int total = _allPropietarios.length;
    int alDia = _allPropietarios.where((p) => p.estadoFinanciero == 'Al día' || p.estadoFinanciero == 'Al Día').length;
    int enMora = _allPropietarios.where((p) => p.estadoFinanciero == 'Mora').length;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: CustomScrollView(
        key: const PageStorageKey('propietarios_scroll'),
        slivers: [
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
          
          // Resumen
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
              child: _buildResumenHeader(total, alDia, enMora),
            ),
          ),
          
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
          
          // Botón Nuevo
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
              child: Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: () async {
                    final result = await context.push<bool>('/nuevo-residente');
                    if (result == true) {
                      _loadData();
                    }
                  },
                  icon: const Icon(Icons.person_add_rounded, size: 18),
                  label: const Text('Nuevo Propietario'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    backgroundColor: AppColors.info,
                  ),
                ),
              ),
            ),
          ),
          
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
          
          // Historial Title
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
              child: Text(
                'Historial',
                style: AppTypography.subtitle.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
          
          // Buscador
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre, usuario o casa...',
                  hintStyle: AppTypography.body.copyWith(color: AppColors.textDisabled),
                  prefixIcon: Icon(Icons.search_rounded, color: AppColors.textDisabled),
                  filled: true,
                  fillColor: AppColors.card,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),

          // Filtros (Chips)
          SliverToBoxAdapter(
            child: _buildFilters(),
          ),
          
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),

          // Lista
          filteredList.isEmpty
              ? SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xl),
                    child: _allPropietarios.isEmpty 
                      ? const EmptyState(
                          icon: Icons.person_off_rounded,
                          title: 'Sin Propietarios',
                          description: 'Aún no hay propietarios registrados.',
                        )
                      : const EmptyState(
                          icon: Icons.search_off_rounded,
                          title: 'No hay resultados',
                          description: 'Intenta cambiar el filtro o la búsqueda.',
                        ),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: ResidenteCard(
                            propietario: filteredList[index],
                            onUpdate: _loadData,
                          ),
                        );
                      },
                      childCount: filteredList.length,
                    ),
                  ),
                ),
                
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  Widget _buildResumenHeader(int total, int alDia, int enMora) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Text(
            'Balance de Residentes',
            style: AppTypography.subtitle.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildResumenMetric('Total', total.toString(), AppColors.primary),
              Container(width: 1, height: 30, color: AppColors.border),
              _buildResumenMetric('Al Día', alDia.toString(), AppColors.success),
              Container(width: 1, height: 30, color: AppColors.border),
              _buildResumenMetric('En Mora', enMora.toString(), AppColors.warning),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResumenMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: AppTypography.title.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    final filters = ['Todos', 'Al Día', 'Pendiente', 'Mora'];
    
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

class _PropietariosSkeleton extends StatelessWidget {
  const _PropietariosSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.md),
          const SkeletonBox(width: double.infinity, height: 80, borderRadius: 16),
          const SizedBox(height: AppSpacing.md),
          const SkeletonBox(width: double.infinity, height: 48, borderRadius: 12),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: List.generate(
              4,
              (index) => const Padding(
                padding: EdgeInsets.only(right: 8.0),
                child: SkeletonBox(width: 70, height: 32, borderRadius: 16),
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
                height: 120,
                borderRadius: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
