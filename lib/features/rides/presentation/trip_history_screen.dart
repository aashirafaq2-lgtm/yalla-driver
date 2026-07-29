import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../../../core/theme/app_colors.dart';

class TripHistoryScreen extends StatelessWidget {
  const TripHistoryScreen({super.key});

  final _trips = const [
    {'price': '10,000 IQD', 'date': 'Feb 14 Saturday noon ride', 'from': 'Kirkuk, ...', 'to': 'Erbil, ...'},
    {'price': '10,000 IQD', 'date': 'Feb 14 Saturday noon ride', 'from': 'Kirkuk, ...', 'to': 'Erbil, ...'},
    {'price': '10,000 IQD', 'date': 'Feb 14 Saturday noon ride', 'from': 'Kirkuk, ...', 'to': 'Erbil, ...'},
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
          'Trips',
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
                  children: [
                    // ── Map Thumbnail ────────────────────────────────
                    SizedBox(
                      height: 140,
                      width: double.infinity,
                      child: Image.network(
                        'https://staticmapmaker.com/img/google.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFFE8EAE6),
                          child: const Center(child: Icon(Icons.map_outlined, size: 40, color: Colors.grey)),
                        ),
                      ),
                    ),
                    // ── Info ─────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                trip['price']!,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black),
                              ),
                              Text(
                                trip['date']!,
                                style: const TextStyle(color: Colors.black38, fontSize: 11, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(Icons.location_on, color: Colors.blue, size: 15),
                              const SizedBox(width: 6),
                              Text(trip['from']!, style: const TextStyle(fontSize: 13, color: Colors.black87)),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              const Icon(Icons.location_on, color: Colors.red, size: 15),
                              const SizedBox(width: 6),
                              Text(trip['to']!, style: const TextStyle(fontSize: 13, color: Colors.black87)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
