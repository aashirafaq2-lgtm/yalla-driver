import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/driver_locale_provider.dart';
import '../../../core/network/api_service.dart';
import '../../../core/services/storage_service.dart';

class TripPassengersScreen extends StatefulWidget {
  final String tripId;
  final String tripFrom;
  final String tripTo;
  final String tripDate;

  const TripPassengersScreen({
    super.key,
    required this.tripId,
    required this.tripFrom,
    required this.tripTo,
    required this.tripDate,
  });

  @override
  State<TripPassengersScreen> createState() => _TripPassengersScreenState();
}

class _TripPassengersScreenState extends State<TripPassengersScreen> {
  bool _isLoading = true;
  List<dynamic> _bookings = [];
  Map<String, dynamic>? _tripInfo;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() { _isLoading = true; _error = null; });
    final api = Provider.of<ApiService>(context, listen: false);
    final storage = Provider.of<StorageService>(context, listen: false);
    final token = await storage.getToken();
    if (token == null) {
      setState(() { _isLoading = false; _error = 'Not logged in'; });
      return;
    }
    try {
      final res = await api.getTripBookings(widget.tripId, token);
      if (res.statusCode == 200) {
        setState(() {
          _bookings = res.data['bookings'] ?? [];
          _tripInfo = res.data['trip'];
          _isLoading = false;
        });
      } else {
        setState(() { _isLoading = false; _error = 'Failed to load'; });
      }
    } catch (e) {
      debugPrint('TripPassengersScreen error: $e');
      setState(() { _isLoading = false; _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = Provider.of<DriverLocaleProvider>(context);
    final isArabic = locale.isArabic;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: AppColors.primaryOrange, size: 32),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          isArabic ? 'ركاب الرحلة' : 'Trip Passengers',
          style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primaryOrange),
            onPressed: _loadBookings,
          ),
        ],
      ),
      body: Column(
        children: [
          // Trip info header
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryOrange, Color(0xFFFF8C42)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryOrange.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Colors.white70, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      widget.tripDate,
                      style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.trip_origin, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      widget.tripFrom,
                      style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Container(
                    width: 1, height: 14,
                    color: Colors.white38,
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      widget.tripTo,
                      style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.people_outline, color: Colors.white, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '${_bookings.length} ${isArabic ? "حجز" : "booking(s)"}',
                            style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    if (_tripInfo != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.event_seat, color: Colors.white, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              '${_tripInfo!['availableSeats']} ${isArabic ? "مقعد متاح" : "seats left"}',
                              style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Passengers list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryOrange))
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.error_outline, color: Colors.red.shade300, size: 50),
                            const SizedBox(height: 12),
                            Text(
                              isArabic ? 'حدث خطأ' : 'An error occurred',
                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryOrange,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: _loadBookings,
                              child: Text(isArabic ? 'إعادة المحاولة' : 'Retry',
                                style: const TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      )
                    : _bookings.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.people_outline, size: 70, color: Colors.grey.shade300),
                                const SizedBox(height: 16),
                                Text(
                                  isArabic ? 'لا يوجد ركاب بعد' : 'No passengers yet',
                                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black54),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  isArabic ? 'سيظهر الركاب هنا عند الحجز' : 'Passengers will appear here when they book',
                                  style: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            color: AppColors.primaryOrange,
                            onRefresh: _loadBookings,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 30),
                              itemCount: _bookings.length,
                              itemBuilder: (context, i) {
                                final b = _bookings[i];
                                return FadeInUp(
                                  delay: Duration(milliseconds: i * 80),
                                  child: _buildPassengerCard(b, isArabic),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildPassengerCard(dynamic b, bool isArabic) {
    final name = b['passengerName']?.toString() ?? (isArabic ? 'راكب' : 'Passenger');
    final phone = b['passengerPhone']?.toString() ?? '';
    final seats = b['seatsBooked'] ?? 1;
    final price = b['totalPrice'];
    final status = b['status']?.toString() ?? 'CONFIRMED';

    Color statusColor;
    String statusLabel;
    switch (status) {
      case 'CONFIRMED': statusColor = const Color(0xFF22C55E); statusLabel = isArabic ? 'مؤكد' : 'Confirmed'; break;
      case 'CANCELLED': statusColor = Colors.red; statusLabel = isArabic ? 'ملغى' : 'Cancelled'; break;
      case 'PENDING': statusColor = Colors.orange; statusLabel = isArabic ? 'معلق' : 'Pending'; break;
      default: statusColor = Colors.grey; statusLabel = status;
    }

    final initials = name.isNotEmpty ? name.substring(0, name.length > 1 ? 2 : 1).toUpperCase() : 'P';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.07)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primaryOrange.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primaryOrange.withOpacity(0.3)),
            ),
            child: Center(
              child: Text(
                initials,
                style: GoogleFonts.outfit(
                  color: AppColors.primaryOrange,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                if (phone.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.phone_outlined, size: 12, color: Colors.black45),
                      const SizedBox(width: 4),
                      Text(phone, style: GoogleFonts.inter(fontSize: 12, color: Colors.black54)),
                    ],
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    _miniChip(Icons.event_seat_outlined, '$seats ${isArabic ? "مقعد" : "seat(s)"}'),
                    const SizedBox(width: 6),
                    if (price != null) _miniChip(Icons.monetization_on_outlined, '$price ${isArabic ? "د.ع" : "IQD"}'),
                  ],
                ),
              ],
            ),
          ),
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
                fontSize: 11,
                fontFamily: isArabic ? 'NotoKufiArabic' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.black54),
          const SizedBox(width: 4),
          Text(label, style: GoogleFonts.inter(fontSize: 11, color: Colors.black54)),
        ],
      ),
    );
  }
}
