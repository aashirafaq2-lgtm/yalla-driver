import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../../core/theme/app_colors.dart';

class TripOngoingScreen extends StatefulWidget {
  final Map<String, String> tripData;
  const TripOngoingScreen({super.key, required this.tripData});

  @override
  State<TripOngoingScreen> createState() => _TripOngoingScreenState();
}

class _TripOngoingScreenState extends State<TripOngoingScreen> {
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
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 32),
            ),
            Text(
              'يَلَّا',
              style: TextStyle(color: AppColors.primaryOrange.withOpacity(0.8), fontWeight: FontWeight.bold, fontSize: 32),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          // ── Background Map (Mock Live) ──────────────────────────────
          Positioned.fill(
            child: Container(
              color: const Color(0xFFF1F1F1),
              child: Stack(
                children: [
                  // Mock Map Background
                  Image.network(
                    'https://images.unsplash.com/photo-1526778548025-fa2f459cd5c1?q=80&w=1500', // Map-like aerial view
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    color: Colors.white.withOpacity(0.6),
                    colorBlendMode: BlendMode.lighten,
                  ),
                  // Mock Route Line
                  CustomPaint(
                    size: Size.infinite,
                    painter: RoutePainter(),
                  ),
                  // Car Marker (Mock Live)
                  const Center(
                    child: PulseMarker(),
                  ),
                ],
              ),
            ),
          ),
          
          // ── Trip Details Overlay ──────────────────────────────
          Align(
            alignment: Alignment.bottomCenter,
            child: FadeInUp(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, -5)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle for aesthetic
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey.withOpacity(0.1),
                          ),
                          child: const Icon(Icons.person, size: 45, color: AppColors.primaryOrange),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.tripData['name']!,
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.star, color: Colors.amber, size: 16),
                                  const SizedBox(width: 4),
                                  const Text('4.9', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  const SizedBox(width: 10),
                                  Text(
                                    widget.tripData['time']!,
                                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.phone, color: Colors.green, size: 28),
                            onPressed: () {},
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 35),
                    _buildInfoRow(Icons.location_on, 'Pickup', widget.tripData['from']!),
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.flag, 'Drop-off', widget.tripData['to']!),
                    const SizedBox(height: 25),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 60,
                            child: ElevatedButton(
                              onPressed: () {
                                _showCompletionDialog(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryOrange,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              ),
                              child: const Text(
                                'Finish Trip',
                                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Icon(Icons.navigation, color: Colors.white, size: 30),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryOrange, size: 22),
        const SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }

  void _showCompletionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Center(child: Text('Trip Completed!')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: 20),
            const Text('You have successfully finished the trip.', textAlign: TextAlign.center),
            const SizedBox(height: 15),
            Text('Amount: 25,000 IQD', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primaryOrange)),
          ],
        ),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // dialog
                  Navigator.of(context).pop(); // ongoing screen
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                  minimumSize: const Size(180, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Back to Home', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PulseMarker extends StatefulWidget {
  const PulseMarker({super.key});

  @override
  State<PulseMarker> createState() => _PulseMarkerState();
}

class _PulseMarkerState extends State<PulseMarker> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 100 * _controller.value,
              height: 100 * _controller.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryOrange.withOpacity(1 - _controller.value),
              ),
            ),
            Container(
              width: 25,
              height: 25,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryOrange,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
              ),
              child: const Icon(Icons.directions_car, color: Colors.white, size: 14),
            ),
          ],
        );
      },
    );
  }
}

class RoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primaryOrange.withOpacity(0.4)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(size.width * 0.2, size.height * 0.8)
      ..quadraticBezierTo(size.width * 0.5, size.height * 0.7, size.width * 0.5, size.height * 0.5)
      ..lineTo(size.width * 0.8, size.height * 0.2);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
