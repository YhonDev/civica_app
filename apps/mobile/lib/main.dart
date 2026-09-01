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
import 'features/auth/auth_cubit.dart';

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

  await initializeDateFormatting('es', null);
  await AppDatabase.init();

  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Variables de entorno (.env) no cargadas: $e");
  }

  ApiClient.init(
    baseUrl: _detectBaseUrl(),
    enableLogging: !kReleaseMode,
  );

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
          title: 'Cívica Pago',
          debugShowCheckedModeBanner: false,
          theme: buildLightTheme(),
          darkTheme: buildDarkTheme(),
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
        return _RouterWithAuth();
      },
    );
  }
}

class _RouterWithAuth extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: darkThemeNotifier,
      builder: (context, isDark, _) {
        AppColors.setDarkMode(isDark);
        return BlocListener<AuthCubit, AuthState>(
          listener: (context, state) {
            if (!state.isAuthenticated) {
              appRouter.go('/login');
            }
          },
          child: MaterialApp.router(
            title: 'Cívica Pago',
            debugShowCheckedModeBanner: false,
            theme: buildLightTheme(),
            darkTheme: buildDarkTheme(),
            themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
            routerConfig: appRouter,
          ),
        );
      },
    );
  }
}
