import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/socket_service.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/active_ride_provider.dart';
import '../../../../core/providers/driver_locale_provider.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/sound_service.dart';
import '../../../../core/services/background_service.dart';
import '../../rides/presentation/trip_ongoing_screen.dart';
import '../../rides/presentation/parcel_active_delivery_screen.dart';
import 'package:flutter_background_service/flutter_background_service.dart';


// Kirkuk, Iraq coordinates (matches the default map center)
const _kMapCenter = LatLng(35.4681, 44.3922);

class DriverMapScreen extends StatefulWidget {
  const DriverMapScreen({super.key});

  @override
  State<DriverMapScreen> createState() => _DriverMapScreenState();
}

class _DriverMapScreenState extends State<DriverMapScreen> {
  final MapController _mapController = MapController();
  LatLng _currentLocation = _kMapCenter;
  dynamic _pendingRideRequest;
  bool _requestSheetOpen = false;
  StreamSubscription<Position>? _locationSubscription;
  StreamSubscription<Map<String, dynamic>?>? _bgLocationSub;
  bool _isMockLocationDetected = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initSocketListeners();
      _startRealGPS();
    });
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _bgLocationSub?.cancel();
    super.dispose();
  }

  void _initSocketListeners() {
    final socketService = Provider.of<SocketService>(context, listen: false);
    socketService.onNewRideRequest = (data) {
      if (!mounted) return;

      // Show local notification (Uber-style alert)
      NotificationService.showNotification(
        id: NotificationService.idRideRequest,
        title: '🚕 New Ride Request!',
        body: 'From: ${data['pickupName'] ?? 'Pickup'} → ${data['dropName'] ?? 'Destination'}',
        payload: jsonEncode(data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{}),
      );

      // Play loud Uber-style ping sound alert
      if (_requestSheetOpen) return;
      setState(() => _pendingRideRequest = data);
      _showRideRequestSheet(data);
    };

    socketService.onNewParcelRequest = (data) {
      if (!mounted) return;
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (!auth.isOnline) return;

      NotificationService.showNotification(
        id: 2,
        title: '📦 New Parcel Request!',
        body: 'From: ${data['pickupRegion'] ?? 'Sender'} → ${data['dropRegion'] ?? 'Recipient'}',
        payload: jsonEncode({
          ...Map<String, dynamic>.from(data as Map),
          'id': data['parcelId'],
          'type': 'NEW_PARCEL_REQUEST',
        }),
      );

      SoundService().playRideRequest();

      final parcelData = {
        'id': data['parcelId'],
        'pickupName': data['pickupRegion'] ?? 'Sender Area',
        'dropName': data['dropRegion'] ?? 'Delivery Area',
        'estimatedPrice': data['price'] ?? 10000,
        'pickupLat': data['pickupLat'],
        'pickupLng': data['pickupLng'],
        'dropLat': data['dropLat'],
        'dropLng': data['dropLng'],
        'passenger': {'firstName': 'Parcel', 'lastName': 'Delivery', 'rating': 5.0, 'phone': ''},
        'isParcel': true,
      };

      setState(() => _pendingRideRequest = parcelData);
      _showRideRequestSheet(parcelData);
    };

    // ✅ New scheduled trip booking notification
    socketService.onNewTripBooking = (data) {
      if (!mounted) return;
      SoundService().playRideRequest();
      NotificationService.showNotification(
        id: 3,
        title: '🎉 New Seat Booked!',
        body: '${data['passengerName'] ?? 'Passenger'} booked ${data['seatsBooked'] ?? 1} seat(s) on your trip',
        payload: data['tripId']?.toString() ?? '',
      );
      _showTripBookingNotif(data);
    };

    socketService.onRideCancelled = (data) {
      if (!mounted) return;
      final wasPendingRequest = _pendingRideRequest != null &&
          _pendingRideRequest['id']?.toString() == data['rideId']?.toString();
      if (!wasPendingRequest) return;
      SoundService().stopRingtone();
      setState(() => _pendingRideRequest = null);
      if (_requestSheetOpen) {
        Navigator.of(context).pop();
      }
      NotificationService.showNotification(
        id: NotificationService.idRideRequest,
        title: data['cancelledBy'] == 'another_driver' ? 'Ride Assigned' : 'Ride Cancelled',
        body: data['reason']?.toString() ?? 'This ride request is no longer available.',
        payload: data['rideId']?.toString() ?? '',
      );
    };

    unawaited(_restorePendingRequest());
  }

  Future<void> _restorePendingRequest() async {
    final pendingRequest = NotificationService.takePendingRideRequest();
    if (pendingRequest != null) {
      final isParcel = pendingRequest['type'] == 'NEW_PARCEL_REQUEST';
      pendingRequest['id'] ??= isParcel ? pendingRequest['parcelId'] : pendingRequest['rideId'];
      final requestId = pendingRequest['id']?.toString();
      if (requestId != null && requestId.isNotEmpty) {
        try {
          final storage = Provider.of<StorageService>(context, listen: false);
          final api = Provider.of<ApiService>(context, listen: false);
          final token = await storage.getToken();
          if (token == null) return;
          if (isParcel) {
            final response = await api.getParcelRequest(requestId, token);
            final parcel = response.data?['parcel'];
            if (parcel is! Map || !mounted) return;
            final sender = parcel['sender'];
            final request = <String, dynamic>{
              'id': requestId,
              'parcelId': requestId,
              'pickupName': parcel['pickupRegion'] ?? pendingRequest['pickupRegion'] ?? 'Sender Area',
              'dropName': parcel['dropRegion'] ?? pendingRequest['dropRegion'] ?? 'Delivery Area',
              'estimatedPrice': parcel['price'] ?? pendingRequest['price'] ?? 0,
              'pickupLat': parcel['pickupLat'] ?? pendingRequest['pickupLat'],
              'pickupLng': parcel['pickupLng'] ?? pendingRequest['pickupLng'],
              'dropLat': parcel['dropLat'] ?? pendingRequest['dropLat'],
              'dropLng': parcel['dropLng'] ?? pendingRequest['dropLng'],
              'parcelType': parcel['parcelType'],
              'isParcel': true,
              'passengerName': [sender?['firstName'], sender?['lastName']]
                  .where((part) => part != null && part.toString().isNotEmpty).join(' '),
              'passengerPhone': sender?['phone'] ?? '',
            };
            setState(() => _pendingRideRequest = request);
            _showRideRequestSheet(request);
          } else {
            final response = await api.getRideRequest(requestId, token);
            final ride = response.data?['ride'];
            if (ride is! Map || !mounted) return;
            final authoritativeRide = Map<String, dynamic>.from(ride);
            authoritativeRide['id'] ??= requestId;
            authoritativeRide['rideId'] ??= requestId;
            authoritativeRide['passengerName'] ??= [ride['passenger']?['firstName'], ride['passenger']?['lastName']]
                .where((part) => part != null && part.toString().isNotEmpty).join(' ');
            authoritativeRide['pickupName'] ??= pendingRequest['pickupName'];
            authoritativeRide['dropName'] ??= pendingRequest['dropName'];
            authoritativeRide['estimatedPrice'] ??= pendingRequest['estimatedPrice'];
            setState(() => _pendingRideRequest = authoritativeRide);
            _showRideRequestSheet(authoritativeRide);
          }
        } catch (e) {
          debugPrint('[Driver] Pending request is no longer valid: $e');
        }
      }
    }
  }
  void _showTripBookingNotif(dynamic data) {
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      builder: (ctx) {
        final passengerName = data['passengerName'] ?? 'Passenger';
        final seats = data['seatsBooked'] ?? 1;
        final from = data['from'] ?? '';
        final to = data['to'] ?? '';
        final price = data['totalPrice'] ?? 0;
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 18),
                    SizedBox(width: 6),
                    Text('New Booking!', style: TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.primaryOrange.withOpacity(0.15),
                    child: const Icon(Icons.person, color: AppColors.primaryOrange, size: 26),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(passengerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('$seats seat${seats > 1 ? 's' : ''} booked', style: const TextStyle(color: Colors.black54, fontSize: 13)),
                      ],
                    ),
                  ),
                  Text('${price > 0 ? price : ''} IQD', style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primaryOrange, fontSize: 15)),
                ],
              ),
              if (from.isNotEmpty && to.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(from, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const Icon(Icons.arrow_forward, size: 18, color: Colors.black45),
                      Text(to, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('OK, Got it!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }


  Future<void> _startRealGPS() async {
    // Request permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) return;

    // Get initial position fast
    try {
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      _onLocationUpdate(pos);
    } catch (_) {}

    // Stream continuous updates
    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // update every 10 meters
      ),
    ).listen(_onLocationUpdate);

    // Listen to background service location updates
    _bgLocationSub = FlutterBackgroundService().on('locationUpdate').listen((event) {
      if (event != null) {
        final lat = (event['lat'] as num?)?.toDouble();
        final lng = (event['lng'] as num?)?.toDouble();
        final heading = (event['heading'] as num?)?.toDouble();
        final speed = (event['speed'] as num?)?.toDouble();
        if (lat != null && lng != null) {
          final newLoc = LatLng(lat, lng);
          if (mounted) {
            setState(() => _currentLocation = newLoc);
          }
          final activeRide = Provider.of<ActiveRideProvider>(context, listen: false).activeRide;
          final rideId = activeRide?['id']?.toString() ?? activeRide?['rideId']?.toString();
          Provider.of<SocketService>(context, listen: false).updateLocation(
            lat,
            lng,
            activeRideId: rideId,
            heading: heading,
            speed: speed,
          );
        }
      }
    });
  }

  void _onLocationUpdate(Position pos) {
    if (!mounted) return;

    // ── Mock Location / Fake GPS Blocker ──────────────────────────────
    if (pos.isMocked) {
      if (!_isMockLocationDetected) {
        setState(() => _isMockLocationDetected = true);
        final auth = Provider.of<AuthProvider>(context, listen: false);
        if (auth.isOnline) {
          auth.toggleStatus(); // Force offline if using fake GPS
        }
      }
      return; // Do NOT emit fake coordinates to server
    } else {
      if (_isMockLocationDetected) {
        setState(() => _isMockLocationDetected = false);
      }
    }

    final newLoc = LatLng(pos.latitude, pos.longitude);
    setState(() => _currentLocation = newLoc);

    try {
      _mapController.move(newLoc, _mapController.camera.zoom);
    } catch (_) {}

    final socketService = Provider.of<SocketService>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.isOnline) {
      socketService.updateLocation(
        pos.latitude,
        pos.longitude,
        heading: pos.heading,
        speed: pos.speed,
      );
    }
  }

  void _streamLocation() {
    // kept for the refresh button — just re-fetch once
    Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
        .then(_onLocationUpdate)
        .catchError((_) {});
  }

  void _showRideRequestSheet(dynamic data) {
    if (_requestSheetOpen || !mounted) return;
    _requestSheetOpen = true;
    SoundService().playRideRequest();

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _IncomingRideModal(
        data: data,
        onAccept: (rideId) => _acceptRide(ctx, rideId, data),
        onDecline: () {
          SoundService().stopRingtone();
          if (Navigator.of(ctx).canPop()) Navigator.pop(ctx);
          setState(() => _pendingRideRequest = null);
        },
      ),
    ).whenComplete(() {
      _requestSheetOpen = false;
      SoundService().stopRingtone();
    });
  }


  Future<void> _acceptRide(BuildContext dialogContext, String rideId, dynamic data) async {
    final api = Provider.of<ApiService>(context, listen: false);
    final storage = Provider.of<StorageService>(context, listen: false);
    final token = await storage.getToken();

    if (token == null || token.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in again before accepting a ride.')),
        );
      }
      return;
    }
    final isParcel = data is Map && data['isParcel'] == true;
    try {
      if (isParcel) {
        await api.acceptParcel(rideId, token);
      } else {
        await api.acceptRide(rideId, token);
      }
    } catch (e) {
      debugPrint('Accept ride rejected by backend: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This ride is no longer available. Please refresh requests.')),
        );
      }
      return;
    }

    // PATCH /ride/accept is authoritative and emits the acceptance event.
    // Do not send a second, client-authored accept_ride socket event.
    await SoundService().stopRingtone();
    if (isParcel) {
      if (Navigator.of(dialogContext).canPop()) Navigator.pop(dialogContext);
      if (mounted) setState(() => _pendingRideRequest = null);
      final parcelType = (data['type'] ?? data['parcelType'] ?? '').toString().toUpperCase();
      if (mounted) {
        await Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ParcelActiveDeliveryScreen(orderData: {
            ...Map<String, dynamic>.from(data),
            'id': rideId,
            'isMail': parcelType == 'MAIL',
          }),
        ));
      }
      return;
    }
    BackgroundServiceInstance.updateRideId(rideId);
    final passenger = data is Map ? data['passenger'] : null;
    Provider.of<ActiveRideProvider>(context, listen: false).setActiveRide({
      'id': rideId,
      'rideId': rideId,
      'status': 'ACCEPTED',
      'name': data is Map ? (data['passengerName'] ?? 'Passenger') : 'Passenger',
      'phone': data is Map ? (data['passengerPhone'] ?? passenger?['phone'] ?? '') : '',
      'from': data is Map ? (data['pickupName'] ?? 'Pickup Location') : 'Pickup Location',
      'to': data is Map ? (data['dropName'] ?? 'Destination') : 'Destination',
      'price': data is Map ? (data['estimatedPrice'] ?? 0) : 0,
      'pickupLat': data is Map ? data['pickupLat'] : null,
      'pickupLng': data is Map ? data['pickupLng'] : null,
      'dropLat': data is Map ? data['dropLat'] : null,
      'dropLng': data is Map ? data['dropLng'] : null,
    });

    Navigator.pop(dialogContext);
    setState(() => _pendingRideRequest = null);

    if (mounted) {
      // Yango-style Animated Success Overlay Overlay
      showGeneralDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withOpacity(0.85),
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (ctx, anim1, anim2) {
          return Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElasticIn(
                    duration: const Duration(milliseconds: 1200),
                    child: Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF65CA28),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF65CA28).withOpacity(0.6),
                            blurRadius: 35,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.check_rounded, color: Colors.white, size: 80),
                    ),
                  ),
                  const SizedBox(height: 30),
                  FadeInUp(
                    delay: const Duration(milliseconds: 300),
                    child: const Text(
                      'RIDE ACCEPTED!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  FadeInUp(
                    delay: const Duration(milliseconds: 500),
                    child: Text(
                      'Navigating to Pickup Location...',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );

      // Wait 1.8s for Yango animation effect before launching ongoing ride screen
      await Future.delayed(const Duration(milliseconds: 1800));
      if (!mounted) return;
      Navigator.pop(context); // Close animation dialog

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TripOngoingScreen(
            tripData: {
              'id': rideId,
              'name': data['passengerName'] ?? 'Passenger',
              'time': 'Now',
              'from': data['pickupName'] ?? 'Pickup',
              'to': data['dropName'] ?? 'Destination',
              'price': '${data['estimatedPrice'] ?? 10000} IQD',
              'phone': data['passengerPhone'] ?? '07xx xxx xxxx',
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final isOnline = auth.isOnline;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ── FULL SCREEN MAP ──────────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation,
              initialZoom: 14.5,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.yalla.driver',
                maxZoom: 19,
              ),

              MarkerLayer(
                markers: [
                  Marker(
                    point: _currentLocation,
                    width: 50,
                    height: 50,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primaryOrange,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, 3))],
                      ),
                      child: const Icon(Icons.directions_car, color: Colors.white, size: 24),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // ── TOP BAR ──────────────────────────────────────────────────────
          SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      _buildCircleIcon(
                        icon: Icons.person,
                        onTap: () => Navigator.pushNamed(context, '/profile'),
                      ),
                      const SizedBox(width: 8),

                      // Language Dropdown Pill
                      Consumer<DriverLocaleProvider>(
                        builder: (context, localeProv, _) {
                          final isAr = localeProv.isArabic;
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: isAr ? 'ar' : 'en',
                                isDense: true,
                                icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFFFF5E00)),
                                borderRadius: BorderRadius.circular(16),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'ar',
                                    child: Text('🇮🇶 العربية', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  ),
                                  DropdownMenuItem(
                                    value: 'en',
                                    child: Text('🇬🇧 English', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                                onChanged: (code) {
                                  if (code != null) {
                                    localeProv.setLocale(Locale(code));
                                  }
                                },
                              ),
                            ),
                          );
                        },
                      ),

                      const Spacer(),

                      // Online / Offline Pill Toggle (Guarded against Fake GPS)
                      GestureDetector(
                        onTap: () {
                          if (_isMockLocationDetected) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: const Color(0xFFDC2626),
                                content: const Text(
                                  '⚠️ لا يمكن الاتصال بالإنترنت أثناء استخدام Fake GPS / Mock Location!',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            );
                            return;
                          }
                          auth.toggleStatus();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeInOut,
                          width: 110,
                          height: 38,
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          decoration: BoxDecoration(
                            color: isOnline ? const Color(0xFF4CAF50) : const Color(0xFFE53935),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3))],
                          ),
                          child: Row(
                            mainAxisAlignment: isOnline ? MainAxisAlignment.end : MainAxisAlignment.start,
                            children: [
                              if (!isOnline)
                                const Expanded(
                                  child: Center(
                                    child: Text('Offline', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                  ),
                                ),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: Container(
                                  key: ValueKey(isOnline),
                                  width: 26,
                                  height: 26,
                                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                  child: Center(
                                    child: Icon(
                                      isOnline ? Icons.check : Icons.close,
                                      size: 15,
                                      color: isOnline ? const Color(0xFF4CAF50) : const Color(0xFFE53935),
                                    ),
                                  ),
                                ),
                              ),
                              if (isOnline)
                                const Expanded(
                                  child: Center(
                                    child: Text('Online', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      _buildCircleIcon(
                        icon: Icons.refresh,
                        onTap: () {
                          _streamLocation();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('GPS Location updated and synced!'), duration: Duration(seconds: 1)),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // ── Fake GPS Warning Banner ──────────────────────────────
                if (_isMockLocationDetected)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC2626),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 3))],
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.white, size: 24),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '⚠️ تم اكتشاف موقع وهمي (Fake GPS)! يرجى إيقاف برامج التزييف لاستقبال الرحلات.',
                            style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

        ],
      ),
    );
  }

  Widget _buildCircleIcon({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Icon(icon, color: Colors.black87, size: 24),
      ),
    );
  }
}

