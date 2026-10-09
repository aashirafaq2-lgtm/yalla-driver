import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/services/storage_service.dart';

class TripHistoryScreen extends StatefulWidget {
  const TripHistoryScreen({super.key});

  @override
  State<TripHistoryScreen> createState() => _TripHistoryScreenState();
}

class _TripHistoryScreenState extends State<TripHistoryScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  List<dynamic> _rides = [];
  List<dynamic> _scheduledTrips = [];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchHistory() async {
    setState(() => _isLoading = true);
    final api = Provider.of<ApiService>(context, listen: false);
    final storage = Provider.of<StorageService>(context, listen: false);
    final token = await storage.getToken();

    if (token != null) {
      try {
        final res = await api.getHistory(token);
        if (res.statusCode == 200) {
          final allRides = List<dynamic>.from(res.data['rides'] ?? []);
          setState(() {
            _rides = allRides.where((r) => r['isScheduled'] != true).toList();
            _scheduledTrips = allRides.where((r) => r['isScheduled'] == true).toList();
            _isLoading = false;
          });
          return;
        }
      } catch (e) {
        debugPrint('Fetch history: $e');
      }
    }
    setState(() => _isLoading = false);
  }

  String _fmt(dynamic val) {
    final n = double.tryParse(val?.toString() ?? '') ?? 0;
    return n.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }

  String _formatDate(dynamic iso) {
    if (iso == null) return '--';
    try {
      final dt = DateTime.parse(iso.toString()).toLocal();
      final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final amPm = dt.hour >= 12 ? 'PM' : 'AM';
      final min = dt.minute.toString().padLeft(2, '0');
      return '${dt.day} ${months[dt.month - 1]} — $h:$min $amPm';
    } catch (_) { return iso.toString(); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black12),
                      ),
                      child: const Icon(Icons.arrow_back, color: Colors.black87, size: 20),
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Trip History',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                  ),
                  GestureDetector(
                    onTap: _fetchHistory,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black12),
                      ),
                      child: const Icon(Icons.refresh_rounded, color: AppColors.primaryOrange, size: 20),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Tab Bar ──
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              height: 46,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.black.withOpacity(0.08)),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppColors.primaryOrange,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: AppColors.primaryOrange.withOpacity(0.3), blurRadius: 8)],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.black54,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                tabs: const [
                  Tab(icon: Icon(Icons.directions_car_rounded, size: 18), text: 'Instant Rides'),
                  Tab(icon: Icon(Icons.calendar_month_rounded, size: 18), text: 'Scheduled'),
                ],
              ),
            ),

            const SizedBox(height: 8),

            Expanded(
              child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryOrange))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildRidesList(),
                      _buildScheduledList(),
                    ],
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRidesList() {
    if (_rides.isEmpty) return _emptyState('No trips yet', Icons.directions_car_outlined);
    return RefreshIndicator(
      color: AppColors.primaryOrange,
      onRefresh: _fetchHistory,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 30),
        itemCount: _rides.length,
        itemBuilder: (ctx, i) => FadeInUp(
          delay: Duration(milliseconds: i * 80),
          child: _buildRideCard(_rides[i]),
        ),
      ),
    );
  }

  Widget _buildRideCard(dynamic trip) {
    final rawPrice = double.tryParse(
      (trip['finalPrice'] ?? trip['estimatedPrice'] ?? trip['price'] ?? 0)
          .toString()
          .replaceAll(RegExp(r'[^0-9.]'), ''),
    ) ?? 0.0;
    final commission = (rawPrice * 0.15);
    final net = rawPrice - commission;

    final pickup = trip['pickupName'] ?? trip['originName'] ??
        '${trip['pickupLat'] ?? '--'}, ${trip['pickupLng'] ?? '--'}';
    final drop = trip['dropName'] ?? trip['destinationName'] ??
        '${trip['dropLat'] ?? '--'}, ${trip['dropLng'] ?? '--'}';
    final status = (trip['status'] ?? 'COMPLETED').toString();
    final date = _formatDate(trip['requestedAt'] ?? trip['createdAt']);

    final driverMap = trip['driver'];
    final driverName = driverMap is Map
        ? '${driverMap['firstName'] ?? ''} ${driverMap['lastName'] ?? ''}'.trim()
        : (trip['driverName'] ?? 'Captain');

    final passengerMap = trip['passenger'];
    final passengerName = passengerMap is Map
        ? '${passengerMap['firstName'] ?? ''} ${passengerMap['lastName'] ?? ''}'.trim()
        : 'Passenger';

    Color statusColor;
    IconData statusIcon;
    switch (status.toUpperCase()) {
      case 'COMPLETED': statusColor = const Color(0xFF22C55E); statusIcon = Icons.check_circle_rounded; break;
      case 'CANCELLED': statusColor = Colors.red; statusIcon = Icons.cancel_rounded; break;
      case 'ACCEPTED':  statusColor = const Color(0xFF3B82F6); statusIcon = Icons.directions_car_rounded; break;
      default:          statusColor = Colors.orange; statusIcon = Icons.access_time_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.07)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 14, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          // Status bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.07),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  Icon(statusIcon, color: statusColor, size: 16),
                  const SizedBox(width: 6),
                  Text(status, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
                ]),
                Text(date, style: const TextStyle(color: Colors.black38, fontSize: 11)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Route
                Row(children: [
                  const Icon(Icons.trip_origin, color: Color(0xFF22C55E), size: 16),
                  const SizedBox(width: 10),
                  Expanded(child: Text(pickup, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
                ]),
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Container(width: 1, height: 12, color: Colors.black12),
                ),
                Row(children: [
                  const Icon(Icons.location_on, color: Colors.redAccent, size: 16),
                  const SizedBox(width: 10),
                  Expanded(child: Text(drop, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
                ]),
                const SizedBox(height: 14),

                // Driver & Passenger info
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(children: [
                        const Icon(Icons.person_outline, size: 14, color: Colors.black54),
                        const SizedBox(width: 4),
                        Text(driverName.isEmpty ? passengerName : driverName, style: const TextStyle(fontSize: 12, color: Colors.black87)),
                      ]),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 12),

                // Earnings breakdown
                if (rawPrice > 0) ...[
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Total Fare', style: TextStyle(fontSize: 12, color: Colors.black45)),
                    Text('${_fmt(rawPrice)} IQD', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
                  ]),
                  const SizedBox(height: 4),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Commission (15%)', style: TextStyle(fontSize: 12, color: Colors.redAccent)),
                    Text('- ${_fmt(commission)} IQD', style: const TextStyle(fontSize: 12, color: Colors.redAccent, fontWeight: FontWeight.bold)),
                  ]),
                  const SizedBox(height: 4),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Your Net', style: TextStyle(fontSize: 13, color: Color(0xFF22C55E), fontWeight: FontWeight.bold)),
                    Text('+ ${_fmt(net)} IQD', style: const TextStyle(fontSize: 15, color: Color(0xFF22C55E), fontWeight: FontWeight.w900)),
                  ]),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduledList() {
    if (_scheduledTrips.isEmpty) return _emptyState('No scheduled trips yet', Icons.calendar_today_outlined);
    return RefreshIndicator(
      color: AppColors.primaryOrange,
      onRefresh: _fetchHistory,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 30),
        itemCount: _scheduledTrips.length,
        itemBuilder: (ctx, i) => FadeInUp(
          delay: Duration(milliseconds: i * 80),
          child: _buildScheduledCard(_scheduledTrips[i]),
        ),
      ),
    );
  }

  Widget _buildScheduledCard(dynamic trip) {
    final from = trip['originName']?.toString() ?? '--';
    final to = trip['destinationName']?.toString() ?? '--';
    final status = (trip['status'] ?? 'SCHEDULED').toString();
    final date = _formatDate(trip['departureTime'] ?? trip['createdAt']);
    final price = _fmt(trip['price']);
    final seats = trip['seatsBooked']?.toString() ?? '1';

    Color statusColor;
    switch (status.toUpperCase()) {
      case 'COMPLETED':   statusColor = const Color(0xFF22C55E); break;
      case 'CANCELLED':   statusColor = Colors.red; break;
      case 'IN_PROGRESS': statusColor = AppColors.primaryOrange; break;
      default:            statusColor = const Color(0xFF3B82F6);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.07)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 14, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.07),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                  child: Text(status, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                Text(date, style: const TextStyle(color: Colors.black38, fontSize: 11)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.trip_origin, color: AppColors.primaryOrange, size: 16),
                  const SizedBox(width: 10),
                  Expanded(child: Text(from, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis)),
                ]),
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Container(width: 1, height: 12, color: Colors.black12),
                ),
                Row(children: [
                  const Icon(Icons.location_on, color: Color(0xFF3B82F6), size: 16),
                  const SizedBox(width: 10),
                  Expanded(child: Text(to, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis)),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  _pill(Icons.event_seat_outlined, '$seats seat(s)'),
                  const SizedBox(width: 8),
                  const Spacer(),
                  Text('$price IQD', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.primaryOrange)),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: Colors.black54),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.black87)),
      ]),
    );
  }

  Widget _emptyState(String msg, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFFEDD5), width: 2),
            ),
            child: Icon(icon, size: 44, color: AppColors.primaryOrange),
          ),
          const SizedBox(height: 16),
          Text(msg, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black87)),
          const SizedBox(height: 8),
          const Text('Complete rides to see them here', style: TextStyle(fontSize: 13, color: Colors.black45)),
        ],
      ),
    );
  }
}
