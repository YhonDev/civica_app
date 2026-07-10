import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/database/app_database.dart';
import 'core/network/api_client.dart';
import 'core/sync/connectivity_detector.dart';
import 'core/sync/sync_service.dart';
import 'screens/auth/auth_cubit.dart';
import 'screens/auth/login_screen.dart';
import 'screens/search_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar base de datos local
  await AppDatabase.init();

  // Inicializar ApiClient con la URL del backend
  ApiClient.init(
    baseUrl: const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://localhost:3000',
    ),
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
    final theme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF1565C0), // Blue 800
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
      ),
    );

    return MaterialApp(
      title: 'Cívica Pago',
      debugShowCheckedModeBanner: false,
      theme: theme,
      home: BlocProvider(
        create: (_) => AuthCubit()..checkSession(),
        child: const _AuthGate(),
      ),
    );
  }
}

/// Auth gate: muestra LoginScreen o Home según el estado de autenticación.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        switch (state.status) {
          case AuthStatus.initial:
          case AuthStatus.loading:
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          case AuthStatus.authenticated:
            return const SearchScreen();
          case AuthStatus.unauthenticated:
          case AuthStatus.error:
            return const LoginScreen();
        }
      },
    );
  }
}


