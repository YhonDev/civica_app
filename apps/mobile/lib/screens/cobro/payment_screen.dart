import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../core/database/app_database.dart';
import '../../core/theme/app_spacing.dart';
import '../../features/cartera/widgets/residente_inline_sheet.dart';
import 'bloc.dart';

/// Pantalla de cobro donde el cobrador selecciona cuotas y registra el pago offline.
class PaymentScreen extends StatelessWidget {
  final Residente? propietario;
  final String casaDireccion;
  final String etapaNombre;
  final String cobradorId;
  final String? solicitudId;
  final String? casaId;

  const PaymentScreen({
    super.key,
    this.propietario,
    required this.casaDireccion,
    required this.etapaNombre,
    this.cobradorId = 'offline',
    this.solicitudId,
    this.casaId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final bloc = CobroBloc();
        if (propietario != null) {
          bloc.add(CargarResidente(
            residente: propietario!,
            casaDireccion: casaDireccion,
            etapaNombre: etapaNombre,
          ));
        }
        return bloc;
      },
      child: _PaymentScreenBody(
        propietario: propietario,
        casaDireccion: casaDireccion,
        etapaNombre: etapaNombre,
        cobradorId: cobradorId,
        solicitudId: solicitudId,
        casaId: casaId,
      ),
    );
  }
}

class _PaymentScreenBody extends StatefulWidget {
  final Residente? propietario;
  final String casaDireccion;
  final String etapaNombre;
  final String cobradorId;
  final String? solicitudId;
  final String? casaId;

  const _PaymentScreenBody({
    this.propietario,
    required this.casaDireccion,
    required this.etapaNombre,
    this.cobradorId = 'offline',
    this.solicitudId,
    this.casaId,
  });

  @override
  State<_PaymentScreenBody> createState() => _PaymentScreenBodyState();
}

class _PaymentScreenBodyState extends State<_PaymentScreenBody> {
  final _montoController = TextEditingController();
  Residente? _propietario;

  @override
  void initState() {
    super.initState();
    _propietario = widget.propietario;
  }

