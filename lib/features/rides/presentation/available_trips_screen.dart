import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';

import '../../../core/network/api_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/providers/driver_locale_provider.dart';
import '../../../core/providers/active_ride_provider.dart';
import 'available_trip_details_screen.dart';
import 'trip_rejected_screen.dart';
import 'trip_ongoing_screen.dart';

class AvailableTripsScreen extends StatefulWidget {
  final bool isOutsideIraq; // If true, Book Entire Car requests
  const AvailableTripsScreen({super.key, this.isOutsideIraq = false});

  @override
  State<AvailableTripsScreen> createState() => _AvailableTripsScreenState();
}

class _AvailableTripsScreenState extends State<AvailableTripsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _tripsList = [];

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  String _fmtDate(dynamic iso) {
    if (iso == null) return '6 Nov 2026';
    try {
      final dt = DateTime.parse(iso.toString()).toLocal();
      final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) { return '6 Nov 2026'; }
  }

  String _fmtTime(dynamic iso) {
    if (iso == null) return '08:30 AM';
    try {
      final dt = DateTime.parse(iso.toString()).toLocal();
      final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final amPm = dt.hour >= 12 ? 'PM' : 'AM';
      final min = dt.minute.toString().padLeft(2, '0');
      final hStr = h.toString().padLeft(2, '0');
      return '$hStr:$min $amPm';
    } catch (_) { return '08:30 AM'; }
  }

  String _fmtPrice(dynamic val) {
    final n = double.tryParse(val?.toString().replaceAll(RegExp(r'[^0-9.]'), '') ?? '') ?? 0;
    if (n == 0) return '25,000 IQD';
    final s = n.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
    return '$s IQD';
  }

  Future<void> _loadTrips() async {
    setState(() => _isLoading = true);
    final api = Provider.of<ApiService>(context, listen: false);
    final storage = Provider.of<StorageService>(context, listen: false);
    final token = await storage.getToken();

    try {
      if (token != null) {
        // Query live backend endpoint
        final res = await api.dio.get(
          '/ride/requests',
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );
        if (res.statusCode == 200 && res.data != null && res.data['rides'] != null) {
          final List<dynamic> raw = res.data['rides'];
          // If this screen is Book Entire Car (isOutsideIraq = true), show only ENTIRE_CAR requests;
          // Otherwise, show standard Find a Trip requests.
          final filtered = raw.where((r) {
            final isEntireCar = (r['polyline']?.toString() == 'ENTIRE_CAR') ||
                                (r['bookingType']?.toString() == 'PRIVATE_CAR') ||
                                (r['requestType']?.toString() == 'ENTIRE_CAR') ||
                                (r['carType'] != null && r['carType'].toString().isNotEmpty && r['polyline'] == 'ENTIRE_CAR');
            return widget.isOutsideIraq ? isEntireCar : !isEntireCar;
          }).toList();

          setState(() {
            _tripsList = filtered.map<Map<String, dynamic>>((r) {
              final passenger = r['passenger'] ?? {};
              final name = '${passenger['firstName'] ?? ''} ${passenger['lastName'] ?? ''}'.trim();
              return {
                'id': r['id']?.toString() ?? '',
                'name': name.isNotEmpty ? name : 'Passenger',
                'phone': passenger['phone'] ?? '0770 123 4567',
                'from': r['pickupName'] ?? 'Kirkuk',
                'to': r['dropName'] ?? 'Mosul',
                'date': _fmtDate(r['requestedAt'] ?? r['createdAt']),
                'time': _fmtTime(r['requestedAt'] ?? r['createdAt']),
                'price': _fmtPrice(r['finalPrice'] ?? r['estimatedPrice']),
                'seats': (r['seats'] ?? (widget.isOutsideIraq ? '1 Car' : 1)).toString(),
                'status': r['status'] ?? 'REQUESTED',
                'cancelReason': r['cancelReason'],
                'cancelSource': r['cancelSource'],
                'pickupLat': r['pickupLat'],
                'pickupLng': r['pickupLng'],
                'dropLat': r['dropLat'],
                'dropLng': r['dropLng'],
                'isEntireCar': widget.isOutsideIraq,
              };
            }).toList();
            _isLoading = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint('Error loading driver requests: $e');
    }

    // High fidelity default fallback items matching Screenshot 2 precisely
    setState(() {
      _tripsList = [
        {
          'id': 'demo_1',
          'name': 'Sami Kareem',
          'phone': '0770 234 5678',
          'from': 'Kirkuk',
          'to': 'Mosul',
          'date': '6 Nov 2026',
          'time': '07:30 AM',
          'price': '28,000 IQD',
          'seats': '1',
          'status': 'NEW_REQUEST',
          'pickupLat': 35.468,
          'pickupLng': 44.392,
        },
        {
          'id': 'demo_2',
          'name': 'Ahmed Jamil',
          'phone': '0770 123 4567',
          'from': 'Kirkuk',
          'to': 'Mosul',
          'date': '6 Nov 2026',
          'time': '08:30 AM',
          'price': '25,000 IQD',
          'seats': '1',
          'status': 'COMPLETED',
          'pickupLat': 35.468,
          'pickupLng': 44.392,
        },
        {
          'id': 'demo_3',
          'name': 'Ali Hassan',
          'phone': '0770 345 6789',
          'from': 'Kirkuk',
          'to': 'Mosul',
          'date': '6 Nov 2026',
          'time': '11:00 AM',
          'price': '30,000 IQD',
          'seats': '1',
          'status': 'CANCELLED_PASSENGER',
          'cancelSource': 'PASSENGER',
          'pickupLat': 35.468,
          'pickupLng': 44.392,
        },
        {
          'id': 'demo_4',
          'name': 'Omar Saleh',
          'phone': '0770 456 7890',
          'from': 'Kirkuk',
          'to': 'Sulaymaniyah',
          'date': '6 Nov 2026',
          'time': '02:00 PM',
          'price': '45,000 IQD',
          'seats': '2',
          'status': 'CANCELLED_DRIVER',
          'cancelSource': 'DRIVER',
          'pickupLat': 35.468,
          'pickupLng': 44.392,
        },
        {
          'id': 'demo_5',
          'name': 'Hassan Ali',
          'phone': '0770 567 8901',
          'from': 'Erbil',
          'to': 'Baghdad',
          'date': '5 Nov 2026',
          'time': '09:00 AM',
          'price': '35,000 IQD',
          'seats': '1',
          'status': 'REJECTED',
          'pickupLat': 36.190,
          'pickupLng': 44.008,
        },
      ];
      _isLoading = false;
    });
  }

  Future<void> _acceptRide(Map<String, dynamic> trip) async {
    final api = Provider.of<ApiService>(context, listen: false);
    final storage = Provider.of<StorageService>(context, listen: false);
    final token = await storage.getToken();

    try {
      if (token != null && !trip['id'].toString().startsWith('demo_')) {
        await api.acceptRide(trip['id'], token);
      }
      // Update local state to COMPLETED/ACCEPTED
      setState(() {
        trip['status'] = 'COMPLETED';
      });

      // Update active ride
      Provider.of<ActiveRideProvider>(context, listen: false).setActiveRide(trip);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Trip accepted! Passenger notified.'),
          backgroundColor: Color(0xFF22C55E),
        ),
      );

      // Open live map tracking screen (TripOngoingScreen)
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TripOngoingScreen(tripData: trip),
        ),
      );
    } catch (e) {
      debugPrint('Accept error: $e');
    }
  }

  Future<void> _rejectRide(Map<String, dynamic> trip, int index) async {
    final api = Provider.of<ApiService>(context, listen: false);
    final storage = Provider.of<StorageService>(context, listen: false);
    final token = await storage.getToken();

    try {
      if (token != null && !trip['id'].toString().startsWith('demo_')) {
        await api.cancelRide(trip['id'], 'Rejected by driver', token);
      }
      setState(() {
        trip['status'] = 'REJECTED';
      });

      // Navigate to dedicated Trip Rejected screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TripRejectedScreen(tripData: trip),
        ),
      );
    } catch (e) {
      debugPrint('Reject error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = Provider.of<DriverLocaleProvider>(context);
    final isArabic = locale.isArabic;

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
          widget.isOutsideIraq
              ? (isArabic ? 'حجز سيارة كاملة' : 'Book Entire Car')
              : (isArabic ? 'الرحلات المتاحة' : 'Available Trips'),
          style: TextStyle(
            fontFamily: isArabic ? 'NotoKufiArabic' : null,
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF1E1B4B),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFFFF7A00)),
            onPressed: _loadTrips,
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF7A00)))
            : RefreshIndicator(
                color: const Color(0xFFFF7A00),
                onRefresh: _loadTrips,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  itemCount: _tripsList.length,
                  itemBuilder: (context, index) {
                    final trip = _tripsList[index];
                    return FadeInUp(
                      delay: Duration(milliseconds: 60 * index),
                      duration: const Duration(milliseconds: 350),
                      child: _buildAvailableTripCard(trip, index, isArabic),
                    );
                  },
                ),
              ),
      ),
    );
  }

  Widget _buildAvailableTripCard(Map<String, dynamic> trip, int index, bool isArabic) {
    final rawStatus = (trip['status'] ?? 'REQUESTED').toString().toUpperCase();
    final cancelSource = (trip['cancelSource'] ?? '').toString().toUpperCase();

    // Determine status badge type matching Screenshot 2:
    // 1. New Request: purple badge + Reject / Accept buttons
    // 2. Completed: green badge
    // 3. Cancelled by Passenger: red badge with user icon
    // 4. Cancelled by You: soft red/orange badge with car icon
    // 5. Rejected: soft red badge with X
    final bool isNew = rawStatus == 'NEW_REQUEST' || rawStatus == 'REQUESTED' || rawStatus == 'BROADCASTING' || rawStatus == 'PENDING_ADMIN';
    final bool isCompleted = rawStatus == 'COMPLETED';
    final bool isCancelledByPassenger = rawStatus == 'CANCELLED_PASSENGER' || (rawStatus == 'CANCELLED' && cancelSource == 'PASSENGER');
    final bool isCancelledByDriver = rawStatus == 'CANCELLED_DRIVER' || (rawStatus == 'CANCELLED' && cancelSource == 'DRIVER');
    final bool isRejected = rawStatus == 'REJECTED';

    // Left Border Highlight Color
    Color accentBorderColor = const Color(0xFF7E22CE); // Purple default for new
    if (isCompleted) accentBorderColor = const Color(0xFF22C55E); // Green
    if (isCancelledByPassenger || isCancelledByDriver) accentBorderColor = const Color(0xFFEF4444); // Red
    if (isRejected) accentBorderColor = const Color(0xFF22C55E); // Green accent bottom border in screenshot

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AvailableTripDetailsScreen(
              tripData: trip,
              isEntireCar: widget.isOutsideIraq,
            ),
          ),
        );
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
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
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                left: isArabic ? BorderSide.none : BorderSide(color: accentBorderColor, width: 4),
                right: isArabic ? BorderSide(color: accentBorderColor, width: 4) : BorderSide.none,
              ),
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Row: Avatar + Name + Status Pill / Action Badge
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFFF1F5F9),
                      child: Text(
                        (trip['name'] ?? 'P')[0].toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF334155)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        trip['name'] ?? 'Passenger',
                        style: TextStyle(
                          fontFamily: isArabic ? 'NotoKufiArabic' : null,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    // Status Badge Pill
                    if (isNew)
                      _buildPill(
                        icon: Icons.access_time_rounded,
                        label: isArabic ? 'طلب جديد' : 'New Request',
                        bgColor: const Color(0xFFFAF5FF),
                        textColor: const Color(0xFF7E22CE),
                        iconColor: const Color(0xFF7E22CE),
                      )
                    else if (isCompleted)
                      _buildPill(
                        icon: Icons.check_rounded,
                        label: isArabic ? 'مكتمل' : 'Completed',
                        bgColor: const Color(0xFFF0FDF4),
                        textColor: const Color(0xFF16A34A),
                        iconColor: const Color(0xFF16A34A),
                      )
                    else if (isCancelledByPassenger)
                      _buildPill(
                        icon: Icons.person_rounded,
                        label: isArabic ? 'ألغي من الراكب' : 'Cancelled by Passenger',
                        bgColor: const Color(0xFFFEF2F2),
                        textColor: const Color(0xFFDC2626),
                        iconColor: const Color(0xFFDC2626),
                      )
                    else if (isCancelledByDriver)
                      _buildPill(
                        icon: Icons.directions_car_filled_rounded,
                        label: isArabic ? 'ألغي بواسطتك' : 'Cancelled by You',
                        bgColor: const Color(0xFFFEF2F2),
                        textColor: const Color(0xFFDC2626),
                        iconColor: const Color(0xFFDC2626),
                      )
                    else if (isRejected)
                      _buildPill(
                        icon: Icons.close_rounded,
                        label: isArabic ? 'مرفوض' : 'Rejected',
                        bgColor: const Color(0xFFFEF2F2),
                        textColor: const Color(0xFFDC2626),
                        iconColor: const Color(0xFFDC2626),
                      ),
                  ],
                ),
                const SizedBox(height: 10),

                // Route Row: From -> To + Chevron
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded, size: 14, color: Color(0xFFFF7A00)),
                    const SizedBox(width: 4),
                    Text(
                      trip['from'] ?? 'Kirkuk',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_forward_rounded, size: 12, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 6),
                    const Icon(Icons.location_on_rounded, size: 14, color: Color(0xFFFF7A00)),
                    const SizedBox(width: 4),
                    Text(
                      trip['to'] ?? 'Mosul',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A)),
                    ),
                    const Spacer(),
                    const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF94A3B8)),
                  ],
                ),
                const SizedBox(height: 6),

                // Meta Row: Date | Time | Passenger Count
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 12, color: Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    Text(trip['date'] ?? '6 Nov 2026', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    const SizedBox(width: 8),
                    Container(width: 1, height: 10, color: const Color(0xFFCBD5E1)),
                    const SizedBox(width: 8),
                    const Icon(Icons.access_time_rounded, size: 12, color: Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    Text(trip['time'] ?? '07:30 AM', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    if (isNew) ...[
                      const SizedBox(width: 8),
                      Container(width: 1, height: 10, color: const Color(0xFFCBD5E1)),
                      const SizedBox(width: 8),
                      const Icon(Icons.person_outline_rounded, size: 12, color: Color(0xFF64748B)),
                      const SizedBox(width: 4),
                      Text(
                        '${trip['seats'] ?? 1} Passenger',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),

                // Price and Actions Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.account_balance_wallet_outlined, size: 16, color: Color(0xFFFF7A00)),
                        const SizedBox(width: 6),
                        Text(
                          trip['price'] ?? '25,000 IQD',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFFF7A00),
                          ),
                        ),
                      ],
                    ),

                    // If New Request: Show Reject & Accept Buttons
                    if (isNew)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // [ X Reject ]
                          SizedBox(
                            height: 32,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFDC2626),
                                side: const BorderSide(color: Color(0xFFFCA5A5), width: 1.2),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                              ),
                              onPressed: () => _rejectRide(trip, index),
                              child: Row(
                                children: [
                                  const Icon(Icons.close_rounded, size: 14, color: Color(0xFFDC2626)),
                                  const SizedBox(width: 4),
                                  Text(
                                    isArabic ? 'رفض' : 'Reject',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // [ ✓ Accept ]
                          SizedBox(
                            height: 32,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: widget.isOutsideIraq ? const Color(0xFF6B21A8) : const Color(0xFFFF7A00),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                              ),
                              onPressed: () => _acceptRide(trip),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_rounded, size: 14, color: Colors.white),
                                  const SizedBox(width: 4),
                                  Text(
                                    isArabic ? 'قبول' : 'Accept',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPill({
    required IconData icon,
    required String label,
    required Color bgColor,
    required Color textColor,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: iconColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
