import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/iq_header.dart';
import '../../rides/presentation/available_trips_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import 'driver_map_screen.dart';
import 'package:animate_do/animate_do.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomeDashboardContent(),
    const DriverMapScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        height: 100,
        decoration: BoxDecoration(
          color: AppColors.primaryOrange.withOpacity(0.9),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(35)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, -5)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(0, Icons.home_filled, 'Home'),
            _buildNavItem(1, Icons.directions_car_rounded, 'Rides'),
            _buildNavItem(2, Icons.person, 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      behavior: HitTestBehavior.opaque,
      child: BounceInUp(
        duration: const Duration(milliseconds: 800),
        delay: Duration(milliseconds: index * 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 100,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 34,
                color: isSelected ? Colors.white : Colors.black87,
              ),
              const SizedBox(height: 5),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeDashboardContent extends StatelessWidget {
  const HomeDashboardContent({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 15),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ElasticIn(
              duration: const Duration(milliseconds: 1000),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Yalla',
                    style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  const SizedBox(width: 15),
                  Text(
                    'يَلَّا',
                    style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppColors.primaryOrange),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 15),
          // Online Status Badge Bar
          FadeInDown(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Color(0xFF22C55E),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Color(0x8822C55E), blurRadius: 8, spreadRadius: 2),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'YOU ARE ONLINE',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.black87, letterSpacing: 0.5),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryOrange.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Ready for rides',
                      style: TextStyle(color: AppColors.primaryOrange, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 15),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              children: [
                _buildMenuCard(
                  context,
                  title: 'Available Trips',
                  image: 'assets/images/available_trip.png',
                  route: '/available_trips',
                  delay: 0,
                ),
                _buildMenuCard(
                  context,
                  title: 'Schedule trip',
                  image: 'assets/images/schedule_trip.png',
                  route: '/schedule',
                  delay: 100,
                ),
                _buildMenuCard(
                  context,
                  title: 'mail or Parcels',
                  image: 'assets/images/mail_parcel.png',
                  route: '/mail_parcels',
                  delay: 200,
                ),
                _buildMenuCard(
                  context,
                  title: 'Booking',
                  subtitle: 'outside Iraq',
                  image: 'assets/images/booking.png',
                  route: '/available_trips_outside',
                  isBooking: true,
                  delay: 300,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, {
    required String title,
    String? subtitle,
    required String image,
    required String route,
    bool isBooking = false,
    int delay = 0,
  }) {
    return FadeInUp(
      delay: Duration(milliseconds: delay),
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, route),
        child: Container(
          margin: const EdgeInsets.only(bottom: 20),
          height: 160,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  image, 
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
                  ),
                ),
                // Gradient overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.1),
                        Colors.black.withOpacity(0.4),
                      ],
                    ),
                  ),
                ),
                
                if (isBooking)
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: const BoxDecoration(
                        color: AppColors.primaryOrange,
                        borderRadius: BorderRadius.only(bottomRight: Radius.circular(20)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Booking',
                            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.public, size: 14, color: Colors.white),
                              const SizedBox(width: 4),
                              Text(
                                subtitle!,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                
                if (!isBooking)
                  Center(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(color: Colors.black87, blurRadius: 15, offset: Offset(0, 2)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
