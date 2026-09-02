import 'package:flutter_test/flutter_test.dart';

import 'package:civica_pago_mobile/core/network/api_client.dart';
import 'package:civica_pago_mobile/features/solicitudes/solicitudes_repository.dart';
import 'package:civica_pago_mobile/shared/widgets/solicitud_card.dart';
import 'mock_http_adapter.dart';

void main() {
  late MockHttpAdapter mockAdapter;
  late SolicitudesRepository repository;

  setUp(() {
    ApiClient.init(
      baseUrl: 'http://test.local',
      tokenStorage: TokenStorage(storage: InMemorySecureStorage()),
    );
    mockAdapter = MockHttpAdapter();
    ApiClient.setHttpClientAdapter(mockAdapter);
    repository = SolicitudesRepository();
  });

  group('SolicitudesRepository.getSolicitudes', () {
    test('mapea correctamente el campo nroRecibo del backend', () async {
      mockAdapter.onGet('/solicitudes/admin', [
        {
          'id': 'SOL_1',
          'cobroId': 'CUO_1',
          'nroRecibo': 'TK-123456',
          'tipo': 'Revisión pago de Junio 2026',
          'descripcion': 'Error en el monto',
          'estado': 'EN_REVISION',
          'fecha': '2026-06-15T10:00:00Z',
          'createdAt': '2026-06-15T10:00:00Z',
          'usuarioId': 'USR_1',
          'usuario': {'id': 'USR_1', 'nombre': 'Juan Pérez'},
          'respuesta': null,
        },
      ]);

      final solicitudes = await repository.getSolicitudes();

      expect(solicitudes.length, 1);
      expect(solicitudes[0].id, 'SOL_1');
      expect(solicitudes[0].nroRecibo, 'TK-123456');
      expect(solicitudes[0].tipo, 'Revisión pago de Junio 2026');
      expect(solicitudes[0].descripcion, 'Error en el monto');
      expect(solicitudes[0].estado, SolicitudEstado.enRevision);
      expect(solicitudes[0].residenteId, 'USR_1');
      expect(solicitudes[0].residenteNombre, 'Juan Pérez');
      expect(solicitudes[0].respuesta, isNull);
    });

    test('mapea correctamente el campo estado RESUELTA', () async {
      mockAdapter.onGet('/solicitudes/admin', [
        {
          'id': 'SOL_2',
          'cobroId': 'CUO_1',
          'nroRecibo': 'TK-654321',
          'tipo': 'Revisión',
          'descripcion': 'Ok',
          'estado': 'RESUELTA',
          'fecha': '2026-06-15T10:00:00Z',
          'createdAt': '2026-06-15T10:00:00Z',
          'usuarioId': 'USR_1',
          'usuario': {'id': 'USR_1', 'nombre': 'Juan'},
          'respuesta': 'Corregido',
        },
      ]);

      final solicitudes = await repository.getSolicitudes();

      expect(solicitudes.length, 1);
      expect(solicitudes[0].estado, SolicitudEstado.resuelta);
      expect(solicitudes[0].respuesta, 'Corregido');
    });

    test('mapea RECHAZADA correctamente', () async {
      mockAdapter.onGet('/solicitudes/admin', [
        {
          'id': 'SOL_3',
          'cobroId': 'CUO_1',
          'nroRecibo': 'TK-999999',
          'tipo': 'Otro',
          'descripcion': 'No procede',
          'estado': 'RECHAZADA',
          'fecha': '2026-06-15T10:00:00Z',
          'createdAt': '2026-06-15T10:00:00Z',
          'usuarioId': 'USR_1',
          'usuario': {'id': 'USR_1', 'nombre': 'Juan'},
          'respuesta': 'Rechazado',
        },
      ]);

      final solicitudes = await repository.getSolicitudes();

      expect(solicitudes[0].estado, SolicitudEstado.rechazada);
    });
  });

  group('SolicitudesRepository.getSolicitudesPendientes', () {
    test('retorna solicitudes pendientes correctamente', () async {
      mockAdapter.onGet('/solicitudes/pendientes', [
        {
          'id': 'SOL_P1',
          'cobroId': 'CUO_2',
          'nroRecibo': 'TK-111111',
          'tipo': 'Revisión',
          'descripcion': 'Urgente',
          'estado': 'PENDIENTE',
          'fecha': '2026-06-15T10:00:00Z',
          'createdAt': '2026-06-15T10:00:00Z',
          'usuarioId': 'USR_2',
          'usuario': {'id': 'USR_2', 'nombre': 'Ana'},
          'respuesta': null,
        },
      ]);

      final result = await repository.getSolicitudesPendientes();

      expect(result.length, 1);
      expect(result[0].estado, SolicitudEstado.pendiente);
      expect(result[0].residenteNombre, 'Ana');
    });
  });

  group('SolicitudesRepository.crearSolicitud', () {
    test('envía POST a /solicitudes con los datos correctos', () async {
      mockAdapter.onPost('/solicitudes', {'id': 'NEW_SOL'});

      await repository.crearSolicitud(
        cobroId: 'CUO_1',
        tipo: 'Revisión pago de Junio 2026',
        descripcion: 'Error en monto',
        residenteId: 'USR_1',
      );

      expect(mockAdapter.calls('POST', '/solicitudes'), 1);
    });
  });

  group('SolicitudesRepository.resolverSolicitud', () {
    test('envía PATCH a /solicitudes/:id/resolver', () async {
      mockAdapter.onPatch('/solicitudes/SOL_1/resolver', {'success': true});

      await repository.resolverSolicitud(
        id: 'SOL_1',
        estado: 'RESUELTA',
        respuesta: 'Corregido manualmente',
      );

      expect(mockAdapter.calls('PATCH', '/solicitudes/SOL_1/resolver'), 1);
    });
  });

  group('SolicitudesRepository — edge cases', () {
    test('estado desconocido en JSON se mapea a enEspera (fallback)', () async {
      mockAdapter.onGet('/solicitudes/admin', [
        {
          'id': 'SOL_UNKNOWN',
          'cobroId': 'CUO_1',
          'nroRecibo': 'TK-000000',
          'tipo': 'Desconocido',
          'descripcion': 'Estado raro',
          'estado': 'ESTADO_INEXISTENTE',
          'fecha': '2026-06-15T10:00:00Z',
          'createdAt': '2026-06-15T10:00:00Z',
          'usuarioId': 'USR_1',
          'usuario': {'id': 'USR_1', 'nombre': 'Test'},
          'respuesta': null,
        },
      ]);

      final result = await repository.getSolicitudes();
      expect(result[0].estado, SolicitudEstado.enEspera);
    });

    test('sin fecha usa createdAt como fallback', () async {
      mockAdapter.onGet('/solicitudes/admin', [
        {
          'id': 'SOL_NO_DATE',
          'cobroId': 'CUO_1',
          'nroRecibo': 'TK-111111',
          'tipo': 'Test',
          'descripcion': 'Sin fecha',
          'estado': 'PENDIENTE',
          // sin fecha
          'createdAt': '2026-06-15T10:00:00Z',
          'usuarioId': 'USR_1',
          'usuario': {'id': 'USR_1', 'nombre': 'Test'},
          'respuesta': null,
        },
      ]);

      final solicitudes = await repository.getSolicitudes();

      expect(solicitudes[0].fecha.year, 2026);
      expect(solicitudes[0].fecha.month, 6);
      expect(solicitudes[0].fecha.day, 15);
    });
  });

  group('SolicitudesRepository — error handling', () {
    test('lanza Exception cuando la API falla', () async {
      expect(
        () => repository.getSolicitudes(),
        throwsA(isA<Exception>()),
      );
    });
  });
}
