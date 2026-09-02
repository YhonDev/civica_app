import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/top_toast.dart';
import '../cartera/models/cartera_models.dart';
import '../cartera/widgets/registrar_pago_bottom_sheet.dart';
import 'casas_cubit.dart';

class ModoInmersivoItem {
  final String casaId;
  final String casaNombre;
  final String manzanaNombre;
  final String etapaNombre;
  final String residenteId;
  final String residenteNombre;
  final String residenteTelefono;
  final String estado;
  final double saldo;
  final bool tieneSolicitud;
  final String? solicitudNota;

  ModoInmersivoItem({
    required this.casaId,
    required this.casaNombre,
    required this.manzanaNombre,
    required this.etapaNombre,
    required this.residenteId,
    required this.residenteNombre,
    required this.residenteTelefono,
    required this.estado,
    required this.saldo,
    this.tieneSolicitud = false,
    this.solicitudNota,
  });

  ModoInmersivoItem copyWith({
    String? estado,
    double? saldo,
    bool? tieneSolicitud,
    String? solicitudNota,
  }) {
    return ModoInmersivoItem(
      casaId: casaId,
      casaNombre: casaNombre,
      manzanaNombre: manzanaNombre,
      etapaNombre: etapaNombre,
      residenteId: residenteId,
      residenteNombre: residenteNombre,
      residenteTelefono: residenteTelefono,
      estado: estado ?? this.estado,
      saldo: saldo ?? this.saldo,
      tieneSolicitud: tieneSolicitud ?? this.tieneSolicitud,
      solicitudNota: solicitudNota ?? this.solicitudNota,
    );
  }
}

class ModoInmersivoRutaScreen extends StatefulWidget {
  final List<EtapaExplorer> etapas;
  final List<dynamic> solicitudes;
  final String selectedEtapaId;
  final String selectedEstadoFiltro;
  final bool sentidoInverso;

  const ModoInmersivoRutaScreen({
    super.key,
    required this.etapas,
    required this.solicitudes,
    this.selectedEtapaId = 'TODAS',
    this.selectedEstadoFiltro = 'TODAS',
    this.sentidoInverso = false,
  });

  @override
  State<ModoInmersivoRutaScreen> createState() => _ModoInmersivoRutaScreenState();
}

