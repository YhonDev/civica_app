import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:civica_pago_mobile/core/network/api_client.dart';
import 'package:civica_pago_mobile/features/residentes/nuevo_cobrador_screen.dart';
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
            ],
          },
        ],
      },
    ],
  },
];

final Map<String, dynamic> _mockCreateResponse = <String, dynamic>{
  'usuario': <String, dynamic>{
    'id': 'usr-cob-1',
    'nombre': 'Carlos Cobrador',
    'rol': 'COBRADOR',
  },
  'credenciales': <String, dynamic>{
    'username': 'carlos.cobrador',
    'password': 'Cobrador2026!',
  },
};

Widget createScreen() {
  return const MaterialApp(home: NuevoCobradorScreen());
}

Future<void> pumpLoaded(WidgetTester tester) async {
  // initState calls _loadTree() which does 2 HTTP GETs
  for (int i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  late MockHttpAdapter mockAdapter;

  setUp(() async {
    // Usar InMemorySecureStorage en vez de SharedPreferences/FlutterSecureStorage
    final testStorage = TokenStorage(storage: InMemorySecureStorage());
    // Set timeouts to zero to avoid Dio internal timers
    ApiClient.init(
      baseUrl: 'http://test.local',
      connectTimeout: Duration.zero,
      receiveTimeout: Duration.zero,
      tokenStorage: testStorage,
    );
    mockAdapter = MockHttpAdapter();
    mockAdapter.onGet('/proyectos', () => _mockTree);
    mockAdapter.onGet('/residentes', () => <Map<String, dynamic>>[]);
    mockAdapter.onPost('/cobradores', () => _mockCreateResponse);
    ApiClient.setHttpClientAdapter(mockAdapter);
    await initializeDateFormatting('es', null);
    await initializeDateFormatting('es_CO', null);
  });

  testWidgets('shows spinner then form', (WidgetTester tester) async {
    await tester.pumpWidget(createScreen());
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await pumpLoaded(tester);
    await tester.pumpAndSettle();
    expect(find.text('Nuevo Cobrador'), findsOneWidget);
  });

  testWidgets('shows guardar button after loading', (WidgetTester tester) async {
    await tester.pumpWidget(createScreen());
    await pumpLoaded(tester);
    await tester.pumpAndSettle();
    expect(find.text('Guardar Cobrador'), findsOneWidget);
  });

  testWidgets('shows credentials after create', (WidgetTester tester) async {
    await tester.pumpWidget(createScreen());
    await pumpLoaded(tester);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Carlos Cobrador');
    await tester.tap(find.text('Guardar Cobrador'));
    await tester.pump();
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.text('Cobrador creado'), findsOneWidget);
  });

  testWidgets('shows error on failure', (WidgetTester tester) async {
    mockAdapter.onPost('/cobradores', () {
      throw Exception('API Error');
    });
    await tester.pumpWidget(createScreen());
    await pumpLoaded(tester);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Error Test');
    await tester.tap(find.text('Guardar Cobrador'));
    await tester.pump();
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.textContaining('Error al crear cobrador'), findsOneWidget);
  });
}
