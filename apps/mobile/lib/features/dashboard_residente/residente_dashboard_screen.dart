import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../screens/auth/auth_cubit.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/status_badge.dart';
import '../../shared/widgets/estado_cuenta_card.dart';
import '../../shared/widgets/solicitud_card.dart';
import '../../shared/widgets/ticket_bottom_sheet.dart';
import '../../shared/widgets/solicitud_bottom_sheet.dart';
import '../../shared/widgets/timeline_widget.dart';
import '../../shared/widgets/recaudo_timeline_widget.dart';
import '../../core/network/api_client.dart';
import '../../core/network/local_cache_repository.dart';
import '../solicitudes/solicitudes_repository.dart';
import '../dashboard/widgets/skeleton_loading.dart';
import '../../core/widgets/lifecycle_observer_mixin.dart';

/// Residente Dashboard — "Mi Estado"
///
/// Per ROLE_DASHBOARDS.md (§3 Experiencia del Residente):
///   Pregunta: ¿Cómo está mi cuenta y qué debo hacer?
///   El dashboard es un ESTADO DE CUENTA.
///
/// Per doc/19-dashboard-specification.md (DASHBOARD RESIDENTE):
///   Tarjeta principal (estado) → Próximo Cobro/Último Pago →
///   Últimos 2 Movimientos (Timeline) → Solicitudes (solo si pendientes)
///
/// Structure (5 blocks max per doc/19):
///   1. Header (saludo + casa)
///   2. EstadoCuentaCard (protagonista)
///   3. Timeline (2 últimos movimientos)
///   4. Solicitudes (condicional — solo si hay pendientes)
class ResidenteDashboardScreen extends StatefulWidget {
  const ResidenteDashboardScreen({super.key});

  @override
  State<ResidenteDashboardScreen> createState() => _ResidenteDashboardScreenState();
}

