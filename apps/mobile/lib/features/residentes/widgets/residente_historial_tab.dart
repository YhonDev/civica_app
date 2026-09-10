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
import '../../../shared/widgets/ticket_bottom_sheet.dart';

class ResidenteHistorialScreen extends StatefulWidget {
  final ResidenteItem residente;

  const ResidenteHistorialScreen({super.key, required this.residente});

  @override
  State<ResidenteHistorialScreen> createState() => _ResidenteHistorialScreenState();
}

class _ResidenteHistorialScreenState extends State<ResidenteHistorialScreen> {
  final ResidentesRepository _repo = ResidentesRepository();
  bool _isLoading = true;
  List<dynamic> _pagos = [];

  @override
  void initState() {
    super.initState();
    _loadPagos();
  }

  Future<void> _loadPagos() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiClient.instance.get<List<dynamic>>(
        '/pagos',
        queryParameters: {'residenteId': widget.residente.id},
      );
      if (mounted) {
        setState(() {
          _pagos = response.data ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar historial: ${sanitizeApiError(e)}')),
        );
      }
    }
  }

  void _eliminarPago(String id) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reversar Pago'),
        content: const Text('¿Estás seguro de reversar este pago? El dinero se restará y las cuotas volverán a estar en Mora o Pendientes.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              final success = await _repo.deletePago(id);
              if (success) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Pago reversado. La deuda se ha restaurado.')),
                  );
                }
                _loadPagos();
              } else {
                if (mounted) {
                  setState(() => _isLoading = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Error: No se pudo reversar el pago.')),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Reversar'),
          ),
        ],
      ),
    );
  }

  Future<void> _abrirTicket(Map<String, dynamic> pago) async {
    final pagoId = pago['id'];
    if (pagoId != null) {
      try {
        final response = await ApiClient.instance.get<dynamic>(
          '/tickets',
          queryParameters: {'pagoId': pagoId},
        );
        if (response.data != null && mounted) {
          final ticketData = TicketData.fromJson(response.data as Map<String, dynamic>);
          TicketBottomSheet.show(context, ticketData);
          return;
        }
      } catch (_) {
        // Fallback if backend ticket lookup fails
      }
    }

    if (!mounted) return;
    final monto = AppCurrency.centsFromJson(pago['monto']);
    TicketBottomSheet.show(
      context,
      TicketData(
        numero: pago['clientPaymentId'] ?? 'N/A',
        fecha: pago['createdAt'] != null
            ? (DateTime.tryParse(pago['createdAt'])?.toLocal() ?? DateTime.now())
            : (pago['fechaPago'] != null ? (DateTime.tryParse(pago['fechaPago'])?.toLocal() ?? DateTime.now()) : DateTime.now()),
        monto: monto,
        estado: 'PAGADO',
        residente: widget.residente.nombre,
        casa: widget.residente.casa,
        metodo: 'Efectivo',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Pagos'),
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

    if (_pagos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_rounded, size: 64, color: AppColors.textDisabled),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No hay pagos registrados',
              style: AppTypography.title.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPagos,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        itemCount: _pagos.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) {
          final pago = _pagos[index];
          final monto = AppCurrency.centsFromJson(pago['monto']).toDouble();
          final fechaPago = pago['fechaPago'] != null
              ? DateFormat('dd MMM yyyy', 'es').format(DateTime.parse(pago['fechaPago']))
              : '';
          final ref = pago['clientPaymentId'] ?? 'N/A';

          return Card(
            child: ListTile(
              onTap: () => _abrirTicket(pago),
              contentPadding: const EdgeInsets.all(AppSpacing.md),
              leading: CircleAvatar(
                backgroundColor: AppColors.success.withValues(alpha: 0.1),
                child: Icon(Icons.receipt_long_rounded, color: AppColors.success),
              ),
              title: Text(
                'Pago por ${AppCurrency.format(monto)}',
                style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text('Fecha: $fechaPago', style: AppTypography.caption),
                  Text('Ref: $ref', style: AppTypography.caption),
                ],
              ),
              trailing: IconButton(
                icon: Icon(Icons.undo_rounded, color: AppColors.error.withValues(alpha: 0.8)),
                tooltip: 'Reversar Pago',
                onPressed: () => _eliminarPago(pago['id']),
              ),
            ),
          );
        },
      ),
    );
  }
}
