import 'package:flutter/foundation.dart' show kReleaseMode, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/database/app_database.dart';
import 'core/network/api_client.dart';
import 'core/sync/connectivity_detector.dart';
import 'core/sync/sync_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
import 'core/router/app_router.dart';
import 'screens/auth/auth_cubit.dart';

/// Detecta la URL base del backend según la plataforma:
/// - Android emulator: 10.0.2.2 (localhost del host)
/// - iOS simulator / otros: localhost
/// Se puede sobrescribir con --dart-define=API_BASE_URL=...
String _detectBaseUrl() {
  const envUrl = String.fromEnvironment('API_BASE_URL');
  if (envUrl.isNotEmpty) return envUrl;
  if (defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:3000/api';
  }
  return 'http://localhost:3000/api';
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar formateo de fechas en español
  await initializeDateFormatting('es', null);

  // Inicializar base de datos local
  await AppDatabase.init();

  // Cargar variables de entorno
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Variables de entorno (.env) no cargadas: $e");
  }

  // Inicializar ApiClient con la URL del backend
  // En release mode se desactiva el LogInterceptor para no exponer datos sensibles
  ApiClient.init(
    baseUrl: _detectBaseUrl(),
    enableLogging: !kReleaseMode,
  );

  // Inicializar detector de conectividad y servicio de sync
  final detector = ConnectivityDetector.init();
  SyncService.init(detector: detector);

  runApp(const CivicaPagoApp());
}

class CivicaPagoApp extends StatelessWidget {
  const CivicaPagoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: darkThemeNotifier,
      builder: (context, isDark, _) {
        AppColors.setDarkMode(isDark);
        return MaterialApp(
          title: 'VigiVecino',
          debugShowCheckedModeBanner: false,
          theme: buildLightTheme(),
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
          home: BlocProvider(
            create: (_) => AuthCubit()..checkSession(),
            child: const AuthGate(),
          ),
        );
      },
    );
  }
}

/// Auth gate: espera que se determine la sesión, luego pasa a GoRouter.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        if (state.status == AuthStatus.initial ||
            state.status == AuthStatus.loading) {
          return Scaffold(
            body: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          );
        }
        // Una vez determinado el estado, usar GoRouter
        // El router se reconstruye aquí para que tenga acceso al AuthCubit
        return _RouterWithAuth();
      },
    );
  }
}

/// Wraps GoRouter inside the BlocProvider tree so redirect callbacks
/// can access AuthCubit via context.
class _RouterWithAuth extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (!state.isAuthenticated) {
          appRouter.go('/login');
        }
      },
      child: MaterialApp.router(
        title: 'VigiVecino',
        debugShowCheckedModeBanner: false,
        theme: buildLightTheme(),
        routerConfig: appRouter,
      ),
    );
  }
}
