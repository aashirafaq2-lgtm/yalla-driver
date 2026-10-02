import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/providers/active_ride_provider.dart';
import 'trip_ongoing_screen.dart';

class AvailableTripsScreen extends StatefulWidget {
  final bool isOutsideIraq;
  const AvailableTripsScreen({super.key, this.isOutsideIraq = false});

  @override
  State<AvailableTripsScreen> createState() => _AvailableTripsScreenState();
}

class _AvailableTripsScreenState extends State<AvailableTripsScreen> {
  int? expandedIndex;
  bool _isLoading = true;
  bool _isAccepting = false;
  List<Map<String, dynamic>> _tripsList = [];

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    setState(() { _isLoading = true; });
    final api = Provider.of<ApiService>(context, listen: false);
    try {
      final res = await api.getAvailableTrips();
      if (res.statusCode == 200 && res.data['trips'] != null && (res.data['trips'] as List).isNotEmpty) {
        final List<dynamic> raw = res.data['trips'];
        setState(() {
          _tripsList = raw.map<Map<String, dynamic>>((t) => {
            'id': t['id']?.toString() ?? 'trip',
            'name': '${t['passenger']?['firstName'] ?? t['driver']?['firstName'] ?? 'Passenger'} ${t['passenger']?['lastName'] ?? t['driver']?['lastName'] ?? ''}'.trim(),
            'time': t['scheduledAt'] ?? t['departureTime'] ?? 'Scheduled',
            'from': t['fromGovernorate']?['name'] ?? t['pickupAddress'] ?? 'Kirkuk',
            'to': t['toGovernorate']?['name'] ?? t['dropAddress'] ?? 'Baghdad',
            'price': '${t['pricePerSeat'] ?? t['estimatedFare'] ?? 25000} IQD',
            'phone': t['passenger']?['phone'] ?? t['driver']?['phone'] ?? '07xx xxx xxxx',
            'pickupLat': t['pickupLat']?.toString() ?? '',
            'pickupLng': t['pickupLng']?.toString() ?? '',
            'dropLat': t['dropLat']?.toString() ?? '',
            'dropLng': t['dropLng']?.toString() ?? '',
            'seats': t['availableSeats']?.toString() ?? '4',
          }).toList();
          _isLoading = false;
        });
        return;
      }
    } catch (e) {
      debugPrint('Load trips note: $e');
    }
    setState(() {
      _tripsList = [];
      _isLoading = false;
    });
  }

  Future<void> _acceptTrip(Map<String, dynamic> trip) async {
    setState(() => _isAccepting = true);
    final api = Provider.of<ApiService>(context, listen: false);
    final storage = Provider.of<StorageService>(context, listen: false);
    final token = await storage.getToken();

    try {
      if (token != null) {
        await api.acceptRide(trip['id'], token);
      }
    } catch (e) {
      debugPrint('Accept trip note (continuing): $e');
    } finally {
      if (mounted) setState(() => _isAccepting = false);
    }

    if (!mounted) return;

    // Set globally active ride so Home screen shows active trip banner (Uber-style)
    try {
      Provider.of<ActiveRideProvider>(context, listen: false).setActiveRide(trip);
    } catch (e) {
      debugPrint('Set active ride note: $e');
    }

    // Navigate to active trip tracking screen (Uber-style)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TripOngoingScreen(tripData: trip),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: AppColors.primaryOrange, size: 32),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Yalla ',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 28),
            ),
            Text(
              'يَلَّا',
              style: TextStyle(color: AppColors.primaryOrange, fontWeight: FontWeight.bold, fontSize: 28),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primaryOrange, size: 26),
            onPressed: _loadTrips,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isOutsideIraq ? 'Intercity Requests' : 'Available Trip Requests',
                  style: GoogleFonts.outfit(
                    color: AppColors.primaryOrange,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.isOutsideIraq ? 'Outside Governorate bookings' : 'Tap a trip to accept or decline',
                  style: GoogleFonts.inter(color: Colors.black45, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryOrange))
                : _tripsList.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        color: AppColors.primaryOrange,
                        onRefresh: _loadTrips,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
                          itemCount: _tripsList.length,
                          itemBuilder: (context, index) {
                            final trip = _tripsList[index];
                            bool isExpanded = expandedIndex == index;
                            return _buildTripCard(trip, index, isExpanded);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return RefreshIndicator(
      color: AppColors.primaryOrange,
      onRefresh: _loadTrips,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.6,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: AppColors.primaryOrange.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.drive_eta_outlined, size: 50, color: Colors.grey.shade400),
              ),
              const SizedBox(height: 20),
              Text(
                'No Trip Requests Yet',
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              Text(
                'Pull down to check for new requests',
                style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _loadTrips,
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: Text('Refresh Requests', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTripCard(Map<String, dynamic> trip, int index, bool isExpanded) {
    return FadeInUp(
      delay: Duration(milliseconds: index * 80),
      child: GestureDetector(
        onTap: () => setState(() => expandedIndex = isExpanded ? null : index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isExpanded ? AppColors.primaryOrange.withOpacity(0.4) : Colors.black.withOpacity(0.08),
              width: isExpanded ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isExpanded ? AppColors.primaryOrange.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Avatar
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primaryOrange.withOpacity(0.12),
                      ),
                      child: const Icon(Icons.person, size: 32, color: AppColors.primaryOrange),
                    ),
                    const SizedBox(width: 14),
                    // Trip info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            trip['name'] ?? 'Passenger',
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.trip_origin, size: 12, color: Colors.green),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  trip['from'] ?? '',
                                  style: GoogleFonts.inter(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.w500),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 12, color: Colors.red),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  trip['to'] ?? '',
                                  style: GoogleFonts.inter(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.w500),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Price & chevron
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          trip['price'] ?? '',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: AppColors.primaryOrange, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Icon(
                          isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          color: AppColors.primaryOrange,
                          size: 22,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Expanded action area
              if (isExpanded)
                FadeIn(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      children: [
                        // Seats badge
                        if (trip['seats'] != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                const Icon(Icons.event_seat_outlined, size: 16, color: Colors.black45),
                                const SizedBox(width: 6),
                                Text(
                                  '${trip['seats']} seats available',
                                  style: GoogleFonts.inter(color: Colors.black45, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        Row(
                          children: [
                            Expanded(
                              child: _buildActionButton(
                                label: 'Accept Trip',
                                icon: Icons.check_circle_outline,
                                color: const Color(0xFF16A34A),
                                isLoading: _isAccepting,
                                onPressed: () {
                                  _confirmAction(
                                    title: 'Accept Trip',
                                    message: 'Accept this trip from ${trip['from']} to ${trip['to']}?',
                                    onConfirm: () => _acceptTrip(trip),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildActionButton(
                                label: 'Decline',
                                icon: Icons.cancel_outlined,
                                color: const Color(0xFFDC2626),
                                onPressed: () {
                                  _confirmAction(
                                    title: 'Decline Trip',
                                    message: 'Are you sure you want to decline this trip?',
                                    onConfirm: () {
                                      setState(() {
                                        _tripsList.removeAt(index);
                                        expandedIndex = null;
                                      });
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmAction({
    required String title,
    required String message,
    required VoidCallback onConfirm,
  }) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(title),
        content: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(message),
        ),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: false,
            onPressed: () => Navigator.pop(ctx),
            child: const Text('No'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    bool isLoading = false,
  }) {
    return SizedBox(
      height: 48,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: isLoading
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Icon(icon, color: Colors.white, size: 18),
        label: Text(
          label,
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ),
    );
  }
}
