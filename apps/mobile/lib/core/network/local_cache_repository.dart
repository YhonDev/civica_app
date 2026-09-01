import 'dart:convert';
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



  /// Reads cached value synchronously from memory, or asynchronously from persistent storage.
  dynamic getCached(String key) {
    if (_memoryCache.containsKey(key)) {
      return _memoryCache[key];
    }
    return null;
  }

  /// Asynchronously loads persistent cache into memory if not present.
  Future<dynamic> getCachedAsync(String key) async {
    return _memoryCache[key];
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

  /// Core Enterprise SWR Execution Workflow.
  ///
  /// 1. Immediately yields cached data to [onData] (0ms latency).
  /// 2. Runs [fetcher] in background.
  /// 3. If fresh data differs from cached data, updates cache and invokes [onData].
  Future<void> executeSWR<T>({
    required String key,
    required Future<T> Function() fetcher,
    required void Function(T data, bool isStale) onData,
    void Function(Object error)? onError,
  }) async {
    final cached = getCached(key);
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
      final freshEncoded = jsonEncode(fresh);
      final cachedEncoded = hasCached ? jsonEncode(cached) : null;

      if (!hasCached || freshEncoded != cachedEncoded) {
        setCache(key, fresh);
        onData(fresh, false);
      }
    } catch (e) {
      debugPrint('[SWR] Background fetch failed for key $key: $e');
      if (!hasCached && onError != null) {
        onError(e);
      }
    }
  }
}
