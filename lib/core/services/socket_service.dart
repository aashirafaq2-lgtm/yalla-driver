import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../services/storage_service.dart';

class SocketService {
  late IO.Socket socket;
  final StorageService _storageService;

  SocketService(this._storageService);

  // Callbacks – set by screens that need them
  Function(dynamic)? onRideAccepted;
  Function(dynamic)? onDriverMoved;
  Function(dynamic)? onNewRideRequest;

  void connect() async {
    final token = await _storageService.getToken();

    socket = IO.io('http://76.13.3.121:4000',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token ?? ''})
          .build());

    socket.connect();

    socket.onConnect((_) {
      print('[Socket] Connected');
      // Authenticate after connection
      socket.emit('authenticate', {
        'userId': 'current_user_id', // This should be passed from UI/Storage
        'role': 'DRIVER', // For driver app
        'governorateId': 'current_governorate_id' // Optional
      });
    });

    socket.on('ride_accepted', (data) {
      onRideAccepted?.call(data);
    });

    socket.on('driver_moved', (data) {
      onDriverMoved?.call(data);
    });

    socket.on('new_ride_request', (data) {
      onNewRideRequest?.call(data);
    });

    socket.on('notification', (data) {
      print('[Socket] Notification received: $data');
    });

    socket.onDisconnect((_) => print('[Socket] Disconnected'));
  }

  /// Emit location updates
  void updateLocation(double lat, double lng, {String? rideId}) {
    socket.emit('update_location', {'lat': lat, 'lng': lng, 'rideId': rideId});
  }

  void disconnect() => socket.disconnect();
}
