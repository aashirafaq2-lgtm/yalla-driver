import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../network/api_service.dart';
import 'storage_service.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
    debugPrint('[FCM Background] Driver received message: ${message.messageId}');
  } catch (_) {}
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;
  static Map<String, dynamic>? _pendingRideRequest;

  // Channels
  static const String channelRideRequests = 'yalla_ride_request';
  static const String channelActiveRide = 'yalla_active_ride';
  static const String channelScheduled = 'yalla_scheduled';
  static const String channelGeneral = 'yalla_general';

  // Deterministic Notification IDs
  static const int idRideRequest = 1001;
  static const int idParcelRequest = 1002;
  static const int idActiveRide = 2001;
  static const int idScheduledBase = 3000;

  NotificationService([dynamic api, dynamic storage]);

  static Future<void> initialize(
      [ApiService? apiService, StorageService? storageService]) async {
    if (_initialized) return;

    try {
      tz.initializeTimeZones();
      final tzInfo = await FlutterTimezone.getLocalTimezone().timeout(
        const Duration(seconds: 2),
      );
      tz.setLocalLocation(tz.getLocation(tzInfo.identifier));
    } catch (_) {}

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('launcher_icon');

    // On iOS, do not prompt for notification permissions immediately on initialization
    // to prevent blocking UI rendering or triggering modal dialogues during App Review
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        debugPrint('[Notification] Driver Tapped: ${details.payload}');
        if (details.payload != null && details.payload!.isNotEmpty) {
          try {
            final decoded = jsonDecode(details.payload!);
            if (decoded is Map) _pendingRideRequest = Map<String, dynamic>.from(decoded);
          } catch (_) {
            _pendingRideRequest = {'id': details.payload, 'rideId': details.payload};
          }
        }
      },
    );

    // Create Dedicated Android Channels
    final androidImpl = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      await androidImpl.createNotificationChannel(
        AndroidNotificationChannel(
          channelRideRequests,
          'Incoming Ride Requests',
          description: 'High-priority ride and parcel request alerts',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 500, 200, 500, 200, 500]),
        ),
      );

      await androidImpl.createNotificationChannel(
        const AndroidNotificationChannel(
          channelActiveRide,
          'Active Ride Status',
          description: 'Ongoing trip status and passenger updates',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        ),
      );

      await androidImpl.createNotificationChannel(
        const AndroidNotificationChannel(
          channelScheduled,
          'Scheduled Rides & Bookings',
          description: 'Reminders for upcoming trips and bookings',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        ),
      );

      await androidImpl.createNotificationChannel(
        const AndroidNotificationChannel(
          channelGeneral,
          'General Notifications',
          description: 'General system announcements and account alerts',
          importance: Importance.defaultImportance,
        ),
      );

      try {
        await androidImpl.requestNotificationsPermission();
      } catch (e) {
        debugPrint('[NotificationService] Driver Android notification permission request: $e');
      }
    }

    _initialized = true;

    // Safely Initialize Firebase & FCM for Driver
    try {
      if (!kIsWeb) {
        await Firebase.initializeApp().timeout(
          const Duration(seconds: 4),
        );
        FirebaseMessaging.onBackgroundMessage(
            _firebaseMessagingBackgroundHandler);

        final messaging = FirebaseMessaging.instance;
        await messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        ).timeout(
          const Duration(seconds: 4),
          onTimeout: () => const NotificationSettings(
            authorizationStatus: AuthorizationStatus.notDetermined,
            alert: AppleNotificationSetting.notSupported,
            announcement: AppleNotificationSetting.notSupported,
            badge: AppleNotificationSetting.notSupported,
            carPlay: AppleNotificationSetting.notSupported,
            criticalAlert: AppleNotificationSetting.notSupported,
            lockScreen: AppleNotificationSetting.notSupported,
            notificationCenter: AppleNotificationSetting.notSupported,
            showPreviews: AppleShowPreviewSetting.notSupported,
            sound: AppleNotificationSetting.notSupported,
            timeSensitive: AppleNotificationSetting.notSupported,
          ),
        );

        // Foreground presentation options for iOS
        await FirebaseMessaging.instance
            .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );

        FirebaseMessaging.onMessageOpenedApp.listen((message) {
          if (['NEW_RIDE_REQUEST', 'NEW_PARCEL_REQUEST'].contains(message.data['type'])) {
            _pendingRideRequest = Map<String, dynamic>.from(message.data);
          }
        });
        final initialMessage = await messaging.getInitialMessage().timeout(
          const Duration(seconds: 3),
          onTimeout: () => null,
        );
        if (['NEW_RIDE_REQUEST', 'NEW_PARCEL_REQUEST'].contains(initialMessage?.data['type'])) {
          _pendingRideRequest = Map<String, dynamic>.from(initialMessage!.data);
        }

        final fcmToken = await messaging.getToken().timeout(
          const Duration(seconds: 4),
          onTimeout: () => null,
        );
        debugPrint('[FCM] Driver Device Token: $fcmToken');

        if (fcmToken != null &&
            apiService != null &&
            storageService != null) {
          final authToken = await storageService.getToken();
          if (authToken != null && authToken.isNotEmpty) {
            try {
              await apiService.updateFcmToken(fcmToken, authToken);
            } catch (_) {}
          }
        }

        // Listen for token refreshes
        messaging.onTokenRefresh.listen((newToken) async {
          debugPrint('[FCM] Driver Token Refreshed: $newToken');
          if (apiService != null && storageService != null) {
            final authToken = await storageService.getToken();
            if (authToken != null && authToken.isNotEmpty) {
              try {
                await apiService.updateFcmToken(newToken, authToken);
              } catch (_) {}
            }
          }
        });

        // Handle FCM messages in foreground
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          debugPrint('[FCM Foreground] Received: ${message.data}');
          final notification = message.notification;
          final data = message.data;
          final type = data['type']?.toString();

          // Foreground socket listeners show request sheets for rides and parcels.
          final isLiveRequest = ['NEW_RIDE_REQUEST', 'NEW_PARCEL_REQUEST'].contains(type);
          if (notification != null && !isLiveRequest) {
            showNotification(
              id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
              title: notification.title ?? 'Yalla Driver',
              body: notification.body ?? '',
              channelId: type == 'RIDE_CANCELLED' ? channelRideRequests : channelActiveRide,
            );
          }
        });
      }
    } catch (e) {
      debugPrint('[Firebase] Init note: $e');
    }
  }

  static Future<void> syncDeviceToken(ApiService apiService, String authToken) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        await apiService.updateFcmToken(token, authToken);
      }
    } catch (e) {
      debugPrint('[FCM] Driver token registration failed: $e');
    }
  }

  static Map<String, dynamic>? takePendingRideRequest() {
    final request = _pendingRideRequest;
    _pendingRideRequest = null;
    return request;
  }

  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String channelId = channelRideRequests,
  }) async {
    if (kIsWeb || !_initialized) return;

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      channelId,
      channelId == channelRideRequests
          ? 'Incoming Ride Requests'
          : (channelId == channelActiveRide ? 'Active Ride' : 'Yalla Driver'),
      channelDescription: 'Real-time ride notifications',
      importance: channelId == channelRideRequests ? Importance.max : Importance.high,
      priority: channelId == channelRideRequests ? Priority.max : Priority.high,
      playSound: true,
      enableVibration: true,
      vibrationPattern: channelId == channelRideRequests
          ? Int64List.fromList([0, 500, 200, 500, 200, 500])
          : Int64List.fromList([0, 250, 250, 250]),
      icon: 'launcher_icon',
      fullScreenIntent: channelId == channelRideRequests,
      category: channelId == channelRideRequests
          ? AndroidNotificationCategory.call
          : AndroidNotificationCategory.status,
    );

    final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: channelId == channelRideRequests
          ? InterruptionLevel.timeSensitive
          : InterruptionLevel.active,
    );

    final NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      id,
      title,
      body,
      platformDetails,
      payload: payload,
    );
  }

  static Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  static Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  // ── Scheduled Reminders ──────────────────────────────────────────────────
  static Future<void> scheduleRideReminders(DateTime rideTime, String rideId) async {
    if (kIsWeb || !_initialized) return;

    final now = DateTime.now();
    final androidDetails = const AndroidNotificationDetails(
      channelScheduled,
      'Scheduled Reminders',
      channelDescription: 'Reminders for your upcoming scheduled rides',
      importance: Importance.high,
      priority: Priority.high,
    );
    final iosDetails = const DarwinNotificationDetails();
    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    final intervals = [
      {'minutes': 60, 'message': 'You have a scheduled ride in 1 hour.'},
      {'minutes': 30, 'message': 'You have a scheduled ride in 30 minutes.'},
      {'minutes': 15, 'message': 'You have a scheduled ride in 15 minutes.'},
      {'minutes': 5, 'message': 'You have a scheduled ride in 5 minutes! Get ready.'},
    ];

    int offset = 0;
    for (final interval in intervals) {
      final mins = interval['minutes'] as int;
      final msg = interval['message'] as String;
      final reminderTime = rideTime.subtract(Duration(minutes: mins));
      
      if (reminderTime.isAfter(now)) {
        try {
          await _notificationsPlugin.zonedSchedule(
            idScheduledBase + offset + rideId.hashCode.abs() % 10000,
            'Upcoming Scheduled Ride',
            msg,
            tz.TZDateTime.from(reminderTime, tz.local),
            details,
            uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          );
        } catch (_) {}
      }
      offset++;
    }
  }
}
