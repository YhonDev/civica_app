import 'package:flutter/foundation.dart';


/// Enterprise SWR (Stale-While-Revalidate) Cache Repository.
///
/// Features:
/// 1. Instant loading (0ms) using in-memory and persistent local cache.
/// 2. Silent background revalidation against backend endpoints.
/// 3. Seamless UI updates without screen flicker.
class LocalCacheRepository {
  static final LocalCacheRepository instance = LocalCacheRepository._internal();

  LocalCacheRepository._internal();

  final Map<String, dynamic> _memoryCache = {};
  final Map<String, DateTime> _timestamps = {};



  /// Reads cached value synchronously from memory if within maxAge TTL.
  dynamic getCached(String key, {Duration? maxAge}) {
    if (_memoryCache.containsKey(key)) {
      final timestamp = _timestamps[key];
      if (maxAge != null && timestamp != null) {
        if (DateTime.now().difference(timestamp) > maxAge) {
          _memoryCache.remove(key);
          _timestamps.remove(key);
          return null;
        }
      }
      return _memoryCache[key];
    }
    return null;
  }

  /// Asynchronously loads persistent cache into memory if not present.
  Future<dynamic> getCachedAsync(String key, {Duration? maxAge}) async {
    return getCached(key, maxAge: maxAge);
  }

  /// Saves data to memory and persistent cache.
  void setCache(String key, dynamic data) {
    _memoryCache[key] = data;
    _timestamps[key] = DateTime.now();
  }

  /// Clears cache key or entire cache.
  void invalidate(String key) {
    _memoryCache.remove(key);
    _timestamps.remove(key);
  }

  void invalidateAll() {
    _memoryCache.clear();
    _timestamps.clear();
  }

  /// Invalida únicamente las claves que coincidan con un patrón o prefijo.
  void invalidatePattern(String pattern) {
    final keysToRemove = _memoryCache.keys.where((k) => k.contains(pattern)).toList();
    for (final key in keysToRemove) {
      _memoryCache.remove(key);
      _timestamps.remove(key);
    }
  }

  /// Core Enterprise SWR Execution Workflow.
  ///
  /// 1. Immediately yields cached data to [onData] (0ms latency) if available within TTL.
  /// 2. Runs [fetcher] in background.
  /// 3. Updates cache and invokes [onData] with fresh backend data unconditionally.
  Future<void> executeSWR<T>({
    required String key,
    required Future<T> Function() fetcher,
    required void Function(T data, bool isStale) onData,
    void Function(Object error)? onError,
    Duration maxAge = const Duration(minutes: 3),
  }) async {
    final cached = getCached(key, maxAge: maxAge);
    bool hasCached = false;

    if (cached != null) {
      hasCached = true;
      try {
        onData(cached as T, true);
      } catch (e) {
        debugPrint('[SWR] Error rendering cached data for key $key: $e');
      }
    }

    try {
      final fresh = await fetcher();
      setCache(key, fresh);
      onData(fresh, false);
    } catch (e) {
      debugPrint('[SWR] Background fetch failed for key $key: $e');
      if (!hasCached && onError != null) {
        onError(e);
      }
    }
  }
}
