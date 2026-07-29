import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_service.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/socket_service.dart';
import '../../../core/services/storage_service.dart';
import 'active_ride_screen.dart';
import '../../home/presentation/driver_earnings_screen.dart';
import 'driver_profile_screen.dart';

class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initSocket();
    });
  }

  void _initSocket() {
    final socketService = Provider.of<SocketService>(context, listen: false);
    socketService.connect();
    socketService.onNewRideRequest = (data) {
      if (mounted) _showRideRequestSheet(data);
    };
  }

  void _showRideRequestSheet(dynamic data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ShakeX(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 24),
              const Text('NEW RIDE REQUEST', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2, color: Colors.black45)),
              const SizedBox(height: 16),
              Row(
                children: [
                  const CircleAvatar(radius: 25, backgroundColor: Color(0xFFF5F5F5), child: Icon(Icons.person, color: Colors.black45)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data['passengerName'] ?? 'John Doe', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(data['passengerPhone'] ?? '07xx xxx xxxx', style: const TextStyle(color: Colors.black45)),
                      ],
                    ),
                  ),
                  Text('${data['estimatedPrice']} IQD', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.primaryOrange)),
                ],
              ),
              const SizedBox(height: 24),
              _buildRouteInfo(Icons.trip_origin, 'Pickup', data['pickupName'] ?? 'Current Location', Colors.green),
              Padding(padding: const EdgeInsets.only(left: 11), child: Container(width: 2, height: 20, color: Colors.black12)),
              _buildRouteInfo(Icons.location_on, 'Drop-off', data['dropName'] ?? 'Destination', Colors.red),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Decline', style: TextStyle(color: Colors.black45, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () => _acceptRide(data),
                      child: const Text('Accept Ride', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRouteInfo(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.black45)),
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _acceptRide(dynamic data) async {
    final api     = Provider.of<ApiService>(context, listen: false);
    final storage = Provider.of<StorageService>(context, listen: false);
    final socket  = Provider.of<SocketService>(context, listen: false);
    final token   = await storage.getToken();

    try {
      final response = await api.acceptRide(data['id'], token!);
      if (response.statusCode == 200) {
        final acceptedRide = response.data['ride'];
        socket.socket.emit('accept_ride', {
          'rideId': acceptedRide['id'],
          'passengerId': acceptedRide['passengerId'],
          'driverName': 'Ahmed Hassan', // Should fetch from profile
          'carModel': 'White Toyota Camry',
          'plate': 'ABC-123'
        });
        Navigator.pop(context); // close sheet
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => ActiveRideScreen(rideData: acceptedRide),
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          // Background simulation
          Center(
            child: Opacity(
              opacity: 0.3,
              child: Icon(Icons.map_outlined, size: 300, color: Colors.white.withOpacity(0.1)),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('GOVERNORATE', style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1.5)),
                          const Text('Baghdad, Central', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      const Spacer(),
                      _buildActionBtn(Icons.attach_money, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverEarningsScreen()))),
                      const SizedBox(width: 12),
                      _buildActionBtn(Icons.person_outline, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverProfileScreen()))),
                    ],
                  ),
                ),
                
                const Spacer(),
                
                FadeInUp(
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildStatusToggle(auth),
                        const SizedBox(height: 32),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text('DASHBOARD', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2, color: Colors.black38)),
                        ),
                        const SizedBox(height: 16),
                        _buildMenuOption('Earnings Today', 'IQD 75,000', Icons.account_balance_wallet_outlined),
                        _buildMenuOption('Completed Trips', '12 Trips', Icons.directions_car_outlined),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }

  Widget _buildStatusToggle(AuthProvider auth) {
    bool isOnline = auth.isOnline;
    return GestureDetector(
      onTap: () => auth.toggleStatus(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 80,
        width: double.infinity,
        decoration: BoxDecoration(
          color: isOnline ? Colors.green : Colors.black,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: (isOnline ? Colors.green : Colors.black).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
        ),
        child: Center(
          child: auth.isLoading 
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(isOnline ? 'ONLINE' : 'GO ONLINE', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
        ),
      ),
    );
  }

  Widget _buildMenuOption(String title, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryOrange),
          const SizedBox(width: 16),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primaryOrange)),
        ],
      ),
    );
  }
}
