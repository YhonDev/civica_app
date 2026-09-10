import 'package:flutter/material.dart';
import '../../core/theme/app_spacing.dart';

import '../../core/theme/app_colors.dart';
import '../../core/network/api_health_service.dart';

/// Pantalla de bloqueo que se muestra cuando la API no responde al arrancar
/// en builds de debug. Explica el problema real (backend apagado / URL mal
/// configurada) en lugar de dejar pantallas con "DioException [unknown]: null".
class ApiUnavailableScreen extends StatefulWidget {
  final ApiHealthService healthService;

  /// Llamado cuando un reintento logra alcanzar la API.
  final VoidCallback? onAvailable;

  const ApiUnavailableScreen({
    super.key,
    required this.healthService,
    this.onAvailable,
  });

  @override
  State<ApiUnavailableScreen> createState() => _ApiUnavailableScreenState();
}

class _ApiUnavailableScreenState extends State<ApiUnavailableScreen> {
  bool _checking = false;

  Future<void> _reintentar() async {
    setState(() => _checking = true);
    final ok = await widget.healthService.isApiReachable();
    if (!mounted) return;
    if (ok) {
      widget.onAvailable?.call();
    } else {
      setState(() => _checking = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sigue sin responder. Verifica que el backend esté corriendo.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.cloud_off_rounded,
                  size: 72,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
                const SizedBox(height: 24),
                Text(
                  'API no disponible',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'La aplicación no pudo conectarse con el servidor backend.\n\n'
                  'Verifica que:\n'
                  '• El backend esté corriendo (puerto 3000)\n'
                  '• La URL de la API sea correcta\n'
                  '• No haya un firewall bloqueando la conexión',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: _checking ? null : _reintentar,
                  icon: _checking
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh_rounded),
                  label: Text(_checking ? 'Verificando…' : 'Reintentar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
