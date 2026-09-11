// Galería de depuración visual (solo desarrollo; no se referencia desde la app).
//
// Monta pantallas REALES (LoginScreen, CarteraScreen) con repositorio fake
// y permite alternar los ejes a validar tras la rama de hardening:
// pantalla (login/cartera), modo (claro/oscuro), textScaler (1.0/1.3/1.6)
// y viewport (phone/tablet/desktop).
//
// Con el clamp de producción (§7.6), 1.6 se ve IGUAL que 1.3; aquí el valor
// se inyecta crudo a propósito para poder comparar el efecto del clamp.
//
// Ejecutar:  flutter run -d web-server -t lib/debug/visual_gallery.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/network/api_client.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/auth_cubit.dart';
import '../features/auth/login_screen.dart';
import '../features/cartera/cartera_screen.dart';
import '../core/widgets/top_toast.dart';
import 'fake_cartera_data.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // El constructor base de CarteraRepository resuelve ApiClient.instance;
  // con el repo fake nunca se hace HTTP, pero la instancia debe existir.
  ApiClient.init(baseUrl: 'http://127.0.0.1:1/api', enableLogging: false);
  runApp(const VisualGalleryApp());
}

class VisualGalleryApp extends StatefulWidget {
  const VisualGalleryApp({super.key});

  @override
  State<VisualGalleryApp> createState() => _VisualGalleryAppState();
}

class _VisualGalleryAppState extends State<VisualGalleryApp> {
  String _screen = 'login';
  bool _dark = false;
  double _scale = 1.0;
  String _vp = 'phone';
  String? _toast;

  double get _vpWidth {
    switch (_vp) {
      case 'desktop':
        return 1000;
      case 'tablet':
        return 820;
      default:
        return 390;
    }
  }

  double get _vpHeight {
    switch (_vp) {
      case 'desktop':
        return 900;
      case 'tablet':
        return 1180;
      default:
        return 844;
    }
  }

  AuthCubit? _authCubit;

  @override
  void initState() {
    super.initState();
    // Estado inicial por query string: cada combinación es una URL
    // navegable/compartible. Ej.: /?screen=cartera&dark=1&scale=1.3&vp=phone
    final q = Uri.base.queryParameters;
    _screen = q['screen'] ?? _screen;
    _dark = q['dark'] == '1';
    _scale = double.tryParse(q['scale'] ?? '') ?? _scale;
    _vp = q['vp'] ?? _vp;
    _toast = q['toast']; // ?toast=success|error|info|warning dispara el toast
    AppColors.setDarkMode(_dark);

    // Cubit fresco (estado initial): CarteraScreen resuelve la vista admin
    // por defecto y LoginScreen muestra el formulario sin sesión.
    _authCubit = AuthCubit();
  }

  @override
  void dispose() {
    _authCubit?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _dark;
    return MaterialApp(
      title: 'Cívica Pago — Galería visual (debug)',
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      builder: (context, child) {
        // textScaler crudo: permite ver el clamp de producción comparando.
        final scaler = TextScaler.linear(_scale);
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: scaler),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: Scaffold(
        backgroundColor:
            isDark ? AppColors.darkBackground : AppColors.lightBackground,
        // Layout apilado: panel arriba, host debajo con todo el ancho
        // disponible (evita recortes cuando la ventana de preview es angosta).
        body: Stack(
          children: [
            Column(
              children: [
                _GalleryPanel(
                  screen: _screen,
                  dark: isDark,
                  scale: _scale,
                  vp: _vp,
                  toast: _toast,
                  onScreen: (s) => setState(() => _screen = s),
                  onDark: (d) {
                    setState(() {
                      _dark = d;
                      // AppColors es estático: sincronizar el modo para los
                      // widgets que leen tokens dinámicos fuera del Theme.
                      AppColors.setDarkMode(d);
                    });
                  },
                  onScale: (s) => setState(() => _scale = s),
                  onVp: (v) => setState(() => _vp = v),
                  onToast: (t) => setState(
                      () => _toast = (_toast == t) ? null : t),
                ),
                Expanded(
                  child: _GalleryHost(
                    key: ValueKey('$_screen-$_dark-$_scale-$_vp'),
                    screen: _screen,
                    vpWidth: _vpWidth,
                    vpHeight: _vpHeight,
                    authCubit: _authCubit!,
                  ),
                ),
              ],
            ),
            // Disparador del toast estándar (si se pidió por panel o URL).
            // Duración larga: la galería es para inspección visual.
            if (_toast != null)
              _ToastAutoShow(
                key: ValueKey('toast-$_toast-$_dark'),
                type: switch (_toast) {
                  'error' => ToastType.error,
                  'info' => ToastType.info,
                  'warning' => ToastType.warning,
                  _ => ToastType.success,
                },
              ),
          ],
        ),
      ),
    );
  }
}

