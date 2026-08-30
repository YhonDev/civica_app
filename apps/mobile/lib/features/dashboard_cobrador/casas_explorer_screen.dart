import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

import 'casas_cubit.dart';

/// Viviendas Explorer — Navegador jerárquico para el Cobrador.
///
/// Permite explorar la comunidad en la jerarquía natural:
///   Etapa → Manzana → Casa
///
/// Cada casa muestra un semáforo de estado:
///   🟢 AL_DIA   🟠 Pendiente   🔵 Parcial   🔴 En mora
class CasasExplorerScreen extends StatelessWidget {
  final CasasCubit? cubit;

  const CasasExplorerScreen({super.key, this.cubit});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CasasCubit>(
      create: (_) => cubit ?? (CasasCubit()..loadViviendas()),
      child: const _CasasExplorerView(),
    );
  }
}

class _CasasExplorerView extends StatefulWidget {
  const _CasasExplorerView();

  @override
  State<_CasasExplorerView> createState() => _CasasExplorerViewState();
}

class _CasasExplorerViewState extends State<_CasasExplorerView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rutas'),
        centerTitle: true,
      ),
      body: BlocBuilder<CasasCubit, CasasState>(
        builder: (context, state) {
          if (state is ViviendasLoading || state is ViviendasInitial) {
            return _buildSkeletonLoading();
          } else if (state is ViviendasLoaded) {
            return _buildContent(state.etapas);
          }
          return _buildError((state as ViviendasError).message);
        },
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

  Widget _buildContent(List<EtapaExplorer> etapas) {
    if (etapas.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.map_outlined, size: 48, color: AppColors.textSecondary),
              const SizedBox(height: AppSpacing.md),
              Text(
                'No hay casas asignadas',
                style: AppTypography.subtitle.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'No tienes etapas asignadas. Consulta con el administrador.',
                style: AppTypography.body.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => context.read<CasasCubit>().refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        itemCount: etapas.length,
        itemBuilder: (context, index) {
          final etapa = etapas[index];
          return _buildEtapaTile(etapa);
        },
      ),
    );
  }

  // ── Etapa Tile ────────────────────────────────────────────────────

  Widget _buildEtapaTile(EtapaExplorer etapa) {
    // Contar total de casas y casas en mora
    int totalCasas = 0;
    int enMora = 0;
    int pendientes = 0;
    for (final m in etapa.manzanas) {
      for (final c in m.casas) {
        totalCasas++;
        if (c.estado == 'VENCIDA') {
          enMora++;
        } else if (c.estado == 'PENDIENTE' || c.estado == 'PARCIAL') pendientes++;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: ExpansionTile(
        initiallyExpanded: true, // Primera etapa expandida por defecto
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.folder_rounded, color: AppColors.primary, size: 22),
        ),
        title: Text(
          etapa.nombre,
          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '$totalCasas casas · $enMora en mora · $pendientes pendientes',
          style: AppTypography.small.copyWith(color: AppColors.textSecondary),
        ),
        childrenPadding: const EdgeInsets.only(bottom: AppSpacing.md),
        children: etapa.manzanas
            .map((m) => _buildManzanaTile(m))
            .toList(),
      ),
    );
  }

  // ── Manzana Tile ──────────────────────────────────────────────────

  Widget _buildManzanaTile(ManzanaExplorer manzana) {
    int enMora = manzana.casas.where((c) => c.estado == 'VENCIDA').length;
    int pendientes = manzana.casas.where((c) => c.estado == 'PENDIENTE' || c.estado == 'PARCIAL').length;

    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.xl),
      child: ExpansionTile(
        initiallyExpanded: true,
        tilePadding: const EdgeInsets.only(right: AppSpacing.md),
        leading: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: enMora > 0
                ? AppColors.error
                : pendientes > 0
                    ? AppColors.warning
                    : AppColors.success,
            shape: BoxShape.circle,
          ),
        ),
        title: Text(
          manzana.nombre,
          style: AppTypography.body.copyWith(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          '${manzana.casas.length} casas',
          style: AppTypography.small.copyWith(color: AppColors.textSecondary),
        ),
        children: manzana.casas
            .map((c) => _buildCasaItem(c))
            .toList(),
      ),
    );
  }

  // ── Casa Item — con semáforo 🟢🟠🔴🔵 ───────────────────────────

  Widget _buildCasaItem(CasaExplorer casa) {
    final (Color color, String label, String emoji) = switch (casa.estado) {
      'VENCIDA' => (AppColors.error, 'En mora', '🔴'),
      'PARCIAL' => (AppColors.info, 'Parcial', '🔵'),
      'PENDIENTE' => (AppColors.warning, 'Pendiente', '🟠'),
      _ => (AppColors.success, 'Al día', '🟢'),
    };

    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.xl, right: AppSpacing.md, bottom: AppSpacing.sm),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: AppColors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.cardInnerPadding),
          child: Row(
            children: [
              // Semáforo
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

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      casa.direccion,
                      style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
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

              // Estado + saldo
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
                'No se pudieron cargar las casas',
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
