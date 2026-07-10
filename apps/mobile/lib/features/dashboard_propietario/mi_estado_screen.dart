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
import '../../core/network/api_client.dart';
import '../solicitudes/solicitudes_repository.dart';
import '../dashboard/widgets/skeleton_loading.dart';

/// Propietario Dashboard — "Mi Estado"
///
/// Per ROLE_DASHBOARDS.md (§3 Experiencia del Propietario):
///   Pregunta: ¿Cómo está mi cuenta y qué debo hacer?
///   El dashboard es un ESTADO DE CUENTA.
///
/// Per doc/19-dashboard-specification.md (DASHBOARD PROPIETARIO):
///   Tarjeta principal (estado) → Próximo Cobro/Último Pago →
///   Últimos 2 Movimientos (Timeline) → Solicitudes (solo si pendientes)
///
/// Structure (5 blocks max per doc/19):
///   1. Header (saludo + casa)
///   2. EstadoCuentaCard (protagonista)
///   3. Timeline (2 últimos movimientos)
///   4. Solicitudes (condicional — solo si hay pendientes)
class MiEstadoScreen extends StatefulWidget {
  const MiEstadoScreen({super.key});

  @override
  State<MiEstadoScreen> createState() => _MiEstadoScreenState();
}

class _MiEstadoScreenState extends State<MiEstadoScreen>
    with TickerProviderStateMixin {
  // ── Animation controllers for stagger effect ─────────────────────
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _fadeAnimations;
  late final List<Animation<Offset>> _slideAnimations;

  // Number of animated sections
  static const _sectionCount = 4;

  // ── Backend integration state variables ──────────────────────────
  bool _loading = true;
  int _saldo = 0;
  StatusType _status = StatusType.alDia;
  String? _proximoCobro;
  Map<String, dynamic>? _proximoPago;
  List<TimelineItem> _movimientos = [];
  List<SolicitudData> _solicitudesPendientes = [];

  final _solicitudesRepo = SolicitudesRepository();

  @override
  void initState() {
    super.initState();
    _initAnimations();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardData();
    });
  }

  Future<void> _loadDashboardData() async {
    try {
      final response = await ApiClient.instance.get<Map<String, dynamic>>('/dashboard/propietario');
      final data = response.data!;

      final listPendientes = await _solicitudesRepo.getSolicitudesPendientes();

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
              usuario: isPago ? 'Pago recibido' : 'Cuota mensual',
              timestamp: date,
              hace: '\$${m['monto']} · $formattedDate',
              monto: m['monto'] as int,
            );
          }).toList();

          _solicitudesPendientes = listPendientes;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading dashboard: $e');
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
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
    final nombre = user?['nombre'] as String? ?? 'Propietario';
    final parts = nombre.split(' ');
    final displayName = parts.length >= 2 ? '${parts[0]} ${parts[1]}' : nombre;

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

    final saldoStr = NumberFormat.currency(
      locale: 'es_CO',
      symbol: r'$',
      decimalDigits: 0,
    ).format(_saldo);

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

              // ── Section 0: Header ──────────────────────────────────
              _buildAnimatedSection(
                index: 0,
                child: _buildHeader(displayName),
              ),

              const SizedBox(height: AppSpacing.lg),

              // ── Section 1: Estado Cuenta Card (protagonista) ───────
              _buildAnimatedSection(
                index: 1,
                child: EstadoCuentaCard(
                  status: _status,
                  saldoLabel: 'Saldo actual: $saldoStr',
                  proximoCobro: _formatFecha(_proximoCobro),
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
              _buildAnimatedSection(
                index: 2,
                child: _buildMovimientos(),
              ),

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
    );
  }

  // ── Próximo pago section ──────────────────────────────────────────
  Widget _buildProximoPago(Map<String, dynamic> pago) {
    final concepto = pago['concepto'] as String;
    final fecha = _formatFecha(pago['fechaVencimiento'] as String);
    final esperados = pago['pagosEsperados'] as int?;
    final registrados = pago['pagosRegistrados'] as int? ?? 0;
    final montoPagado = pago['montoPagado'] as int? ?? 0;
    final montoTotal = pago['montoTotal'] as int? ?? pago['monto'] as int;
    final montoParcial = pago['montoParcial'] as int? ?? pago['monto'] as int;
    final saldo = montoTotal - montoPagado;
    final proximoAbono = NumberFormat.currency(
      locale: 'es_CO',
      symbol: r'$',
      decimalDigits: 0,
    ).format(pago['monto'] as int);
    final saldoStr = NumberFormat.currency(
      locale: 'es_CO',
      symbol: r'$',
      decimalDigits: 0,
    ).format(saldo);
    final abonoStr = NumberFormat.currency(
      locale: 'es_CO',
      symbol: r'$',
      decimalDigits: 0,
    ).format(montoParcial);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.25)),
      ),
      child: Row(
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
                  concepto,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$proximoAbono · Vence $fecha',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                if (esperados != null && esperados > 1) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Abono: $abonoStr · $registrados de $esperados pagos',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Saldo mes: $saldoStr',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String? _formatFecha(String? isoDate) {
    if (isoDate == null) return null;
    final date = DateTime.parse(isoDate);
    return DateFormat('dd MMM yyyy', 'es').format(date);
  }

  // ── Header ────────────────────────────────────────────────────────
  Widget _buildHeader(String displayName) {
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
                    'Urb. San Sebastián - Etapa 1',
                    style: AppTypography.subtitle.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Mz. A, Casa 1',
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
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
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
          Text(
            'Últimos movimientos',
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Timeline widget — max 2 items per doc/19
          TimelineWidget(
            items: _movimientos.take(2).toList(),
            onItemTap: _openTicket,
          ),

          const SizedBox(height: AppSpacing.sm),

          // "Ver todos" → navigates to /historial
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => context.go('/historial'),
              child: Text(
                'Ver todos ›',
                style: AppTypography.body.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
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
    TicketBottomSheet.show(
      context,
      TicketData(
        numero: 'TK-${item.id.hashCode.abs().toString().padLeft(6, '0')}',
        fecha: item.timestamp,
        propietario: context.read<AuthCubit>().state.usuario?['nombre'] as String? ?? 'Propietario',
        casa: 'Casa 101',
        monto: item.monto ?? 0,
        metodo: 'Efectivo',
        estado: item.tipo == 'pago' ? 'Pagado' : 'Generada',
        cobrador: item.tipo == 'pago' ? 'Carlos Gómez' : null,
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
