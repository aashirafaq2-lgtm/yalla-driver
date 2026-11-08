import 'dart:async';
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
      backgroundColor: const Color(0xFFFAFAFC),
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
              blurRadius: 18,
              offset: const Offset(0, -4),
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

class DriverHomeDashboardContent extends StatefulWidget {
  const DriverHomeDashboardContent({super.key});

  @override
  State<DriverHomeDashboardContent> createState() => _DriverHomeDashboardContentState();
}

class _DriverHomeDashboardContentState extends State<DriverHomeDashboardContent> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    await auth.loadProfile();
  }

  @override
  Widget build(BuildContext context) {
    final locale = Provider.of<DriverLocaleProvider>(context);
    final isArabic = locale.isArabic;
    final auth = Provider.of<AuthProvider>(context);
    final String driverName = auth.driverName;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _refreshData,
        color: const Color(0xFFFF7A00),
        child: ListView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          children: [
            // ── Top Header Row: Profile Avatar, Welcome Greeting & Language Pill ──
            FadeInDown(
              duration: const Duration(milliseconds: 400),
              child: Row(
                children: [
                  // Driver Avatar with online indicator ring
                  Stack(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF7A00), Color(0xFFFF9E40)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF7A00).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            driverName.isNotEmpty ? driverName[0].toUpperCase() : 'D',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 13,
                          height: 13,
                          decoration: BoxDecoration(
                            color: auth.isOnline ? const Color(0xFF22C55E) : const Color(0xFF94A3B8),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  // Welcome Greeting & Name
                  Expanded(
                    child: Column(
                      crossAxisAlignment: isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        Text(
                          isArabic ? 'مرحباً بك،' : 'Welcome back,',
                          style: TextStyle(
                            fontFamily: isArabic ? 'NotoKufiArabic' : null,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        Text(
                          driverName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: isArabic ? 'NotoKufiArabic' : null,
                            fontSize: 16.5,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Yalla Arabic/English branding pill
                  GestureDetector(
                    onTap: () => locale.toggleLocale(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                              fontWeight: FontWeight.w800,
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

            // ── Driver Status Toggle Bar with Animated Pulsing Beacon ──
            FadeInDown(
              delay: const Duration(milliseconds: 100),
              duration: const Duration(milliseconds: 450),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: auth.isOnline
                        ? [const Color(0xFFF0FDF4), const Color(0xFFDCFCE7)]
                        : [const Color(0xFFF8FAFC), const Color(0xFFF1F5F9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                    color: auth.isOnline ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0),
                    width: 1.3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: auth.isOnline
                          ? const Color(0xFF22C55E).withOpacity(0.12)
                          : Colors.black.withOpacity(0.03),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Green Car Icon with Animated Pulsing Beacon when online
                    ScaleTransition(
                      scale: auth.isOnline ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: auth.isOnline ? const Color(0xFF86EFAC) : const Color(0xFFCBD5E1),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: auth.isOnline
                                  ? const Color(0xFF22C55E).withOpacity(0.2)
                                  : Colors.transparent,
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.directions_car_filled_rounded,
                          color: auth.isOnline ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Texts
                    Expanded(
                      child: Column(
                        crossAxisAlignment: isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                isArabic ? 'حالة السائق' : 'Driver Status',
                                style: TextStyle(
                                  fontFamily: isArabic ? 'NotoKufiArabic' : null,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              if (auth.isOnline) ...[
                                const SizedBox(width: 6),
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF22C55E),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            auth.isOnline
                                ? (isArabic ? 'جاهز لاستقبال الطلبات الآن' : 'Ready & receiving trip requests')
                                : (isArabic ? 'فعّل لاستقبال طلبات الرحلات' : 'Turn on to receive trip requests'),
                            style: TextStyle(
                              fontFamily: isArabic ? 'NotoKufiArabic' : null,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                              color: auth.isOnline ? const Color(0xFF15803D) : const Color(0xFF64748B),
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
                        fontWeight: FontWeight.w900,
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

            // ── Quick Performance & Stats Glass Strip (Uber-style) ──
            FadeInDown(
              delay: const Duration(milliseconds: 140),
              duration: const Duration(milliseconds: 450),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFF1F5F9), width: 1.3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Stat 1: Wallet Balance
                    Expanded(
                      child: _buildQuickStatItem(
                        icon: Icons.account_balance_wallet_rounded,
                        iconColor: const Color(0xFFFF7A00),
                        label: isArabic ? 'المحفظة' : 'Wallet',
                        value: '${auth.walletBalance.toInt()} IQD',
                        isArabic: isArabic,
                      ),
                    ),
                    Container(width: 1, height: 32, color: const Color(0xFFE2E8F0)),
                    // Stat 2: Completed Trips
                    Expanded(
                      child: _buildQuickStatItem(
                        icon: Icons.route_rounded,
                        iconColor: const Color(0xFF7E22CE),
                        label: isArabic ? 'الرحلات' : 'Trips',
                        value: '${auth.totalTrips}',
                        isArabic: isArabic,
                      ),
                    ),
                    Container(width: 1, height: 32, color: const Color(0xFFE2E8F0)),
                    // Stat 3: Driver Rating
                    Expanded(
                      child: _buildQuickStatItem(
                        icon: Icons.star_rounded,
                        iconColor: const Color(0xFFF59E0B),
                        label: isArabic ? 'التقييم' : 'Rating',
                        value: auth.rating > 0 ? auth.rating.toStringAsFixed(1) : '5.0',
                        isArabic: isArabic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // ── Active Ride Card (if any ongoing trip) ──
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
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xFFFF7A00), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF7A00).withOpacity(0.25),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF7A00).withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.navigation_rounded, color: Color(0xFFFF7A00), size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    passengerName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 14.5,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF22C55E).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      isArabic ? 'نشط' : 'LIVE',
                                      style: const TextStyle(
                                        color: Color(0xFF4ADE80),
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$from → $to • $price',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white70, fontSize: 11.5),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF7A00),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => TripOngoingScreen(tripData: ride)),
                            );
                          },
                          child: Text(
                            isArabic ? 'متابعة' : 'Resume',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // ── Hero Banner: Full-HD Illustration with Specular Glass Border ──
            FadeIn(
              delay: const Duration(milliseconds: 160),
              duration: const Duration(milliseconds: 500),
              child: Container(
                height: 125,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Image.asset(
                    'assets/images/driver_hero_banner_hd.png',
                    fit: BoxFit.cover,
                    width: double.infinity,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (context, error, stackTrace) => Image.asset(
                      'assets/images/driver_hero_banner.png',
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFFFFF7ED),
                        child: const Center(
                          child: Icon(Icons.directions_car_rounded, size: 40, color: Color(0xFFFF7A00)),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── 2x2 Services Grid (Matching Screenshot 100% with Modern Gradients) ──
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
                    badgeText: isArabic ? 'طلبات حية' : 'Live Requests',
                    imagePath: 'assets/images/ic_available_trips_hd.png',
                    fallbackImagePath: 'assets/images/ic_available_trips.png',
                    gradientColors: const [Color(0xFFFFFBF6), Color(0xFFFFF4E8)],
                    borderColor: const Color(0xFFFFE0B8),
                    accentColor: const Color(0xFFFF7A00),
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
                  delay: const Duration(milliseconds: 230),
                  duration: const Duration(milliseconds: 450),
                  child: _DriverServiceGridCard(
                    title: isArabic ? 'جدولة رحلة' : 'Schedule Trips',
                    subtitle: isArabic ? 'احجز رحلة لموعد لاحق' : 'Book a trip for a later date',
                    badgeText: isArabic ? 'حجوزات' : 'Scheduled',
                    imagePath: 'assets/images/ic_schedule_trips_hd.png',
                    fallbackImagePath: 'assets/images/ic_schedule_trips.png',
                    gradientColors: const [Color(0xFFFCF9FF), Color(0xFFF3ECFF)],
                    borderColor: const Color(0xFFE5D7FD),
                    accentColor: const Color(0xFF7E22CE),
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
                  delay: const Duration(milliseconds: 280),
                  duration: const Duration(milliseconds: 450),
                  child: _DriverServiceGridCard(
                    title: isArabic ? 'البريد والطرود' : 'Mail or Parcel',
                    subtitle: isArabic ? 'أرسل واستلم الطرود بين المحافظات' : 'Send packages between provinces',
                    badgeText: isArabic ? 'شحن سريع' : 'Fast Cargo',
                    imagePath: 'assets/images/ic_mail_parcel_hd.png',
                    fallbackImagePath: 'assets/images/ic_mail_parcel.png',
                    gradientColors: const [Color(0xFFF6F9FF), Color(0xFFE9F2FE)],
                    borderColor: const Color(0xFFCDE2FE),
                    accentColor: const Color(0xFF2563EB),
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
                  delay: const Duration(milliseconds: 330),
                  duration: const Duration(milliseconds: 450),
                  child: _DriverServiceGridCard(
                    title: isArabic ? 'حجز سيارة كاملة' : 'Book Entire Car',
                    subtitle: isArabic ? 'احجز سيارة بالكامل لرحلتك' : 'Reserve a whole car for your trip',
                    badgeText: isArabic ? 'VIP خاصة' : 'VIP Private',
                    imagePath: 'assets/images/ic_book_entire_car_hd.png',
                    fallbackImagePath: 'assets/images/ic_book_entire_car.png',
                    gradientColors: const [Color(0xFFF5FEF8), Color(0xFFE4F9EB)],
                    borderColor: const Color(0xFFBAF0CB),
                    accentColor: const Color(0xFF16A34A),
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
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStatItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required bool isArabic,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: iconColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: isArabic ? 'NotoKufiArabic' : null,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}

class _DriverServiceGridCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final String badgeText;
  final String imagePath;
  final String? fallbackImagePath;
  final List<Color> gradientColors;
  final Color borderColor;
  final Color accentColor;
  final bool isArabic;
  final VoidCallback onTap;

  const _DriverServiceGridCard({
    required this.title,
    required this.subtitle,
    required this.badgeText,
    required this.imagePath,
    this.fallbackImagePath,
    required this.gradientColors,
    required this.borderColor,
    required this.accentColor,
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
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: widget.borderColor, width: 1.3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Top Row: Small category badge pill
              Align(
                alignment: widget.isArabic ? Alignment.topLeft : Alignment.topRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: widget.borderColor, width: 0.8),
                  ),
                  child: Text(
                    widget.badgeText,
                    style: TextStyle(
                      fontFamily: widget.isArabic ? 'NotoKufiArabic' : null,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                      color: widget.accentColor,
                    ),
                  ),
                ),
              ),

              // 3D / Graphic Illustration (256x256 Ultra-HD)
              SizedBox(
                height: 48,
                child: Image.asset(
                  widget.imagePath,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (context, error, stackTrace) {
                    if (widget.fallbackImagePath != null) {
                      return Image.asset(
                        widget.fallbackImagePath!,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.directions_car_rounded,
                          size: 38,
                          color: widget.accentColor,
                        ),
                      );
                    }
                    return Icon(
                      Icons.directions_car_rounded,
                      size: 38,
                      color: widget.accentColor,
                    );
                  },
                ),
              ),
              const SizedBox(height: 6),

              // Title
              Text(
                widget.title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: widget.isArabic ? 'NotoKufiArabic' : null,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),

              // Subtitle
              Expanded(
                child: Text(
                  widget.subtitle,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: widget.isArabic ? 'NotoKufiArabic' : null,
                    fontSize: 10,
                    height: 1.25,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ),

              // Bottom Circular Arrow Button
              Align(
                alignment: widget.isArabic ? Alignment.bottomLeft : Alignment.bottomRight,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: widget.accentColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: widget.accentColor.withOpacity(0.35),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    widget.isArabic ? Icons.arrow_back_rounded : Icons.arrow_forward_rounded,
                    size: 15,
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
