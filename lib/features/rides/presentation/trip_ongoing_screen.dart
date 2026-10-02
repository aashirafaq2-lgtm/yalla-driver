import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/socket_service.dart';
import '../../../core/network/api_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/driver_locale_provider.dart';
import '../../profile/presentation/chat_screen.dart';

enum RideProgressStep { drivingToPickup, arrivedAtPickup, inProgress, completed }

class TripOngoingScreen extends StatefulWidget {
  final Map<String, dynamic> tripData;
  const TripOngoingScreen({super.key, required this.tripData});

  @override
  State<TripOngoingScreen> createState() => _TripOngoingScreenState();
}

class _TripOngoingScreenState extends State<TripOngoingScreen> {
  final MapController _mapController = MapController();
  RideProgressStep _step = RideProgressStep.drivingToPickup;

  late LatLng _pickupPos;
  late LatLng _dropPos;
  // Start with null until we get real GPS; fallback to pickup as visual placeholder
  LatLng? _driverPos;
  StreamSubscription<Position>? _positionSub;
  bool _isProcessing = false;
  bool _gpsReady = false;

  @override
  void initState() {
    super.initState();
    final pLat = double.tryParse(widget.tripData['pickupLat']?.toString() ?? '') ?? 33.3152;
    final pLng = double.tryParse(widget.tripData['pickupLng']?.toString() ?? '') ?? 44.3661;
    final dLat = double.tryParse(widget.tripData['dropLat']?.toString() ?? '') ?? 33.3000;
    final dLng = double.tryParse(widget.tripData['dropLng']?.toString() ?? '') ?? 44.3800;

    _pickupPos = LatLng(pLat, pLng);
    _dropPos = LatLng(dLat, dLng);
    // Don't set _driverPos here – wait for real GPS

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startLiveGpsTracking();
      _joinRideRoom();
    });
  }

  void _joinRideRoom() {
    final socket = Provider.of<SocketService>(context, listen: false);
    final rideId = (widget.tripData['id'] ?? widget.tripData['rideId'] ?? 'active_ride').toString();
    socket.joinRide(rideId);
  }

  void _startLiveGpsTracking() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        // fallback to pickup location
        if (mounted) {
          setState(() {
            _driverPos = _pickupPos;
            _gpsReady = true;
          });
          _mapController.move(_pickupPos, 14.5);
        }
        return;
      }

      // Get immediate position first (no waiting for stream)
      try {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        ).timeout(const Duration(seconds: 6));
        if (mounted) {
          final realPos = LatLng(pos.latitude, pos.longitude);
          setState(() {
            _driverPos = realPos;
            _gpsReady = true;
          });
          _mapController.move(realPos, 14.5);
          _broadcastLocation(pos);
        }
      } catch (_) {
        // If immediate position fails, fallback to pickup temporarily
        if (mounted) {
          setState(() {
            _driverPos = _pickupPos;
            _gpsReady = true;
          });
        }
      }

      // Then subscribe to live updates
      _positionSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 8),
      ).listen((pos) {
        if (!mounted) return;
        final realPos = LatLng(pos.latitude, pos.longitude);
        setState(() {
          _driverPos = realPos;
          _gpsReady = true;
        });
        // Auto follow driver on map
        _mapController.move(realPos, _mapController.camera.zoom);
        _broadcastLocation(pos);
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _driverPos = _pickupPos;
          _gpsReady = true;
        });
      }
    }
  }

  void _broadcastLocation(Position pos) {
    final socket = Provider.of<SocketService>(context, listen: false);
    final rideId = (widget.tripData['id'] ?? widget.tripData['rideId'] ?? 'active_ride').toString();
    socket.updateLocation(
      pos.latitude,
      pos.longitude,
      activeRideId: rideId,
      heading: pos.heading,
      speed: pos.speed,
    );
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    super.dispose();
  }

  String _getStepButtonLabel(bool isArabic) {
    switch (_step) {
      case RideProgressStep.drivingToPickup:
        return isArabic ? 'وصلت لنقطة الانطلاق' : 'Arrived at Pickup';
      case RideProgressStep.arrivedAtPickup:
        return isArabic ? 'تأكيد الرمز وبدء الرحلة' : 'Verify PIN & Start Trip';
      case RideProgressStep.inProgress:
        return isArabic ? 'إنهاء الرحلة' : 'Finish Trip';
      case RideProgressStep.completed:
        return isArabic ? 'اكتملت الرحلة' : 'Trip Completed';
    }
  }

  Future<void> _handleStepAction() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    final socket = Provider.of<SocketService>(context, listen: false);
    final api = Provider.of<ApiService>(context, listen: false);
    final storage = Provider.of<StorageService>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final token = await storage.getToken();

    final rideId = (widget.tripData['id'] ?? widget.tripData['rideId'] ?? 'active_ride').toString();
    final currentDriverPos = _driverPos ?? _pickupPos;

    try {
      if (_step == RideProgressStep.drivingToPickup) {
        // Only warn if GPS is confirmed real and far away
        if (_gpsReady) {
          double distanceInMeters = Geolocator.distanceBetween(
            currentDriverPos.latitude,
            currentDriverPos.longitude,
            _pickupPos.latitude,
            _pickupPos.longitude,
          );

          if (distanceInMeters > 500) {
            final isArabic = Provider.of<DriverLocaleProvider>(context, listen: false).isArabic;
            final distKm = (distanceInMeters / 1000).toStringAsFixed(1);

            bool? proceed = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                title: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
                    const SizedBox(width: 8),
                    Flexible(child: Text(isArabic ? 'تنبيه الموقع' : 'Distance Alert', style: const TextStyle(fontWeight: FontWeight.bold))),
                  ],
                ),
                content: Text(
                  isArabic
                      ? 'أنت حالياً بعيد عن موقع الراكب بمقدار ($distKm كم). هل تريد الاستمرار؟'
                      : 'You are currently $distKm km from the passenger pickup location. Confirm arrival anyway?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(isArabic ? 'إلغاء' : 'Cancel', style: const TextStyle(color: Colors.grey)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryOrange),
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(isArabic ? 'تأكيد الوصول' : 'Confirm Arrival'),
                  ),
                ],
              ),
            );

            if (proceed != true) {
              setState(() => _isProcessing = false);
              return;
            }
          }
        }

        socket.changeStatus(rideId: rideId, status: 'ARRIVED');
        if (token != null) {
          if (widget.tripData['isTripMode'] == true) {
            await api.updateTripStatus(rideId, 'ARRIVED', token);
          } else {
            await api.updateRideStatus(rideId, 'ARRIVED', token);
          }
        }
        setState(() {
          _step = RideProgressStep.arrivedAtPickup;
          _isProcessing = false;
        });
      } else if (_step == RideProgressStep.arrivedAtPickup) {
        setState(() => _isProcessing = false);
        _showOtpVerificationDialog(rideId);
      } else if (_step == RideProgressStep.inProgress) {
        final priceStr = widget.tripData['price']?.toString().replaceAll(RegExp(r'[^0-9.]'), '') ?? '10000';
        final finalPrice = double.tryParse(priceStr) ?? 10000.0;

        socket.changeStatus(
          rideId: rideId,
          status: 'COMPLETED',
          payload: {'finalPrice': finalPrice},
        );

        if (token != null) {
          if (widget.tripData['isTripMode'] == true) {
            await api.updateTripStatus(rideId, 'COMPLETED', token);
          } else {
            await api.updateRideStatus(rideId, 'COMPLETED', token, finalPrice: finalPrice);
          }
        }

        await auth.loadProfile();

        setState(() {
          _step = RideProgressStep.completed;
          _isProcessing = false;
        });

        if (mounted) {
          _showCompletionDialog(context, finalPrice);
        }
      }
    } catch (e) {
      debugPrint('Step action note: $e');
      setState(() => _isProcessing = false);
    }
  }

  void _showOtpVerificationDialog(String rideId) {
    final locale = Provider.of<DriverLocaleProvider>(context, listen: false);
    final isArabic = locale.isArabic;
    final pinController = TextEditingController();
    String? errorMessage;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.pin_outlined, color: AppColors.primaryOrange, size: 28),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  isArabic ? 'تأكيد رمز أمان الراكب' : 'Verify Passenger PIN',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isArabic
                    ? 'اطلب رمز PIN المكون من 4 أرقام من الراكب لبدء الرحلة:'
                    : 'Ask the passenger for their 4-digit PIN code to start the trip:',
                style: GoogleFonts.inter(color: Colors.black54, fontSize: 13),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: pinController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 4,
                style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 8),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '••••',
                  hintStyle: const TextStyle(letterSpacing: 8, color: Colors.black26),
                  filled: true,
                  fillColor: const Color(0xFFF1F5F9),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  errorText: errorMessage,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(isArabic ? 'إلغاء' : 'Cancel', style: const TextStyle(color: Colors.black54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onPressed: () async {
                final otp = pinController.text.trim();
                if (otp.length < 4) {
                  setDialogState(() {
                    errorMessage = isArabic ? 'الرمز يجب أن يتكون من 4 أرقام' : 'Code must be 4 digits';
                  });
                  return;
                }

                final api = Provider.of<ApiService>(context, listen: false);
                final storage = Provider.of<StorageService>(context, listen: false);
                final socket = Provider.of<SocketService>(context, listen: false);
                final token = await storage.getToken();

                try {
                  if (token != null) {
                    if (widget.tripData['isTripMode'] == true) {
                      await api.updateTripStatus(rideId, 'IN_PROGRESS', token);
                    } else {
                      await api.verifyOtpForRide(rideId, otp, token);
                    }
                  }
                  socket.changeStatus(rideId: rideId, status: 'PICKED_UP');

                  if (mounted) {
                    Navigator.pop(ctx);
                    setState(() => _step = RideProgressStep.inProgress);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isArabic ? 'تم تأكيد الرمز وبدء الرحلة بنجاح!' : 'PIN Verified! Trip started.'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                } catch (e) {
                  setDialogState(() {
                    errorMessage = isArabic ? 'رمز التحقق غير صحيح، يرجى التأكد من الراكب' : 'Invalid PIN code. Please confirm with passenger.';
                  });
                }
              },
              child: Text(
                isArabic ? 'تحقق وبدء' : 'Verify & Start',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCompletionDialog(BuildContext context, double finalPrice) {
    final locale = Provider.of<DriverLocaleProvider>(context, listen: false);
    final isArabic = locale.isArabic;

    final commission = (finalPrice * 0.15).round();
    final driverNet = (finalPrice - commission).round();

    String formatIqd(num amount) {
      return amount.toInt().toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      );
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 54),
            ),
            const SizedBox(height: 16),
            Text(
              isArabic ? 'اكتملت الرحلة بنجاح!' : 'Trip Completed!',
              style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              isArabic ? 'تم تسجيل الأرباح في محفظتك' : 'Earnings have been credited to your wallet',
              style: GoogleFonts.inter(fontSize: 13, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black.withOpacity(0.06)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(isArabic ? 'إجمالي الأجرة' : 'Total Fare', style: GoogleFonts.inter(color: Colors.black54, fontSize: 13)),
                      Text('${formatIqd(finalPrice)} IQD', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(isArabic ? 'عمولة المنصة (15%)' : 'Platform fee (15%)', style: GoogleFonts.inter(color: Colors.black54, fontSize: 13)),
                      Text('- ${formatIqd(commission)} IQD', style: GoogleFonts.outfit(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(isArabic ? 'صافي أرباحك' : 'Your Net Earnings', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(
                        '+ ${formatIqd(driverNet)} IQD',
                        style: GoogleFonts.outfit(color: AppColors.success, fontWeight: FontWeight.w900, fontSize: 18),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
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
                  Navigator.pop(context);
                },
                child: Text(
                  isArabic ? 'العودة للرئيسية' : 'Back to Dashboard',
                  style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDriverCancelDialog(String rideId) {
    final locale = Provider.of<DriverLocaleProvider>(context, listen: false);
    final isArabic = locale.isArabic;

    final reasons = isArabic
        ? ['تعذر الوصول للراكب', 'الراكب لم يحضر لنقطة الانطلاق', 'عطل في المركبة', 'ازدحام شديد / إغلاق طريق']
        : ['Cannot reach passenger', 'Passenger no-show', 'Vehicle breakdown', 'Heavy road obstruction'];

    String selectedReason = reasons[0];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Text(
                isArabic ? 'إلغاء الرحلة' : 'Cancel Trip',
                style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                isArabic ? 'يرجى اختيار سبب الإلغاء:' : 'Please select cancellation reason:',
                style: GoogleFonts.inter(color: Colors.black54, fontSize: 13),
              ),
              const SizedBox(height: 16),
              ...reasons.map((r) => RadioListTile<String>(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(r, style: GoogleFonts.inter(fontSize: 14)),
                    value: r,
                    groupValue: selectedReason,
                    activeColor: AppColors.primaryOrange,
                    onChanged: (val) {
                      if (val != null) setSheetState(() => selectedReason = val);
                    },
                  )),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(isArabic ? 'رجوع' : 'Dismiss', style: const TextStyle(color: Colors.black87)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        final api = Provider.of<ApiService>(context, listen: false);
                        final storage = Provider.of<StorageService>(context, listen: false);
                        final token = await storage.getToken();

                        if (token != null) {
                          try {
                            if (widget.tripData['isTripMode'] == true) {
                              await api.cancelTripById(rideId, token);
                            } else {
                              await api.cancelRide(rideId, selectedReason, token);
                            }
                          } catch (e) {
                            debugPrint('Cancel ride note: $e');
                          }
                        }

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isArabic ? 'تم إلغاء الرحلة' : 'Trip cancelled'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          Navigator.pop(context);
                        }
                      },
                      child: Text(
                        isArabic ? 'تأكيد الإلغاء' : 'Confirm Cancel',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  void _showPassengerPhoneDialog(String name, String phone) {
    final locale = Provider.of<DriverLocaleProvider>(context, listen: false);
    final isArabic = locale.isArabic;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(isArabic ? 'الاتصال بالراكب' : 'Call Passenger', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.primaryOrange.withOpacity(0.15),
              child: const Icon(Icons.phone, color: AppColors.primaryOrange, size: 30),
            ),
            const SizedBox(height: 16),
            Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 6),
            Text(phone, style: const TextStyle(color: Colors.black54, fontSize: 16, letterSpacing: 1)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isArabic ? 'إلغاء' : 'Close', style: const TextStyle(color: Colors.black54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: phone));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(isArabic ? 'تم نسخ رقم الهاتف: $phone' : 'Copied phone: $phone')),
              );
            },
            child: Text(isArabic ? 'نسخ الرقم' : 'Copy Number', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Color _getStepColor() {
    switch (_step) {
      case RideProgressStep.drivingToPickup:
        return AppColors.primaryOrange;
      case RideProgressStep.arrivedAtPickup:
        return const Color(0xFF1E3A5F);
      case RideProgressStep.inProgress:
        return const Color(0xFF16A34A);
      case RideProgressStep.completed:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = Provider.of<DriverLocaleProvider>(context);
    final isArabic = locale.isArabic;

    final name = widget.tripData['name'] ?? (isArabic ? 'الراكب' : 'Passenger');
    final from = widget.tripData['from'] ?? 'Pickup';
    final to = widget.tripData['to'] ?? 'Destination';
    final price = widget.tripData['price'] ?? '10,000 IQD';
    final phone = widget.tripData['phone'] ?? '07700000000';
    final rideId = (widget.tripData['id'] ?? widget.tripData['rideId'] ?? 'active_ride').toString();

    final currentPos = _driverPos ?? _pickupPos;

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
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 26),
            ),
            Text(
              'يَلَّا',
              style: TextStyle(color: AppColors.primaryOrange, fontWeight: FontWeight.bold, fontSize: 26),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.cancel_outlined, color: Colors.red, size: 26),
            tooltip: isArabic ? 'إلغاء الرحلة' : 'Cancel Trip',
            onPressed: () => _showDriverCancelDialog(rideId),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Live OpenStreetMap
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: currentPos,
              initialZoom: 14.5,
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
                    points: [currentPos, _pickupPos, _dropPos],
                    color: AppColors.primaryOrange,
                    strokeWidth: 4,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  // Pickup marker (green)
                  Marker(
                    point: _pickupPos,
                    width: 36,
                    height: 36,
                    child: _buildPin(Icons.trip_origin, Colors.green),
                  ),
                  // Driver marker (orange car)
                  Marker(
                    point: currentPos,
                    width: 50,
                    height: 50,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primaryOrange,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, 3))],
                      ),
                      child: const Icon(Icons.directions_car, color: Colors.white, size: 24),
                    ),
                  ),
                  // Drop marker (red)
                  Marker(
                    point: _dropPos,
                    width: 36,
                    height: 36,
                    child: _buildPin(Icons.location_on, Colors.red),
                  ),
                ],
              ),
            ],
          ),

          // GPS loading indicator
          if (!_gpsReady)
            Positioned(
              top: 12,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                      const SizedBox(width: 8),
                      Text(isArabic ? 'جارٍ تحديد موقعك...' : 'Getting your location...', style: const TextStyle(color: Colors.white, fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ),

          // Step status banner at top
          Positioned(
            top: _gpsReady ? 12 : 50,
            left: 16,
            right: 16,
            child: FadeInDown(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: _getStepColor(),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 3))],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _step == RideProgressStep.drivingToPickup ? Icons.navigation :
                      _step == RideProgressStep.arrivedAtPickup ? Icons.location_on :
                      _step == RideProgressStep.inProgress ? Icons.directions_car : Icons.check_circle,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _step == RideProgressStep.drivingToPickup
                          ? (isArabic ? '🚗 في الطريق إلى الراكب' : '🚗 Driving to passenger')
                          : _step == RideProgressStep.arrivedAtPickup
                              ? (isArabic ? '📍 وصلت — في انتظار الراكب' : '📍 Arrived — Waiting for passenger')
                              : _step == RideProgressStep.inProgress
                                  ? (isArabic ? '🟢 الرحلة جارية' : '🟢 Trip in progress')
                                  : (isArabic ? '✅ اكتملت الرحلة' : '✅ Trip completed'),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Trip Details Bottom Card
          Align(
            alignment: Alignment.bottomCenter,
            child: FadeInUp(
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, -5)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                    ),
                    Row(
                      children: [
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.star, color: Colors.amber, size: 16),
                                  const SizedBox(width: 4),
                                  const Text('5.0', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  const SizedBox(width: 10),
                                  Text(
                                    price,
                                    style: const TextStyle(color: AppColors.primaryOrange, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Call Action
                        IconButton(
                          icon: const Icon(Icons.call, color: Colors.black87, size: 22),
                          onPressed: () => _showPassengerPhoneDialog(name, phone),
                        ),
                        // Chat Action
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.primaryOrange.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.chat_bubble_outline, color: AppColors.primaryOrange, size: 22),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatScreen(
                                    rideId: rideId,
                                    passengerName: name,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    _buildInfoRow(Icons.trip_origin, isArabic ? 'نقطة الانطلاق' : 'Pickup', from, Colors.green),
                    const SizedBox(height: 10),
                    _buildInfoRow(Icons.location_on, isArabic ? 'نقطة الوصول' : 'Drop-off', to, Colors.red),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 54,
                            child: ElevatedButton(
                              onPressed: (_step == RideProgressStep.completed || _isProcessing) ? null : _handleStepAction,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _getStepColor(),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                elevation: 3,
                              ),
                              child: _isProcessing
                                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : Text(
                                      _getStepButtonLabel(isArabic),
                                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.my_location, color: Colors.white, size: 22),
                            onPressed: () {
                              _mapController.move(currentPos, 15.0);
                            },
                          ),
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

  Widget _buildPin(IconData icon, Color color) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
              Text(
                value,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
