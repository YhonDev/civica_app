import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_breakpoints.dart';
import 'cobradores_repository.dart';
import 'models/cobradores_models.dart';
import 'widgets/cobrador_card.dart';
import '../../shared/widgets/empty_state.dart';
import '../dashboard/widgets/skeleton_loading.dart';
class CobradoresScreen extends StatefulWidget {
  const CobradoresScreen({super.key});

  @override
  State<CobradoresScreen> createState() => _CobradoresScreenState();
}

class _CobradoresScreenState extends State<CobradoresScreen> {
  final CobradoresRepository _repository = CobradoresRepository();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  List<CobradorItem> _allCobradores = [];
  
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
      final cobradores = await _repository.getCobradores();
      
      if (mounted) {
        setState(() {
          _allCobradores = cobradores;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<CobradorItem> get _filteredCobradores {
    return _allCobradores.where((c) {
      final matchesFilter = _activeFilter == 'Todos' ||
          (_activeFilter == 'Activos' && c.activo) ||
          (_activeFilter == 'Inactivos' && !c.activo);
      
      final matchesSearch = _searchQuery.isEmpty ||
          c.nombre.toLowerCase().contains(_searchQuery) ||
          c.zonas.join(' ').toLowerCase().contains(_searchQuery) ||
          (c.username?.toLowerCase().contains(_searchQuery) ?? false);
          
      return matchesFilter && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Cobradores'),
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
      return const _CobradoresSkeleton();
    }

    final filteredList = _filteredCobradores;
    
    int total = _allCobradores.length;
    int activos = _allCobradores.where((c) => c.activo).length;
    int inactivos = _allCobradores.where((c) => !c.activo).length;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: CustomScrollView(
        key: const PageStorageKey('cobradores_scroll'),
        slivers: [
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
          
          // Resumen
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
              child: _buildResumenHeader(total, activos, inactivos),
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
                    final creado = await context.push<bool>('/nuevo-cobrador');
                    if (creado == true) _loadData();
                  },
                  icon: const Icon(Icons.shield_rounded, size: 18),
                  label: const Text('Nuevo Cobrador'),
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
                  hintText: 'Buscar por nombre o zona...',
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
                    child: _allCobradores.isEmpty 
                      ? const EmptyState(
                          icon: Icons.person_off_rounded,
                          title: 'Sin Cobradores',
                          description: 'Aún no hay cobradores registrados.',
                        )
                      : const EmptyState(
                          icon: Icons.search_off_rounded,
                          title: 'No hay resultados',
                          description: 'Intenta cambiar el filtro o la búsqueda.',
                        ),
                  ),
                )
              : context.isWideScreen
                  ? SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
                      sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: context.gridColumns,
                          mainAxisExtent: 140,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            return CobradorCard(
                              cobrador: filteredList[index],
                              onTap: () async {
                                final res = await context.push('/cobrador-detalle', extra: filteredList[index]);
                                if (res == true && mounted) {
                                  _loadData();
                                }
                              },
                            );
                          },
                          childCount: filteredList.length,
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
                              child: CobradorCard(
                                cobrador: filteredList[index],
                                onTap: () async {
                                  final res = await context.push('/cobrador-detalle', extra: filteredList[index]);
                                  if (res == true && mounted) {
                                    _loadData();
                                  }
                                },
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

  Widget _buildResumenHeader(int total, int activos, int inactivos) {
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
            'Balance de Cobradores',
            style: AppTypography.subtitle.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildResumenMetric('Total', total, AppColors.info),
              Container(width: 1, height: 30, color: AppColors.border),
              _buildResumenMetric('Activos', activos, AppColors.success),
              Container(width: 1, height: 30, color: AppColors.border),
              _buildResumenMetric('Inactivos', inactivos, AppColors.textSecondary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResumenMetric(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          value.toString(),
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
    final filters = ['Todos', 'Activos', 'Inactivos'];
    
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
              selectedColor: AppColors.info,
              checkmarkColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? AppColors.info : AppColors.border,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _CobradoresSkeleton extends StatelessWidget {
  const _CobradoresSkeleton();

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
              3,
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
