import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/solicitud_card.dart';
import '../../shared/widgets/empty_state.dart';
import 'solicitudes_repository.dart';

/// Pantalla de Solicitudes (P06)
///
/// Accesible mediante push desde el menú de Perfil de Propietario.
/// Permite visualizar la lista completa de solicitudes enviadas y filtrarlas por estado.
class SolicitudesScreen extends StatefulWidget {
  const SolicitudesScreen({super.key});

  @override
  State<SolicitudesScreen> createState() => _SolicitudesScreenState();
}

class _SolicitudesScreenState extends State<SolicitudesScreen> {
  String _filtroActivo = 'TODAS';
  List<SolicitudData> _solicitudes = [];
  bool _loading = true;

  final _repo = SolicitudesRepository();

  @override
  void initState() {
    super.initState();
    _loadSolicitudes();
  }

  Future<void> _loadSolicitudes() async {
    try {
      final list = await _repo.getSolicitudes();
      if (mounted) {
        setState(() {
          _solicitudes = list;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading solicitudes: $e');
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  List<SolicitudData> get _solicitudesFiltradas {
    if (_filtroActivo == 'TODAS') return _solicitudes;
    if (_filtroActivo == 'PENDIENTES') {
      return _solicitudes
          .where((s) =>
              s.estado == SolicitudEstado.pendiente ||
              s.estado == SolicitudEstado.enRevision)
          .toList();
    }
    // RESUELTAS / RECHAZADAS
    return _solicitudes
        .where((s) =>
            s.estado == SolicitudEstado.resuelta ||
            s.estado == SolicitudEstado.rechazada)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final listado = _solicitudesFiltradas;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Solicitudes'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Filtros (Chips) ──────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenPadding,
                      vertical: AppSpacing.md,
                    ),
                    child: Row(
                      children: [
                        _buildFilterChip('Todas', 'TODAS'),
                        const SizedBox(width: AppSpacing.sm),
                        _buildFilterChip('Pendientes', 'PENDIENTES'),
                        const SizedBox(width: AppSpacing.sm),
                        _buildFilterChip('Historial', 'RESUELTAS'),
                      ],
                    ),
                  ),

                  // ── Listado o Empty State ─────────────────────────────
                  Expanded(
                    child: listado.isEmpty
                        ? const EmptyState(
                            icon: Icons.description_outlined,
                            title: 'No hay solicitudes',
                            description: 'No se encontraron solicitudes con este filtro.',
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.screenPadding,
                            ),
                            itemCount: listado.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: AppSpacing.sm),
                            itemBuilder: (context, index) {
                              final solicitud = listado[index];
                              return SolicitudCard(
                                solicitud: solicitud,
                                onTap: () => _mostrarDetalle(solicitud),
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/solicitud-nueva'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, size: 24),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filtroActivo == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _filtroActivo = value;
          });
        }
      },
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
      ),
      backgroundColor: AppColors.surface,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
      ),
    );
  }

  void _mostrarDetalle(SolicitudData solicitud) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final dateStr = DateFormat('dd/MM/yyyy').format(solicitud.fecha);
        Color statusColor = AppColors.textDisabled;
        String statusText = '';

        switch (solicitud.estado) {
          case SolicitudEstado.pendiente:
            statusColor = AppColors.warning;
            statusText = 'Pendiente';
            break;
          case SolicitudEstado.enRevision:
            statusColor = AppColors.info;
            statusText = (solicitud.tipo.toLowerCase().contains('pago') ||
                          solicitud.tipo.toLowerCase().contains('pagad'))
                ? 'Pago en revisión'
                : 'En revisión';
            break;
          case SolicitudEstado.resuelta:
            statusColor = AppColors.success;
            statusText = 'Resuelta';
            break;
          case SolicitudEstado.rechazada:
            statusColor = AppColors.error;
            statusText = 'Rechazada';
            break;
        }

        return Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.screenPadding,
            right: AppSpacing.screenPadding,
            bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
            top: AppSpacing.sm,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.description_outlined,
                      color: statusColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          solicitud.tipo,
                          style: AppTypography.subtitle.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Referencia vinculante: ${solicitud.nroRecibo}',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Fecha de creación: $dateStr',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Estado de la solicitud',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.lens, color: statusColor, size: 10),
                  const SizedBox(width: 6),
                  Text(
                    statusText,
                    style: AppTypography.bodyMedium.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Descripción del Propietario',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.cardInnerPadding),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                ),
                child: Text(
                  solicitud.descripcion,
                  style: AppTypography.body,
                ),
              ),
              if (solicitud.respuesta != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Respuesta del Administrador',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.cardInnerPadding),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.05),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.15),
                    ),
                    borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                  ),
                  child: Text(
                    solicitud.respuesta!,
                    style: AppTypography.body,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cerrar'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
