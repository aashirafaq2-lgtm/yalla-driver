import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:animate_do/animate_do.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_bottom_nav.dart';

enum RideStep { arrived, confirmPickup, inProgress }

class RideActiveScreen extends StatefulWidget {
  const RideActiveScreen({super.key});

  @override
  State<RideActiveScreen> createState() => _RideActiveScreenState();
}

class _RideActiveScreenState extends State<RideActiveScreen> {
  RideStep _step = RideStep.arrived;

  void _onNavTap(int i) {
    if (i == 0) Navigator.pushReplacementNamed(context, '/home');
    if (i == 1) Navigator.pushReplacementNamed(context, '/trips');
    if (i == 2) Navigator.pushReplacementNamed(context, '/profile');
  }

  Widget _buildBottomSheet() {
    switch (_step) {
      case RideStep.arrived:
        return FadeInUp(
          duration: const Duration(milliseconds: 400),
          child: Container(
            color: AppColors.primaryOrange,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Arrived button
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TextButton(
                    onPressed: () => setState(() => _step = RideStep.confirmPickup),
                    child: const Text('Arrived', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black)),
                  ),
                ),
                const SizedBox(height: 12),
                // Cancel button
                Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.red[600],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TextButton(
                    onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
                    child: const Text('Call support to cancel the ride', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      case RideStep.confirmPickup:
        return FadeInUp(
          duration: const Duration(milliseconds: 400),
          child: Container(
            color: AppColors.primaryOrange,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: TextButton(
                    onPressed: () => setState(() => _step = RideStep.inProgress),
                    child: const Text('Confirm pickup', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black)),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      case RideStep.inProgress:
        return FadeInUp(
          duration: const Duration(milliseconds: 400),
          child: Container(
            color: AppColors.primaryOrange,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: TextButton(
                    onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
                    child: const Text('Arrived', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black)),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            options: const MapOptions(
              initialCenter: LatLng(35.4681, 44.3922),
              initialZoom: 14,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.yalla.driver',
              ),
              MarkerLayer(markers: [
                Marker(
                  point: const LatLng(35.4681, 44.3922),
                  child: const Icon(Icons.location_pin, color: Colors.red, size: 40),
                ),
                Marker(
                  point: const LatLng(35.475, 44.400),
                  child: const Icon(Icons.flag, color: Colors.green, size: 36),
                ),
              ]),
            ],
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                    ),
                    child: const Icon(Icons.person, size: 24),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.circle, color: Colors.white, size: 10),
                        SizedBox(width: 8),
                        Text('Online', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Trip info card
          Positioned(
            top: 100,
            left: 16,
            right: 16,
            child: FadeInDown(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 15)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.location_on, color: Colors.blue, size: 18),
                      const SizedBox(width: 8),
                      const Text('Kirkuk, ...', style: TextStyle(fontWeight: FontWeight.w700)),
                    ]),
                    const SizedBox(height: 8),
                    Row(children: [
                      const Icon(Icons.flag, color: Colors.orange, size: 18),
                      const SizedBox(width: 8),
                      const Text('Erbil, ...', style: TextStyle(fontWeight: FontWeight.w700)),
                    ]),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildBottomSheet(),
                AppBottomNav(currentIndex: 0, onTap: _onNavTap),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
