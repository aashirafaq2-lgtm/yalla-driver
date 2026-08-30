import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../services/storage_service.dart';

class SocketService {
  IO.Socket? _socket;
  final StorageService _storageService;
  bool _isConnected = false;

  SocketService(this._storageService);

  IO.Socket? get socket => _socket;
  bool get isConnected => _isConnected;

  // Callbacks
  Function(dynamic)? onRideAccepted;
  Function(dynamic)? onDriverMoved;
  Function(dynamic)? onNewRideRequest;
  Function(dynamic)? onRideStatusUpdate;
  Function(dynamic)? onNewMessage;
  Function(dynamic)? onNotification;

  void connect() async {
    if (_socket != null && _socket!.connected) return;

    final token = await _storageService.getToken();
    final userId = await _storageService.getUserId();

    _socket = IO.io(
      'http://72.62.50.86',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token ?? ''})
          .enableAutoConnect()
          .enableReconnection()
          .build(),
    );

    _socket!.connect();

    _socket!.onConnect((_) {
      _isConnected = true;
      debugPrint('[Socket] Connected to server');
      
      if (userId != null && userId.isNotEmpty) {
        authenticate(userId);
      }
    });

    _socket!.on('new_ride_request', (data) {
      debugPrint('[Socket] Received new_ride_request: $data');
      onNewRideRequest?.call(data);
    });

    _socket!.on('ride_accepted', (data) {
      debugPrint('[Socket] Received ride_accepted: $data');
      onRideAccepted?.call(data);
    });

    _socket!.on('ride_status_update', (data) {
      debugPrint('[Socket] Received ride_status_update: $data');
      onRideStatusUpdate?.call(data);
    });

    _socket!.on('driver_moved', (data) {
      onDriverMoved?.call(data);
    });

    _socket!.on('new_message', (data) {
      onNewMessage?.call(data);
    });

    _socket!.on('notification', (data) {
      debugPrint('[Socket] Notification received: $data');
      onNotification?.call(data);
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
      debugPrint('[Socket] Disconnected from server');
    });

    _socket!.onError((err) => debugPrint('[Socket] Error: $err'));
  }

  void authenticate(String userId) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('authenticate', {
        'userId': userId,
        'role': 'DRIVER',
      });
      debugPrint('[Socket] Authenticated as DRIVER with userId: $userId');
    }
  }

  void joinRide(String rideId) {
    _socket?.emit('join_ride', {'rideId': rideId});
  }

  void updateLocation(double lat, double lng, {String? activeRideId, double? heading, double? speed}) async {
    final userId = await _storageService.getUserId();
    _socket?.emit('update_location', {
      'driverId': userId,
      'lat': lat,
      'lng': lng,
      'heading': heading ?? 0,
      'speed': speed ?? 0,
      'activeRideId': activeRideId,
    });
  }

  void acceptRide({
    required String rideId,
    required String driverName,
    required String carModel,
    required String plate,
  }) async {
    final userId = await _storageService.getUserId();
    _socket?.emit('accept_ride', {
      'rideId': rideId,
      'driverId': userId,
      'driverName': driverName,
      'carModel': carModel,
      'plate': plate,
    });
  }

  void changeStatus({required String rideId, required String status, Map<String, dynamic>? payload}) {
    _socket?.emit('status_change', {
      'rideId': rideId,
      'status': status,
      'payload': payload ?? {},
    });
  }

  void toggleDriverStatus(bool isOnline) async {
    final userId = await _storageService.getUserId();
    _socket?.emit('toggle_driver_status', {
      'driverId': userId,
      'status': isOnline ? 'ONLINE' : 'OFFLINE',
    });
  }

  void sendMessage(String rideId, String text) async {
    final userId = await _storageService.getUserId();
    _socket?.emit('send_message', {
      'rideId': rideId,
      'text': text,
      'senderId': userId,
    });
  }

  void disconnect() {
    _socket?.disconnect();
    _isConnected = false;
  }
}

