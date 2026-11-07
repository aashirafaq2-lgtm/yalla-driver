import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';

import '../../../../core/providers/active_ride_provider.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/driver_locale_provider.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/services/storage_service.dart';

import '../../rides/presentation/available_trips_screen.dart';
import '../../rides/presentation/scheduled_trips_screen.dart';
import '../../rides/presentation/schedule_trips_hub_screen.dart';
import '../../rides/presentation/mail_parcels_screen.dart';
import '../../rides/presentation/trip_ongoing_screen.dart';
import '../../profile/presentation/profile_screen.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const DriverHomeDashboardContent(),
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
      } else {
        activeRideProv.clearActiveRide();
      }
    } catch (e) {
      debugPrint('[DriverHome] Active ride check error: $e');
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
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 15,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  index: 0,
                  icon: Icons.home_rounded,
                  label: isArabic ? 'الرئيسية' : 'Home',
                  isSelected: _selectedIndex == 0,
                  isArabic: isArabic,
                ),
                _buildNavItem(
                  index: 1,
                  icon: Icons.person_outline_rounded,
                  label: isArabic ? 'حسابي' : 'Profile',
                  isSelected: _selectedIndex == 1,
                  isArabic: isArabic,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    required bool isSelected,
    required bool isArabic,
  }) {
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF3EB) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 26,
              color: isSelected ? const Color(0xFFFF7A00) : const Color(0xFF1E293B),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontFamily: isArabic ? 'NotoKufiArabic' : null,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? const Color(0xFFFF7A00) : const Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DriverHomeDashboardContent extends StatelessWidget {
  const DriverHomeDashboardContent({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = Provider.of<DriverLocaleProvider>(context);
    final isArabic = locale.isArabic;
    final auth = Provider.of<AuthProvider>(context);

    return SafeArea(
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        children: [
          // ── Top Header Row: Logo & Language Toggle ────────────────────────
          FadeInDown(
            duration: const Duration(milliseconds: 400),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(width: 80), // Balance center logo
                // Yalla Logo
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Yalla',
                      style: GoogleFonts.outfit(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'يَلَّا',
                      style: GoogleFonts.notoKufiArabic(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFFFF7A00),
                      ),
                    ),
                  ],
                ),
                // Language Pill
                GestureDetector(
                  onTap: () {
                    locale.toggleLocale();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isArabic ? 'العربية' : 'English',
                          style: TextStyle(
                            fontFamily: isArabic ? 'NotoKufiArabic' : null,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Icon(
                          Icons.language_rounded,
                          size: 16,
                          color: Color(0xFFFF7A00),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Driver Status Toggle Bar ──────────────────────────────────────
          FadeInDown(
            delay: const Duration(milliseconds: 100),
            duration: const Duration(milliseconds: 450),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFFBBF7D0), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF22C55E).withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Green Car Icon in rounded container
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF86EFAC)),
                    ),
                    child: const Icon(
                      Icons.directions_car_filled_rounded,
                      color: Color(0xFF22C55E),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Texts
                  Expanded(
                    child: Column(
                      crossAxisAlignment: isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        Text(
                          isArabic ? 'حالة السائق' : 'Driver Status',
                          style: TextStyle(
                            fontFamily: isArabic ? 'NotoKufiArabic' : null,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          isArabic ? 'فعّل لاستقبال طلبات الرحلات' : 'Turn on to receive trip requests',
                          style: TextStyle(
                            fontFamily: isArabic ? 'NotoKufiArabic' : null,
                            fontSize: 10.5,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Online/Offline label & Switch
                  Text(
                    auth.isOnline
                        ? (isArabic ? 'متصل' : 'Online')
                        : (isArabic ? 'غير متصل' : 'Offline'),
                    style: TextStyle(
                      fontFamily: isArabic ? 'NotoKufiArabic' : null,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: auth.isOnline ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CupertinoSwitch(
                    value: auth.isOnline,
                    activeColor: const Color(0xFF22C55E),
                    onChanged: (val) {
                      auth.toggleStatus();
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Active Ride Card (if any ongoing trip) ────────────────────────
          Consumer<ActiveRideProvider>(
            builder: (context, rideProv, _) {
              final ride = rideProv.activeRide;
              if (ride == null) return const SizedBox.shrink();

              final passengerName = ride['name'] ?? (isArabic ? 'الراكب' : 'Passenger');
              final from = ride['from'] ?? (isArabic ? 'نقطة الانطلاق' : 'Pickup');
              final to = ride['to'] ?? (isArabic ? 'الوجهة' : 'Destination');
              final price = ride['price'] ?? '10,000 IQD';

              return FadeInDown(
                duration: const Duration(milliseconds: 400),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFFF7A00), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF7A00).withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF7A00).withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.navigation_rounded, color: Color(0xFFFF7A00), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            Text(
                              passengerName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              '$from → $to • $price',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white70, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF7A00),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => TripOngoingScreen(tripData: ride)),
                          );
                        },
                        child: Text(
                          isArabic ? 'عرض' : 'View',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // ── Hero Banner: Car & Road Illustration ───────────────────────────
          FadeIn(
            delay: const Duration(milliseconds: 150),
            duration: const Duration(milliseconds: 500),
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/images/driver_hero_banner.png',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: const Color(0xFFFFF7ED),
                    child: const Center(
                      child: Icon(Icons.directions_car_rounded, size: 40, color: Color(0xFFFF7A00)),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── 2x2 Services Grid (Matching Screenshot 100%) ──────────────────
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 0.88,
            children: [
              // 1. Available Trips (Top-Left)
              FadeInUp(
                delay: const Duration(milliseconds: 180),
                duration: const Duration(milliseconds: 450),
                child: _DriverServiceGridCard(
                  title: isArabic ? 'الرحلات المتاحة' : 'Available Trips',
                  subtitle: isArabic ? 'ابحث وانضم للرحلات المتاحة الآن' : 'Find and join available trips now',
                  imagePath: 'assets/images/ic_available_trips.png',
                  bgColor: const Color(0xFFFFF8F1), // Warm Peach Tint
                  borderColor: const Color(0xFFFFEDD5),
                  isArabic: isArabic,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AvailableTripsScreen()),
                    );
                  },
                ),
              ),

              // 2. Schedule Trips (Top-Right)
              FadeInUp(
                delay: const Duration(milliseconds: 240),
                duration: const Duration(milliseconds: 450),
                child: _DriverServiceGridCard(
                  title: isArabic ? 'جدولة رحلة' : 'Schedule Trips',
                  subtitle: isArabic ? 'احجز رحلة لموعد لاحق' : 'Book a trip for a later date',
                  imagePath: 'assets/images/ic_schedule_trips.png',
                  bgColor: const Color(0xFFF9F7FF), // Soft Lilac Tint
                  borderColor: const Color(0xFFEDE9FE),
                  isArabic: isArabic,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ScheduleTripsHubScreen()),
                    );
                  },
                ),
              ),

              // 3. Mail or Parcel (Bottom-Left)
              FadeInUp(
                delay: const Duration(milliseconds: 300),
                duration: const Duration(milliseconds: 450),
                child: _DriverServiceGridCard(
                  title: isArabic ? 'البريد والطرود' : 'Mail or Parcel',
                  subtitle: isArabic ? 'أرسل واستلم الطرود بين المحافظات' : 'Send packages between provinces',
                  imagePath: 'assets/images/ic_mail_parcel.png',
                  bgColor: const Color(0xFFF3F8FF), // Soft Sky Tint
                  borderColor: const Color(0xFFDBEAFE),
                  isArabic: isArabic,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MailParcelsScreen()),
                    );
                  },
                ),
              ),

              // 4. Book Entire Car (Bottom-Right)
              FadeInUp(
                delay: const Duration(milliseconds: 360),
                duration: const Duration(milliseconds: 450),
                child: _DriverServiceGridCard(
                  title: isArabic ? 'حجز سيارة كاملة' : 'Book Entire Car',
                  subtitle: isArabic ? 'احجز سيارة بالكامل لرحلتك' : 'Reserve a whole car for your trip',
                  imagePath: 'assets/images/ic_book_entire_car.png',
                  bgColor: const Color(0xFFF4FDF6), // Soft Mint Tint
                  borderColor: const Color(0xFFDCFCE7),
                  isArabic: isArabic,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AvailableTripsScreen(isOutsideIraq: true)),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

class _DriverServiceGridCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final String imagePath;
  final Color bgColor;
  final Color borderColor;
  final bool isArabic;
  final VoidCallback onTap;

  const _DriverServiceGridCard({
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.bgColor,
    required this.borderColor,
    required this.isArabic,
    required this.onTap,
  });

  @override
  State<_DriverServiceGridCard> createState() => _DriverServiceGridCardState();
}

class _DriverServiceGridCardState extends State<_DriverServiceGridCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 140),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
          decoration: BoxDecoration(
            color: widget.bgColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: widget.borderColor, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Top 3D / Graphic Illustration
              SizedBox(
                height: 48,
                child: Image.asset(
                  widget.imagePath,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.directions_car_rounded,
                    size: 38,
                    color: Color(0xFFFF7A00),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Title
              Text(
                widget.title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: widget.isArabic ? 'NotoKufiArabic' : null,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 3),

              // Subtitle
              Expanded(
                child: Text(
                  widget.subtitle,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: widget.isArabic ? 'NotoKufiArabic' : null,
                    fontSize: 10.5,
                    height: 1.25,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ),

              // Bottom Orange Arrow Button Circle
              Align(
                alignment: widget.isArabic ? Alignment.bottomLeft : Alignment.bottomRight,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF7A00),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x55FF7A00),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    widget.isArabic ? Icons.arrow_back_rounded : Icons.arrow_forward_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
