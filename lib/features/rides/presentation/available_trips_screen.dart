import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_service.dart';
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
  List<Map<String, dynamic>> _tripsList = [];

  final List<Map<String, dynamic>> _tripsFallback = [
    {'id': 'trip_1', 'name': 'Ahmed Muhammad', 'time': 'Now', 'from': 'Kirkuk', 'to': 'Baghdad', 'price': '25,000 IQD', 'phone': '0770 123 4567'},
    {'id': 'trip_2', 'name': 'Ahmed Yasin', 'time': 'Today 2:00 PM', 'from': 'Kirkuk', 'to': 'Erbil', 'price': '15,000 IQD', 'phone': '0771 987 6543'},
    {'id': 'trip_3', 'name': 'Muhammad Ali', 'time': 'Today 4:30 PM', 'from': 'Erbil', 'to': 'Basra', 'price': '45,000 IQD', 'phone': '0750 456 7890'},
    {'id': 'trip_4', 'name': 'Jamila Ali', 'time': 'Now', 'from': 'Kirkuk', 'to': 'Sulaymaniyah', 'price': '20,000 IQD', 'phone': '0780 112 2334'},
    {'id': 'trip_5', 'name': 'Amir Ahmed', 'time': 'Tomorrow 10:00 AM', 'from': 'Baghdad', 'to': 'Najaf', 'price': '30,000 IQD', 'phone': '0772 334 4556'},
  ];

  final List<Map<String, dynamic>> _tripsOutsideFallback = [
    {'id': 'trip_out_1', 'name': 'Ahmed Muhammad', 'time': 'Now', 'from': 'IRAQ', 'to': 'QATAR', 'price': '150,000 IQD', 'phone': '0770 123 4567'},
    {'id': 'trip_out_2', 'name': 'Ahmed Yasin', 'time': 'Tomorrow', 'from': 'IRAQ', 'to': 'UAE', 'price': '200,000 IQD', 'phone': '0771 987 6543'},
    {'id': 'trip_out_3', 'name': 'Muhammad Ali', 'time': 'Friday', 'from': 'IRAQ', 'to': 'KSA', 'price': '180,000 IQD', 'phone': '0750 456 7890'},
    {'id': 'trip_out_4', 'name': 'Jamila Ali', 'time': 'Saturday', 'from': 'IRAQ', 'to': 'Oman', 'price': '220,000 IQD', 'phone': '0780 112 2334'},
    {'id': 'trip_out_5', 'name': 'Amir Ahmed', 'time': 'Next Week', 'from': 'IRAQ', 'to': 'Kuwait', 'price': '140,000 IQD', 'phone': '0772 334 4556'},
  ];

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    final api = Provider.of<ApiService>(context, listen: false);
    try {
      final res = await api.getAvailableTrips();
      if (res.statusCode == 200 && res.data['trips'] != null && (res.data['trips'] as List).isNotEmpty) {
        final List<dynamic> raw = res.data['trips'];
        setState(() {
          _tripsList = raw.map<Map<String, dynamic>>((t) => {
            'id': t['id']?.toString() ?? 'trip',
            'name': '${t['driver']?['firstName'] ?? 'Passenger'} ${t['driver']?['lastName'] ?? ''}'.trim(),
            'time': 'Scheduled',
            'from': t['fromGovernorate']?['name'] ?? 'Kirkuk',
            'to': t['toGovernorate']?['name'] ?? 'Baghdad',
            'price': '${t['pricePerSeat'] ?? 25000} IQD',
            'phone': t['driver']?['phone'] ?? '07xx xxx xxxx',
          }).toList();
          _isLoading = false;
        });
        return;
      }
    } catch (e) {
      debugPrint('Load trips note: $e');
    }

    setState(() {
      _tripsList = widget.isOutsideIraq ? List.from(_tripsOutsideFallback) : List.from(_tripsFallback);
      _isLoading = false;
    });
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
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Text(
              widget.isOutsideIraq ? 'Passenger requests outside IRAQ' : 'Available Trip Requests',
              style: const TextStyle(
                color: AppColors.primaryOrange,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryOrange))
                : RefreshIndicator(
                    color: AppColors.primaryOrange,
                    onRefresh: _loadTrips,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
                      itemCount: _tripsList.length,
                      itemBuilder: (context, index) {
                        final trip = _tripsList[index];
                        bool isExpanded = expandedIndex == index;

                        return FadeInUp(
                          delay: Duration(milliseconds: index * 100),
                          child: GestureDetector(
                            onTap: () => setState(() => expandedIndex = isExpanded ? null : index),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.black.withOpacity(0.08)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.06),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 54,
                                        height: 54,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppColors.primaryOrange.withOpacity(0.12),
                                        ),
                                        child: const Icon(Icons.person, size: 34, color: AppColors.primaryOrange),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              trip['name'] ?? 'Passenger',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              trip['time'] ?? 'Now',
                                              style: const TextStyle(color: Colors.black45, fontSize: 11, fontWeight: FontWeight.w500),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'from ${trip['from']} to ${trip['to']}',
                                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        trip['price'] ?? '',
                                        style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primaryOrange, fontSize: 13),
                                      ),
                                      const SizedBox(width: 6),
                                      Icon(
                                        isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                        color: AppColors.primaryOrange,
                                        size: 26,
                                      ),
                                    ],
                                  ),
                                  if (isExpanded)
                                    FadeIn(
                                      child: Padding(
                                        padding: const EdgeInsets.only(top: 16),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: _buildActionButton(
                                                'Accept & Start', 
                                                const Color(0xFF65CA28),
                                                onPressed: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) => TripOngoingScreen(tripData: trip),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: _buildActionButton(
                                                'Decline', 
                                                const Color(0xFFFF1717),
                                                onPressed: () {
                                                  setState(() {
                                                    _tripsList.removeAt(index);
                                                    expandedIndex = null;
                                                  });
                                                },
                                              ),
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
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, Color color, {required VoidCallback onPressed}) {
    return SizedBox(
      height: 46,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(
          label,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ),
    );
  }
}

