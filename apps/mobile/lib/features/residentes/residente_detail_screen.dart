import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../screens/auth/auth_cubit.dart';
import 'models/residentes_models.dart';
import 'residentes_repository.dart';
import 'widgets/security_section.dart';
import '../../core/widgets/top_toast.dart';
import '../../core/network/local_cache_repository.dart';

import '../../shared/widgets/user_profile_header.dart';
import '../../shared/widgets/basic_information_section.dart';
import '../../shared/widgets/territory_hierarchy_card.dart';
import '../../shared/widgets/kpi_card.dart';

class ResidenteDetailScreen extends StatefulWidget {
  final ResidenteItem residente;

  const ResidenteDetailScreen({super.key, required this.residente});

  @override
  State<ResidenteDetailScreen> createState() => _ResidenteDetailScreenState();
}

class _ResidenteDetailScreenState extends State<ResidenteDetailScreen> {
  late ResidenteItem _residente;
  bool _cargando = false;

  final _repo = ResidentesRepository();

  @override
  void initState() {
    super.initState();
    _residente = widget.residente;
  }

  Future<void> _recargarResidente() async {
    setState(() => _cargando = true);
    try {
      final lista = await _repo.getResidentes();
      final actualizado = lista.where((p) => p.id == _residente.id).firstOrNull;
      if (actualizado != null && mounted) {
        setState(() => _residente = actualizado);
      }
    } catch (_) {
      // Si falla la recarga, se queda con los datos actuales
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  // ── Fechas de cobro según modalidad ─────────────────────────────
  List<_ProximoCobro> _getProximosCobros() {
    final now = DateTime.now();
    final year = now.year;
    final month = now.month;
    final modalidad = _residente.modalidadPago.toUpperCase();

    List<DateTime> fechas;
    switch (modalidad) {
      case 'SEMANAL':
        fechas = _sabadosDelMes(year, month);
        break;
      case 'QUINCENAL':
        final ancla1 = DateTime(year, month, 15);
        final ancla2 = DateTime(year, month + 1, 0); // last day
        fechas = [_sabadoCercano(ancla1), _sabadoCercano(ancla2)];
        break;
      default: // MENSUAL
        final ultimoDia = DateTime(year, month + 1, 0);
        fechas = [_sabadoCercano(ultimoDia)];
    }

    return fechas.map((f) {
      final dateOnly = DateTime(f.year, f.month, f.day);
      final todayOnly = DateTime(now.year, now.month, now.day);

      _CobroStatus status;
      if (dateOnly.isBefore(todayOnly)) {
        status = _CobroStatus.pagado;
      } else if (dateOnly.isAtSameMomentAs(todayOnly)) {
        status = _CobroStatus.hoy;
      } else {
        status = _CobroStatus.pendiente;
      }
      return _ProximoCobro(fecha: f, status: status);
    }).toList();
  }

  List<DateTime> _sabadosDelMes(int year, int month) {
    final ultimoDia = DateTime(year, month + 1, 0).day;
    final sabados = <DateTime>[];
    for (int d = 1; d <= ultimoDia; d++) {
      final fecha = DateTime(year, month, d);
      if (fecha.weekday == DateTime.saturday) sabados.add(fecha);
    }
    if (sabados.length == 5) {
      if (sabados.first.day <= 2) {
        sabados.removeAt(0);
      } else {
        sabados.removeLast();
      }
    }
    return sabados;
  }

  DateTime _sabadoCercano(DateTime ancla) {
    final weekday = ancla.weekday;
    final diff = (DateTime.saturday - weekday) % 7;
    if (diff == 0) return ancla;
    final after = ancla.add(Duration(days: diff));
    final before = ancla.subtract(Duration(days: 7 - diff));
    return (diff <= 3) ? after : before;
  }

  String _proximoVencimiento() {
    final cobros = _getProximosCobros();
    final pendientes = cobros.where((c) => c.status != _CobroStatus.pagado);
    if (pendientes.isNotEmpty) {
      return DateFormat("d 'de' MMMM", 'es').format(pendientes.first.fecha);
    }
    // Proyección automática de la próxima cuota si no hay vencidos
    final now = DateTime.now();
    final modalidad = _residente.modalidadPago.toUpperCase();
    DateTime proxima;
    if (modalidad == 'SEMANAL') {
      proxima = _sabadoCercano(now.add(const Duration(days: 6)));
    } else if (modalidad == 'QUINCENAL') {
      proxima = DateTime(now.year, now.month + (now.day > 15 ? 1 : 0), now.day > 15 ? 1 : 15);
    } else {
      proxima = DateTime(now.year, now.month + 1, 1);
    }
    return DateFormat("d 'de' MMMM", 'es').format(proxima);
  }

  Future<void> _confirmarEliminar(BuildContext context) async {
    final seguro = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error),
            const SizedBox(width: AppSpacing.sm),
            const Text('Eliminar Residente'),
          ],
        ),
        content: Text(
          '¿Estás seguro de que deseas eliminar a "${_residente.nombre}"? Esta acción desasignará su casa y eliminará su usuario.',
          style: AppTypography.body,
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (seguro != true || !mounted) return;

    try {
      await ApiClient.instance.delete('/residentes/${_residente.id}');

      LocalCacheRepository.instance.invalidateAll();

      if (mounted) {
        TopToast.showSuccess(context, 'Residente eliminado correctamente');
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        TopToast.showError(context, 'Error al eliminar residente: $e');
      }
    }
  }

