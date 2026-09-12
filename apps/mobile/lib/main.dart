import 'dart:ui' show PlatformDispatcher;
import 'package:flutter/foundation.dart' show kDebugMode, kReleaseMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/database/app_database.dart';
import 'core/network/api_client.dart';
import 'core/network/api_health_service.dart';
import 'core/network/base_url.dart';
import 'core/network/error_messages.dart' show debugReportUnknownError;
import 'core/sync/connectivity_detector.dart';
import 'core/sync/sync_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
import 'core/security/biometric_lifecycle_lock.dart';
import 'core/security/session_lifecycle_manager.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_breakpoints.dart';
import 'features/auth/auth_cubit.dart';
import 'features/setup/api_unavailable_screen.dart';
import 'shared/widgets/empty_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugReportUnknownError(details.exception, 'FlutterError', stackTrace: details.stack);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugReportUnknownError(error, 'PlatformDispatcher', stackTrace: stack);
    return true;
  };
  ErrorWidget.builder = (details) {
    if (kDebugMode) {
      return ErrorWidget(details.exception);
    }
    return const Material(
      child: Center(
        child: EmptyState(
          icon: Icons.error_outline_rounded,
          title: 'Ocurrió un error inesperado',
          description: 'Por favor, reinicia la pantalla o intenta de nuevo.',
        ),
      ),
    );
  };

  await initializeDateFormatting('es', null);
  if (!kIsWeb) {
    await AppDatabase.init();
  }

  ApiClient.init(
    baseUrl: detectBaseUrl(),
    // kDebugMode (no !kReleaseMode): en profile tampoco se loguean URIs.
    enableLogging: kDebugMode,
  );

  final detector = ConnectivityDetector.init();
  if (!kIsWeb) {
    SyncService.init(detector: detector);
  }

  // Cargar preferencia persistente de tema (Dark / Light Mode)
  await DarkThemeNotifier.init();

  // Inicializar ciclo de vida de la sesión
  SessionLifecycleManager.instance.init();

  runApp(const CivicaPagoApp());
}

class CivicaPagoApp extends StatefulWidget {
  const CivicaPagoApp({super.key});

  @override
  State<CivicaPagoApp> createState() => _CivicaPagoAppState();
}

/// Builder compartido de MaterialApp: unifica tema (light/dark), animación
/// de tema nula y el clamp de textScaler a [1.0, AppBreakpoints.maxTextScale].
///
/// El clamp garantiza que los usuarios con fuente de sistema grande vean la
/// UI escalada hasta un límite seguro, sin romper alturas fijas de chips,
/// badges ni extents de grid (ver doc/DESIGN_SYSTEM.md §7.6).
///
/// Usa exactamente uno de: [home] (MaterialApp clásico) o [routerConfig]
/// (MaterialApp.router, con [pageBuilder] como builder adicional).
class _AppThemeBuilder extends StatelessWidget {
  final Widget? home;
  final RouterConfig<Object>? routerConfig;
  final Widget Function(BuildContext, Widget?)? pageBuilder;

  const _AppThemeBuilder({this.home, this.routerConfig, this.pageBuilder});

  /// Builder combinado: pageBuilder opcional + clamp de textScaler.
  Widget _wrapTransitions(BuildContext context, Widget? child) {
    child = pageBuilder?.call(context, child) ?? child;
    final ratio = MediaQuery.textScalerOf(context).scale(14) / 14;
    final clamped = TextScaler.linear(
      ratio.clamp(1.0, AppBreakpoints.maxTextScale),
    );
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: clamped),
      child: child ?? const SizedBox.shrink(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: darkThemeNotifier,
      builder: (context, isDark, _) {
        if (routerConfig != null) {
          return MaterialApp.router(
            title: 'Cívica Pago',
            debugShowCheckedModeBanner: false,
            theme: buildLightTheme(),
            darkTheme: buildDarkTheme(),
            themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
            themeAnimationDuration: Duration.zero,
            routerConfig: routerConfig,
            builder: _wrapTransitions,
          );
        }
        return MaterialApp(
          title: 'Cívica Pago',
          debugShowCheckedModeBanner: false,
          theme: buildLightTheme(),
          darkTheme: buildDarkTheme(),
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
          themeAnimationDuration: Duration.zero,
          builder: _wrapTransitions,
          home: home,
        );
      },
    );
  }
}

class _CivicaPagoAppState extends State<CivicaPagoApp> {
  /// Solo en debug: verificar que la API responde antes de entrar a la app.
  /// En release el gate se salta (modo offline tolerante, no bloquea arranque).
  Future<bool>? _apiCheck;

  @override
  void initState() {
    super.initState();
    if (!kReleaseMode) {
      _apiCheck = ApiHealthService(baseUrl: detectBaseUrl()).isApiReachable();
    }
  }

  void _reverificar() {
    setState(() {
      _apiCheck = ApiHealthService(baseUrl: detectBaseUrl()).isApiReachable();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _apiCheck,
      builder: (context, snapshot) {
        // Release (o check ya pasado): flujo normal.
        final apiOk = kReleaseMode || (snapshot.data == true);

        if (!apiOk) {
          if (snapshot.connectionState != ConnectionState.done) {
            return _AppThemeBuilder(
              home: Scaffold(
                body: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            );
          }

          // Check terminó y la API NO responde → pantalla de bloqueo clara.
          return _AppThemeBuilder(
            home: ApiUnavailableScreen(
              healthService: ApiHealthService(baseUrl: detectBaseUrl()),
              onAvailable: _reverificar,
            ),
          );
        }

        return BlocProvider(
          create: (_) => AuthCubit()..checkSession(),
          child: const _AppRoot(),
        );
      },
    );
  }
}

class _AppRoot extends StatelessWidget {
  const _AppRoot();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        if (state.status == AuthStatus.initial ||
            state.status == AuthStatus.loading) {
          return const _AppThemeBuilder(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          );
        }

        return BlocListener<AuthCubit, AuthState>(
          listener: (context, authState) {
            if (authState.isAuthenticated) {
              appRouter.go('/');
            } else {
              appRouter.go('/login');
            }
          },
          child: _AppThemeBuilder(
            routerConfig: appRouter,
            pageBuilder: (context, child) => BiometricLifecycleLock(
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        );
      },
    );
  }
}
