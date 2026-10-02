import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/theme/app_colors.dart';

enum ParcelDeliveryStep { pickingUp, inTransit, delivered }

class ParcelActiveDeliveryScreen extends StatefulWidget {
  final Map<String, dynamic> orderData;
  const ParcelActiveDeliveryScreen({super.key, required this.orderData});

  @override
  State<ParcelActiveDeliveryScreen> createState() => _ParcelActiveDeliveryScreenState();
}

class _ParcelActiveDeliveryScreenState extends State<ParcelActiveDeliveryScreen> {
  final MapController _mapController = MapController();
  ParcelDeliveryStep _step = ParcelDeliveryStep.pickingUp;
  bool _isProcessing = false;
  bool _gpsReady = false;

  // Baghdad coordinates as default; would be real coordinates from order
  LatLng _driverPos = const LatLng(33.3152, 44.3661);
  LatLng _pickupPos = const LatLng(33.3200, 44.3500);
  LatLng _dropPos = const LatLng(33.3000, 44.4000);
  StreamSubscription<Position>? _positionSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initGps();
    });
  }

  void _initGps() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.deniedForever) {
        setState(() => _gpsReady = true);
        return;
      }

      try {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        ).timeout(const Duration(seconds: 6));
        if (mounted) {
          final realPos = LatLng(pos.latitude, pos.longitude);
          setState(() { _driverPos = realPos; _gpsReady = true; });
          _mapController.move(realPos, 14.0);
        }
      } catch (_) {
        setState(() => _gpsReady = true);
      }

      _positionSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10),
      ).listen((pos) {
        if (!mounted) return;
        final realPos = LatLng(pos.latitude, pos.longitude);
        setState(() { _driverPos = realPos; });
        _mapController.move(realPos, _mapController.camera.zoom);
      });
    } catch (_) {
      setState(() => _gpsReady = true);
    }
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    super.dispose();
  }

  String _getStepLabel() {
    switch (_step) {
      case ParcelDeliveryStep.pickingUp:
        return 'Pick Up Package';
      case ParcelDeliveryStep.inTransit:
        return 'Deliver Package';
      case ParcelDeliveryStep.delivered:
        return 'Delivery Confirmed';
    }
  }

  Color _getStepColor() {
    switch (_step) {
      case ParcelDeliveryStep.pickingUp:
        return AppColors.primaryOrange;
      case ParcelDeliveryStep.inTransit:
        return const Color(0xFF2563EB);
      case ParcelDeliveryStep.delivered:
        return const Color(0xFF16A34A);
    }
  }

  Future<void> _handleAction() async {
    if (_isProcessing || _step == ParcelDeliveryStep.delivered) return;
    setState(() => _isProcessing = true);

    await Future.delayed(const Duration(milliseconds: 800)); // simulate API call

    if (!mounted) return;

    if (_step == ParcelDeliveryStep.pickingUp) {
      setState(() { _step = ParcelDeliveryStep.inTransit; _isProcessing = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Package picked up! Navigate to delivery address.'), backgroundColor: Color(0xFF2563EB)),
      );
    } else if (_step == ParcelDeliveryStep.inTransit) {
      _showDeliveryConfirmDialog();
      setState(() => _isProcessing = false);
    }
  }

  void _showDeliveryConfirmDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        contentPadding: const EdgeInsets.all(28),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: const Color(0xFF16A34A).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.inventory_2_outlined, color: Color(0xFF16A34A), size: 40),
            ),
            const SizedBox(height: 18),
            Text(
              'Confirm Delivery',
              style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Has the package been successfully delivered to the recipient?',
              style: GoogleFonts.inter(color: Colors.black54, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: Text('Not Yet', style: GoogleFonts.outfit(color: Colors.black87, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      setState(() => _step = ParcelDeliveryStep.delivered);
                      _showDeliverySuccessDialog();
                    },
                    child: Text('Delivered!', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDeliverySuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(28),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF16A34A).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 60),
            ),
            const SizedBox(height: 18),
            Text(
              'Delivery Complete!',
              style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Package ${widget.orderData['id'] ?? '#001'} delivered successfully.',
              style: GoogleFonts.inter(color: Colors.black54, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF16A34A).withOpacity(0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Delivery Earnings', style: GoogleFonts.inter(color: Colors.black54, fontSize: 13)),
                  Text('+5,000 IQD', style: GoogleFonts.outfit(color: const Color(0xFF16A34A), fontWeight: FontWeight.w900, fontSize: 17)),
                ],
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black87,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context); // back to mail/parcels list
                },
                child: Text('Back to Orders', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderType = widget.orderData['type'] ?? 'Parcel';
    final orderId = widget.orderData['id'] ?? '#001';
    final fromCity = widget.orderData['from'] ?? 'Kirkuk';
    final toCity = widget.orderData['to'] ?? 'Baghdad';
    final count = widget.orderData['count'] ?? '1x Package';
    final recipientName = widget.orderData['recipientName'] ?? 'Ahmed';
    final recipientPhone = widget.orderData['recipientPhone'] ?? '07700000000';

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
            const Text('Yalla ', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 26)),
            Text('يَلَّا', style: TextStyle(color: AppColors.primaryOrange, fontWeight: FontWeight.bold, fontSize: 26)),
          ],
        ),
      ),
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _driverPos,
              initialZoom: 13.5,
              interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.yalla.driver',
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: [_driverPos, _step == ParcelDeliveryStep.pickingUp ? _pickupPos : _dropPos],
                    color: _getStepColor(),
                    strokeWidth: 4,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  // Pickup (orange package)
                  Marker(
                    point: _pickupPos,
                    width: 40, height: 40,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primaryOrange,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                      ),
                      child: const Icon(Icons.inventory_2_outlined, color: Colors.white, size: 20),
                    ),
                  ),
                  // Driver (car)
                  Marker(
                    point: _driverPos,
                    width: 50, height: 50,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, 3))],
                      ),
                      child: const Icon(Icons.local_shipping, color: Colors.white, size: 24),
                    ),
                  ),
                  // Drop (destination pin)
                  Marker(
                    point: _dropPos,
                    width: 36, height: 36,
                    child: Container(
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)]),
                      child: const Icon(Icons.home_outlined, color: Colors.red, size: 22),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // GPS loading
          if (!_gpsReady)
            Positioned(
              top: 12, left: 0, right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(20)),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                      SizedBox(width: 8),
                      Text('Getting your location...', style: TextStyle(color: Colors.white, fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ),

          // Step banner
          Positioned(
            top: _gpsReady ? 12 : 50,
            left: 16, right: 16,
            child: FadeInDown(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: _getStepColor(),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8)],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _step == ParcelDeliveryStep.pickingUp ? Icons.inventory_2_outlined :
                      _step == ParcelDeliveryStep.inTransit ? Icons.local_shipping : Icons.check_circle,
                      color: Colors.white, size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _step == ParcelDeliveryStep.pickingUp ? '📦 Go pick up the package' :
                      _step == ParcelDeliveryStep.inTransit ? '🚚 Delivering to $toCity' : '✅ Delivery complete',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom card
          Align(
            alignment: Alignment.bottomCenter,
            child: FadeInUp(
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, -5))],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40, height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                    ),
                    // Order header row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primaryOrange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            widget.orderData['isMail'] == true ? Icons.mail_outline : Icons.inventory_2_outlined,
                            color: AppColors.primaryOrange, size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Order $orderId', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 17)),
                              Text('$count · $orderType', style: GoogleFonts.inter(color: Colors.black45, fontSize: 13)),
                            ],
                          ),
                        ),
                        // Call recipient
                        IconButton(
                          icon: const Icon(Icons.call_outlined, color: Colors.black87),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: recipientPhone));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Copied: $recipientPhone')),
                            );
                          },
                        ),
                      ],
                    ),
                    const Divider(height: 22),
                    // Route info
                    Row(
                      children: [
                        Column(
                          children: [
                            const Icon(Icons.trip_origin, color: Colors.green, size: 18),
                            Container(height: 20, width: 2, color: Colors.grey.shade300),
                            const Icon(Icons.location_on, color: Colors.red, size: 18),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('From: $fromCity', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
                              const SizedBox(height: 14),
                              Text('To: $toCity · $recipientName', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    // Action button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: (_step == ParcelDeliveryStep.delivered || _isProcessing) ? null : _handleAction,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _getStepColor(),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 3,
                        ),
                        child: _isProcessing
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(_getStepLabel(), style: GoogleFonts.outfit(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                      ),
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
}