/// Panel de control lateral.
class _GalleryPanel extends StatelessWidget {
  final String screen;
  final bool dark;
  final double scale;
  final String vp;
  final String? toast;
  final ValueChanged<String> onScreen;
  final ValueChanged<bool> onDark;
  final ValueChanged<double> onScale;
  final ValueChanged<String> onVp;
  final ValueChanged<String> onToast;

  const _GalleryPanel({
    required this.screen,
    required this.dark,
    required this.scale,
    required this.vp,
    required this.toast,
    required this.onScreen,
    required this.onDark,
    required this.onScale,
    required this.onVp,
    required this.onToast,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: dark ? AppColors.darkSurface : AppColors.lightSurface,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Text('Galería (debug)',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(width: 18),
            const Text('Pantalla'),
            Wrap(
              spacing: 6,
              children: [
                ChoiceChip(
                  label: const Text('Login'),
                  selected: screen == 'login',
                  onSelected: (_) => onScreen('login'),
                ),
                ChoiceChip(
                  label: const Text('Cartera'),
                  selected: screen == 'cartera',
                  onSelected: (_) => onScreen('cartera'),
                ),
              ],
            ),
            const SizedBox(width: 18),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Oscuro'),
                Switch(
                  value: dark,
                  onChanged: onDark,
                  activeThumbColor: AppColors.primary,
                ),
              ],
            ),
            const SizedBox(width: 12),
            const Text('Texto'),
            Wrap(
              spacing: 6,
              children: [
                for (final s in const [1.0, 1.3, 1.6])
                  ChoiceChip(
                    label: Text('x$s'),
                    selected: scale == s,
                    onSelected: (_) => onScale(s),
                  ),
              ],
            ),
            const SizedBox(width: 18),
            const Text('Viewport'),
            Wrap(
              spacing: 6,
              children: [
                for (final v in const ['phone', 'tablet', 'desktop'])
                  ChoiceChip(
                    label: Text(v),
                    selected: vp == v,
                    onSelected: (_) => onVp(v),
                  ),
              ],
            ),
            const SizedBox(width: 18),
            const Text('Toast'),
            Wrap(
              spacing: 6,
              children: [
                for (final t in const ['success', 'error', 'info', 'warning'])
                  ChoiceChip(
                    label: Text(t),
                    selected: toast == t,
                    onSelected: (_) => onToast(t),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Text(
              'Con el clamp de producción (§7.6), x1.6 se ve igual a x1.3.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

/// Dispara el toast estándar una vez por combinación (panel/URL).
/// Muestra título + mensaje para ejercitar ambos textos del estándar.
class _ToastAutoShow extends StatefulWidget {
  final ToastType type;

  const _ToastAutoShow({super.key, required this.type});

  @override
  State<_ToastAutoShow> createState() => _ToastAutoShowState();
}

class _ToastAutoShowState extends State<_ToastAutoShow> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      TopToast.show(
        context,
        type: widget.type,
        duration: const Duration(seconds: 60),
        title: switch (widget.type) {
          ToastType.success => 'Pago registrado',
          ToastType.error => 'Error',
          ToastType.info => 'En segundo plano',
          ToastType.warning => 'Atención',
        },
        message: switch (widget.type) {
          ToastType.success =>
            'El cobro quedó registrado y sincronizado.',
          ToastType.error =>
            'No se pudo sincronizar. Intenta de nuevo.',
          ToastType.info =>
            'La sincronización continúa en segundo plano.',
          ToastType.warning =>
            'Quedan pocos reintentos disponibles.',
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

/// Host: simula el viewport elegido y monta la pantalla real.
class _GalleryHost extends StatelessWidget {
  final String screen;
  final double vpWidth;
  final double vpHeight;
  final AuthCubit authCubit;

  const _GalleryHost({
    super.key,
    required this.screen,
    required this.vpWidth,
    required this.vpHeight,
    required this.authCubit,
  });

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (screen == 'cartera') {
      child = BlocProvider<AuthCubit>.value(
        value: authCubit,
        child: CarteraScreen(repository: DebugCarteraRepository()),
      );
    } else {
      child = BlocProvider<AuthCubit>.value(
        value: authCubit,
        child: const LoginScreen(),
      );
    }    return Padding(
      padding: const EdgeInsets.all(10),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: vpWidth,
            maxHeight: vpHeight,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            child: ColoredBox(
              color: AppColors.isDark
                  ? AppColors.darkBackground
                  : AppColors.lightBackground,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
