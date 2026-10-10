import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';

/// Fully functional background location service for the Driver app.
/// This runs as a Foreground Service on Android, keeping the socket alive
/// and broadcasting GPS coordinates even when the app is minimized or locked.
class BackgroundServiceInstance {

  static const String _notifChannelId = 'yalla_driver_bg_service';
  static const String _notifChannelName = 'Yalla Driver Active';

  static final FlutterBackgroundService _service = FlutterBackgroundService();

  static Future<void> initializeService() async {
    // Only configure and run on Android; iOS handles background location via geolocator & UIBackgroundModes
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;

    // Create Android notification channel first
    final FlutterLocalNotificationsPlugin notificationsPlugin =
        FlutterLocalNotificationsPlugin();
    await notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _notifChannelId,
            _notifChannelName,
            description: 'Keeps Yalla Driver active for receiving rides',
            importance: Importance.low,
            playSound: false,
            enableVibration: false,
          ),
        );

    await _service.configure(
      androidConfiguration: AndroidConfiguration(
        // The entrypoint that runs in the background isolate
        onStart: _onStart,
        autoStart: false, // Don't auto-start; only start when driver goes ONLINE
        isForegroundMode: true,
        notificationChannelId: _notifChannelId,
        initialNotificationTitle: 'Yalla Driver',
        initialNotificationContent: 'Online — Ready to receive rides',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: _onStart,
        onBackground: _onIosBackground,
      ),
    );
  }

  static void startService() {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    _service.startService();
  }

  static void stopService() {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    _service.invoke('stop');
  }

  static void updateRideId(String? rideId) {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    _service.invoke('setRideId', {'rideId': rideId ?? ''});
  }
}

/// iOS background handler (required by flutter_background_service)
@pragma('vm:entry-point')
Future<bool> _onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

/// Main background isolate entrypoint — runs continuously
@pragma('vm:entry-point')
void _onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  String? activeRideId;

  // Allow the main isolate to update the active rideId
  service.on('setRideId').listen((event) {
    final rideId = event?['rideId'];
    activeRideId = rideId is String && rideId.isNotEmpty ? rideId : null;
  });

  // Allow the main isolate to stop this service gracefully
  service.on('stop').listen((_) {
    service.stopSelf();
  });

  // Update foreground notification text
  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((_) {
      service.setAsForegroundService();
    });
    service.on('setAsBackground').listen((_) {
      service.setAsBackgroundService();
    });

    service.setForegroundNotificationInfo(
      title: 'Yalla Driver — Online',
      content: 'Receiving ride requests',
    );
  }

  // GPS stream — high accuracy, 5m distance filter
  try {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        ),
      ).listen((Position pos) {
        // Broadcast to the main isolate via invoke so it can emit via socket
        service.invoke('locationUpdate', {
          'lat': pos.latitude,
          'lng': pos.longitude,
          'heading': pos.heading,
          'speed': pos.speed,
          'rideId': activeRideId ?? '',
        });
      });
    }
  } catch (e) {
    debugPrint('[BGService] GPS Error: $e');
  }

  // Keep alive indefinitely via periodic heartbeat
  Timer.periodic(const Duration(seconds: 30), (_) {
    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: 'Yalla Driver — Online',
        content: 'Receiving ride requests · ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
      );
    }
    service.invoke('heartbeat', {'timestamp': DateTime.now().toIso8601String()});
  });
}
