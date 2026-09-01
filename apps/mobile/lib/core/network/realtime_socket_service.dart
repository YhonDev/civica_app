import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'local_cache_repository.dart';

/// Enterprise Real-Time WebSockets Service for Flutter.
///
/// Listens to real-time events emitted by NestJS backend (e.g. PAGO_REGISTRADO,
/// MODALIDAD_CAMBIADA, SOLICITUD_CREADA) and invalidates local SWR caches
/// to push instant live updates to UI screens without user interaction.
class RealtimeSocketService {
  static final RealtimeSocketService instance = RealtimeSocketService._internal();

  RealtimeSocketService._internal();

  io.Socket? _socket;
  bool _isConnected = false;
  
  final List<VoidCallback> _onPagoListeners = [];
  final List<VoidCallback> _onModalidadListeners = [];

  void addPagoListener(VoidCallback listener) => _onPagoListeners.add(listener);
  void removePagoListener(VoidCallback listener) => _onPagoListeners.remove(listener);

  void addModalidadListener(VoidCallback listener) => _onModalidadListeners.add(listener);
  void removeModalidadListener(VoidCallback listener) => _onModalidadListeners.remove(listener);

  /// Initializes socket connection with tenant and user rooms.
  void init({
    required String serverUrl,
    required String tenantId,
    required String userId,
    String? residenteId,
  }) {
    if (_isConnected && _socket != null) return;

    try {
      debugPrint('[RealtimeSocket] Connecting to WebSockets gateway at $serverUrl...');
      _socket = io.io(
        serverUrl,
        io.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .build(),
      );

      _socket?.connect();

      _socket?.onConnect((_) {
        _isConnected = true;
        debugPrint('[RealtimeSocket] Connected successfully!');

        // Join Rooms
        _socket?.emit('joinTenantRoom', tenantId);
        _socket?.emit('joinUserRoom', {
          'tenantId': tenantId,
          'userId': userId,
          'residenteId': residenteId,
        });
      });

      _socket?.on('pago:registrado', (data) {
        debugPrint('[RealtimeSocket] Event PAGO_REGISTRADO received: $data');
        LocalCacheRepository.instance.invalidate('dashboard:residente');
        LocalCacheRepository.instance.invalidate('cartera:cobros');
        LocalCacheRepository.instance.invalidate('dashboard:cobrador');
        LocalCacheRepository.instance.invalidate('dashboard:administrador');
        
        for (final listener in _onPagoListeners) {
          listener();
        }
      });

      _socket?.on('modalidad:cambiada', (data) {
        debugPrint('[RealtimeSocket] Event MODALIDAD_CAMBIADA received: $data');
        LocalCacheRepository.instance.invalidate('dashboard:residente');
        LocalCacheRepository.instance.invalidate('cartera:cobros');
        LocalCacheRepository.instance.invalidate('dashboard:administrador');
        
        for (final listener in _onModalidadListeners) {
          listener();
        }
      });

      _socket?.on('solicitud:creada', (data) {
        debugPrint('[RealtimeSocket] Event SOLICITUD_CREADA received: $data');
        LocalCacheRepository.instance.invalidate('dashboard:cobrador');
        LocalCacheRepository.instance.invalidate('cobrador:viviendas');
        LocalCacheRepository.instance.invalidate('dashboard:administrador');
      });

      _socket?.onDisconnect((_) {
        _isConnected = false;
        debugPrint('[RealtimeSocket] Disconnected from WebSockets gateway');
      });
    } catch (e) {
      debugPrint('[RealtimeSocket] Failed to initialize WebSockets: $e');
    }
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
  }
}
