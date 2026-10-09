import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/iq_header.dart';
import '../../../../core/providers/active_ride_provider.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/driver_locale_provider.dart';
import '../../rides/presentation/available_trips_screen.dart';
import '../../rides/presentation/scheduled_trips_screen.dart';
import '../../rides/presentation/trip_ongoing_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import 'driver_map_screen.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../core/network/api_service.dart';
import '../../../../core/services/storage_service.dart';

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
  void initState() {
    super.initState();
    _checkActiveRide();
  }

  Future<void> _checkActiveRide() async {
    try {
      await Provider.of<AuthProvider>(context, listen: false).loadProfile();
      final storage = Provider.of<StorageService>(context, listen: false);
      final api = Provider.of<ApiService>(context, listen: false);
      final activeRideProv = Provider.of<ActiveRideProvider>(context, listen: false);

      final token = await storage.getToken();
      if (token == null) return;

      final res = await api.getActiveRide(token);
      if (res.statusCode == 200 && res.data != null && res.data['activeRide'] != null) {
        final r = res.data['activeRide'];
        final p = r['passenger'] ?? {};
        activeRideProv.setActiveRide({
          'id': r['id'],
          'rideId': r['id'],
          'name': '${p['firstName'] ?? ''} ${p['lastName'] ?? ''}'.trim().isNotEmpty
              ? '${p['firstName'] ?? ''} ${p['lastName'] ?? ''}'.trim()
              : 'Passenger',
          'phone': p['phone'] ?? '',
          'rating': p['rating']?.toString() ?? '5.0',
          'from': r['pickupName'] ?? 'Pickup Location',
          'to': r['dropName'] ?? 'Destination',
          'price': '${r['estimatedPrice'] ?? r['finalPrice'] ?? 10000} IQD',
          'status': r['status'] ?? 'ACCEPTED',
          'pickupLat': r['pickupLat'],
          'pickupLng': r['pickupLng'],
          'dropLat': r['dropLat'],
          'dropLng': r['dropLng'],
          'otp': r['otp'] ?? '',
          'isTripMode': false,
        });
      }
    } catch (e) {
      debugPrint('[Home] Note checking active ride: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = Provider.of<DriverLocaleProvider>(context);
    final isArabic = locale.isArabic;

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
            _buildNavItem(0, Icons.home_filled, locale.tr('home'), isArabic),
            _buildNavItem(1, Icons.directions_car_rounded, locale.tr('rides'), isArabic),
            _buildNavItem(2, Icons.person, locale.tr('profile'), isArabic),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, bool isArabic) {
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
                  fontFamily: isArabic ? 'NotoKufiArabic' : null,
                  color: isSelected ? Colors.white : Colors.black87,
                  fontSize: isArabic ? 13 : 15,
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
    final locale = Provider.of<DriverLocaleProvider>(context);
    final isArabic = locale.isArabic;

    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 15),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 48), // Balance for language button
                ElasticIn(
                  duration: const Duration(milliseconds: 1000),
                  child: Row(
                    children: [
                      Text(
                        isArabic ? 'يَلَّا ' : 'Yalla ',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: isArabic ? AppColors.primaryOrange : Colors.black,
                          fontFamily: isArabic ? 'NotoKufiArabic' : null,
                        ),
                        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                      ),
                      Text(
                        isArabic ? 'YALLA' : 'يَلَّا',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: isArabic ? Colors.black : AppColors.primaryOrange,
                        ),
                      ),
                    ],
                  ),
                ),
                // Language Dropdown Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.black12),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: isArabic ? 'ar' : 'en',
                      isDense: true,
                      icon: const Icon(Icons.language, size: 16, color: AppColors.primaryOrange),
                      borderRadius: BorderRadius.circular(12),
                      items: [
                        DropdownMenuItem(
                          value: 'ar',
                          child: Text('العربية', style: GoogleFonts.notoKufiArabic(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                        DropdownMenuItem(
                          value: 'en',
                          child: Text('English', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                      onChanged: (lang) {
                        if (lang != null) locale.setLocale(Locale(lang));
                      },
                    ),
                  ),
                ),
              ],
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
                      Text(
                        locale.tr('you_are_online'),
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: isArabic ? 14 : 13,
                          color: Colors.black87,
                          letterSpacing: isArabic ? 0 : 0.5,
                          fontFamily: isArabic ? 'NotoKufiArabic' : null,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryOrange.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      locale.tr('ready_for_rides'),
                      style: TextStyle(
                        color: AppColors.primaryOrange,
                        fontWeight: FontWeight.bold,
                        fontSize: isArabic ? 12 : 12,
                        fontFamily: isArabic ? 'NotoKufiArabic' : null,
                      ),
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
                // Active Ride Banner
                Consumer<ActiveRideProvider>(
                  builder: (context, rideProv, child) {
                    final ride = rideProv.activeRide;
                    if (ride == null) return const SizedBox.shrink();

                    final passengerName = ride['name'] ?? (isArabic ? 'الراكب' : 'Passenger');
                    final from = ride['from'] ?? (isArabic ? 'نقطة الانطلاق' : 'Pickup');
                    final to = ride['to'] ?? (isArabic ? 'الوجهة' : 'Destination');
                    final price = ride['price'] ?? '10,000 IQD';
                    final status = ride['status'] ?? 'ACCEPTED';

                    String statusText = locale.tr('driving_to_passenger');
                    if (status == 'ARRIVED') statusText = locale.tr('arrived_at_pickup');
                    if (status == 'IN_PROGRESS' || status == 'PICKED_UP') statusText = locale.tr('trip_in_progress');

                    return FadeInDown(
                      duration: const Duration(milliseconds: 400),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryOrange.withOpacity(0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                          border: Border.all(color: AppColors.primaryOrange, width: 1.5),
                        ),
                        child: Column(
                          crossAxisAlignment: isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: const BoxDecoration(
                                        color: AppColors.primaryOrange,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(color: AppColors.primaryOrange, blurRadius: 6, spreadRadius: 2),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      locale.tr('active_ride'),
                                      style: GoogleFonts.outfit(
                                        color: AppColors.primaryOrange,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 13,
                                        letterSpacing: isArabic ? 0 : 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    statusText,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: isArabic ? 'NotoKufiArabic' : null,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: AppColors.primaryOrange.withOpacity(0.2),
                                  child: const Icon(Icons.person, color: AppColors.primaryOrange, size: 24),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        passengerName,
                                        style: GoogleFonts.outfit(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '$from → $to',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                          fontFamily: isArabic ? 'NotoKufiArabic' : null,
                                        ),
                                        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  price,
                                  style: GoogleFonts.outfit(
                                    color: AppColors.primaryOrange,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              height: 44,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryOrange,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 0,
                                ),
                                icon: const Icon(Icons.navigation_rounded, color: Colors.white, size: 20),
                                label: Text(
                                  locale.tr('return_to_ride'),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    fontFamily: isArabic ? 'NotoKufiArabic' : null,
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => TripOngoingScreen(tripData: ride),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                _buildMenuCard(
                  context,
                  title: locale.tr('available_trips'),
                  image: 'assets/images/available_trip.png',
                  route: '/available_trips',
                  delay: 0,
                  isArabic: isArabic,
                ),
                _buildMenuCard(
                  context,
                  title: locale.tr('schedule_trip'),
                  image: 'assets/images/schedule_trip.png',
                  route: '/schedule',
                  delay: 100,
                  isArabic: isArabic,
                ),
                _buildMenuCard(
                  context,
                  title: locale.tr('mail_parcel'),
                  image: 'assets/images/mail_parcel.png',
                  route: '/mail_parcels',
                  delay: 200,
                  isArabic: isArabic,
                ),
                _buildMenuCard(
                  context,
                  title: locale.tr('booking'),
                  subtitle: locale.tr('outside_governorate'),
                  image: 'assets/images/booking.png',
                  route: '/available_trips_outside',
                  isBooking: true,
                  delay: 300,
                  isArabic: isArabic,
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
    bool isArabic = false,
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
                    left: isArabic ? null : 0,
                    right: isArabic ? 0 : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryOrange,
                        borderRadius: BorderRadius.only(
                          bottomRight: isArabic ? Radius.zero : const Radius.circular(20),
                          bottomLeft: isArabic ? const Radius.circular(20) : Radius.zero,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              fontFamily: isArabic ? 'NotoKufiArabic' : null,
                            ),
                            textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                          ),
                          Row(
                            children: [
                              const Icon(Icons.public, size: 14, color: Colors.white),
                              const SizedBox(width: 4),
                              Text(
                                subtitle!,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  fontFamily: isArabic ? 'NotoKufiArabic' : null,
                                ),
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
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        fontFamily: isArabic ? 'NotoKufiArabic' : null,
                        shadows: const [
                          Shadow(color: Colors.black87, blurRadius: 15, offset: Offset(0, 2)),
                        ],
                      ),
                      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
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
