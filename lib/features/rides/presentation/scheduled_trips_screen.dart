import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../../core/theme/app_colors.dart';

class ScheduledTripsScreen extends StatefulWidget {
  const ScheduledTripsScreen({super.key});

  @override
  State<ScheduledTripsScreen> createState() => _ScheduledTripsScreenState();
}

class _ScheduledTripsScreenState extends State<ScheduledTripsScreen> {
  final List<Map<String, String>> _trips = [
    {
      'price': '10,000 IQD - All seats are available',
      'date': 'Feb 14 Saturday noon ride',
      'from': 'Kirkuk, ...',
      'to': 'Erbil, ...'
    },
    {
      'price': '- 2 passengers',
      'date': 'Feb 14 Saturday noon ride',
      'from': 'Kirkuk, ...',
      'to': 'Erbil, ...'
    },
  ];

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
        title: const Text(
          'My schedule trip',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 30),
        itemCount: _trips.length,
        itemBuilder: (context, index) {
          final trip = _trips[index];
          return FadeInUp(
            delay: Duration(milliseconds: index * 150),
            child: Container(
              margin: const EdgeInsets.only(bottom: 20),
              child: Dismissible(
                key: Key('trip_$index'),
                direction: DismissDirection.endToStart,
                onDismissed: (direction) {
                  setState(() => _trips.removeAt(index));
                },
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 25),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF4848),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.delete_outline, color: Colors.white, size: 35),
                ),
                child: GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/schedule_trip_info'),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.black.withOpacity(0.07)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Map Thumbnail ────────────────────────────────
                          SizedBox(
                            height: 140,
                            width: double.infinity,
                            child: Image.network(
                              'https://images.unsplash.com/photo-1524661135-423995f22d0b?q=80&w=800',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: const Color(0xFFE8EAE6),
                                child: const Center(child: Icon(Icons.map_outlined, size: 40, color: Colors.grey)),
                              ),
                            ),
                          ),
                          // ── Info Section ───────────────────────────────
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        trip['price']!,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black),
                                      ),
                                    ),
                                    Text(
                                      trip['date']!,
                                      style: const TextStyle(color: Colors.black38, fontSize: 10, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on, color: Color(0xFFFF4848), size: 16),
                                    const SizedBox(width: 8),
                                    Text(trip['from']!, style: const TextStyle(fontSize: 13, color: Colors.black)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on, color: Color(0xFF488DFF), size: 16),
                                    const SizedBox(width: 8),
                                    Text(trip['to']!, style: const TextStyle(fontSize: 13, color: Colors.black)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