class _ModoInmersivoRutaScreenState extends State<ModoInmersivoRutaScreen> with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late ScrollController _stepperScrollController;
  late AnimationController _pulseController;
  late List<ModoInmersivoItem> _items;
  int _currentIndex = 0;
  double _pageOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.88);
    _pageController.addListener(() {
      if (_pageController.hasClients) {
        setState(() {
          _pageOffset = _pageController.page ?? _currentIndex.toDouble();
        });
      }
    });
    _stepperScrollController = ScrollController();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _items = _construirRutaPlana();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _stepperScrollController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
    _scrollToActiveNode(index);
  }

  void _scrollToActiveNode(int index) {
    if (!_stepperScrollController.hasClients) return;
    const double approxItemWidth = 140.0;
    final double targetOffset = (index * approxItemWidth) - 20.0;
    _stepperScrollController.animateTo(
      targetOffset.clamp(0.0, _stepperScrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  List<ModoInmersivoItem> _construirRutaPlana() {
    List<EtapaExplorer> etapasFiltradas = widget.etapas;
    if (widget.selectedEtapaId != 'TODAS') {
      etapasFiltradas = widget.etapas.where((e) => e.id == widget.selectedEtapaId).toList();
    }

    final List<EtapaExplorer> etapasOrdenadas = List.from(etapasFiltradas);
    etapasOrdenadas.sort((a, b) {
      final cmp = a.nombre.compareTo(b.nombre);
      return widget.sentidoInverso ? -cmp : cmp;
    });

    final List<ModoInmersivoItem> resultado = [];

    final Set<String> casasConSolicitud = {};
    final Map<String, String> notasSolicitud = {};
    for (final sol in widget.solicitudes) {
      final key = '${sol['manzanaNombre'] ?? ''}_${sol['casaDireccion'] ?? ''}';
      casasConSolicitud.add(key);
      notasSolicitud[key] = sol['descripcion'] as String? ?? 'Solicitud de atención presencial';
    }

    for (final etapa in etapasOrdenadas) {
      final List<ManzanaExplorer> manzanasOrdenadas = List.from(etapa.manzanas);
      manzanasOrdenadas.sort((a, b) {
        final cmp = a.nombre.compareTo(b.nombre);
        return widget.sentidoInverso ? -cmp : cmp;
      });

      for (final manzana in manzanasOrdenadas) {
        final List<CasaExplorer> casasOrdenadas = List.from(manzana.casas);
        casasOrdenadas.sort((a, b) {
          final aMatch = RegExp(r'\d+').firstMatch(a.direccion);
          final bMatch = RegExp(r'\d+').firstMatch(b.direccion);
          if (aMatch != null && bMatch != null) {
            final aNum = int.tryParse(aMatch.group(0)!) ?? 0;
            final bNum = int.tryParse(bMatch.group(0)!) ?? 0;
            final cmp = aNum.compareTo(bNum);
            return widget.sentidoInverso ? -cmp : cmp;
          }
          final cmp = a.direccion.compareTo(b.direccion);
          return widget.sentidoInverso ? -cmp : cmp;
        });

        for (final casa in casasOrdenadas) {
          final double saldoReal = casa.saldo.toDouble();
          final String estadoReal = casa.estado;

          bool incluir = true;
          if (widget.selectedEstadoFiltro == 'PENDIENTES') {
            incluir = estadoReal != 'AL_DIA' || saldoReal > 0;
          } else if (widget.selectedEstadoFiltro == 'MORA') {
            incluir = estadoReal == 'EN_MORA' || estadoReal == 'MORA';
          }

          if (incluir) {
            final solKey = '${manzana.nombre}_${casa.direccion}';
            resultado.add(
              ModoInmersivoItem(
                casaId: casa.id,
                casaNombre: casa.direccion,
                manzanaNombre: manzana.nombre,
                etapaNombre: etapa.nombre,
                residenteId: casa.id,
                residenteNombre: casa.residenteNombre.isNotEmpty ? casa.residenteNombre : 'Sin residente',
                residenteTelefono: casa.residenteTelefono,
                estado: estadoReal,
                saldo: saldoReal,
                tieneSolicitud: casasConSolicitud.contains(solKey),
                solicitudNota: notasSolicitud[solKey],
              ),
            );
          }
        }
      }
    }

    return resultado;
  }

  void _marcarEnMora(ModoInmersivoItem item) {
    setState(() {
      _items[_currentIndex] = item.copyWith(
        estado: 'MORA',
      );
    });
    TopToast.showInfo(context, '${item.manzanaNombre} ${item.casaNombre} marcada EN MORA');

    if (_currentIndex < _items.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.fastOutSlowIn,
      );
    }
  }

  void _abrirCobroRapido(ModoInmersivoItem item) {
    final cobroItem = CobroItem(
      id: item.casaId,
      concepto: 'Cuota de Recaudo',
      monto: item.saldo > 0 ? item.saldo : 20000.0,
      montoPagado: 0,
      saldo: item.saldo > 0 ? item.saldo : 20000.0,
      estado: item.estado,
      modalidad: 'Mensual',
      casa: item.casaNombre,
      manzana: item.manzanaNombre,
      etapa: item.etapaNombre,
      residenteId: item.residenteId,
      nombre: item.residenteNombre,
    );

    RegistrarPagoBottomSheet.show(
      context,
      cobro: cobroItem,
      cuotas: const [],
      initialQuickMode: true,
      onSuccess: () {
        setState(() {
          _items[_currentIndex] = item.copyWith(
            estado: 'AL_DIA',
            saldo: 0.0,
          );
        });
        TopToast.showSuccess(context, 'Pago registrado con éxito en ${item.casaNombre}');

        try {
          context.read<CasasCubit>().loadViviendas(silent: true);
        } catch (_) {}

        if (_currentIndex < _items.length - 1) {
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              _pageController.nextPage(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOutCubic,
              );
            }
          });
        }
      },
    );
  }

  Future<void> _confirmarSalidaRuta(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (dialogContext) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.95) : Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : AppColors.border,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icono de advertencia circular en rojo
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                    ),
                    child: Icon(
                      Icons.warning_amber_rounded,
                      size: 38,
                      color: AppColors.error,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Título principal de alerta
                  Text(
                    '¿Cancelar Ruta en Curso?',
                    textAlign: TextAlign.center,
                    style: AppTypography.title.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Explicación clara y concisa
                  Text(
                    'Tené en cuenta que al salir de la caminata, el progreso actual se consolidará y deberás reanudar la ruta desde el dashboard.',
                    textAlign: TextAlign.center,
                    style: AppTypography.body.copyWith(
                      fontSize: 13,
                      height: 1.4,
                      color: isDark ? Colors.white70 : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Botón Principal Gigante: Continuar Ruta (Intención Guiada)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 4,
                        shadowColor: AppColors.primary.withValues(alpha: 0.35),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      icon: const Icon(Icons.directions_walk_rounded, size: 22),
                      label: const Text(
                        'CONTINUAR RUTA DE RECAUDO',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Botón Secundario Más Pequeño Centrado en Relación al Botón Azul Principal
                  Center(
                    child: SizedBox(
                      width: 220,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: BorderSide(color: AppColors.error.withValues(alpha: 0.6), width: 1.2),
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        icon: const Icon(Icons.exit_to_app_rounded, size: 15),
                        label: const Text(
                          'Cancelar ruta y salir',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (result == true && context.mounted) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/casas');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalItems = _items.length;
    final progress = totalItems > 0 ? (_currentIndex + 1) / totalItems : 0.0;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _confirmarSalidaRuta(context);
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF090D16) : const Color(0xFFF1F5F9),
        body: Stack(
          children: [
            // ── Mapa de Fondo Estilizado Dinámico (Background Pattern Animado) ───
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _MapGridBackgroundPainter(
                      isDark: isDark,
                      pulseValue: _pulseController.value,
                      currentIndex: _currentIndex,
                      pageOffset: _pageOffset,
                    ),
                  );
                },
              ),
            ),

            SafeArea(
              child: Column(
                children: [
                  // ── Header: Título "Ruta Iniciada" + Botón Cerrar ───────
                  _buildHeader(isDark),

                  const SizedBox(height: AppSpacing.xs),

                  // ── Barra de Progreso Vibrante ─────────────────────────
                  _buildProgressBar(progress, totalItems, isDark),

                  const SizedBox(height: AppSpacing.sm),

                  // ── Stepper Visual de Nodos de Caminata ────────────────
                  _buildRouteMapHeader(isDark),

                  const SizedBox(height: AppSpacing.sm),

                  // ── PageView Central (Tarjeta de Foco Animada) ──────────
                  Expanded(
                    child: totalItems == 0
                        ? _buildEmptyState(isDark)
                        : PageView.builder(
                            controller: _pageController,
                            itemCount: totalItems,
                            onPageChanged: _onPageChanged,
                            itemBuilder: (context, index) {
                              final item = _items[index];
                              return _buildAnimatedFocusCard(item, index == _currentIndex, isDark);
                            },
                          ),
                  ),

                  // ── Footer: Control Navigacional + Botón Gigante de Pago ──
                  if (totalItems > 0) _buildBottomControls(isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header Bar ──────────────────────────────────────────────────────

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Icon(Icons.close_rounded, size: 20),
            ),
            onPressed: () => _confirmarSalidaRuta(context),
          ),
          Text(
            'Ruta Iniciada',
            style: AppTypography.title.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 20,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  // ── Barra de Progreso Estilo Dashboard ───────────────────────────────

  Widget _buildProgressBar(double progress, int totalItems, bool isDark) {
    final porcentajeInt = (progress * 100).toInt();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF334155) : AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.directions_walk_rounded, size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Progreso de Ruta',
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white70 : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  '${_currentIndex + 1}/$totalItems casas ($porcentajeInt%)',
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  // ── Indicador Elegante de Puntos de Camino (Waypoints / Stepper Dots) ───

  Widget _buildRouteMapHeader(bool isDark) {
    if (_items.isEmpty) return const SizedBox.shrink();

    return Center(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_items.length, (idx) {
            final isCurrent = idx == _currentIndex;
            final isPassed = idx < _currentIndex;
            final isPagado = _items[idx].estado == 'AL_DIA' || _items[idx].saldo == 0;

            return GestureDetector(
              onTap: () {
                _pageController.animateToPage(
                  idx,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 8,
                width: isCurrent ? 24 : 8,
                decoration: BoxDecoration(
                  color: isCurrent
                      ? AppColors.primary
                      : isPassed || isPagado
                          ? AppColors.success
                          : (isDark ? Colors.white24 : AppColors.border),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isCurrent
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.5),
                            blurRadius: 6,
                            spreadRadius: 1,
                          )
                        ]
                      : null,
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // ── Tarjeta de Foco Gigante Animada ─────────────────────────────────

  Widget _buildAnimatedFocusCard(ModoInmersivoItem item, bool isSelected, bool isDark) {
    final isPagado = item.estado == 'AL_DIA' || item.saldo == 0;
    final isMora = item.estado == 'MORA';

    final Color statusBorderColor = isPagado
        ? AppColors.success
        : isMora
            ? AppColors.error
            : AppColors.warning;

    final Color statusBgColor = isPagado
        ? (isDark ? const Color(0xFF064E3B).withValues(alpha: 0.25) : const Color(0xFFF0FDF4))
        : isMora
            ? (isDark ? const Color(0xFF450A0A).withValues(alpha: 0.25) : const Color(0xFFFEF2F2))
            : (isDark ? const Color(0xFF261D0C).withValues(alpha: 0.45) : const Color(0xFFFFFDF0));

    return AnimatedScale(
      scale: isSelected ? 1.0 : 0.94,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding, vertical: 6),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: statusBgColor,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isSelected ? statusBorderColor : statusBorderColor.withValues(alpha: 0.5),
              width: isSelected ? 2.5 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? statusBorderColor.withValues(alpha: 0.25)
                    : Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge Header de Sector (Etapa Destacada en Azul Consistente)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      item.etapaNombre.toUpperCase(),
                      style: AppTypography.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),

                  // Pill de Estado Limpio y Consistente
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusBorderColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusBorderColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isPagado
                              ? Icons.check_circle_rounded
                              : isMora
                                  ? Icons.warning_amber_rounded
                                  : Icons.schedule_rounded,
                          size: 16,
                          color: statusBorderColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isPagado
                              ? '✓ PAGADO'
                              : isMora
                                  ? 'EN MORA'
                                  : 'PENDIENTE',
                          style: AppTypography.caption.copyWith(
                            color: statusBorderColor,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              // Dirección Completa Destacada (Manzana X • Casa Y en Color Neutro)
              Text(
                '${item.manzanaNombre} • ${item.casaNombre}',
                style: AppTypography.title.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: AppSpacing.sm),
              const Divider(),
              const SizedBox(height: AppSpacing.sm),

              // Residente Info (Avatar Azul Consistente)
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                    radius: 28,
                    child: Icon(Icons.person_rounded, color: AppColors.primary, size: 30),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Residente:',
                          style: AppTypography.caption.copyWith(
                            color: isDark ? Colors.white60 : AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.residenteNombre,
                          style: AppTypography.title.copyWith(
                            fontWeight: FontWeight.w900,
                            fontSize: 22,
                            color: isDark ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              if (item.solicitudNota != null) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nota de la Solicitud:',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.warning,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '"${item.solicitudNota}"',
                        style: AppTypography.body.copyWith(
                          fontStyle: FontStyle.italic,
                          fontSize: 13,
                          color: isDark ? Colors.white70 : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.lg),

              // Card Gigante de Deuda con Estado Dinámico Limpio
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.85) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isDark ? const Color(0xFF334155) : AppColors.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Estado del Recaudo',
                            style: AppTypography.caption.copyWith(
                              color: isDark ? Colors.white60 : AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                isPagado
                                    ? Icons.check_circle_rounded
                                    : isMora
                                        ? Icons.warning_amber_rounded
                                        : Icons.schedule_rounded,
                                size: 18,
                                color: statusBorderColor,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  isPagado
                                      ? 'Al día / Pagado'
                                      : isMora
                                          ? 'En Mora'
                                          : 'Pendiente',
                                  style: AppTypography.subtitle.copyWith(
                                    color: isDark ? Colors.white : AppColors.textPrimary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Monto Adeudado',
                          style: AppTypography.caption.copyWith(
                            color: isDark ? Colors.white60 : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isPagado ? '\$0' : '\$${item.saldo.toInt()}',
                          style: AppTypography.title.copyWith(
                            color: isPagado ? AppColors.success : AppColors.primary,
                            fontWeight: FontWeight.w900,
                            fontSize: 22,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Botón Único de Acción In-Card: Marcar Mora (Sin duplicar el botón de cobro principal)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isMora ? AppColors.warning : AppColors.error,
                    side: BorderSide(
                      color: isMora ? AppColors.warning : AppColors.error,
                      width: 1.5,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {
                    if (isMora) {
                      setState(() {
                        _items[_currentIndex] = item.copyWith(estado: 'PENDIENTE');
                      });
                      TopToast.showInfo(context, '${item.casaNombre} restablecida a PENDIENTE');
                    } else {
                      _marcarEnMora(item);
                    }
                  },
                  icon: Icon(
                    isMora ? Icons.replay_rounded : Icons.warning_amber_rounded,
                    size: 18,
                  ),
                  label: Text(
                    isMora ? 'Restablecer a Pendiente' : 'Marcar en Mora',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Footer Controls ─────────────────────────────────────────────────

  Widget _buildBottomControls(bool isDark) {
    final item = _items[_currentIndex];

    return Container(
      margin: const EdgeInsets.only(
        left: AppSpacing.screenPadding,
        right: AppSpacing.screenPadding,
        bottom: 20,
        top: 8,
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Botón Flotante Flecha Izquierda
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(26),
                onTap: _currentIndex > 0
                    ? () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.fastOutSlowIn,
                        );
                      }
                    : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: _currentIndex > 0
                        ? (isDark ? const Color(0xFF1E293B) : Colors.white)
                        : (isDark ? const Color(0xFF0F172A).withValues(alpha: 0.5) : const Color(0xFFE2E8F0).withValues(alpha: 0.5)),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                      width: 1.5,
                    ),
                    boxShadow: _currentIndex > 0
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    Icons.arrow_back_rounded,
                    color: _currentIndex > 0
                        ? (isDark ? Colors.white : AppColors.textPrimary)
                        : (isDark ? Colors.white30 : Colors.black26),
                    size: 24,
                  ),
                ),
              ),
            ),

            const SizedBox(width: AppSpacing.sm),

            // Botón Flotante Gigante REGISTRAR COBRO
            Expanded(
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.45),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () => _abrirCobroRapido(item),
                  icon: const Icon(Icons.payments_rounded, size: 22),
                  label: const Text(
                    'REGISTRAR COBRO',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 0.5),
                  ),
                ),
              ),
            ),

            const SizedBox(width: AppSpacing.sm),

            // Botón Flotante Flecha Derecha
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(26),
                onTap: _currentIndex < _items.length - 1
                    ? () {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.fastOutSlowIn,
                        );
                      }
                    : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: _currentIndex < _items.length - 1
                        ? (isDark ? const Color(0xFF1E293B) : Colors.white)
                        : (isDark ? const Color(0xFF0F172A).withValues(alpha: 0.5) : const Color(0xFFE2E8F0).withValues(alpha: 0.5)),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                      width: 1.5,
                    ),
                    boxShadow: _currentIndex < _items.length - 1
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: _currentIndex < _items.length - 1
                        ? (isDark ? Colors.white : AppColors.textPrimary)
                        : (isDark ? Colors.white30 : Colors.black26),
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_walk_rounded, size: 64, color: AppColors.textSecondary),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No hay casas en este filtro',
              style: AppTypography.title.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Prueba cambiando la etapa o filtro de estado en la pantalla de Rutas.',
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton(
              onPressed: () => context.pop(),
              child: const Text('Volver a Rutas'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Custom Painter para el Fondo de Mapa Vectorial de Ruta ─────────────

class _MapGridBackgroundPainter extends CustomPainter {
  final bool isDark;
  final double pulseValue;
  final int currentIndex;
  final double pageOffset;

  _MapGridBackgroundPainter({
    required this.isDark,
    required this.pulseValue,
    required this.currentIndex,
    required this.pageOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final baseColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final primaryGlow = AppColors.primary;

    // 1. Radial Glow Centrado detrás de la Tarjeta
    final radialPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.0, -0.1),
        radius: 0.85,
        colors: [
          primaryGlow.withValues(alpha: isDark ? 0.18 : 0.10),
          baseColor.withValues(alpha: 0.04),
          Colors.transparent,
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), radialPaint);

    canvas.save();

    // ── Transición Dinámica de Desplazamiento de Mapa GPS 2D (Desplazamiento Continuo y Suave) ──
    final double blockW = size.width * 0.38;
    final double mapTranslateX = -(pageOffset * 35.0);
    final double mapTranslateY = -(pageOffset * 12.0);

    canvas.translate(mapTranslateX, mapTranslateY);

    // 2. Grilla de Manzanas Residenciales Alargadas (Urbanismo Real)
    final blockPaint = Paint()
      ..color = baseColor.withValues(alpha: isDark ? 0.03 : 0.04)
      ..style = PaintingStyle.fill;

    final blockBorderPaint = Paint()
      ..color = baseColor.withValues(alpha: isDark ? 0.07 : 0.06)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final double blockH = size.height * 0.09;

    for (double y = -size.height * 0.3; y < size.height * 1.5; y += blockH + 30) {
      for (double x = -size.width * 0.5; x < size.width * 2.0; x += blockW + 28) {
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, blockW, blockH),
          const Radius.circular(8),
        );
        canvas.drawRRect(rect, blockPaint);
        canvas.drawRRect(rect, blockBorderPaint);
      }
    }

    // 3. Red de Carreteras y Avenidas Principales
    final mainRoadPaint = Paint()
      ..color = baseColor.withValues(alpha: isDark ? 0.08 : 0.07)
      ..strokeWidth = 18.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final roadCenterLinePaint = Paint()
      ..color = primaryGlow.withValues(alpha: isDark ? 0.12 : 0.08)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Avenida Principal Diagonal 1
    final roadPath1 = Path()
      ..moveTo(-50, size.height * 0.25)
      ..cubicTo(size.width * 0.3, size.height * 0.2, size.width * 0.7, size.height * 0.35, size.width + 50, size.height * 0.3);
    canvas.drawPath(roadPath1, mainRoadPaint);
    canvas.drawPath(roadPath1, roadCenterLinePaint);

    // Avenida Principal Curva 2 (Baja a través de la tarjeta)
    final roadPath2 = Path()
      ..moveTo(size.width * 0.2, -50)
      ..cubicTo(size.width * 0.25, size.height * 0.4, size.width * 0.85, size.height * 0.6, size.width * 0.5, size.height + 50);
    canvas.drawPath(roadPath2, mainRoadPaint);
    canvas.drawPath(roadPath2, roadCenterLinePaint);

    // Glorieta / Rotonda Central Transparente
    final roundaboutCenter = Offset(size.width * 0.72, size.height * 0.33);
    final roundaboutPaint = Paint()
      ..color = baseColor.withValues(alpha: isDark ? 0.07 : 0.06)
      ..strokeWidth = 14.0
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(roundaboutCenter, 36, roundaboutPaint);

    // 4. Trazo Neon GPS de la Ruta a Cobrar (Ruta Activa Resaltada)
    final routeGlowPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          AppColors.success.withValues(alpha: 0.7),
          primaryGlow,
          AppColors.warning.withValues(alpha: 0.8),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..strokeWidth = 4.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final routePath = Path()
      ..moveTo(size.width * 0.15, size.height * 0.18)
      ..cubicTo(size.width * 0.45, size.height * 0.22, size.width * 0.25, size.height * 0.52, size.width * 0.78, size.height * 0.58)
      ..cubicTo(size.width * 0.95, size.height * 0.62, size.width * 0.65, size.height * 0.82, size.width * 0.3, size.height * 0.88);

    canvas.drawPath(routePath, routeGlowPaint);

    // Nodos / Waypoints de GPS sobre la ruta
    final nodePoints = [
      Offset(size.width * 0.15, size.height * 0.18),
      Offset(size.width * 0.38, size.height * 0.32),
      Offset(size.width * 0.52, size.height * 0.55),
      Offset(size.width * 0.78, size.height * 0.58),
      Offset(size.width * 0.45, size.height * 0.85),
    ];
    final activeIndex = currentIndex % nodePoints.length;

    for (int i = 0; i < nodePoints.length; i++) {
      final pt = nodePoints[i];
      final isCurrentNode = i == activeIndex;
      final isPassedNode = i < activeIndex;

      if (isCurrentNode) {
        // Baliza Pulsante Animada de la Casa Actual (Punto Naranja con Onda Radar)
        final pulseRadius = 12.0 + (pulseValue * 14.0);
        final beaconPaint = Paint()
          ..color = AppColors.warning.withValues(alpha: 0.45 * (1.0 - pulseValue))
          ..style = PaintingStyle.fill;
        canvas.drawCircle(pt, pulseRadius, beaconPaint);

        final corePaint = Paint()
          ..color = AppColors.warning
          ..style = PaintingStyle.fill;
        canvas.drawCircle(pt, 7, corePaint);
      } else if (isPassedNode) {
        // Nodo Pasado Exitosamente (Verde ✓)
        final passPaint = Paint()
          ..color = AppColors.success
          ..style = PaintingStyle.fill;
        canvas.drawCircle(pt, 6, passPaint);
      } else {
        // Nodo Futuro
        final futurePaint = Paint()
          ..color = primaryGlow.withValues(alpha: 0.4)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(pt, 4, futurePaint);
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MapGridBackgroundPainter oldDelegate) {
    return oldDelegate.isDark != isDark ||
        oldDelegate.pulseValue != pulseValue ||
        oldDelegate.currentIndex != currentIndex ||
        oldDelegate.pageOffset != pageOffset;
  }
}
