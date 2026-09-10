import 'package:flutter/material.dart';
import '../../core/format/app_currency.dart';
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
  List<Map<String, dynamic>> _queueItems = [];

  @override
  void initState() {
    super.initState();
    _loadQueue();
  }

  Future<void> _loadQueue() async {
    setState(() => _loading = true);
    try {
      final queue = await SyncService.instance.getAllQueueItems();
      if (mounted) {
        setState(() {
          _queueItems = queue;
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
          const SnackBar(content: Text('Proceso de sincronización ejecutado.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al sincronizar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  Future<void> _limpiarSincronizados() async {
    final count = await SyncService.instance.limpiarSincronizados();
    await _loadQueue();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Se limpiaron $count registro(s) sincronizados.')),
      );
    }
  }

  Future<void> _reintentarItem(String id) async {
    setState(() => _syncing = true);
    try {
      await SyncService.instance.reintentarPago(id);
      await _loadQueue();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reintento manual completado.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reintento fallido: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasSincronizados = _queueItems.any((i) => i['syncStatus'] == 'SYNC_OK');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cola de Sincronización'),
        centerTitle: false,
        actions: [
          if (hasSincronizados)
            IconButton(
              icon: Icon(Icons.cleaning_services_rounded, color: AppColors.success),
              onPressed: _limpiarSincronizados,
              tooltip: 'Limpiar Sincronizados',
            ),
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
              child: _queueItems.isEmpty
                  ? const EmptyState(
                      icon: Icons.cloud_done_rounded,
                      title: 'Todo Sincronizado',
                      description: 'No hay cobros pendientes de envío en la memoria local del dispositivo.',
                    )
                  : Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF0F172A)
                              : const Color(0xFFF8FAFC),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline_rounded, size: 16, color: AppColors.textSecondary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Los cobros en verde están guardados en la nube. Los rojos permiten reintento manual.',
                                  style: AppTypography.small.copyWith(color: AppColors.textSecondary),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            itemCount: _queueItems.length,
                            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                            itemBuilder: (context, index) {
                              final item = _queueItems[index];
                              final id = item['id'] as String;
                              final clientPaymentId = item['clientPaymentId'] as String? ?? 'ID Local';
                              final montoCents = (item['monto'] as num?)?.toInt() ?? 0;
                              final montoCop = AppCurrency.centsToPesos(montoCents);
                              final fecha = item['fechaPago'] as String? ?? '';
                              final syncStatus = item['syncStatus'] as String? ?? 'PENDIENTE_SYNC';

                              final bool isOk = syncStatus == 'SYNC_OK';
                              final bool isError = syncStatus == 'CONFLICTO' || syncStatus == 'ERROR_RED';

                              final Color statusColor = isOk
                                  ? AppColors.success
                                  : isError
                                      ? AppColors.error
                                      : AppColors.warning;

                              final IconData statusIcon = isOk
                                  ? Icons.check_circle_rounded
                                  : isError
                                      ? Icons.error_outline_rounded
                                      : Icons.cloud_upload_outlined;

                              final String statusLabel = isOk
                                  ? '✓ SINCRONIZADO'
                                  : isError
                                      ? '⚠ ERROR / CONFLICTO'
                                      : '⏳ PENDIENTE';

                              return Card(
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(color: statusColor.withValues(alpha: 0.3)),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: statusColor.withValues(alpha: 0.12),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(statusIcon, color: statusColor, size: 22),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              AppCurrency.format(montoCop),
                                              style: AppTypography.subtitle.copyWith(fontWeight: FontWeight.bold),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Ticket: ${clientPaymentId.length > 12 ? clientPaymentId.substring(0, 12) : clientPaymentId}',
                                              style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                                            ),
                                            Text(
                                              'Fecha: $fecha',
                                              style: AppTypography.small.copyWith(color: AppColors.textSecondary.withValues(alpha: 0.8)),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: statusColor.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              statusLabel,
                                              style: AppTypography.smallBold.copyWith(
                                                color: statusColor,
                                              ),
                                            ),
                                          ),
                                          if (isError) ...[
                                            const SizedBox(height: 6),
                                            InkWell(
                                              onTap: _syncing ? null : () => _reintentarItem(id),
                                              borderRadius: BorderRadius.circular(8),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: AppColors.error.withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(Icons.refresh_rounded, size: 12, color: Colors.red),
                                                    SizedBox(width: 4),
                                                    Text(
                                                      'Reintentar',
                                                      style: AppTypography.smallBold.copyWith(color: Colors.red),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
            ),
    );
  }
}
