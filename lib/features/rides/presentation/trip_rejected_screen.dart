import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/driver_locale_provider.dart';

class TripRejectedScreen extends StatelessWidget {
  final Map<String, dynamic> tripData;

  const TripRejectedScreen({
    super.key,
    required this.tripData,
  });

  @override
  Widget build(BuildContext context) {
    final locale = Provider.of<DriverLocaleProvider>(context);
    final isArabic = locale.isArabic;

    final String passengerName = tripData['name'] ?? (isArabic ? 'الراكب' : 'Passenger');
    final String from = tripData['from'] ?? 'Kirkuk';
    final String to = tripData['to'] ?? 'Mosul';
    final String price = tripData['price'] ?? '25,000 IQD';
    final String date = tripData['date'] ?? '6 Nov 2026';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black12, width: 1),
          ),
          child: IconButton(
            icon: Icon(
              isArabic ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded,
              color: const Color(0xFF0F172A),
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        centerTitle: true,
        title: Text(
          isArabic ? 'تفاصيل الرفض' : 'Trip Rejected',
          style: TextStyle(
            fontFamily: isArabic ? 'NotoKufiArabic' : null,
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF1E1B4B),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),

              // Animated Pulsing Red Icon
              FadeInDown(
                duration: const Duration(milliseconds: 500),
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFFECACA), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFEF4444).withOpacity(0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.cancel_rounded,
                      size: 48,
                      color: Color(0xFFDC2626),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Title
              FadeInDown(
                delay: const Duration(milliseconds: 150),
                duration: const Duration(milliseconds: 400),
                child: Text(
                  isArabic ? 'تم رفض الرحلة' : 'Trip Request Rejected',
                  style: TextStyle(
                    fontFamily: isArabic ? 'NotoKufiArabic' : null,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Subtitle
              FadeInDown(
                delay: const Duration(milliseconds: 250),
                duration: const Duration(milliseconds: 400),
                child: Text(
                  isArabic
                      ? 'لقد قمت برفض هذا الطلب. تم إرسال التحديث إلى الراكب ولوحة التحكم بنجاح.'
                      : 'You have rejected this request. The update has been sent to the passenger and admin panel.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: isArabic ? 'NotoKufiArabic' : null,
                    fontSize: 13,
                    height: 1.4,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Summary Card
              FadeInUp(
                delay: const Duration(milliseconds: 300),
                duration: const Duration(milliseconds: 450),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      _buildRow(
                        label: isArabic ? 'الراكب' : 'Passenger',
                        value: passengerName,
                        isArabic: isArabic,
                      ),
                      const Divider(height: 16, color: Color(0xFFE2E8F0)),
                      _buildRow(
                        label: isArabic ? 'المسار' : 'Route',
                        value: '$from → $to',
                        isArabic: isArabic,
                      ),
                      const Divider(height: 16, color: Color(0xFFE2E8F0)),
                      _buildRow(
                        label: isArabic ? 'التاريخ' : 'Date',
                        value: date,
                        isArabic: isArabic,
                      ),
                      const Divider(height: 16, color: Color(0xFFE2E8F0)),
                      _buildRow(
                        label: isArabic ? 'السعر' : 'Price',
                        value: price,
                        isArabic: isArabic,
                        valueColor: const Color(0xFFFF7A00),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // Back to Available Trips Button
              FadeInUp(
                delay: const Duration(milliseconds: 400),
                duration: const Duration(milliseconds: 450),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF7A00),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      isArabic ? 'العودة للطلبات المتاحة' : 'Back to Available Trips',
                      style: TextStyle(
                        fontFamily: isArabic ? 'NotoKufiArabic' : null,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow({
    required String label,
    required String value,
    required bool isArabic,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: valueColor ?? const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}
