import 'package:flutter/foundation.dart' show kReleaseMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/database/app_database.dart';
import 'core/network/api_client.dart';
import 'core/network/api_health_service.dart';
import 'core/network/base_url.dart';
import 'core/sync/connectivity_detector.dart';
import 'core/sync/sync_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
import 'core/security/biometric_lifecycle_lock.dart';
import 'core/security/session_lifecycle_manager.dart';
import 'core/router/app_router.dart';
import 'features/auth/auth_cubit.dart';
import 'features/setup/api_unavailable_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('es', null);
  if (!kIsWeb) {
    await AppDatabase.init();
  }

  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Variables de entorno (.env) no cargadas: $e");
  }

  ApiClient.init(
    baseUrl: detectBaseUrl(),
    enableLogging: !kReleaseMode,
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
            return MaterialApp(
              title: 'Cívica Pago',
              debugShowCheckedModeBanner: false,
              theme: buildLightTheme(),
              darkTheme: buildDarkTheme(),
              themeMode: darkThemeNotifier.value ? ThemeMode.dark : ThemeMode.light,
              themeAnimationDuration: Duration.zero,
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
          return MaterialApp(
            title: 'Cívica Pago',
            debugShowCheckedModeBanner: false,
            theme: buildLightTheme(),
            darkTheme: buildDarkTheme(),
            themeMode: darkThemeNotifier.value ? ThemeMode.dark : ThemeMode.light,
            themeAnimationDuration: Duration.zero,
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
    return ValueListenableBuilder<bool>(
      valueListenable: darkThemeNotifier,
      builder: (context, isDark, _) {
        return BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            if (state.status == AuthStatus.initial ||
                state.status == AuthStatus.loading) {
              return MaterialApp(
                title: 'Cívica Pago',
                debugShowCheckedModeBanner: false,
                theme: buildLightTheme(),
                darkTheme: buildDarkTheme(),
                themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
                themeAnimationDuration: Duration.zero,
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
              child: MaterialApp.router(
                title: 'Cívica Pago',
                debugShowCheckedModeBanner: false,
                theme: buildLightTheme(),
                darkTheme: buildDarkTheme(),
                themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
                themeAnimationDuration: Duration.zero,
                routerConfig: appRouter,
                builder: (context, child) => BiometricLifecycleLock(
                  child: child ?? const SizedBox.shrink(),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
