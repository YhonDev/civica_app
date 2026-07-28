import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:dio/dio.dart';

import 'package:civica_pago_mobile/core/network/api_client.dart';
import 'package:civica_pago_mobile/features/residentes/nuevo_residente_screen.dart';
import 'mock_http_adapter.dart';

final List<Map<String, dynamic>> _mockTree = [
  <String, dynamic>{
    'id': 'proy-1',
    'nombre': 'Proyecto Test',
    'etapas': <Map<String, dynamic>>[
      <String, dynamic>{
        'id': 'etapa-1',
        'nombre': 'Etapa Alfa',
        'manzanas': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'mza-1',
            'nombre': 'Manzana A',
            'casas': <Map<String, dynamic>>[
              <String, dynamic>{'id': 'casa-1', 'direccionInterna': 'Lote 1'},
              <String, dynamic>{'id': 'casa-2', 'direccionInterna': 'Lote 2'},
            ],
          },
        ],
      },
    ],
  },
];

final Map<String, dynamic> _mockCreateResponse = <String, dynamic>{
  'usuario': <String, dynamic>{
    'id': 'usr-1',
    'nombre': 'Juan Perez',
    'email': 'juan@test.com',
    'rol': 'PROPIETARIO',
  },
  'credenciales': <String, dynamic>{
    'username': 'juan.perez',
    'password': 'Temp1234!',
  },
};

Widget createScreen() {
  return const MaterialApp(home: NuevoResidenteScreen());
}

/// Pump enough frames for Dio async responses to complete.
Future<void> pumpUntilSettled(WidgetTester tester) async {
  for (int i = 0; i < 15; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  late MockHttpAdapter mockAdapter;

  setUp(() async {
    ApiClient.init(
      baseUrl: 'http://test.local',
      connectTimeout: Duration.zero,
      receiveTimeout: Duration.zero,
      tokenStorage: TokenStorage(storage: InMemorySecureStorage()),
    );
    mockAdapter = MockHttpAdapter();
    mockAdapter.onGet('/proyectos', () => _mockTree);
    mockAdapter.onGet('/residentes', () => <Map<String, dynamic>>[]);
    mockAdapter.onPost('/residentes', () => _mockCreateResponse);
    ApiClient.setHttpClientAdapter(mockAdapter);
    await initializeDateFormatting('es', null);
    await initializeDateFormatting('es_CO', null);
  });

  group('Loading', () {
    testWidgets('shows spinner then form', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createScreen());
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await pumpUntilSettled(tester);
      expect(find.text('Nuevo Residente'), findsOneWidget);
    });
  });

  group('Form', () {
    testWidgets('shows required fields', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createScreen());
      await pumpUntilSettled(tester);
      // Scroll down to find the button at the bottom of the SingleChildScrollView
      await tester.scrollUntilVisible(
        find.text('Crear Residente'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('Crear Residente'), findsOneWidget);
    });
  });

  group('Success', () {
    testWidgets('shows credentials after create',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createScreen());
      await pumpUntilSettled(tester);

      // Scroll down to show the form fields + button
      await tester.scrollUntilVisible(
        find.text('Crear Residente'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();

      final nombreField = find.widgetWithText(TextField, 'Nombre completo');
      await tester.enterText(nombreField, 'Juan Perez');
      final telefonoField = find.widgetWithText(TextField, 'Teléfono');
      await tester.enterText(telefonoField, '3001234567');

      await tester.tap(find.text('Crear Residente'));
      await pumpUntilSettled(tester);
      await tester.pump();
      expect(find.text('Residente creado'), findsOneWidget);
    });
  });

  group('Error', () {
    testWidgets('shows error on failure', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      mockAdapter.onPost('/residentes', () => throw DioException(
            requestOptions: RequestOptions(path: 'http://test.local/residentes'),
          ));
      await tester.pumpWidget(createScreen());
      await pumpUntilSettled(tester);

      // Scroll down to show the form fields + button
      await tester.scrollUntilVisible(
        find.text('Crear Residente'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();

      await tester.enterText(find.widgetWithText(TextField, 'Nombre completo'), 'Error Test');
      await tester.enterText(find.widgetWithText(TextField, 'Teléfono'), '3000000000');

      await tester.tap(find.text('Crear Residente'));
      await pumpUntilSettled(tester);
      await tester.pump();
      expect(find.textContaining('Error al crear'), findsOneWidget);
    });
  });
}
