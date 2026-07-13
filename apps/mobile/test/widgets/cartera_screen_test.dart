import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:civica_pago_mobile/core/network/api_client.dart';
import 'package:civica_pago_mobile/features/cartera/cartera_screen.dart';
import '../unit/repositories/mock_http_adapter.dart';

/// Three cuotas: PAGADA, VENCIDA, PENDIENTE → 1 pagado, 1 mora, 1 pendiente
final _cuotasData = [
  {
    'id': 'C1',
    'monto': 5000000,
    'montoPagado': 5000000,
    'estado': 'PAGADA',
    'propietario': {
      'id': 'P1',
      'nombre': 'Juan Pagado',
      'tenencias': [
        {
          'casa': {
            'direccionInterna': 'Casa 101',
            'manzana': {'etapa': {'nombre': 'Etapa 1'}},
          },
        },
      ],
    },
  },
  {
    'id': 'C2',
    'monto': 5000000,
    'montoPagado': 0,
    'estado': 'VENCIDA',
    'propietario': {
      'id': 'P2',
      'nombre': 'Maria Mora',
      'tenencias': [
        {
          'casa': {
            'direccionInterna': 'Casa 102',
            'manzana': {'etapa': {'nombre': 'Etapa 1'}},
          },
        },
      ],
    },
  },
  {
    'id': 'C3',
    'monto': 5000000,
    'montoPagado': 0,
    'estado': 'PENDIENTE',
    'propietario': {
      'id': 'P3',
      'nombre': 'Carlos Pendiente',
      'tenencias': [
        {
          'casa': {
            'direccionInterna': 'Casa 103',
            'manzana': {'etapa': {'nombre': 'Etapa 1'}},
          },
        },
      ],
    },
  },
];

Widget createCarteraScreen() {
  return const MaterialApp(
    home: CarteraScreen(),
  );
}

void main() {
  late MockHttpAdapter mockAdapter;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ApiClient.init(baseUrl: 'http://test.local');
    mockAdapter = MockHttpAdapter();
    ApiClient.setHttpClientAdapter(mockAdapter);
  });

  Future<void> pumpUntilLoaded(WidgetTester tester) async {
    await tester.pumpWidget(createCarteraScreen());
    // First frame: initState → loading
    await tester.pump();
    // Pump to resolve async API calls
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
  }

  group('CarteraScreen — loading state', () {
    testWidgets('mustra skeleton durante la carga', (tester) async {
      mockAdapter.onGet('/cuotas', _cuotasData);

      await tester.pumpWidget(createCarteraScreen());
      // Sin pump adicional, el skeleton está visible
      await tester.pump();

      // Debe mostrar el título
      expect(find.text('Gestión de Cartera'), findsOneWidget);
      // No debe mostrar datos cargados
      expect(find.text('Por cobrar'), findsNothing);
    });
  });

  group('CarteraScreen — loaded state', () {
    testWidgets('mustra resumen header con Por cobrar, Mora, Recaudado',
        (tester) async {
      mockAdapter.onGet('/cuotas', _cuotasData);

      await pumpUntilLoaded(tester);

      // El header debe mostrar las 3 métricas
      expect(find.text('Por cobrar'), findsOneWidget);
      expect(find.text('Mora'), findsOneWidget);
      expect(find.text('Recaudado'), findsOneWidget);
    });

    testWidgets('mustra filter chips: Pendiente, Mora, Pagado, Todos',
        (tester) async {
      mockAdapter.onGet('/cuotas', _cuotasData);

      await pumpUntilLoaded(tester);

      // Filter chips
      expect(find.text('Pendiente'), findsOneWidget);
      expect(find.text('Mora'), findsOneWidget);
      expect(find.text('Pagado'), findsOneWidget);
      expect(find.text('Todos'), findsOneWidget);
    });

    testWidgets('mustra CobroCards con nombres de propietarios',
        (tester) async {
      mockAdapter.onGet('/cuotas', _cuotasData);

      await pumpUntilLoaded(tester);

      // Como el filtro activo es 'Pendiente', solo se muestra "Carlos Pendiente"
      expect(find.text('Carlos Pendiente'), findsOneWidget);
      // No deben estar los filtrados
      expect(find.text('Juan Pagado'), findsNothing);
      expect(find.text('Maria Mora'), findsNothing);
    });

    testWidgets('cambiar filtro a Mora mustra solo propietario en mora',
        (tester) async {
      mockAdapter.onGet('/cuotas', _cuotasData);

      await pumpUntilLoaded(tester);

      // Click en chip "Mora"
      await tester.tap(find.text('Mora').last);
      await tester.pump();

      // Ahora solo Maria Mora debe mostrarse
      expect(find.text('Maria Mora'), findsOneWidget);
      expect(find.text('Carlos Pendiente'), findsNothing);
      expect(find.text('Juan Pagado'), findsNothing);
    });

    testWidgets('cambiar filtro a Todos mustra todos los propietarios',
        (tester) async {
      mockAdapter.onGet('/cuotas', _cuotasData);

      await pumpUntilLoaded(tester);

      // Click en chip "Todos"
      await tester.tap(find.text('Todos').last);
      await tester.pump();

      // Ahora deben mostrarse los 3
      expect(find.text('Carlos Pendiente'), findsOneWidget);
      expect(find.text('Maria Mora'), findsOneWidget);
      expect(find.text('Juan Pagado'), findsOneWidget);
    });
  });

  group('CarteraScreen — empty state', () {
    testWidgets('mustra EmptyState cuando no hay datos', (tester) async {
      mockAdapter.onGet('/cuotas', []); // Lista vacía

      await pumpUntilLoaded(tester);

      // Debe mostrar resumen vacío (0 en todo)
      expect(find.text('Por cobrar'), findsOneWidget);
      expect(find.text('Sin registros'), findsOneWidget);
    });
  });

  group('CarteraScreen — error state', () {
    testWidgets('mustra error EmptyState cuando falla la API', (tester) async {
      // No registramos mock → falla

      await pumpUntilLoaded(tester);

      // Debe mostrar error
      expect(find.text('Error de carga'), findsOneWidget);
      expect(
        find.text('No se pudo cargar la información de la cartera.'),
        findsOneWidget,
      );
    });
  });
}
