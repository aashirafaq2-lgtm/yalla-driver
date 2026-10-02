import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/driver_locale_provider.dart';
import '../../../core/network/api_service.dart';
import '../../../core/services/storage_service.dart';

class ScheduledTripsScreen extends StatefulWidget {
  const ScheduledTripsScreen({super.key});

  @override
  State<ScheduledTripsScreen> createState() => _ScheduledTripsScreenState();
}

class _ScheduledTripsScreenState extends State<ScheduledTripsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _trips = [];

  @override
  void initState() {
    super.initState();
    _loadMyTrips();
  }

  Future<void> _loadMyTrips() async {
    setState(() => _isLoading = true);
    final api = Provider.of<ApiService>(context, listen: false);
    final storage = Provider.of<StorageService>(context, listen: false);
    final token = await storage.getToken();
    if (token == null) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final res = await api.getMyTrips(token);
      if (res.statusCode == 200 && res.data['trips'] != null) {
        final List<dynamic> raw = res.data['trips'];
        setState(() {
          _trips = raw.map<Map<String, dynamic>>((t) => {
            'id': t['id']?.toString() ?? '',
            'from': t['fromGovernorate']?['name'] ?? '—',
            'to': t['toGovernorate']?['name'] ?? '—',
            'date': _formatDate(t['departureTime']),
            'seats': '${t['availableSeats'] ?? 0} / ${t['totalSeats'] ?? 4}',
            'price': '${t['pricePerSeat'] ?? 0} IQD per seat',
            'status': t['currentStatus'] ?? 'SCHEDULED',
            'bookings': t['bookings'] ?? [],
          }).toList();
          _isLoading = false;
        });
      } else {
        setState(() { _trips = []; _isLoading = false; });
      }
    } catch (e) {
      debugPrint('Load my trips error: $e');
      setState(() { _trips = []; _isLoading = false; });
    }
  }

  String _formatDate(dynamic dateStr) {
    if (dateStr == null) return '—';
    try {
      final dt = DateTime.parse(dateStr.toString()).toLocal();
      final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final amPm = dt.hour >= 12 ? 'PM' : 'AM';
      final min = dt.minute.toString().padLeft(2, '0');
      return '${dt.day} ${months[dt.month - 1]} at $hour:$min $amPm';
    } catch (_) {
      return dateStr.toString();
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'SCHEDULED': return const Color(0xFF3B82F6);
      case 'IN_PROGRESS': return AppColors.primaryOrange;
      case 'COMPLETED': return AppColors.success;
      case 'CANCELLED': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _statusLabel(String status, bool isArabic) {
    if (isArabic) {
      switch (status) {
        case 'SCHEDULED': return 'مجدول';
        case 'IN_PROGRESS': return 'جارٍ';
        case 'COMPLETED': return 'مكتمل';
        case 'CANCELLED': return 'ملغى';
        default: return status;
      }
    }
    switch (status) {
      case 'SCHEDULED': return 'Scheduled';
      case 'IN_PROGRESS': return 'In Progress';
      case 'COMPLETED': return 'Completed';
      case 'CANCELLED': return 'Cancelled';
      default: return status;
    }
  }

  Future<void> _cancelTrip(String tripId, int index) async {
    final api = Provider.of<ApiService>(context, listen: false);
    final storage = Provider.of<StorageService>(context, listen: false);
    final token = await storage.getToken();
    if (token == null) return;

    try {
      final res = await api.cancelTripById(tripId, token);
      if (res.statusCode == 200) {
        setState(() => _trips[index]['status'] = 'CANCELLED');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Trip cancelled successfully'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      debugPrint('Cancel trip error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to cancel trip'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showCancelConfirm(String tripId, int index, bool isArabic) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange),
            const SizedBox(width: 8),
            Text(isArabic ? 'إلغاء الرحلة' : 'Cancel Trip',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          isArabic
              ? 'هل أنت متأكد من إلغاء هذه الرحلة المجدولة؟'
              : 'Are you sure you want to cancel this scheduled trip?',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isArabic ? 'رجوع' : 'Go Back',
              style: const TextStyle(color: Colors.black54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _cancelTrip(tripId, index);
            },
            child: Text(isArabic ? 'تأكيد الإلغاء' : 'Confirm Cancel',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
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
          locale.tr('my_scheduled_trips'),
          style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primaryOrange),
            onPressed: _loadMyTrips,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryOrange))
          : _trips.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 70, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        isArabic ? 'لا توجد رحلات مجدولة' : 'No Scheduled Trips',
                        style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black54),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isArabic ? 'أنشئ رحلة جديدة من الشاشة الرئيسية' : 'Create a new trip from the home screen',
                        style: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryOrange,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _loadMyTrips,
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        label: Text(isArabic ? 'تحديث' : 'Refresh', style: const TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: AppColors.primaryOrange,
                  onRefresh: _loadMyTrips,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
                    itemCount: _trips.length,
                    itemBuilder: (context, index) {
                      final trip = _trips[index];
                      final tripId = trip['id'] as String;
                      final status = trip['status'] as String;
                      final isCancelled = status == 'CANCELLED';
                      final isCompleted = status == 'COMPLETED';
                      final bookings = trip['bookings'] as List;

                      return FadeInUp(
                        delay: Duration(milliseconds: index * 100),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isCancelled ? Colors.red.withOpacity(0.3) : Colors.black.withOpacity(0.07),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ── Status bar ───────────────────────────────────
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: _statusColor(status).withOpacity(0.08),
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 8, height: 8,
                                          decoration: BoxDecoration(
                                            color: _statusColor(status),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          _statusLabel(status, isArabic),
                                          style: GoogleFonts.outfit(
                                            color: _statusColor(status),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      trip['date'] as String,
                                      style: GoogleFonts.inter(color: Colors.black45, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),

                              // ── Route info ───────────────────────────────────
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.trip_origin, color: AppColors.primaryOrange, size: 18),
                                        const SizedBox(width: 8),
                                        Text(
                                          trip['from'] as String,
                                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15),
                                        ),
                                      ],
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(left: 9),
                                      child: Container(
                                        width: 2, height: 16,
                                        color: Colors.black12,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on, color: Color(0xFF3B82F6), size: 18),
                                        const SizedBox(width: 8),
                                        Text(
                                          trip['to'] as String,
                                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        _infoChip(Icons.event_seat_outlined, trip['seats'] as String),
                                        const SizedBox(width: 8),
                                        _infoChip(Icons.monetization_on_outlined, trip['price'] as String),
                                      ],
                                    ),

                                    // Bookings list
                                    if (bookings.isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      Text(
                                        isArabic ? 'الحجوزات (${bookings.length})' : 'Bookings (${bookings.length})',
                                        style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black54),
                                      ),
                                      const SizedBox(height: 6),
                                      ...bookings.map((b) {
                                        final p = b['passenger'];
                                        final pName = '${p?['firstName'] ?? ''} ${p?['lastName'] ?? ''}'.trim();
                                        final seats = b['seatsBooked'] ?? 1;
                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 4),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.person_outline, size: 14, color: Colors.black45),
                                              const SizedBox(width: 6),
                                              Text(pName.isEmpty ? 'Passenger' : pName,
                                                style: GoogleFonts.inter(fontSize: 13)),
                                              const Spacer(),
                                              Text('$seats seat${seats > 1 ? 's' : ''}',
                                                style: GoogleFonts.inter(fontSize: 12, color: Colors.black45)),
                                            ],
                                          ),
                                        );
                                      }),
                                    ],
                                  ],
                                ),
                              ),

                              // ── Action buttons ───────────────────────────────
                              if (!isCancelled && !isCompleted)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(
                                            side: const BorderSide(color: Colors.red),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                          ),
                                          onPressed: () => _showCancelConfirm(tripId, index, isArabic),
                                          icon: const Icon(Icons.cancel_outlined, color: Colors.red, size: 18),
                                          label: Text(
                                            isArabic ? 'إلغاء' : 'Cancel',
                                            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.black54),
          const SizedBox(width: 5),
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: Colors.black54)),
        ],
      ),
    );
  }
}
