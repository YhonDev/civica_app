import 'package:dio/dio.dart';

/// Verifica al arrancar que la API responde, antes de que el usuario vea
/// pantallas llenas de errores de red confusos.
///
/// Solo se usa en builds de debug: en release la app debe tolerar la
/// ausencia de la API (modo offline), no bloquear el arranque.
class ApiHealthService {
  final Dio _dio;

  /// [dio] inyectable para tests.
  ApiHealthService({String? baseUrl, Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              // Endpoint público (sin auth, sin rate-limit agresivo).
              baseUrl: baseUrl ?? const String.fromEnvironment('API_BASE_URL'),
              connectTimeout: const Duration(seconds: 4),
              receiveTimeout: const Duration(seconds: 4),
            ));

  /// Intenta alcanzar la API.
  ///
  /// Cualquier respuesta HTTP (incluso 404/401) cuenta como "alcanzable":
  /// lo que se quiere probar es conectividad, no estado del endpoint.
  /// Devuelve `true` si respondió, `false` si hubo error de red.
  Future<bool> isApiReachable() async {
    try {
      await _dio.get('/health');
      return true;
    } on DioException catch (e) {
      // Una respuesta del servidor (aunque sea 404/500) significa que hay
      // conexión: la API está alcanzable.
      if (e.response != null) return true;
      return false;
    } catch (_) {
      return false;
    }
  }
}
