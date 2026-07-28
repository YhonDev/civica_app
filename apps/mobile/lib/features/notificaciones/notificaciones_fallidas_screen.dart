import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/network/api_client.dart';
import '../../shared/widgets/empty_state.dart';

class NotificacionesFallidasScreen extends StatefulWidget {
  const NotificacionesFallidasScreen({super.key});

  @override
  State<NotificacionesFallidasScreen> createState() => _NotificacionesFallidasScreenState();
}

class _NotificacionesFallidasScreenState extends State<NotificacionesFallidasScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _loadFallidas();
  }

  Future<void> _loadFallidas() async {
    setState(() => _loading = true);
    try {
      final response = await ApiClient.instance.get('/notificaciones/fallidas');
      final list = List<Map<String, dynamic>>.from(response.data as List? ?? []);
      if (mounted) {
        setState(() {
          _items = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _reintentar(String id) async {
    try {
      await ApiClient.instance.post('/notificaciones/$id/reintentar');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notificación encolada para reintento.')),
        );
        _loadFallidas();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al reintentar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones Fallidas'),
        centerTitle: false,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadFallidas,
              child: _items.isEmpty
                  ? const EmptyState(
                      icon: Icons.mark_email_read_outlined,
                      title: 'Sin fallos de envío',
                      description: 'Todas las notificaciones por correo fueron entregadas correctamente.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      itemCount: _items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        final id = item['id'] as String;
                        final email = item['destinatarioEmail'] ?? 'Sin email';
                        final asunto = item['asunto'] ?? 'Vencimiento de cuota';
                        final intentos = item['intentos'] ?? 3;

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
                                color: AppColors.error.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.mail_lock_rounded, color: AppColors.error),
                            ),
                            title: Text(email, style: AppTypography.subtitle.copyWith(fontWeight: FontWeight.bold)),
                            subtitle: Text('$asunto • Intento $intentos/3', style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
                            trailing: TextButton.icon(
                              icon: const Icon(Icons.refresh_rounded, size: 18),
                              label: const Text('Reintentar'),
                              onPressed: () => _reintentar(id),
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
