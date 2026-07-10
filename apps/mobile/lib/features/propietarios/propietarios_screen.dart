import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import 'propietarios_repository.dart';
import 'models/propietarios_models.dart';
import 'widgets/propietario_card.dart';
import '../../shared/widgets/empty_state.dart';
import '../dashboard/widgets/skeleton_loading.dart';
import '../../shared/widgets/expandable_fab.dart';

class PropietariosScreen extends StatefulWidget {
  const PropietariosScreen({super.key});

  @override
  State<PropietariosScreen> createState() => _PropietariosScreenState();
}

class _PropietariosScreenState extends State<PropietariosScreen> {
  final PropietariosRepository _repository = PropietariosRepository();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  PropietarioResumen? _resumen;
  List<PropietarioItem> _allPropietarios = [];
  
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
      final resumen = await _repository.getResumen();
      final propietarios = await _repository.getPropietarios();
      
      if (mounted) {
        setState(() {
          _resumen = resumen;
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

  List<PropietarioItem> get _filteredPropietarios {
    return _allPropietarios.where((p) {
      final matchesFilter = _activeFilter == 'Todos' || p.estadoFinanciero == _activeFilter;
      final matchesSearch = _searchQuery.isEmpty ||
          p.nombre.toLowerCase().contains(_searchQuery) ||
          p.casa.toLowerCase().contains(_searchQuery);
      return matchesFilter && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Directorio de Propietarios'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: _buildBody(),
      floatingActionButton: ExpandableFab(
        backgroundColor: AppColors.primary,
        actions: [
          ExpandableFabAction(
            icon: Icons.person_add_rounded,
            label: 'Crear',
            color: AppColors.primary,
            onPressed: () {
              // Simulación de validación de estructura
              final bool hasEstructura = false; // Cambiado a false para probar la validación
              
              if (!hasEstructura) {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Estructura Incompleta'),
                    content: const Text(
                      'No se puede crear un usuario sin antes definir la estructura física del proyecto (Etapas, Manzanas y Casas). Por favor, configure la urbanización primero.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Entendido'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          context.push('/nuevo-propietario'); // Modo desarrollo para ver la UI
                        },
                        child: const Text('Continuar (Demo UI)'),
                      ),
                    ],
                  ),
                );
              } else {
                context.push('/nuevo-propietario');
              }
            },
          ),
          ExpandableFabAction(
            icon: Icons.edit_rounded,
            label: 'Editar',
            color: AppColors.info,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Seleccione un propietario para editar')),
              );
            },
          ),
          ExpandableFabAction(
            icon: Icons.delete_rounded,
            label: 'Eliminar',
            color: AppColors.error,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Seleccione un propietario para eliminar')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const _PropietariosSkeleton();
    }

    if (_resumen == null) {
      return const EmptyState(
        icon: Icons.error_outline,
        title: 'Error de carga',
        description: 'No se pudo cargar la información de los propietarios.',
      );
    }

    final filteredList = _filteredPropietarios;

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
              child: _buildResumenHeader(_resumen!),
            ),
          ),
          
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
          
          // Buscador
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre o casa...',
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
                    child: EmptyState(
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
                          child: PropietarioCard(propietario: filteredList[index]),
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

  Widget _buildResumenHeader(PropietarioResumen resumen) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildResumenMetric('Ocupadas', resumen.ocupadas, AppColors.success),
          Container(width: 1, height: 30, color: AppColors.border),
          _buildResumenMetric('Vacantes', resumen.vacantes, AppColors.textSecondary),
          Container(width: 1, height: 30, color: AppColors.border),
          _buildResumenMetric('Total', resumen.totalPropiedades, AppColors.primary),
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
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (_, __) => const SkeletonBox(
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
