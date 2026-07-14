import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../screens/auth/auth_cubit.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/status_badge.dart';
import '../../shared/widgets/estado_cuenta_card.dart';
import '../../shared/widgets/timeline_widget.dart';
import '../../core/network/api_client.dart';
import '../dashboard/widgets/skeleton_loading.dart';
import '../solicitudes/solicitudes_repository.dart';
import 'widgets/timeline_paged_list.dart';

/// Propietario Dashboard v2 — Activity Timeline.
///
/// Shows:
///   1. Summary card (saldo, status, proximoCobro)
///   2. Infinite-scroll timeline of pagos + solicitudes
///
/// Replaces MiEstadoScreen as the PROPIETARIO home route.
class PropietarioDashboardScreen extends StatefulWidget {
  const PropietarioDashboardScreen({super.key});

  @override
  State<PropietarioDashboardScreen> createState() =>
      _PropietarioDashboardScreenState();
}

class _PropietarioDashboardScreenState
    extends State<PropietarioDashboardScreen> {
  // ── Summary state ─────────────────────────────────
  bool _loadingSummary = true;
  int _saldo = 0;
  StatusType _status = StatusType.alDia;
  String? _proximoCobro;
  Map<String, dynamic>? _proximoPago;
  Map<String, dynamic>? _tarifaActual;
  Map<String, dynamic>? _propietarioInfo;

  final _solicitudesRepo = SolicitudesRepository();

  // ── Timeline state ────────────────────────────────
  bool _loadingTimeline = true;
  List<TimelineItem> _timelineItems = [];
  int _offset = 0;
  bool _hasMore = false;
  bool _isLoadingMore = false;

  static const _pageSize = 20;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAll();
    });
  }

  Future<void> _loadAll() async {
    await Future.wait([_loadSummary(), _loadTimeline(reset: true)]);
  }

  Future<void> _loadSummary() async {
    try {
      final response =
          await ApiClient.instance.get<Map<String, dynamic>>('/dashboard/propietario');
      final data = response.data!;

      if (mounted) {
        setState(() {
          _saldo = data['saldo'] as int;

          final statusStr = data['status'] as String;
          _status = switch (statusStr) {
            'AL_DIA' => StatusType.alDia,
            'PENDIENTE' => StatusType.pendiente,
            'MORA' => StatusType.mora,
            _ => StatusType.alDia,
          };

          _proximoCobro = data['proximoCobro'] as String?;
          _proximoPago = data['proximoPago'] as Map<String, dynamic>?;
          _tarifaActual = data['tarifaActual'] as Map<String, dynamic>?;
          _propietarioInfo =
              data['propietarioInfo'] as Map<String, dynamic>?;
          _loadingSummary = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading summary: $e');
      if (mounted) setState(() => _loadingSummary = false);
    }
  }

  Future<void> _loadTimeline({bool reset = false}) async {
    if (reset) {
      _offset = 0;
      if (mounted) setState(() => _loadingTimeline = true);
    } else {
      if (mounted) setState(() => _isLoadingMore = true);
    }

    try {
      final response = await ApiClient.instance.get<Map<String, dynamic>>(
        '/dashboard/propietario/timeline',
        queryParameters: {'offset': _offset, 'limit': _pageSize},
      );
      final data = response.data!;
      final items = (data['items'] as List<dynamic>).map((item) {
        final type = item['type'] as String;
        final isPago = type == 'PAGO';
        final dateStr = item['date'] as String;
        final date = DateTime.parse(dateStr);
        final formattedDate = DateFormat('dd MMM', 'es').format(date);
        final monto = item['monto'] as int?;

        return TimelineItem(
          id: item['id'] as String,
          tipo: isPago ? 'pago' : 'solicitud',
          descripcion: item['description'] as String,
          usuario: isPago ? 'Pago recibido' : 'Solicitud',
          timestamp: date,
          hace: monto != null ? '\$$monto COP · $formattedDate' : formattedDate,
          monto: monto,
        );
      }).toList();

      if (mounted) {
        setState(() {
          if (reset) {
            _timelineItems = items;
          } else {
            _timelineItems = [..._timelineItems, ...items];
          }
          _hasMore = data['hasMore'] as bool;
          _offset = _offset + items.length;
          _loadingTimeline = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading timeline: $e');
      if (mounted) {
        setState(() {
          _loadingTimeline = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthCubit>().state.usuario;
    final nombre = user?['nombre'] as String? ?? 'Propietario';
    final parts = nombre.split(' ');
    final displayName = parts.length >= 2 ? '${parts[0]} ${parts[1]}' : nombre;

    if (_loadingSummary && _loadingTimeline) {
      return _buildLoadingSkeleton();
    }

    final saldoStr = NumberFormat.currency(
      locale: 'es_CO',
      symbol: r'$',
      decimalDigits: 0,
    ).format(_saldo);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadAll,
          child: CustomScrollView(
            slivers: [
              // ── Header ──────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenPadding,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        displayName,
                        style: AppTypography.body.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (_propietarioInfo != null) ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Icon(
                                Icons.location_on_outlined,
                                size: 20,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _propietarioInfo!['etapaNombre'] as String? ?? '',
                                    style: AppTypography.subtitle.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _propietarioInfo!['casaDireccion'] as String? ?? '',
                                    style: AppTypography.body.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                    ],
                  ),
                ),
              ),

              // ── Summary Card ────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenPadding,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      EstadoCuentaCard(
                        status: _status,
                        saldoLabel: _saldo > 0
                            ? 'Deuda actual: $saldoStr'
                            : 'Saldo actual: $saldoStr',
                        proximoCobro: _formatFecha(_proximoCobro),
                        tarifaActual: _tarifaActual,
                      ),
                      if (_proximoPago != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        _buildProximoPago(_proximoPago!),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                    ],
                  ),
                ),
              ),

              // ── Section title ───────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenPadding,
                  ),
                  child: Text(
                    'Actividad reciente',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              // ── Timeline ────────────────────────────
              if (_loadingTimeline)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                )
              else if (_timelineItems.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Center(
                      child: Text(
                        'Sin actividad reciente',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                )
              else
                SliverToBoxAdapter(
                  child: TimelinePagedList(
                    items: _timelineItems,
                    hasMore: _hasMore,
                    isLoadingMore: _isLoadingMore,
                    onLoadMore: () => _loadTimeline(),
                  ),
                ),

              // ── Bottom padding ──────────────────────
              const SliverToBoxAdapter(
                child: SizedBox(height: AppSpacing.xl),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Loading skeleton ─────────────────────────────────
  Widget _buildLoadingSkeleton() {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.lg),
              const SkeletonBox(width: 140, height: 16),
              const SizedBox(height: 8),
              const SkeletonBox(width: 240, height: 24),
              const SizedBox(height: AppSpacing.lg),
              const SkeletonCard(height: 140),
              const SizedBox(height: AppSpacing.lg),
              const SkeletonCard(height: 200),
            ],
          ),
        ),
      ),
    );
  }

  // ── Próximo pago section ──────────────────────────────
  Widget _buildProximoPago(Map<String, dynamic> pago) {
    final concepto = pago['concepto'] as String;
    final desglose = (pago['desglose'] as List<dynamic>?) ?? [];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.event_outlined,
                  color: AppColors.info,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Próximo pago',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.info,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      concepto.replaceAll(RegExp(r' - .*'), ''),
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Desglose (Partial Payments)
          if (desglose.isNotEmpty)
            ...desglose.map((item) => _buildDesgloseItem(item)),
        ],
      ),
    );
  }

  Widget _buildDesgloseItem(dynamic item) {
    final rawFecha = item['fecha'] as String;
    final fecha = _formatFecha(rawFecha) ?? 'Fecha no disp.';
    final dateObj = DateTime.parse(rawFecha);
    final fallbackMonth = toBeginningOfSentenceCase(DateFormat('MMMM', 'es').format(dateObj));
    final monthName = item['mes'] ?? fallbackMonth;

    final montoValue = NumberFormat.decimalPattern('es_CO').format(item['monto'] as int);
    final montoStr = '\$ $montoValue';

    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$monthName - Pago ${item['numeroPago'] ?? ''}',
                  style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  '$montoStr · Vence $fecha',
                  style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: () => _solicitarCobro(item),
            icon: Icon(Icons.front_hand_outlined, size: 16, color: AppColors.success),
            label: Text('Solicitar Cobro', style: TextStyle(color: AppColors.success)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              side: BorderSide(color: AppColors.success.withValues(alpha: 0.5)),
              foregroundColor: AppColors.success,
              backgroundColor: AppColors.success.withValues(alpha: 0.05),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _solicitarCobro(dynamic item) async {
    final controller = TextEditingController();
    final user = context.read<AuthCubit>().state.usuario;
    if (user == null) return;

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Solicitar Cobro'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Deseas que un cobrador pase a recolectar este pago?',
              style: AppTypography.body,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Nota para el cobrador (Opcional)',
                hintText: 'Ej. Pasen después de las 4 PM',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Enviar Solicitud'),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        await _solicitudesRepo.crearSolicitud(
          cuotaId: item['cuotaId'],
          tipo: 'SOLICITUD_COBRO',
          descripcion: result.isEmpty ? 'Solicita cobro en casa.' : result,
          propietarioId: user['id'],
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Solicitud de cobro enviada al administrador/cobrador')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al enviar solicitud: $e')),
          );
        }
      }
    }
  }

  String? _formatFecha(String? dateStr) {
    if (dateStr == null) return null;
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat("d 'de' MMMM", 'es').format(date);
    } catch (_) {
      return dateStr;
    }
  }
}