  @override
  void dispose() {
    _montoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocConsumer<CobroBloc, CobroState>(
      listener: (context, state) {
        if (state is CobroSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(child: Text(state.mensaje)),
                ],
              ),
              backgroundColor: Colors.green.shade700,
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: 'OK',
                textColor: Colors.white,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          );
        }
        if (state is CobroError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.mensaje),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Registrar Cobro'),
            centerTitle: true,
            backgroundColor: colorScheme.primaryContainer,
            foregroundColor: colorScheme.onPrimaryContainer,
          ),
          body: _buildBody(context, state, theme, colorScheme),
        );
      },
    );
  }

  void _mostrarRegistroInline() {
    ResidenteInlineSheet.show(
      context,
      preselectedCasaId: widget.casaId,
      onSuccess: (creado) {
        final userMap = creado['usuario'] as Map<String, dynamic>;
        final res = Residente(
          id: userMap['id'] ?? '',
          nombre: userMap['nombre'] ?? '',
          telefono: userMap['telefono'] ?? '',
          email: userMap['email'],
          tenantId: userMap['tenantId'] ?? '00000000-0000-0000-0000-000000000001',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        setState(() {
          _propietario = res;
        });
        context.read<CobroBloc>().add(CargarResidente(
              residente: res,
              casaDireccion: widget.casaDireccion,
              etapaNombre: widget.etapaNombre,
            ));
      },
    );
  }

  Widget _buildNoResidenteView(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.house_rounded, size: 64, color: colorScheme.secondary),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Casa sin Residente',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Esta casa no tiene un residente asignado. Registra un residente para poder realizar cobros.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: _mostrarRegistroInline,
              icon: const Icon(Icons.person_add_rounded),
              label: const Text('Registrar Residente'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    CobroState state,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    if (_propietario == null) {
      return _buildNoResidenteView(context, theme, colorScheme);
    }

    if (state is CobroLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is CobroError && state is! CobroLoaded) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: colorScheme.error),
            const SizedBox(height: 16),
            Text(state.mensaje, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.read<CobroBloc>().add(
                    CargarResidente(
                      residente: _propietario!,
                      casaDireccion: widget.casaDireccion,
                      etapaNombre: widget.etapaNombre,
                    ),
                  ),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (state is CobroSuccess) {
      return _buildSuccessView(context, state, theme, colorScheme);
    }

    if (state is! CobroLoaded) {
      return const Center(child: Text('Iniciando...'));
    }

    return _buildPaymentView(context, state, theme, colorScheme);
  }

  Widget _buildSuccessView(
    BuildContext context,
    CobroSuccess state,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final fmt = NumberFormat.decimalPattern('es-CO');
    final fecha = DateTime.tryParse(state.fechaPago);
    final fechaStr = fecha != null
        ? DateFormat("d 'de' MMMM 'de' yyyy, HH:mm", 'es').format(fecha)
        : state.fechaPago;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded, size: 80, color: Colors.green.shade600),
            const SizedBox(height: 24),
            Text(
              '¡Pago registrado!',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
            const SizedBox(height: 20),

            // ── Recibo / trazabilidad ──
            Card(
              elevation: 0,
              color: colorScheme.surfaceContainerHighest,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _DetalleRow(icon: Icons.person, label: 'Residente', value: state.propietarioNombre, colorScheme: colorScheme),
                    const Divider(height: 16),
                    _DetalleRow(icon: Icons.receipt, label: 'Monto', value: '\$${fmt.format(state.montoTotal)}', colorScheme: colorScheme),
                    const Divider(height: 16),
                    _DetalleRow(icon: Icons.tag, label: 'Comprobante', value: state.pagoId.length > 20 ? '...${state.pagoId.substring(state.pagoId.length - 20)}' : state.pagoId, colorScheme: colorScheme),
                    const Divider(height: 16),
                    _DetalleRow(icon: Icons.person_outline, label: 'Cobrador', value: state.cobradorId, colorScheme: colorScheme),
                    const Divider(height: 16),
                    _DetalleRow(icon: Icons.access_time, label: 'Fecha', value: fechaStr, colorScheme: colorScheme),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Se sincronizará automáticamente cuando haya conexión.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.outline,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Volver'),
                ),
                const SizedBox(width: 16),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Nuevo cobro'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentView(
    BuildContext context,
    CobroLoaded state,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final fmt = NumberFormat.decimalPattern('es-CO');
    final p = state.propietario;

    return Column(
      children: [
        // ── Inline error message ────────────────────────────
        if (state.errorMessage != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.red.shade50,
            child: Row(
              children: [
                Icon(Icons.error_outline, size: 18, color: Colors.red.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    state.errorMessage!,
                    style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

        // ── Scrollable content ──────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info del propietario
                _ResidenteHeader(
                  nombre: p.nombre,
                  telefono: p.telefono,
                  casaDireccion: state.casaDireccion,
                  etapaNombre: state.etapaNombre,
                  colorScheme: colorScheme,
                ),
                const SizedBox(height: 20),

                // Cuotas pendientes
                Text(
                  'Cobros pendientes',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),

                if (state.cuotas.isEmpty)
                  Card(
                    elevation: 0,
                    color: colorScheme.surfaceContainerHighest,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'No hay cobros pendientes',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.outline,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  ...state.cuotas.map(
                    (cuota) => _CobroTile(
                      cuota: cuota,
                      isSelected: state.selectedCobroIds.contains(cuota.cuota.id),
                      onToggle: () {
                        context
                            .read<CobroBloc>()
                            .add(AlternarCobro(cuota.cuota.id));
                      },
                      colorScheme: colorScheme,
                      theme: theme,
                      fmt: fmt,
                    ),
                  ),

                const SizedBox(height: 16),

                // Monto manual adicional
                Text(
                  'Monto adicional',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _montoController,
                  decoration: InputDecoration(
                    labelText: 'Monto en pesos',
                    prefixIcon: const Icon(Icons.attach_money),
                    border: const OutlineInputBorder(),
                    hintText: 'Ej: 50000',
                    helperText: 'Monto extra no asociado a una cuota específica',
                    helperMaxLines: 2,
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (val) {
                    context
                        .read<CobroBloc>()
                        .add(CambiarMontoManual(val));
                  },
                ),
              ],
            ),
          ),
        ),

        // ── Barra inferior con total y botón ───────────────
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                // Total
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Total a cobrar',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.outline,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '\$${fmt.format(state.montoTotal)}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Botón
                FilledButton.icon(
                  onPressed: state.puedePagar
                      ? () => _confirmarPago(context, state, fmt)
                      : null,
                  icon: const Icon(Icons.payments_outlined),
                  label: const Text('Registrar pago'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _confirmarPago(
    BuildContext context,
    CobroLoaded state,
    NumberFormat fmt,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar pago'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Propietario: ${state.propietario.nombre}'),
            const SizedBox(height: 8),
            if (state.selectedCobroIds.isNotEmpty) ...[
              Text(
                'Cobros a pagar: ${state.selectedCobroIds.length}',
              ),
              const SizedBox(height: 4),
            ],
            if (state.montoManual > 0) ...[
              // montoManual está en centavos; el display es en pesos
              Text('Monto adicional: \$${fmt.format(state.montoManual / 100)}'),
              const SizedBox(height: 4),
            ],
            const Divider(),
            Text(
              'Total: \$${fmt.format(state.montoTotal)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'El pago se guardará offline y se sincronizará cuando haya conexión.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context
                  .read<CobroBloc>()
                  .add(RegistrarPago(cobradorId: widget.cobradorId, solicitudId: widget.solicitudId));
            },
            child: const Text('Confirmar pago'),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// HEADER DEL PROPIETARIO
// ════════════════════════════════════════════════════════════

class _ResidenteHeader extends StatelessWidget {
  final String nombre;
  final String telefono;
  final String casaDireccion;
  final String etapaNombre;
  final ColorScheme colorScheme;

  const _ResidenteHeader({
    required this.nombre,
    required this.telefono,
    required this.casaDireccion,
    required this.etapaNombre,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: colorScheme.primaryContainer.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.primaryContainer),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: colorScheme.primaryContainer,
              foregroundColor: colorScheme.onPrimaryContainer,
              child: Text(
                nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nombre, style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  )),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.home_outlined, size: 14, color: colorScheme.outline),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          '$casaDireccion · $etapaNombre',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.outline,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (telefono.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.phone_outlined, size: 14, color: colorScheme.outline),
                        const SizedBox(width: 4),
                        Text(telefono, style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.outline,
                        )),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// TILE DE CUOTA SELECCIONABLE
// ════════════════════════════════════════════════════════════

class _CobroTile extends StatelessWidget {
  final CobroConSeleccion cuota;
  final bool isSelected;
  final VoidCallback onToggle;
  final ColorScheme colorScheme;
  final ThemeData theme;
  final NumberFormat fmt;

  const _CobroTile({
    required this.cuota,
    required this.isSelected,
    required this.onToggle,
    required this.colorScheme,
    required this.theme,
    required this.fmt,
  });

  Color? _estadoColor() {
    switch (cuota.cuota.estado) {
      case 'VENCIDA':
        return Colors.red.shade100;
      case 'PENDIENTE':
        return Colors.orange.shade100;
      case 'PARCIAL':
        return Colors.blue.shade100;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = cuota.cuota;
    final vencimiento = DateTime.tryParse(c.fechaVencimiento);
    final vencimientoStr = vencimiento != null
        ? DateFormat('d MMM yyyy', 'es').format(vencimiento)
        : c.fechaVencimiento;

    return Card(
      elevation: 0,
      color: isSelected
          ? colorScheme.primaryContainer.withValues(alpha: 0.4)
          : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // Checkbox
              Checkbox(
                value: isSelected,
                onChanged: (_) => onToggle(),
              ),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          c.concepto,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _estadoColor(),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            cuota.estadoLabel,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Vence: $vencimientoStr',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),

              // Monto
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${fmt.format(c.monto)}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (cuota.saldoPendiente > 0 && cuota.saldoPendiente < c.monto)
                    Text(
                      'Saldo: \$${fmt.format(cuota.saldoPendiente)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.outline,
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
}

/// Helper widget para mostrar una fila de detalle en el recibo de pago.
class _DetalleRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ColorScheme colorScheme;

  const _DetalleRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 18, color: colorScheme.primary),
        const SizedBox(width: 10),
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.outline,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