class _ResidenteDashboardScreenState extends State<ResidenteDashboardScreen>
    with TickerProviderStateMixin, LifecycleObserverMixin {
  // ── Animation controllers for stagger effect ─────────────────────
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _fadeAnimations;
  late final List<Animation<Offset>> _slideAnimations;

  // Number of animated sections
  static const _sectionCount = 4;

  // ── Backend integration state variables ──────────────────────────
  bool _loading = true;
  bool _hasError = false;
  int _saldo = 0;
  StatusType _status = StatusType.alDia;
  String? _proximoCobro;
  Map<String, dynamic>? _proximoPago;
  List<TimelineItem> _movimientos = [];
  List<SolicitudData> _solicitudesPendientes = [];
  Map<String, dynamic>? _tarifaActual;

  final _solicitudesRepo = SolicitudesRepository();

  @override
  void onAppResumed() {
    _loadDashboardData(silent: true);
  }

  @override
  void initState() {
    super.initState();
    _initAnimations();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardData();
    });
  }

  Future<void> _loadDashboardData({bool silent = false}) async {
    if (!silent && LocalCacheRepository.instance.getCached('dashboard:residente') == null) {
      setState(() => _loading = true);
    }

    await LocalCacheRepository.instance.executeSWR<Map<String, dynamic>>(
      key: 'dashboard:residente',
      fetcher: () async {
        final response = await ApiClient.instance.get<Map<String, dynamic>>('/dashboard/residente');
        return response.data!;
      },
      onData: (data, isStale) async {
        final listPendientes = await _solicitudesRepo.getMisSolicitudes();

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

            final listMovs = data['movimientos'] as List<dynamic>;
            _movimientos = listMovs.map((m) {
              final isPago = m['tipo'] == 'pago';
              final dateStr = m['fecha'] as String;
              final date = DateTime.parse(dateStr);
              final formattedDate = DateFormat('dd MMM', 'es').format(date);
              return TimelineItem(
                id: m['id'] as String,
                tipo: m['tipo'] as String,
                descripcion: m['descripcion'] as String,
                usuario: isPago ? 'Pago realizado' : 'Cuota programada',
                timestamp: date,
                hace: '\$${m['monto']} · $formattedDate',
                monto: m['monto'] as int,
              );
            }).toList()
              ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

            _solicitudesPendientes = listPendientes;
            _loading = false;
            _hasError = false;
          });
        }
      },
      onError: (e) {
        debugPrint('Error loading dashboard: $e');
        if (mounted && !silent && LocalCacheRepository.instance.getCached('dashboard:residente') == null) {
          setState(() {
            _loading = false;
            _hasError = true;
          });
        }
      },
    );
  }

  void _initAnimations() {
    _controllers = List.generate(
      _sectionCount,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 250),
      ),
    );

    _fadeAnimations = _controllers
        .map((c) => CurvedAnimation(parent: c, curve: Curves.easeOutCubic))
        .map((c) => Tween<double>(begin: 0.0, end: 1.0).animate(c))
        .toList();

    _slideAnimations = _controllers
        .map((c) => CurvedAnimation(parent: c, curve: Curves.easeOutCubic))
        .map((c) =>
            Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
                .animate(c))
        .toList();

    // Stagger: each section starts 80ms after the previous
    _startStagger();
  }

  Future<void> _startStagger() async {
    for (var i = 0; i < _controllers.length; i++) {
      await Future.delayed(const Duration(milliseconds: 80));
      if (mounted) _controllers[i].forward();
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthCubit>().state.usuario;
    final nombre = user?['nombre'] as String? ?? 'Residente';
    final parts = nombre.split(' ');
    final displayName = parts.length >= 2 ? '${parts[0]} ${parts[1]}' : nombre;

    if (_hasError) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: AppColors.error),
                const SizedBox(height: AppSpacing.md),
                Text('No pudimos cargar la información', style: AppTypography.bodyMedium),
                const SizedBox(height: AppSpacing.md),
                FilledButton.icon(
                  onPressed: () {
                    setState(() {
                      _loading = true;
                      _hasError = false;
                    });
                    _loadDashboardData();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_loading) {
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

    final saldoFormatted = NumberFormat.decimalPattern('es_CO').format(_saldo);
    final saldoLabelText = _saldo > 0 ? 'Deuda actual: \$$saldoFormatted' : 'Saldo actual: \$$saldoFormatted';

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _loadDashboardData(silent: true),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding,
            ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.lg),

              // ── Section 0: Header ──────────────────────────────────
              _buildAnimatedSection(
                index: 0,
                child: _buildHeader(displayName, user),
              ),

              const SizedBox(height: AppSpacing.lg),

              // ── Section 1: Estado Cuenta Card (protagonista) ───────
              _buildAnimatedSection(
                index: 1,
                child: EstadoCuentaCard(
                  status: _status,
                  saldoLabel: saldoLabelText,
                  proximoCobro: _formatFecha(_proximoCobro),
                  tarifaActual: _tarifaActual,
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // ── Section 1.5: Recaudo Timeline Widget ───────────────
              _buildAnimatedSection(
                index: 1,
                child: RecaudoTimelineWidget(
                  cuotasPagadas: _movimientos.where((m) => m.tipo == 'pago').length,
                  totalCuotas: (_tarifaActual?['modalidad'] == 'SEMANAL' || _tarifaActual?['modalidad'] == null) ? 4 : (_tarifaActual?['modalidad'] == 'QUINCENAL' ? 2 : 1),
                  montoPagado: _movimientos
                      .where((m) => m.tipo == 'pago')
                      .fold(0.0, (sum, m) => sum + (m.monto ?? 0)),
                  saldoPendiente: _saldo.toDouble(),
                  modalidad: _tarifaActual?['modalidad'] as String? ?? 'SEMANAL',
                  onAccionTap: () => context.go('/cartera'),
                ),
              ),

              // ── Próximo pago (si hay cuota pendiente) ─────────────
              if (_proximoPago != null) ...[
                const SizedBox(height: AppSpacing.md),
                _buildAnimatedSection(
                  index: 1,
                  child: _buildProximoPago(_proximoPago!),
                ),
              ],

              const SizedBox(height: AppSpacing.lg),

              // ── Section 2: Timeline (últimos 2 movimientos) ────────
              if (_movimientos.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                _buildAnimatedSection(
                  index: 2,
                  child: _buildMovimientos(),
                ),
              ],

              // ── Section 3: Solicitudes (solo si hay pendientes) ────
              if (_solicitudesPendientes.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                _buildAnimatedSection(
                  index: 3,
                  child: _buildSolicitudes(),
                ),
              ],

              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    ),
  );
  }



  // ── Próximos Pagos section (Módulo Encapsulado) ──────────────────────
  Widget _buildProximoPago(Map<String, dynamic> pago) {
    final desglose = (pago['desglose'] as List<dynamic>?) ?? [];
    if (desglose.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.event_outlined, size: 18, color: AppColors.primary),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'Próximos Pagos',
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              for (int i = 0; i < desglose.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.border.withValues(alpha: 0.3),
                    indent: 12,
                    endIndent: 12,
                  ),
                _buildDesgloseRow(desglose[i], i),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDesgloseRow(dynamic item, int index) {
    final rawFecha = item['fecha'] as String;
    final fecha = _formatFecha(rawFecha) ?? 'Fecha no disp.';
    final dateObj = DateTime.tryParse(rawFecha) ?? DateTime.now();
    final fallbackMonth = toBeginningOfSentenceCase(DateFormat('MMMM', 'es').format(dateObj));
    final monthName = item['mes'] ?? fallbackMonth;

    final montoValue = NumberFormat.decimalPattern('es_CO').format(item['monto'] as int);
    final montoStr = '\$ $montoValue';
    final numeroCuota = item['numeroPago'] ?? '${index + 1}';

    final bool isProgramada = item['cobroId'] == null;
    final String? itemCobroId = item['cobroId'] as String?;

    final bool hasActiveRequest = _solicitudesPendientes.isNotEmpty;
    final bool isThisCuotaRequested = hasActiveRequest &&
        _solicitudesPendientes.any((s) {
          final itemId = (item['id'] ?? '').toString();
          if (s.cobroId.isNotEmpty && s.cobroId == itemId) return true;
          if (s.cobroId.isNotEmpty && itemCobroId != null && s.cobroId == itemCobroId && index == 0) return true;
          return false;
        });

    Widget rightWidget;

    if (isProgramada) {
      rightWidget = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.border.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          'Programada',
          style: AppTypography.small.copyWith(
            color: AppColors.textSecondary,
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    } else if (isThisCuotaRequested) {
      rightWidget = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.hourglass_top_rounded, size: 12, color: AppColors.warning),
            const SizedBox(width: 4),
            Text(
              'En Solicitud',
              style: AppTypography.small.copyWith(
                color: AppColors.warning,
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    } else if (hasActiveRequest) {
      rightWidget = const SizedBox.shrink();
    } else {
      rightWidget = OutlinedButton.icon(
        onPressed: () => _solicitarCobro(item),
        icon: Icon(Icons.front_hand_outlined, size: 14, color: AppColors.success),
        label: Text(
          'Solicitar Cobro',
          style: TextStyle(color: AppColors.success, fontSize: 11.5, fontWeight: FontWeight.bold),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          side: BorderSide(color: AppColors.success.withValues(alpha: 0.5)),
          foregroundColor: AppColors.success,
          backgroundColor: AppColors.success.withValues(alpha: 0.05),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$monthName — Cuota $numeroCuota',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '$montoStr · Vence $fecha',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          rightWidget,
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

    controller.dispose();

    if (!mounted) return;

    if (result != null) {
      final messenger = ScaffoldMessenger.of(context);
      try {
        final rawId = (item is Map) ? (item['cobroId'] ?? item['id']) : null;
        final validCobroId = (rawId != null && rawId.toString().length > 20 && !rawId.toString().startsWith('future-'))
            ? rawId.toString()
            : (_movimientos.isNotEmpty ? _movimientos.first.id : null);

        if (validCobroId == null) {
          throw Exception('No se encontró un cobro válido asignado.');
        }

        final userId = (user['id'] ?? user['sub'] ?? '').toString();

        await _solicitudesRepo.crearSolicitud(
          cobroId: validCobroId,
          tipo: 'SOLICITUD_COBRO',
          descripcion: result.isEmpty ? 'Solicita cobro en casa.' : result,
          residenteId: userId,
        );

        LocalCacheRepository.instance.invalidate('dashboard:residente');
        LocalCacheRepository.instance.invalidate('dashboard:administrador');

        if (mounted) {
          messenger.showSnackBar(
            const SnackBar(content: Text('Solicitud de cobro enviada al administrador/cobrador')),
          );
          await _loadDashboardData(silent: true);
        }
      } catch (e) {
        if (mounted) {
          setState(() => _loading = false);
          messenger.showSnackBar(
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

  Widget _buildHeader(String displayName, Map<String, dynamic>? user) {
    final urbanizacion = user?['urbanizacion'] as String? ?? 'Urbanización';
    final casa = user?['casa'] as String? ?? 'Casa';
    final manzana = user?['manzana'] as String? ?? '';
    final casaInfo = manzana.isNotEmpty ? '$casa · $manzana' : casa;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          displayName,
          style: AppTypography.body.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
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
                    urbanizacion,
                    style: AppTypography.subtitle.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    casaInfo,
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
    );
  }

  // ── Movimientos section ───────────────────────────────────────────
  Widget _buildMovimientos() {
    if (_movimientos.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Últimos movimientos',
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              InkWell(
                onTap: () => context.go('/cartera'),
                child: Text(
                  'Ver historial →',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // List of PagoCards (máximo 2 registros para no saturar)
          ..._movimientos.take(2).map((item) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: _buildPagoCard(item),
          )),
        ],
      ),
    );
  }

  Widget _buildPagoCard(TimelineItem item) {
    final isPago = item.tipo == 'pago';
    final color = isPago ? AppColors.success : AppColors.info;
    final icon = isPago ? Icons.payments_outlined : Icons.receipt_long_outlined;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openTicket(item),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.usuario,
                      style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.descripcion,
                      style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    NumberFormat.currency(locale: 'es_CO', symbol: r'$', decimalDigits: 0).format(item.monto ?? 0),
                    style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('dd MMM', 'es').format(item.timestamp),
                    style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Solicitudes section (conditional) ─────────────────────────────
  Widget _buildSolicitudes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Solicitud pendiente',
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${_solicitudesPendientes.length}',
                style: AppTypography.small.copyWith(
                  color: AppColors.warning,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ...List.generate(_solicitudesPendientes.length, (i) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: i < _solicitudesPendientes.length - 1
                  ? AppSpacing.sm
                  : 0,
            ),
            child: SolicitudCard(
              solicitud: _solicitudesPendientes[i],
              onTap: () => _mostrarDetalleSolicitud(_solicitudesPendientes[i]),
            ),
          );
        }),
      ],
    );
  }

  // ── Open ticket bottom sheet ──────────────────────────────────────
  void _openTicket(TimelineItem item) {
    final user = context.read<AuthCubit>().state.usuario;
    final nombre = user?['nombre'] as String? ?? 'Residente';
    final casa = user?['casa'] as String? ?? 'Casa';

    TicketBottomSheet.show(
      context,
      TicketData(
        numero: 'TK-${item.id.hashCode.abs().toString().padLeft(6, '0')}',
        fecha: item.timestamp,
        residente: nombre,
        casa: casa,
        monto: item.monto ?? 0,
        metodo: item.contexto ?? 'Efectivo',
        estado: item.tipo == 'pago' ? 'Pagado' : 'Generada',
        cobrador: null,
      ),
    );
  }

  // ── Open detailed view for pending requests ────────────────────────
  void _mostrarDetalleSolicitud(SolicitudData solicitud) {
    final montoStr = _proximoPago != null
        ? NumberFormat.currency(
            locale: 'es_CO',
            symbol: r'$',
            decimalDigits: 0,
          ).format(_proximoPago!['monto'] as int)
        : '—';

    SolicitudBottomSheet.show(context, solicitud, montoStr: montoStr);
  }

  // ── Animated section wrapper ──────────────────────────────────────
  Widget _buildAnimatedSection({
    required int index,
    required Widget child,
  }) {
    if (index >= _controllers.length) return child;
    return FadeTransition(
      opacity: _fadeAnimations[index],
      child: SlideTransition(
        position: _slideAnimations[index],
        child: child,
      ),
    );
  }
}
