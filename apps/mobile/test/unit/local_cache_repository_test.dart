import 'package:flutter_test/flutter_test.dart';
import 'package:civica_pago_mobile/core/network/local_cache_repository.dart';

void main() {
  group('LocalCacheRepository SWR Tests', () {
    late LocalCacheRepository repository;

    setUp(() {
      repository = LocalCacheRepository.instance;
      repository.invalidateAll();
    });

    test('setCache and getCached stores and retrieves data instantly', () {
      repository.setCache('test:key', {'monto': 40000});

      final cached = repository.getCached('test:key');
      expect(cached, isNotNull);
      expect(cached['monto'], equals(40000));
    });

    test('invalidate removes specified key from cache', () {
      repository.setCache('test:key1', 'value1');
      repository.setCache('test:key2', 'value2');

      repository.invalidate('test:key1');

      expect(repository.getCached('test:key1'), isNull);
      expect(repository.getCached('test:key2'), equals('value2'));
    });

    test('executeSWR yields cached data first then yields fresh background data', () async {
      repository.setCache('swr:key', {'status': 'STALE'});

      final emittedValues = <Map<String, dynamic>>[];
      final isStaleValues = <bool>[];

      await repository.executeSWR<Map<String, dynamic>>(
        key: 'swr:key',
        fetcher: () async => {'status': 'FRESH'},
        onData: (data, isStale) {
          emittedValues.add(data);
          isStaleValues.add(isStale);
        },
      );

      expect(emittedValues.length, equals(2));
      expect(emittedValues[0]['status'], equals('STALE'));
      expect(isStaleValues[0], isTrue);

      expect(emittedValues[1]['status'], equals('FRESH'));
      expect(isStaleValues[1], isFalse);
    });

    test('getCached returns null when maxAge TTL is exceeded', () async {
      repository.setCache('ttl:key', 'data');
      
      // Immediate lookup within TTL
      expect(repository.getCached('ttl:key', maxAge: const Duration(seconds: 5)), equals('data'));

      // Lookup with 0s TTL (expired immediately)
      expect(repository.getCached('ttl:key', maxAge: Duration.zero), isNull);
    });

    test('executeSWR updates UI with fresh backend data unconditionally', () async {
      repository.setCache('swr:fresh_override', 'STALE_DATA');

      final emitted = <String>[];
      await repository.executeSWR<String>(
        key: 'swr:fresh_override',
        fetcher: () async => 'FRESH_BACKEND_DATA',
        onData: (data, isStale) => emitted.add(data),
      );

      expect(emitted, equals(['STALE_DATA', 'FRESH_BACKEND_DATA']));
      expect(repository.getCached('swr:fresh_override'), equals('FRESH_BACKEND_DATA'));
    });

    test('invalidateAll clears all cache keys on logout or real-time event', () {
      repository.setCache('key1', 'data1');
      repository.setCache('key2', 'data2');

      repository.invalidateAll();

      expect(repository.getCached('key1'), isNull);
      expect(repository.getCached('key2'), isNull);
    });
  });
}
