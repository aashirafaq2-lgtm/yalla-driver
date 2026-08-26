import 'dart:async';
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
import '../../rides/presentation/trip_ongoing_screen.dart';

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
  StreamSubscription<Position>? _locationSubscription;

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
    super.dispose();
  }

  void _initSocketListeners() {
    final socketService = Provider.of<SocketService>(context, listen: false);
    socketService.onNewRideRequest = (data) {
      if (!mounted) return;
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (!auth.isOnline) return;

      setState(() => _pendingRideRequest = data);
      _showRideRequestSheet(data);
    };
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
  }

  void _onLocationUpdate(Position pos) {
    if (!mounted) return;
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
    final price = data['estimatedPrice'] ?? '10,000';
    final passengerName = data['passengerName'] ?? 'Passenger';
    final pickup = data['pickupName'] ?? 'Pickup Location';
    final drop = data['dropName'] ?? 'Drop-off Destination';
    final rideId = data['id'] ?? data['rideId'] ?? 'demo_ride';

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BounceInUp(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            boxShadow: [
              BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, -5))
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(2)),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'NEW RIDE REQUEST',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: AppColors.primaryOrange),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.green.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                    child: const Text('Instant', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const CircleAvatar(
                    radius: 26,
                    backgroundColor: Color(0xFFF5F5F5),
                    child: Icon(Icons.person, color: AppColors.primaryOrange, size: 30),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(passengerName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(data['passengerPhone'] ?? '07xx xxx xxxx', style: const TextStyle(color: Colors.black45, fontSize: 13)),
                      ],
                    ),
                  ),
                  Text('$price IQD', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primaryOrange)),
                ],
              ),
              const Divider(height: 30),
              _buildRouteRow(Icons.trip_origin, 'Pickup', pickup, Colors.green),
              const SizedBox(height: 12),
              _buildRouteRow(Icons.location_on, 'Drop-off', drop, Colors.red),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          setState(() => _pendingRideRequest = null);
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.black26),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Decline', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryOrange,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 4,
                        ),
                        onPressed: () => _acceptRide(ctx, rideId, data),
                        child: const Text('Accept Ride', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRouteRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: Colors.black45)),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _acceptRide(BuildContext dialogContext, String rideId, dynamic data) async {
    final api = Provider.of<ApiService>(context, listen: false);
    final storage = Provider.of<StorageService>(context, listen: false);
    final socket = Provider.of<SocketService>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final token = await storage.getToken();

    try {
      if (token != null) {
        await api.acceptRide(rideId, token);
      }
    } catch (e) {
      debugPrint('Accept ride API note: $e');
    }

    final carModel = await storage.getCarModel() ?? 'Standard Vehicle';
    final plate = await storage.getLicensePlate() ?? 'IQ-0000';

    socket.acceptRide(
      rideId: rideId,
      driverName: auth.driverName,
      carModel: carModel,
      plate: plate,
    );

    Navigator.pop(dialogContext);
    setState(() => _pendingRideRequest = null);

    if (mounted) {
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
                maxZoom: 18,
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildCircleIcon(
                    icon: Icons.person,
                    onTap: () => Navigator.pushNamed(context, '/profile'),
                  ),

                  // Online / Offline Pill Toggle
                  GestureDetector(
                    onTap: () => auth.toggleStatus(),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeInOut,
                      width: 125,
                      height: 40,
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
                                child: Text('Offline', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                              ),
                            ),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Container(
                              key: ValueKey(isOnline),
                              width: 28,
                              height: 28,
                              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                              child: Center(
                                child: Icon(
                                  isOnline ? Icons.check : Icons.close,
                                  size: 16,
                                  color: isOnline ? const Color(0xFF4CAF50) : const Color(0xFFE53935),
                                ),
                              ),
                            ),
                          ),
                          if (isOnline)
                            const Expanded(
                              child: Center(
                                child: Text('Online', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

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

