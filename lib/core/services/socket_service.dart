import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../services/storage_service.dart';

class SocketService {
  IO.Socket? _socket;
  final StorageService _storageService;
  bool _isConnected = false;
  String? _currentRideId;

  SocketService(this._storageService);

  IO.Socket? get socket => _socket;
  bool get isConnected => _isConnected;

  // ── Callbacks ──────────────────────────────────────────────────────
  Function(dynamic)? onRideAccepted;
  Function(dynamic)? onDriverMoved;
  Function(dynamic)? onNewRideRequest;
  Function(dynamic)? onNewParcelRequest;
  Function(dynamic)? onRideStatusUpdate;
  Function(dynamic)? onNewMessage;
  Function(dynamic)? onNotification;
  Function(dynamic)? onRideCancelled;
  Function(dynamic)? onNewTripBooking;

  void connect() async {
    if (_socket != null) {
      if (!_socket!.connected) _socket!.connect();
      return;
    }

    final token = await _storageService.getToken();
    final userId = await _storageService.getUserId();

    _socket = IO.io(
      'https://api-yalla.aaaj.shop',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token ?? ''})
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(double.maxFinite.toInt())
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(5000)
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

    _socket!.onReconnect((_) {
      debugPrint('[Socket] Reconnected');
      if (userId != null && userId.isNotEmpty) {
        authenticate(userId);
      }
    });

    _socket!.on('new_ride_request', (data) {
      debugPrint('[Socket] new_ride_request: $data');
      onNewRideRequest?.call(data);
    });

    _socket!.on('new_parcel_request', (data) {
      debugPrint('[Socket] new_parcel_request: $data');
      onNewParcelRequest?.call(data);
    });

    _socket!.on('ride_accepted', (data) {
      debugPrint('[Socket] ride_accepted: $data');
      onRideAccepted?.call(data);
    });

    _socket!.on('ride_status_update', (data) {
      debugPrint('[Socket] ride_status_update: $data');
      onRideStatusUpdate?.call(data);
    });

    _socket!.on('driver_moved', (data) {
      onDriverMoved?.call(data);
    });

    _socket!.on('new_message', (data) {
      onNewMessage?.call(data);
    });

    _socket!.on('notification', (data) {
      debugPrint('[Socket] notification: $data');
      onNotification?.call(data);
      // Also route RIDE_CANCELLED from notification wrapper
      if (data is Map) {
        final payload = data['data'] ?? data;
        final type = payload['type'] ?? data['type'];
        if (type == 'RIDE_CANCELLED') {
          onRideCancelled?.call(payload);
        }
      }
    });

    _socket!.on('ride_cancelled', (data) {
      debugPrint('[Socket] ride_cancelled: $data');
      onRideCancelled?.call(data);
    });

    _socket!.on('new_trip_booking', (data) {
      debugPrint('[Socket] new_trip_booking: $data');
      onNewTripBooking?.call(data);
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
      debugPrint('[Socket] Disconnected from server');
    });

    _socket!.onError((err) => debugPrint('[Socket] Error: $err'));
  }

  void authenticate(String userId) {
    if (_socket != null && _socket!.connected) {
      if (_currentRideId != null) {
        joinRide(_currentRideId!);
      }
    }
  }

  void joinRide(String rideId) {
    _currentRideId = rideId;
    _socket?.emit('join_ride', {'rideId': rideId});
  }

  void updateLocation(double lat, double lng,
      {String? activeRideId, double? heading, double? speed}) async {
    final userId = await _storageService.getUserId();
    _socket?.emit('update_location', {
      'driverId': userId,
      'lat': lat,
      'lng': lng,
      'heading': heading ?? 0,
      'speed': speed ?? 0,
      'activeRideId': activeRideId,
      'rideId': activeRideId,
    });
  }

  void acceptRide({
    required String rideId,
    required String driverName,
    required String carModel,
    required String plate,
    String? passengerId,
  }) async {
    final userId = await _storageService.getUserId();
    _socket?.emit('accept_ride', {
      'rideId': rideId,
      'driverId': userId,
      'driverName': driverName,
      'carModel': carModel,
      'plate': plate,
      if (passengerId != null && passengerId.isNotEmpty) 'passengerId': passengerId,
    });
  }

  void changeStatus(
      {required String rideId,
      required String status,
      Map<String, dynamic>? payload}) {
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
    _currentRideId = null;
    _socket?.disconnect();
    _isConnected = false;
  }
}
