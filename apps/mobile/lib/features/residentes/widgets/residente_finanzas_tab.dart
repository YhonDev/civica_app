import 'package:flutter/material.dart';
import '../../../core/network/error_messages.dart';
import '../../../core/format/app_currency.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/network/api_client.dart';
import '../models/residentes_models.dart';
import '../residentes_repository.dart';
import 'package:intl/intl.dart';

class ResidenteFinanzasScreen extends StatefulWidget {
  final ResidenteItem residente;

  const ResidenteFinanzasScreen({super.key, required this.residente});

  @override
  State<ResidenteFinanzasScreen> createState() => _ResidenteFinanzasScreenState();
}

class _ResidenteFinanzasScreenState extends State<ResidenteFinanzasScreen> {
  final ResidentesRepository _repo = ResidentesRepository();
  bool _isLoading = true;
  List<dynamic> _cuotas = [];

  @override
  void initState() {
    super.initState();
    _loadDeudas();
  }

  Future<void> _loadDeudas() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiClient.instance.get<List<dynamic>>(
        '/cobros/residente/${widget.residente.id}',
      );
      if (mounted) {
        setState(() {
          // Filtrar solo cuotas con deuda (PENDIENTE, PARCIAL, VENCIDA)
          // Si el usuario quiere ver las pagadas, deberían ir en otra pestaña, 
          // pero dejémoslas todas y las separamos visualmente.
          _cuotas = response.data ?? [];
          // Ordenar: primero las que deben
          _cuotas.sort((a, b) {
            final estadoA = a['estado'];
            final estadoB = b['estado'];
            if (estadoA == 'PAGADA' && estadoB != 'PAGADA') return 1;
            if (estadoA != 'PAGADA' && estadoB == 'PAGADA') return -1;
            return b['periodoInicio'].compareTo(a['periodoInicio']);
          });
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar deudas: ${sanitizeApiError(e)}')),
        );
      }
    }
  }

  void _eliminarCuota(String id) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Cobro'),
        content: const Text('¿Estás seguro de que quieres eliminar esta cuota? Esto anulará la deuda. Si ya hay pagos asociados, debes reversarlos primero.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              final success = await _repo.deleteCuota(id);
              if (success) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cobro eliminado. La deuda ha desaparecido.')),
                  );
                }
                _loadDeudas();
              } else {
                if (mounted) {
                  setState(() => _isLoading = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Error: No se pudo eliminar la cuota.')),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión Financiera'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_cuotas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: AppColors.success),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No hay cobros generados',
              style: AppTypography.title.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDeudas,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        itemCount: _cuotas.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) {
          final cuota = _cuotas[index];
          final estado = cuota['estado'] as String;
          final monto = AppCurrency.centsFromJson(cuota['monto']).toDouble();
          final montoPagado = AppCurrency.centsFromJson(cuota['montoPagado']).toDouble();
          final saldo = monto - montoPagado;
          final concepto = cuota['concepto'] ?? 'Cobro';
          final mesStr = cuota['periodoInicio'] != null 
              ? DateFormat('MMMM yyyy', 'es').format(DateTime.parse(cuota['periodoInicio'])) 
              : '';

          Color estadoColor = AppColors.textSecondary;
          if (estado == 'PENDIENTE') estadoColor = AppColors.warning;
          if (estado == 'VENCIDA') estadoColor = AppColors.error;
          if (estado == 'PARCIAL') estadoColor = AppColors.warning;
          if (estado == 'PAGADA') estadoColor = AppColors.success;

          return Card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(AppSpacing.md),
              title: Text(
                '$concepto - ${mesStr.toUpperCase()}',
                style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    'Valor: ${AppCurrency.format(monto)}',
                    style: AppTypography.caption,
                  ),
                  if (saldo > 0 && saldo < monto)
                    Text(
                      'Saldo: ${AppCurrency.format(saldo)}',
                      style: AppTypography.caption.copyWith(color: AppColors.error, fontWeight: FontWeight.w600),
                    ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: estadoColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                    ),
                    child: Text(
                      estado,
                      style: AppTypography.caption.copyWith(
                        color: estadoColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              trailing: IconButton(
                icon: Icon(Icons.delete_outline, color: AppColors.error.withValues(alpha: 0.7)),
                tooltip: 'Eliminar deuda (Anular cobro)',
                onPressed: () => _eliminarCuota(cuota['id']),
              ),
            ),
          );
        },
      ),
    );
  }
}
