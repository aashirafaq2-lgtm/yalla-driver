import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:animate_do/animate_do.dart';
import '../../../../core/theme/app_colors.dart';

// Kirkuk, Iraq coordinates (matches the screenshot map)
const _kMapCenter = LatLng(35.4681, 44.3922);

class DriverMapScreen extends StatefulWidget {
  const DriverMapScreen({super.key});

  @override
  State<DriverMapScreen> createState() => _DriverMapScreenState();
}

enum _RideStatus { none, arrived, confirmPickup }

class _DriverMapScreenState extends State<DriverMapScreen>
    with TickerProviderStateMixin {
  bool _isOnline = true;
  _RideStatus _rideStatus = _RideStatus.none;
  final MapController _mapController = MapController();

  late final AnimationController _panelController;
  late final Animation<Offset> _panelSlide;

  @override
  void initState() {
    super.initState();
    _panelController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _panelSlide = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _panelController, curve: Curves.easeOutCubic));

    // Simulate incoming ride after 3 seconds (for demo on Rides tab)
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _isOnline && _rideStatus == _RideStatus.none) {
        _showRideStatus(_RideStatus.arrived);
      }
    });
  }

  void _showRideStatus(_RideStatus status) {
    setState(() => _rideStatus = status);
    if (status != _RideStatus.none) {
      _panelController.forward(from: 0);
    } else {
      _panelController.reverse();
    }
  }

  @override
  void dispose() {
    _panelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ── FULL SCREEN MAP (OpenStreetMap – FREE, no API key) ──────────
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: _kMapCenter,
              initialZoom: 14.5,
              interactionOptions: InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.yalla.driver',
                maxZoom: 18,
              ),
              // Driver position marker
              MarkerLayer(
                markers: [
                  Marker(
                    point: _kMapCenter,
                    width: 50,
                    height: 50,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primaryOrange,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [BoxShadow(color: Colors.black38, blurRadius: 8, offset: const Offset(0, 3))],
                      ),
                      child: const Icon(Icons.directions_car, color: Colors.white, size: 24),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // ── TOP BAR: Profile icon + Online/Offline toggle ───────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Profile icon
                  _buildCircleIcon(
                    icon: Icons.person,
                    onTap: () => Navigator.pushNamed(context, '/profile'),
                  ),

                  // Online / Offline Pill Toggle
                  GestureDetector(
                    onTap: () {
                      setState(() => _isOnline = !_isOnline);
                      if (!_isOnline) {
                        _showRideStatus(_RideStatus.none);
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeInOut,
                      width: 120,
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      decoration: BoxDecoration(
                        color: _isOnline ? const Color(0xFF4CAF50) : const Color(0xFFE53935),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6, offset: const Offset(0, 3))],
                      ),
                      child: Row(
                        mainAxisAlignment: _isOnline
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        children: [
                          if (!_isOnline)
                            const Expanded(
                              child: Center(
                                child: Text('Offline',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13)),
                              ),
                            ),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Container(
                              key: ValueKey(_isOnline),
                              width: 26,
                              height: 26,
                              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                            ),
                          ),
                          if (_isOnline)
                            const Expanded(
                              child: Center(
                                child: Text('Online',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13)),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Right side balancer (notifications / empty)
                  const SizedBox(width: 46),
                ],
              ),
            ),
          ),

          // ── BOTTOM ACTION PANEL ─────────────────────────────────────────
          if (_rideStatus != _RideStatus.none)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SlideTransition(
                position: _panelSlide,
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.primaryOrange,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Drag handle
                      Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),

                      if (_rideStatus == _RideStatus.arrived) ...[
                        _buildPanelButton(
                          label: 'Arrived',
                          bgColor: Colors.white,
                          textColor: Colors.black,
                          onTap: () => _showRideStatus(_RideStatus.confirmPickup),
                        ),
                        const SizedBox(height: 12),
                        _buildPanelButton(
                          label: 'Call support to cancel the ride',
                          bgColor: const Color(0xFFE53935),
                          textColor: Colors.white,
                          onTap: () => _showRideStatus(_RideStatus.none),
                        ),
                      ] else if (_rideStatus == _RideStatus.confirmPickup) ...[
                        _buildPanelButton(
                          label: 'Confirm pickup',
                          bgColor: Colors.white,
                          textColor: Colors.black,
                          onTap: () {
                            _showRideStatus(_RideStatus.none);
                            Navigator.pushNamed(context, '/ride_active');
                          },
                        ),
                      ],

                      const SizedBox(height: 10),
                    ],
                  ),
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

  Widget _buildPanelButton({
    required String label,
    required Color bgColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}
