import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/socket_service.dart';
import '../../../core/network/api_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/providers/auth_provider.dart';

enum RideProgressStep { drivingToPickup, arrivedAtPickup, inProgress, completed }

class TripOngoingScreen extends StatefulWidget {
  final Map<String, dynamic> tripData;
  const TripOngoingScreen({super.key, required this.tripData});

  @override
  State<TripOngoingScreen> createState() => _TripOngoingScreenState();
}

class _TripOngoingScreenState extends State<TripOngoingScreen> {
  final MapController _mapController = MapController();
  RideProgressStep _step = RideProgressStep.drivingToPickup;

  LatLng _driverPos = const LatLng(35.4681, 44.3922);
  LatLng _pickupPos = const LatLng(35.4720, 44.3880);
  LatLng _dropPos = const LatLng(35.4850, 44.4050);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _joinRideAndBroadcastLocation();
    });
  }

  void _joinRideAndBroadcastLocation() {
    final socket = Provider.of<SocketService>(context, listen: false);
    final rideId = widget.tripData['id'] ?? widget.tripData['rideId'] ?? 'active_ride';
    socket.joinRide(rideId);
    socket.updateLocation(_driverPos.latitude, _driverPos.longitude, activeRideId: rideId);
  }

  String get _stepButtonLabel {
    switch (_step) {
      case RideProgressStep.drivingToPickup:
        return 'Arrived at Pickup';
      case RideProgressStep.arrivedAtPickup:
        return 'Confirm Pickup';
      case RideProgressStep.inProgress:
        return 'Finish Trip';
      case RideProgressStep.completed:
        return 'Trip Completed';
    }
  }

  Future<void> _handleStepAction() async {
    final socket = Provider.of<SocketService>(context, listen: false);
    final api = Provider.of<ApiService>(context, listen: false);
    final storage = Provider.of<StorageService>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final token = await storage.getToken();

    final rideId = widget.tripData['id'] ?? widget.tripData['rideId'] ?? 'active_ride';

    if (_step == RideProgressStep.drivingToPickup) {
      setState(() => _step = RideProgressStep.arrivedAtPickup);
      socket.changeStatus(rideId: rideId, status: 'ARRIVED');
      if (token != null) api.updateRideStatus(rideId, 'ARRIVED', token);
    } else if (_step == RideProgressStep.arrivedAtPickup) {
      setState(() => _step = RideProgressStep.inProgress);
      socket.changeStatus(rideId: rideId, status: 'PICKED_UP');
      if (token != null) api.updateRideStatus(rideId, 'PICKED_UP', token);
    } else if (_step == RideProgressStep.inProgress) {
      setState(() => _step = RideProgressStep.completed);
      
      final priceStr = widget.tripData['price']?.toString().replaceAll(RegExp(r'[^0-9.]'), '') ?? '10000';
      final finalPrice = double.tryParse(priceStr) ?? 10000.0;

      socket.changeStatus(
        rideId: rideId,
        status: 'COMPLETED',
        payload: {'finalPrice': finalPrice},
      );

      if (token != null) {
        await api.updateRideStatus(rideId, 'COMPLETED', token, finalPrice: finalPrice);
      }

      await auth.loadProfile();

      if (mounted) {
        _showCompletionDialog(context, finalPrice);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.tripData['name'] ?? 'Passenger';
    final from = widget.tripData['from'] ?? 'Kirkuk';
    final to = widget.tripData['to'] ?? 'Baghdad';
    final phone = widget.tripData['phone'] ?? '07xx xxx xxxx';
    final price = widget.tripData['price'] ?? '25,000 IQD';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: AppColors.primaryOrange, size: 32),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Yalla ',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 28),
            ),
            Text(
              'يَلَّا',
              style: TextStyle(color: AppColors.primaryOrange, fontWeight: FontWeight.bold, fontSize: 28),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          // ── Real Live OpenStreetMap ─────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _driverPos,
              initialZoom: 14.5,
              interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.yalla.driver',
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: [_driverPos, _pickupPos, _dropPos],
                    color: AppColors.primaryOrange,
                    strokeWidth: 4,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _pickupPos,
                    width: 36,
                    height: 36,
                    child: _buildPin(Icons.trip_origin, Colors.green),
                  ),
                  Marker(
                    point: _driverPos,
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
                  Marker(
                    point: _dropPos,
                    width: 36,
                    height: 36,
                    child: _buildPin(Icons.location_on, Colors.red),
                  ),
                ],
              ),
            ],
          ),

          // ── Trip Details Overlay Card ─────────────────────────────────
          Align(
            alignment: Alignment.bottomCenter,
            child: FadeInUp(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, -5)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primaryOrange.withOpacity(0.1),
                          ),
                          child: const Icon(Icons.person, size: 36, color: AppColors.primaryOrange),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.star, color: Colors.amber, size: 16),
                                  const SizedBox(width: 4),
                                  const Text('5.0', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  const SizedBox(width: 10),
                                  Text(
                                    price,
                                    style: const TextStyle(color: AppColors.primaryOrange, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.phone, color: Colors.green, size: 24),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Calling passenger at $phone...')),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 28),
                    _buildInfoRow(Icons.trip_origin, 'Pickup', from, Colors.green),
                    const SizedBox(height: 10),
                    _buildInfoRow(Icons.location_on, 'Drop-off', to, Colors.red),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 54,
                            child: ElevatedButton(
                              onPressed: _step == RideProgressStep.completed ? null : _handleStepAction,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _step == RideProgressStep.inProgress ? Colors.green : AppColors.primaryOrange,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                elevation: 3,
                              ),
                              child: Text(
                                _stepButtonLabel,
                                style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.navigation, color: Colors.white, size: 26),
                            onPressed: () {
                              _mapController.move(_driverPos, 15.0);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Centered on navigation route'), duration: Duration(seconds: 1)),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPin(IconData icon, Color color) {
    return Container(
      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)]),
      child: Icon(icon, color: color, size: 22),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
            Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }

  void _showCompletionDialog(BuildContext context, double amount) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Center(child: Text('Trip Completed! 🎉', style: TextStyle(fontWeight: FontWeight.bold))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 70),
            const SizedBox(height: 16),
            const Text('You have successfully finished the trip.', textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text('${amount.toStringAsFixed(0)} IQD', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.primaryOrange)),
            const SizedBox(height: 4),
            const Text('Credited to your driver wallet', style: TextStyle(color: Colors.black45, fontSize: 12)),
          ],
        ),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                  minimumSize: const Size(180, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Back to Home', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

