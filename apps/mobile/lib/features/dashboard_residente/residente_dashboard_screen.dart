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
    with TickerProviderStateMixin {
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
          _hasError = true;
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
                child: _buildHeader(displayName, user),
              ),

              const SizedBox(height: AppSpacing.lg),

              // ── Section 1: Estado Cuenta Card (protagonista) ───────
              _buildAnimatedSection(
                index: 1,
                child: EstadoCuentaCard(
                  status: _status,
                  saldoLabel: _saldo > 0 ? 'Deuda actual: $saldoStr' : 'Saldo actual: $saldoStr',
                  proximoCobro: _formatFecha(_proximoCobro),
                  tarifaActual: _tarifaActual,
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
                  '$monthName — Cuota ${item['numeroPago'] ?? ''}',
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

    controller.dispose();

    if (!mounted) return;

    if (result != null) {
      setState(() => _loading = true);
      final messenger = ScaffoldMessenger.of(context);
      try {
        await _solicitudesRepo.crearSolicitud(
          cobroId: item['cobroId'],
          tipo: 'SOLICITUD_COBRO',
          descripcion: result.isEmpty ? 'Solicita cobro en casa.' : result,
          residenteId: user['id'],
        );
        if (mounted) {
          messenger.showSnackBar(
            const SnackBar(content: Text('Solicitud de cobro enviada al administrador/cobrador')),
          );
          _loadDashboardData();
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

          // List of PagoCards
          ..._movimientos.take(2).map((item) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _buildPagoCard(item),
          )),

          const SizedBox(height: AppSpacing.sm),

          // "Ver todos" → navigates to /historial
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => context.go('/cartera'),
              child: Text(
                'Ver historial completo ›',
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
