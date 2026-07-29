import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../../core/theme/app_colors.dart';
import 'trip_ongoing_screen.dart';

class AvailableTripsScreen extends StatefulWidget {
  final bool isOutsideIraq;
  const AvailableTripsScreen({super.key, this.isOutsideIraq = false});

  @override
  State<AvailableTripsScreen> createState() => _AvailableTripsScreenState();
}

class _AvailableTripsScreenState extends State<AvailableTripsScreen> {
  int? expandedIndex;

  final List<Map<String, String>> trips = [
    {'name': 'Ahmed Muhammad', 'time': 'Now', 'from': 'Kirkuk', 'to': 'Baghdad'},
    {'name': 'ahmed yasin', 'time': 'Feb 14 Saturday noon ride', 'from': 'Kirkuk', 'to': 'Baghdad'},
    {'name': 'Muhammad', 'time': 'Feb 17 Saturday noon ride', 'from': 'Erbil', 'to': 'Basra'},
    {'name': 'Jamila Ali', 'time': 'Now', 'from': 'Kirkuk', 'to': 'Baghdad'},
    {'name': 'Amir ahmed', 'time': 'Feb 14 Saturday noon ride', 'from': 'Kirkuk', 'to': 'Baghdad'},
  ];

  final List<Map<String, String>> tripsOutside = [
    {'name': 'Ahmed Muhammad', 'time': 'Now', 'from': 'IRAQ', 'to': 'QATAR'},
    {'name': 'ahmed yasin', 'time': 'Feb 14 Saturday noon ride', 'from': 'IRAQ', 'to': 'UAE'},
    {'name': 'Muhammad', 'time': 'Feb 17 Saturday noon ride', 'from': 'IRAQ', 'to': 'KSA'},
    {'name': 'Jamila Ali', 'time': 'Now', 'from': 'IRAQ', 'to': 'Oman'},
    {'name': 'Amir ahmed', 'time': 'Feb 14 Saturday noon ride', 'from': 'IRAQ', 'to': 'Kuwait'},
  ];

  @override
  Widget build(BuildContext context) {
    final currentTrips = widget.isOutsideIraq ? tripsOutside : trips;

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
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 32),
            ),
            Text(
              'يَلَّا',
              style: TextStyle(color: AppColors.primaryOrange.withOpacity(0.8), fontWeight: FontWeight.bold, fontSize: 32),
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
              widget.isOutsideIraq ? 'New passenger request outside IRAQ' : 'New passenger request',
              style: const TextStyle(
                color: AppColors.primaryOrange,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
              itemCount: currentTrips.length,
              itemBuilder: (context, index) {
                final trip = currentTrips[index];
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
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black.withOpacity(0.08)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              // ── Person Avatar ──────────────────────────────
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.grey.withOpacity(0.2),
                                ),
                                child: const Icon(Icons.person, size: 40, color: AppColors.primaryOrange),
                              ),
                              const SizedBox(width: 16),
                              // ── Trip Details ──────────────────────────────
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      trip['name']!,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      trip['time']!,
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
                              // ── Check Icon/Chevron ──────────────────────────
                              Icon(
                                isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                color: AppColors.primaryOrange,
                                size: 28,
                              ),
                            ],
                          ),
                          // ── Action Buttons (When expanded) ─────────────
                          if (isExpanded)
                            FadeIn(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 20),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _buildActionButton(
                                        'Accept', 
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
                                        'Reject', 
                                        const Color(0xFFFF1717),
                                        onPressed: () {
                                          setState(() {
                                            currentTrips.removeAt(index);
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
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, Color color, {required VoidCallback onPressed}) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(
          label,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }
}
