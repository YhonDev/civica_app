import 'dart:io' show HandshakeException, HttpException, SocketException;

import 'package:dio/dio.dart' show DioException, DioExceptionType, RequestOptions, Response;
import 'package:flutter_test/flutter_test.dart';

import 'package:civica_pago_mobile/core/network/api_exceptions.dart';
import 'package:civica_pago_mobile/core/network/error_messages.dart';

void main() {
  const conexionMsg = kConnectionErrorMessage;
  const fallbackDefault = kGenericErrorMessage;

  group('sanitizeApiError — política allowlist', () {
    test('ApiException con mensaje propio → ese mensaje', () {
      expect(
        sanitizeApiError(const ApiException(message: 'El pago ya fue registrado.')),
        'El pago ya fue registrado.',
      );
    });

    test('ApiException recorta espacios del mensaje', () {
      expect(
        sanitizeApiError(
          const ApiException(message: '  Error de validación del formulario.  '),
        ),
        'Error de validación del formulario.',
      );
    });

    test('AuthException usa su mensaje por defecto', () {
      expect(
        sanitizeApiError(const AuthException()),
        'Sesión expirada. Inicie sesión nuevamente.',
      );
    });

    test('ServerException con mensaje amigable: el mensaje gana', () {
      expect(
        sanitizeApiError(
          const ServerException(message: 'El servidor está saturado, intenta más tarde.'),
        ),
        'El servidor está saturado, intenta más tarde.',
      );
    });

    test('ValidationException nunca expone el mapa de errores ni sus claves', () {
      final e = const ValidationException(
        errors: {
          'password': ['too short'],
          'email': ['invalid'],
        },
      );
      final out = sanitizeApiError(e);
      expect(out, 'Error de validación.');
      expect(out, isNot(contains('too short')));
      expect(out, isNot(contains('password')));
      expect(out, isNot(contains('email')));
    });

    test('ApiException con mensaje solo de espacios → fallback (no toString)', () {
      final e = const ApiException(message: '   ');
      expect(sanitizeApiError(e), fallbackDefault);
    });

    test(
      'el mensaje del dominio se respeta aunque parezca técnico '
      '(los mensajes de ApiException son de autoría propia)',
      () {
        expect(
          sanitizeApiError(
            const ApiException(message: 'SocketException: pago rechazado por el banco'),
          ),
          'SocketException: pago rechazado por el banco',
        );
      },
    );
  });

  group('sanitizeApiError — errores técnicos de red (conocidos)', () {
    test('SocketException real (DNS) → mensaje de conexión', () {
      expect(
        sanitizeApiError(const SocketException('Failed host lookup: api.internal')),
        conexionMsg,
      );
    });

    test('HandshakeException real (TLS) → mensaje de conexión', () {
      expect(
        sanitizeApiError(const HandshakeException('Handshake error in client')),
        conexionMsg,
      );
    });

    test('HttpException real (stream cortado) → mensaje de conexión', () {
      expect(
        sanitizeApiError(
          const HttpException('Connection closed while receiving data'),
        ),
        conexionMsg,
      );
    });

    test('DioException connectionTimeout → mensaje de conexión', () {
      final e = DioException(
        requestOptions: RequestOptions(path: '/api/cobros'),
        type: DioExceptionType.connectionTimeout,
        message: 'The request connection took longer than 0:00:30.000000',
      );
      expect(sanitizeApiError(e), conexionMsg);
    });

    test(
      'cualquier DioException se trata como fallo de transporte, incluso '
      'badResponse 5xx (el mapeo a ApiException ocurre antes, en ApiClient)',
      () {
        final e = DioException(
          requestOptions: RequestOptions(path: '/api/auth/login'),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(path: '/api/auth/login'),
            statusCode: 500,
            data: 'Internal Server Error',
          ),
        );
        expect(sanitizeApiError(e), conexionMsg);
      },
    );
  });

  group('sanitizeApiError — puentes de autoría propia (compatibilidad)', () {
    test('Exception("mensaje propio") → el mensaje del equipo', () {
      expect(
        sanitizeApiError(Exception('El monto excede el saldo disponible')),
        'El monto excede el saldo disponible',
      );
    });

    test('Exception("").toString() con solo espacios → fallback', () {
      expect(sanitizeApiError(Exception('   ')), fallbackDefault);
    });

    test('e.toString() de un Exception propio también se acepta (puente)', () {
      // El objetivo es pasar el objeto; mientras tanto, el toString de un
      // Exception('...') propio sigue siendo presentable.
      final e = Exception('No hay internet en este momento');
      expect(sanitizeApiError(e.toString()), 'No hay internet en este momento');
    });

    test('String plano lanzado como error pasa por la limpieza', () {
      expect(sanitizeApiError('Texto plano del error'), 'Texto plano del error');
    });

    test('String con prefijo técnico se limpia ("Error: algo falló")', () {
      expect(sanitizeApiError('Error: algo falló'), 'algo falló');
    });
  });

  group('sanitizeApiError — todo lo desconocido es leak-proof', () {
    test('Objeto anónimo → fallback (antes: "Instance of \'Object\'")', () {
      expect(sanitizeApiError(Object()), fallbackDefault);
      expect(sanitizeApiError(Object()), isNot(contains('Instance')));
    });

    test('StateError → fallback (antes: "Bad state: no element")', () {
      expect(sanitizeApiError(StateError('no element')), fallbackDefault);
      expect(sanitizeApiError(StateError('no element')), isNot(contains('Bad state')));
    });

    test('FormatException → fallback (su mensaje no es de autoría propia)', () {
      expect(
        sanitizeApiError(const FormatException('Moneda inválida: en índice 3')),
        fallbackDefault,
      );
      expect(
        sanitizeApiError(const FormatException('x')),
        isNot(contains('índice')),
      );
    });

    test('toString técnico con marcador de red ("DioException [bad response]") '
        'en un String crudo → fallback, NO mensaje de conexión', () {
      // Ya no se huelen marcadores dentro de toString: la detección es por
      // tipo. Un string así no es de autoría propia → fallback.
      expect(
        sanitizeApiError('DioException [bad response]: 500'),
        fallbackDefault,
      );
    });

    test('cualquier subclase de Exception que NO sea Exception base → fallback', () {
      expect(sanitizeApiError(_UnauthoredSubclass()), fallbackDefault);
    });

    test('Exception que envuelve un diagnóstico técnico → fallback '
        '(patrón accidental: interpolar un error dentro de Exception)', () {
      expect(
        sanitizeApiError(Exception('DioException [bad response]: 500')),
        fallbackDefault,
      );
      expect(
        sanitizeApiError(Exception('SocketException: Failed host lookup')),
        fallbackDefault,
      );
    });

    test('fallback personalizado se respeta y el default no', () {
      const custom = 'No pudimos procesar el cobro.';
      expect(
        sanitizeApiError(StateError('x'), fallback: custom),
        custom,
      );
      expect(
        sanitizeApiError(StateError('x'), fallback: custom),
        isNot(fallbackDefault),
      );
    });
  });

  group('debugReportUnknownError', () {
    test('en tests (kDebugMode) imprime el diagnóstico con el fallback mostrado',
        () {
      final err = StateError('detalle interno');
      final out = sanitizeApiError(err, fallback: 'Fallback visible');
      expect(out, 'Fallback visible');

      // El reporte es best-effort (print); verificar que no lanza y que el
      // contrato se mantiene en debug.
      debugReportUnknownError(err, out);
      debugReportUnknownError(err, out,
          stackTrace: StackTrace.current);
    });

    test(' ApiException sin mensaje NO dispara el reporte (fallback directo)', () {
      // Rama de ApiException: sin reporte de debug, solo fallback.
      final out = sanitizeApiError(const ApiException(message: ''), fallback: 'x');
      expect(out, 'x');
    });
  });
}

/// Subclase de Exception que no es `Exception` base: su toString no es de
/// autoría propia del equipo, así que debe caer al fallback.
class _UnauthoredSubclass implements Exception {
  @override
  String toString() => 'UnauthoredSubclass: detalle interno sensible';
}
