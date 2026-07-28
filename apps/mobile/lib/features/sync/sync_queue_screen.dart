import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/sync/sync_service.dart';
import '../../shared/widgets/empty_state.dart';

class SyncQueueScreen extends StatefulWidget {
  const SyncQueueScreen({super.key});

  @override
  State<SyncQueueScreen> createState() => _SyncQueueScreenState();
}

class _SyncQueueScreenState extends State<SyncQueueScreen> {
  bool _loading = true;
  bool _syncing = false;
  List<Map<String, dynamic>> _pendingPagos = [];

  @override
  void initState() {
    super.initState();
    _loadQueue();
  }

  Future<void> _loadQueue() async {
    setState(() => _loading = true);
    try {
      final queue = await SyncService.instance.getPendingQueue();
      if (mounted) {
        setState(() {
          _pendingPagos = queue;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _sincronizarAhora() async {
    setState(() => _syncing = true);
    try {
      await SyncService.instance.syncPendingPagos();
      await _loadQueue();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sincronización completada.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error de sincronización: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0, locale: 'es_CO');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cola de Sincronización'),
        centerTitle: false,
        actions: [
          if (_pendingPagos.isNotEmpty)
            IconButton(
              icon: _syncing
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.sync_rounded),
              onPressed: _syncing ? null : _sincronizarAhora,
              tooltip: 'Sincronizar Ahora',
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadQueue,
              child: _pendingPagos.isEmpty
                  ? const EmptyState(
                      icon: Icons.cloud_done_rounded,
                      title: 'Todo Sincronizado',
                      description: 'No hay cobros pendientes de envío en la memoria local del dispositivo.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      itemCount: _pendingPagos.length,
                      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final item = _pendingPagos[index];
                        final clientPaymentId = item['clientPaymentId'] ?? 'ID Local';
                        final montoCents = (item['monto'] as num?)?.toInt() ?? 0;
                        final montoCop = (montoCents / 100).round();
                        final fecha = item['fechaPago'] ?? '';

                        return Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: AppColors.border),
                          ),
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.cloud_upload_outlined, color: AppColors.warning),
                            ),
                            title: Text(
                              currencyFormat.format(montoCop),
                              style: AppTypography.subtitle.copyWith(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text('Fecha: $fecha\nTicket: ${clientPaymentId.substring(0, 8)}...'),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'PENDIENTE',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.warning,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
