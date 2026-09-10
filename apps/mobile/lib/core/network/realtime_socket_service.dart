import 'dart:async';
import 'dart:math' show min;

import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'local_cache_repository.dart';
import 'api_client.dart';

/// Enterprise Real-Time WebSockets Service for Flutter.
///
/// Listens to real-time events emitted by NestJS backend (e.g. PAGO_REGISTRADO,
/// MODALIDAD_CAMBIADA, SOLICITUD_CREADA) and invalidates local SWR caches
/// to push instant live updates to UI screens without user interaction.
///
/// Features:
/// - Automatic reconnection with exponential backoff (1s → 2s → 4s → 8s → 16s → 30s cap)
/// - Configurable server URL (no hardcoded localhost)
/// - Graceful disconnect and resource cleanup
/// - Socket.IO v4 connection with websocket-only transport
class RealtimeSocketService {
  static final RealtimeSocketService instance = RealtimeSocketService._internal();

  RealtimeSocketService._internal();

  io.Socket? _socket;
  bool _isConnected = false;
  bool _intentionalDisconnect = false;
  String? _serverUrl;
  String? _tenantId;
  String? _userId;
  String? _token;
  String? _residenteId;

  // Reconnection state
  int _reconnectAttempt = 0;
  static const int _maxReconnectAttempt = 6;
  static const Duration _baseReconnectDelay = Duration(seconds: 1);
  static const Duration _maxReconnectDelay = Duration(seconds: 30);
  Timer? _reconnectTimer;

  final List<VoidCallback> _onPagoListeners = [];
  final List<VoidCallback> _onModalidadListeners = [];

  void addPagoListener(VoidCallback listener) => _onPagoListeners.add(listener);
  void removePagoListener(VoidCallback listener) => _onPagoListeners.remove(listener);

  void addModalidadListener(VoidCallback listener) => _onModalidadListeners.add(listener);
  void removeModalidadListener(VoidCallback listener) => _onModalidadListeners.remove(listener);

  /// Whether the socket is currently connected.
  bool get isConnected => _isConnected;

  /// Initializes socket connection with tenant and user rooms.
  /// Uses exponential backoff for automatic reconnection on disconnects.
  void init({
    required String serverUrl,
    required String tenantId,
    required String userId,
    String? token,
    String? residenteId,
  }) {
    // Store params for reconnection
    _serverUrl = serverUrl;
    _tenantId = tenantId;
    _userId = userId;
    _token = token;
    _residenteId = residenteId;
    _intentionalDisconnect = false;
    _reconnectAttempt = 0;

    // Realtime gateway strictly requires JWT token authentication
    if (token == null || token.isEmpty) {
      debugPrint('[RealtimeSocket] Token missing; skipping connection.');
      return;
    }

    _connect();
  }