  void _mostrarModalEditar(BuildContext context) {
    final nombreCtrl = TextEditingController(text: _residente.nombre);
    final telefonoCtrl = TextEditingController(text: _residente.telefono);
    final emailCtrl = TextEditingController(text: _residente.email ?? '');
    String modalidadSeleccionada = _residente.modalidadPago.toUpperCase();
    bool guardando = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateModal) {
          return Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.only(
              left: AppSpacing.md,
              right: AppSpacing.md,
              top: AppSpacing.md,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.lg,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Editar Residente',
                    style: AppTypography.subtitle.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Modifica la información general de ${_residente.nombre}',
                    style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  TextField(
                    controller: nombreCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nombre completo',
                      prefixIcon: Icon(Icons.person_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  TextField(
                    controller: telefonoCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Teléfono de contacto',
                      prefixIcon: Icon(Icons.phone_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  TextField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Correo electrónico (Opcional)',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  DropdownButtonFormField<String>(
                    initialValue: modalidadSeleccionada,
                    decoration: const InputDecoration(
                      labelText: 'Modalidad de Pago',
                      prefixIcon: Icon(Icons.calendar_month_outlined),
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'SEMANAL', child: Text('Semanal (4 cuotas)')),
                      DropdownMenuItem(value: 'QUINCENAL', child: Text('Quincenal (2 cuotas)')),
                      DropdownMenuItem(value: 'MENSUAL', child: Text('Mensual (1 cuota)')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setStateModal(() => modalidadSeleccionada = val);
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: guardando ? null : () => Navigator.pop(ctx),
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      FilledButton.icon(
                        onPressed: guardando
                            ? null
                            : () async {
                                final nombre = nombreCtrl.text.trim();
                                if (nombre.isEmpty) {
                                  TopToast.showError(ctx, 'El nombre no puede estar vacío');
                                  return;
                                }
                                setStateModal(() => guardando = true);

                                final emailText = emailCtrl.text.trim();
                                final payload = <String, dynamic>{
                                  'nombre': nombre,
                                  'telefono': telefonoCtrl.text.trim(),
                                  'modalidadPago': modalidadSeleccionada,
                                  if (emailText.isNotEmpty) 'email': emailText,
                                };

                                final exito = await _repo.updateResidente(_residente.id, payload);

                                if (ctx.mounted) {
                                  if (exito) {
                                    Navigator.pop(ctx);
                                    TopToast.showSuccess(context, 'Residente actualizado correctamente');
                                    LocalCacheRepository.instance.invalidateAll();
                                    await _recargarResidente();
                                  } else {
                                    setStateModal(() => guardando = false);
                                    TopToast.showError(ctx, 'Error al actualizar residente');
                                  }
                                }
                              },
                        icon: guardando
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.save_rounded, size: 18),
                        label: const Text('Guardar Cambios'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Residente'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(true),
        ),
        actions: [
          if (_cargando)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Módulos',
              style: AppTypography.subtitle.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildGrid(context),
            const SizedBox(height: AppSpacing.xl),
            // ── Módulo de Seguridad ──
            if (_residente.usuarioId != null) ...[
              SecuritySection(
                usuarioId: _residente.usuarioId!,
                nombre: _residente.nombre,
                initialUsername: _residente.username,
                isAdmin: context.read<AuthCubit>().state.usuario?['rol'] == 'ADMIN',
                onCredentialsUpdated: () {
                  _recargarResidente();
                },
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final cobros = _getProximosCobros();

    return Column(
      children: [
        // 1. User Profile Header
        UserProfileHeader(
          nombre: _residente.nombre,
          rol: 'RESIDENTE',
        ),
        const SizedBox(height: AppSpacing.md),

        // 2. Territory Hierarchy Card (Sin redundancia del nombre ya que está arriba)
        TerritoryHierarchyCard(
          etapa: _residente.etapa,
          manzana: '',
          casaNumero: _residente.casa,
          residenteNombre: _residente.nombre,
          estadoRecaudo: _residente.estadoFinanciero,
          showResidenteName: false,
        ),
        const SizedBox(height: AppSpacing.md),

        // 3. KPI Cards Row (Simétricos en altura con IntrinsicHeight)
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: KPICard(
                  title: 'Deuda Actual',
                  value: '\$${_residente.saldoPendiente.toStringAsFixed(0)}',
                  subtitle: _residente.estadoFinanciero,
                  icon: Icons.account_balance_wallet_outlined,
                  color: _residente.saldoPendiente > 0 ? AppColors.error : AppColors.success,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: KPICard(
                  title: 'Próximo Venc.',
                  value: _proximoVencimiento(),
                  subtitle: 'Modalidad ${_residente.modalidadPago}',
                  icon: Icons.event_outlined,
                  color: AppColors.info,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // 4. Basic Information Section (con botón de edición para Admin)
        Column(
          children: [
            BasicInformationSection(
              emailOverride: _residente.email,
              telefonoOverride: _residente.telefono,
              modalidadOverride: _residente.modalidadPago,
              casaInfoOverride: '${_residente.etapa} - ${_residente.casa}',
            ),
            const SizedBox(height: AppSpacing.xs),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _mostrarModalEditar(context),
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Editar información'),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        _buildProximosCobros(cobros),
      ],
    );
  }

  IconData _modalidadIcon() {
    switch (_residente.modalidadPago.toUpperCase()) {
      case 'SEMANAL':
        return Icons.view_week_rounded;
      case 'QUINCENAL':
        return Icons.date_range_rounded;
      default:
        return Icons.calendar_month_rounded;
    }
  }

  Widget _buildProximosCobros(List<_ProximoCobro> cobros) {
    final modalidad = _residente.modalidadPago.toUpperCase();
    final mesActual = DateFormat('MMMM', 'es').format(DateTime.now());
    final label = switch (modalidad) {
      'SEMANAL' => 'Cobros semanales de $mesActual',
      'QUINCENAL' => 'Cobros quincenales de $mesActual',
      _ => 'Cobro mensual de $mesActual',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.event_note_rounded, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(label, style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        Row(
          children: [
            for (int i = 0; i < cobros.length; i++) ...[
              if (i > 0)
                Expanded(
                  child: Container(
                    height: 2,
                    color: cobros[i - 1].status == _CobroStatus.pagado
                        ? AppColors.success
                        : AppColors.border,
                  ),
                ),
              _buildCobroNode(cobros[i]),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildCobroNode(_ProximoCobro cobro) {
    final dayLabel = DateFormat('d', 'es').format(cobro.fecha);
    final dayName = DateFormat('EEE', 'es').format(cobro.fecha);

    Color nodeColor;
    Color bgColor;
    Widget? icon;

    switch (cobro.status) {
      case _CobroStatus.pagado:
        nodeColor = AppColors.success;
        bgColor = AppColors.success;
        icon = const Icon(Icons.check, size: 10, color: Colors.white);
        break;
      case _CobroStatus.hoy:
        nodeColor = AppColors.info;
        bgColor = AppColors.info;
        icon = const Icon(Icons.circle, size: 6, color: Colors.white);
        break;
      case _CobroStatus.pendiente:
        nodeColor = AppColors.border;
        bgColor = AppColors.background;
        icon = null;
        break;
    }

    return Column(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: bgColor,
            border: cobro.status == _CobroStatus.pendiente
                ? Border.all(color: nodeColor, width: 2)
                : null,
            boxShadow: cobro.status == _CobroStatus.hoy
                ? [BoxShadow(color: nodeColor.withValues(alpha: 0.4), blurRadius: 6, spreadRadius: 1)]
                : null,
          ),
          child: Center(child: icon),
        ),
        const SizedBox(height: 4),
        Text(
          dayLabel,
          style: AppTypography.small.copyWith(
            fontWeight: FontWeight.w700,
            color: cobro.status == _CobroStatus.hoy ? AppColors.info : AppColors.textPrimary,
          ),
        ),
        Text(
          dayName,
          style: AppTypography.small.copyWith(
            fontSize: 9,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      childAspectRatio: 2.8,
      crossAxisSpacing: AppSpacing.md,
      mainAxisSpacing: AppSpacing.md,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildModuleCard(
          context,
          title: 'Finanzas',
          icon: Icons.account_balance_wallet_rounded,
          color: AppColors.primary,
          route: '/comunidad/residentes/detalle/finanzas',
          extra: _residente,
        ),
        _buildModuleCard(
          context,
          title: 'Historial',
          icon: Icons.receipt_long_rounded,
          color: AppColors.success,
          route: '/comunidad/residentes/detalle/historial',
          extra: _residente,
        ),
        _buildModuleCard(
          context,
          title: 'Editar',
          icon: Icons.edit_rounded,
          color: AppColors.info,
          onTap: () => _mostrarModalEditar(context),
        ),
        _buildModuleCard(
          context,
          title: 'Eliminar',
          icon: Icons.delete_forever_rounded,
          color: AppColors.error,
          onTap: () => _confirmarEliminar(context),
        ),
      ],
    );
  }

  Widget _buildModuleCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    String? route,
    Object? extra,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap ?? () {
        if (route != null) {
          context.push(route, extra: extra);
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: AppSpacing.sm),
            Text(
              title,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: color == AppColors.error ? color : null,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

enum _CobroStatus { pagado, hoy, pendiente }

class _ProximoCobro {
  final DateTime fecha;
  final _CobroStatus status;

  const _ProximoCobro({required this.fecha, required this.status});
}
