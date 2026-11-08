import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/providers/driver_locale_provider.dart';
import '../../../core/providers/active_ride_provider.dart';
import 'trip_ongoing_screen.dart';

class AvailableTripDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> tripData;
  final bool isEntireCar;

  const AvailableTripDetailsScreen({
    super.key,
    required this.tripData,
    this.isEntireCar = false,
  });

  @override
  State<AvailableTripDetailsScreen> createState() => _AvailableTripDetailsScreenState();
}

class _AvailableTripDetailsScreenState extends State<AvailableTripDetailsScreen> {
  bool _isLoading = false;

  Future<void> _makePhoneCall(String phone) async {
    final clean = phone.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri(scheme: 'tel', path: clean);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openNavigation(double lat, double lng) async {
    // 1. Open in-app live GPS turn-by-turn tracking screen first
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TripOngoingScreen(tripData: widget.tripData),
        ),
      );
    }
  }

  Future<void> _cancelTrip() async {
    final locale = Provider.of<DriverLocaleProvider>(context, listen: false);
    final isArabic = locale.isArabic;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isArabic ? 'إلغاء الرحلة' : 'Cancel Trip',
          style: TextStyle(
            fontFamily: isArabic ? 'NotoKufiArabic' : null,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          isArabic ? 'هل أنت متأكد من رغبتك في إلغاء هذه الرحلة؟' : 'Are you sure you want to cancel this trip?',
          style: TextStyle(fontFamily: isArabic ? 'NotoKufiArabic' : null),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(isArabic ? 'تراجع' : 'No', style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isArabic ? 'نعم، إلغاء' : 'Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    final api = Provider.of<ApiService>(context, listen: false);
    final storage = Provider.of<StorageService>(context, listen: false);
    final token = await storage.getToken();
    final rideId = widget.tripData['id']?.toString() ?? '';

    try {
      if (token != null && rideId.isNotEmpty) {
        await api.cancelRide(rideId, 'Cancelled by driver', token);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isArabic ? 'تم إلغاء الرحلة بنجاح.' : 'Trip cancelled successfully.'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Cancel error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = Provider.of<DriverLocaleProvider>(context);
    final isArabic = locale.isArabic;
    final trip = widget.tripData;

    final String passengerName = trip['name'] ?? (isArabic ? 'أحمد جميل' : 'Ahmed Jamil');
    final String passengerPhone = trip['phone'] ?? '0770 123 4567';
    final String fromCity = trip['from'] ?? (isArabic ? 'كركوك' : 'Kirkuk');
    final String toCity = trip['to'] ?? (isArabic ? 'الموصل' : 'Mosul');
    final String dateStr = trip['date'] ?? '6 Nov 2026';
    final String timeStr = trip['time'] ?? '08:30 AM';
    final String priceStr = trip['price'] ?? '25,000 IQD';
    final String passengersCount = (trip['seats'] ?? '1').toString();

    final double pLat = double.tryParse(trip['pickupLat']?.toString() ?? '') ?? 35.46;
    final double pLng = double.tryParse(trip['pickupLng']?.toString() ?? '') ?? 44.38;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black12, width: 1),
          ),
          child: IconButton(
            icon: Icon(
              isArabic ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded,
              color: const Color(0xFF0F172A),
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        centerTitle: true,
        title: Text(
          widget.isEntireCar
              ? (isArabic ? 'حجز سيارة كاملة' : 'Book Entire Car')
              : (isArabic ? 'الرحلة المتاحة' : 'Available Trip'),
          style: TextStyle(
            fontFamily: isArabic ? 'NotoKufiArabic' : null,
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF1E1B4B),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Top Passenger Card & Key-Value Details (Image 1 / Image 5) ──
              FadeInDown(
                duration: const Duration(milliseconds: 400),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Passenger Profile Row
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: const Color(0xFFF1F5F9),
                            child: Text(
                              passengerName.isNotEmpty ? passengerName[0].toUpperCase() : 'P',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF334155)),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                              children: [
                                Text(
                                  passengerName,
                                  style: TextStyle(
                                    fontFamily: isArabic ? 'NotoKufiArabic' : null,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.phone_outlined, size: 14, color: Color(0xFF64748B)),
                                    const SizedBox(width: 4),
                                    Text(
                                      passengerPhone,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Phone Call Action Button (Lilac Tint)
                          GestureDetector(
                            onTap: () => _makePhoneCall(passengerPhone),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFAF5FF),
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFFE9D5FF)),
                              ),
                              child: const Icon(Icons.phone_rounded, color: Color(0xFF7E22CE), size: 20),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      const SizedBox(height: 12),

                      // Key Value Rows
                      _buildDetailRow(
                        icon: Icons.person_outline_rounded,
                        label: isArabic ? 'الركاب' : 'Passengers',
                        value: passengersCount,
                      ),
                      const Divider(height: 18, color: Color(0xFFF8FAFC)),
                      _buildDetailRow(
                        icon: Icons.location_on_rounded,
                        iconColor: const Color(0xFFFF7A00),
                        label: isArabic ? 'من' : 'From',
                        value: fromCity,
                      ),
                      const Divider(height: 18, color: Color(0xFFF8FAFC)),
                      _buildDetailRow(
                        icon: Icons.location_on_rounded,
                        iconColor: const Color(0xFFFF7A00),
                        label: isArabic ? 'إلى' : 'To',
                        value: toCity,
                      ),
                      const Divider(height: 18, color: Color(0xFFF8FAFC)),
                      _buildDetailRow(
                        icon: Icons.calendar_today_outlined,
                        label: isArabic ? 'التاريخ' : 'Date',
                        value: dateStr,
                      ),
                      const Divider(height: 18, color: Color(0xFFF8FAFC)),
                      _buildDetailRow(
                        icon: Icons.access_time_rounded,
                        label: isArabic ? 'الوقت' : 'Time',
                        value: timeStr,
                      ),
                      const Divider(height: 18, color: Color(0xFFF8FAFC)),
                      _buildDetailRow(
                        icon: Icons.account_balance_wallet_outlined,
                        label: isArabic ? 'سعر الرحلة' : 'Trip Price',
                        value: priceStr,
                        valueColor: const Color(0xFFFF7A00),
                        isBold: true,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // ── Map Preview with Pickup Callout (Exact Replica) ──
              FadeIn(
                duration: const Duration(milliseconds: 450),
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: Colors.black.withOpacity(0.06)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 15,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Stack(
                      children: [
                        FlutterMap(
                          options: MapOptions(
                            initialCenter: LatLng(pLat, pLng),
                            initialZoom: 14,
                            interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.iqalmassar.driver',
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: LatLng(pLat, pLng),
                                  width: 44,
                                  height: 44,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF7A00).withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Container(
                                        width: 22,
                                        height: 22,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFF7A00),
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 2),
                                          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                                        ),
                                        child: const Icon(Icons.location_on, color: Colors.white, size: 14),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        // Floating Pickup Location Pill Callout
                        Positioned(
                          top: 24,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.12),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    isArabic ? 'نقطة الانطلاق' : 'Pickup Location',
                                    style: TextStyle(
                                      fontFamily: isArabic ? 'NotoKufiArabic' : null,
                                      fontSize: 10,
                                      color: const Color(0xFF64748B),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    fromCity,
                                    style: TextStyle(
                                      fontFamily: isArabic ? 'NotoKufiArabic' : null,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ── Action Buttons ──
              // 1. [ ✈ Navigate to Pickup ] (Solid Orange)
              FadeInUp(
                duration: const Duration(milliseconds: 400),
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF7A00),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                    ),
                    onPressed: () => _openNavigation(pLat, pLng),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.navigation_rounded, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          isArabic ? 'التوجه إلى نقطة الانطلاق' : 'Navigate to Pickup',
                          style: TextStyle(
                            fontFamily: isArabic ? 'NotoKufiArabic' : null,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // 2. [ 🗑 Cancel Trip ] (Red Outlined / Soft Red Pill)
              FadeInUp(
                delay: const Duration(milliseconds: 100),
                duration: const Duration(milliseconds: 400),
                child: SizedBox(
                  height: 52,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDC2626),
                      backgroundColor: const Color(0xFFFEF2F2),
                      side: const BorderSide(color: Color(0xFFFCA5A5), width: 1.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                    ),
                    onPressed: _isLoading ? null : _cancelTrip,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626), size: 20),
                        const SizedBox(width: 8),
                        Text(
                          isArabic ? 'إلغاء الرحلة' : 'Cancel Trip',
                          style: TextStyle(
                            fontFamily: isArabic ? 'NotoKufiArabic' : null,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    Color? iconColor,
    required String label,
    required String value,
    Color? valueColor,
    bool isBold = false,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: iconColor ?? const Color(0xFF64748B)),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Color(0xFF475569), fontWeight: FontWeight.w500),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
            color: valueColor ?? const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}

