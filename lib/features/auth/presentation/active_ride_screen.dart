import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_service.dart';
import '../../../core/services/socket_service.dart';
import '../../../core/services/storage_service.dart';

class ActiveRideScreen extends StatefulWidget {
  final dynamic rideData;
  const ActiveRideScreen({super.key, required this.rideData});

  @override
  State<ActiveRideScreen> createState() => _ActiveRideScreenState();
}

class _ActiveRideScreenState extends State<ActiveRideScreen> {
  LatLng _currentLocation = const LatLng(33.3152, 44.3661); // Dummy driver loc
  String _status = 'ACCEPTED';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _status = widget.rideData['status'] ?? 'ACCEPTED';
    _startLocationUpdates();
  }

  void _startLocationUpdates() {
    // In real app, use geolocator. Here we simulate.
    Future.doWhile(() async {
      if (!mounted) return false;
      await Future.delayed(const Duration(seconds: 5));
      final socket = Provider.of<SocketService>(context, listen: false);
      socket.updateLocation(_currentLocation.latitude, _currentLocation.longitude, activeRideId: widget.rideData['id']);
      // Also notify passenger side status
      socket.socket?.emit('driver_moved', {
        'rideId': widget.rideData['id'],
        'lat': _currentLocation.latitude,
        'lng': _currentLocation.longitude,
        'status': _status == 'ACCEPTED' ? 'Driver is on the way' : 'Ride in progress'
      });
      return true;
    });
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isLoading = true);
    final api     = Provider.of<ApiService>(context, listen: false);
    final storage = Provider.of<StorageService>(context, listen: false);
    final socket  = Provider.of<SocketService>(context, listen: false);
    final token   = await storage.getToken();

    try {
      final response = await api.updateRideStatus(widget.rideData['id'], newStatus, token!);
      if (response.statusCode == 200) {
        setState(() => _status = newStatus);
        
        // Notify passenger via socket
        socket.socket?.emit('driver_moved', {
          'rideId': widget.rideData['id'],
          'lat': _currentLocation.latitude,
          'lng': _currentLocation.longitude,
          'status': newStatus == 'ONGOING' ? 'Ride Started' : 'Ride Completed'
        });


        if (newStatus == 'COMPLETED') {
          if (mounted) Navigator.pop(context);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final passengerName = widget.rideData['passenger'] != null 
        ? '${widget.rideData['passenger']['firstName']} ${widget.rideData['passenger']['lastName']}'
        : 'Passenger';

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: _currentLocation,
              initialZoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.yalla.driver',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _currentLocation,
                    width: 40, height: 40,
                    child: const Icon(Icons.directions_car, color: AppColors.primaryOrange, size: 30),
                  ),
                  Marker(
                    point: const LatLng(33.3152, 44.3661), // Simplified passenger loc
                    width: 40, height: 40,
                    child: const Icon(Icons.person_pin_circle, color: Colors.green, size: 35),
                  ),
                ],
              ),
            ],
          ),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(20)),
                    child: Text(_status == 'ACCEPTED' ? 'Go to Pickup' : 'Driving to Destination', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
          
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(radius: 25, child: Icon(Icons.person)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(passengerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            const Text('Pickup: Al-Mansour, Baghdad', style: TextStyle(color: Colors.black45, fontSize: 12)),
                          ],
                        ),
                      ),
                      IconButton(onPressed: () {}, icon: const Icon(Icons.call, color: Colors.green)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _status == 'ACCEPTED' ? Colors.blue : Colors.green,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: _isLoading ? null : () {
                        if (_status == 'ACCEPTED') {
                          _updateStatus('ONGOING');
                        } else {
                          _updateStatus('COMPLETED');
                        }
                      },
                      child: _isLoading 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(_status == 'ACCEPTED' ? 'START RIDE' : 'COMPLETE RIDE', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