  void _connect() {
    if (_isConnected && _socket != null) return;
    if (_serverUrl == null) return;

    try {
      // Dispose previous socket if exists
      _disposeSocket();

      debugPrint('[RealtimeSocket] Connecting to WebSockets gateway...');
      final optionsBuilder = io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .disableReconnection(); // Evita bucle rápido de reconexión nativa con tokens expirados

      if (_token != null && _token!.isNotEmpty) {
        optionsBuilder.setAuth({'token': _token});
        optionsBuilder.setExtraHeaders({'Authorization': 'Bearer $_token'});
      }

      _socket = io.io(_serverUrl, optionsBuilder.build());

      _setupEventListeners();
      _socket?.connect();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[RealtimeSocket] Failed to initialize WebSockets: $e');
      }
      _scheduleReconnect();
    }
  }

  void _setupEventListeners() {
    _socket?.onConnect((_) {
      _isConnected = true;
      _reconnectAttempt = 0; // Reset on successful connection
      debugPrint('[RealtimeSocket] Connected successfully!');

      // Join Rooms
      _joinRooms();
    });

    _socket?.on('pago:registrado', (data) {
      debugPrint('[RealtimeSocket] Event PAGO_REGISTRADO received');
      LocalCacheRepository.instance.invalidatePattern('dashboard');
      LocalCacheRepository.instance.invalidatePattern('cartera');
      if (data is Map && data['residenteId'] != null) {
        LocalCacheRepository.instance.invalidatePattern(data['residenteId'].toString());
      }
      for (final listener in _onPagoListeners) {
        listener();
      }
    });

    _socket?.on('modalidad:cambiada', (data) {
      debugPrint('[RealtimeSocket] Event MODALIDAD_CAMBIADA received');
      LocalCacheRepository.instance.invalidatePattern('dashboard');
      LocalCacheRepository.instance.invalidatePattern('tarifas');
      for (final listener in _onModalidadListeners) {
        listener();
      }
    });

    _socket?.on('solicitud:creada', (data) {
      debugPrint('[RealtimeSocket] Event SOLICITUD_CREADA received');
      LocalCacheRepository.instance.invalidatePattern('solicitudes');
      LocalCacheRepository.instance.invalidatePattern('dashboard');
    });

    _socket?.on('solicitud:cerrada', (data) {
      debugPrint('[RealtimeSocket] Event SOLICITUD_CERRADA received');
      LocalCacheRepository.instance.invalidatePattern('solicitudes');
      LocalCacheRepository.instance.invalidatePattern('dashboard');
    });

    _socket?.onDisconnect((_) {
      _isConnected = false;
      debugPrint('[RealtimeSocket] Disconnected from WebSockets gateway');
      if (!_intentionalDisconnect) {
        _scheduleReconnect();
      }
    });

    _socket?.onConnectError((error) {
      if (kDebugMode) {
        debugPrint('[RealtimeSocket] Connection error: $error');
      }
      _isConnected = false;
      if (!_intentionalDisconnect) {
        _scheduleReconnect();
      }
    });

    _socket?.onError((error) {
      if (kDebugMode) {
        debugPrint('[RealtimeSocket] Socket error: $error');
      }
    });

    _socket?.on('auth_error', (data) {
      debugPrint('[RealtimeSocket] Auth error from gateway: $data');
      _disposeSocket();
      _scheduleReconnect();
    });
  }

  void _joinRooms() {
    if (_tenantId != null) {
      _socket?.emit('joinTenantRoom', _tenantId);
    }
    if (_userId != null) {
      _socket?.emit('joinUserRoom', {
        'tenantId': _tenantId,
        'userId': _userId,
        'residenteId': _residenteId,
      });
    }
  }

  /// Schedules a reconnection attempt with exponential backoff.
  /// delay = min(baseDelay * 2^attempt, maxDelay)
  void _scheduleReconnect() {
    if (_intentionalDisconnect) return;
    if (_token == null || _token!.isEmpty) {
      debugPrint('[RealtimeSocket] Token missing; aborting reconnect.');
      return;
    }
    if (_reconnectAttempt >= _maxReconnectAttempt) {
      debugPrint('[RealtimeSocket] Max reconnection attempts reached ($_maxReconnectAttempt). Giving up.');
      return;
    }

    final delay = Duration(
      milliseconds: min(
        _baseReconnectDelay.inMilliseconds * (1 << _reconnectAttempt),
        _maxReconnectDelay.inMilliseconds,
      ),
    );

    debugPrint('[RealtimeSocket] Reconnecting in ${delay.inSeconds}s (attempt ${_reconnectAttempt + 1}/$_maxReconnectAttempt)...');

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () async {
      _reconnectAttempt++;
      try {
        final freshToken = await ApiClient.instance.tokenStorage.getAccessToken();
        if (freshToken != null && freshToken.isNotEmpty) {
          _token = freshToken;
        }
      } catch (_) {}
      _connect();
    });
  }

  void _disposeSocket() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  /// Gracefully disconnects and cancels any pending reconnection.
  void disconnect() {
    _intentionalDisconnect = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _disposeSocket();
    _isConnected = false;
    _reconnectAttempt = 0;
  }
}
