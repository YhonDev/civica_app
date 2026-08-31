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
  });
}