class _IncomingRideModal extends StatefulWidget {
  final dynamic data;
  final Function(String rideId) onAccept;
  final VoidCallback onDecline;

  const _IncomingRideModal({
    required this.data,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  State<_IncomingRideModal> createState() => _IncomingRideModalState();
}

class _IncomingRideModalState extends State<_IncomingRideModal> {
  static const int _totalSeconds = 20;
  int _secondsLeft = _totalSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_secondsLeft <= 1) {
        t.cancel();
        widget.onDecline();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final price = data['estimatedPrice'] ?? '10,000';
    final passengerName = data['passengerName'] ?? 'راكب يلا';
    final pickup = data['pickupName'] ?? 'نقطة الانطلاق';
    final drop = data['dropName'] ?? 'الوجهة المقصودة';
    final rideId = (data['id'] ?? data['rideId'] ?? 'ride').toString();

    final progress = _secondsLeft / _totalSeconds;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: BounceInUp(
        duration: const Duration(milliseconds: 300),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              BoxShadow(color: Colors.black38, blurRadius: 25, offset: Offset(0, -6))
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(2)),
              ),

              // Header with Countdown Ring
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryOrange.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.electric_bolt_rounded, color: AppColors.primaryOrange, size: 22),
                      ),
                      const SizedBox(width: 10),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'طلب مشوار فوري جديد',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Colors.black87),
                          ),
                          Text(
                            'المسافة قريبة منك الآن',
                            style: TextStyle(fontSize: 12, color: Colors.black45, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Circular Countdown Badge
                  SizedBox(
                    width: 52,
                    height: 52,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 4.5,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _secondsLeft > 7 ? AppColors.primaryOrange : Colors.red,
                          ),
                        ),
                        Text(
                          '$_secondsLeft',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: _secondsLeft > 7 ? AppColors.primaryOrange : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Passenger Info + Price Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.black.withOpacity(0.06)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: AppColors.primaryOrange.withOpacity(0.15),
                      child: const Icon(Icons.person, color: AppColors.primaryOrange, size: 30),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            passengerName,
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                              const SizedBox(width: 4),
                              Text(
                                '${data['passengerRating'] ?? '5.0'} • ركوب نقدي',
                                style: const TextStyle(color: Colors.black54, fontSize: 13),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$price',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.primaryOrange),
                        ),
                        const Text(
                          'دينار عراقي',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black45),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Pickup & Drop locations
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black.withOpacity(0.07)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
                          child: Icon(Icons.my_location_rounded, color: Colors.green.shade600, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('مكان الانطلاق', style: TextStyle(fontSize: 11, color: Colors.black45, fontWeight: FontWeight.w600)),
                              Text(pickup, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Divider(height: 18),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
                          child: Icon(Icons.location_on_rounded, color: Colors.red.shade600, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('مكان الوصول', style: TextStyle(fontSize: 11, color: Colors.black45, fontWeight: FontWeight.w600)),
                              Text(drop, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // Action Buttons (Decline / Accept)
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: SizedBox(
                      height: 54,
                      child: OutlinedButton(
                        onPressed: widget.onDecline,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text(
                          'تخطي',
                          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryOrange,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 6,
                          shadowColor: AppColors.primaryOrange.withOpacity(0.5),
                        ),
                        onPressed: () {
                          _timer?.cancel();
                          widget.onAccept(rideId);
                        },
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
                            SizedBox(width: 8),
                            Text(
                              'قبول المشوار',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}


