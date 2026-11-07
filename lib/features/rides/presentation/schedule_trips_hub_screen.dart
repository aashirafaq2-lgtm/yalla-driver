import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/providers/driver_locale_provider.dart';
import 'schedule_trip_info_screen.dart';
import 'scheduled_trips_screen.dart';

class ScheduleTripsHubScreen extends StatelessWidget {
  const ScheduleTripsHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = Provider.of<DriverLocaleProvider>(context);
    final isArabic = locale.isArabic;

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
          isArabic ? 'جدولة الرحلات' : 'Schedule Trips',
          style: TextStyle(
            fontFamily: isArabic ? 'NotoKufiArabic' : null,
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF1E1B4B), // Deep Indigo
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              const SizedBox(height: 10),

              // ── 1. Publish Trips Card ──
              FadeInDown(
                duration: const Duration(milliseconds: 400),
                child: _buildActionCard(
                  context,
                  title: isArabic ? 'نشر رحلة' : 'Publish Trips',
                  subtitle: isArabic
                      ? 'أضف جدول رحلة جديد ليتمكن الركاب من الحجز.'
                      : 'Add a new trip schedule for passengers to book.',
                  iconPath: 'assets/images/ic_publish_trips.png',
                  fallbackIcon: Icons.calendar_today_rounded,
                  fallbackColor: const Color(0xFFFF7A00),
                  isArabic: isArabic,
                  gradientColors: const [
                    Color(0xFFFFF9F5),
                    Color(0xFFFFF2E8),
                  ],
                  borderColor: const Color(0xFFFFEDD5),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ScheduleTripInfoScreen()),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              // ── 2. Scheduled Trips Card ──
              FadeInUp(
                duration: const Duration(milliseconds: 450),
                child: _buildActionCard(
                  context,
                  title: isArabic ? 'الرحلات المجدولة' : 'Scheduled Trips',
                  subtitle: isArabic
                      ? 'عرض وإدارة جداول رحلاتك المنشورة.'
                      : 'View and manage your published trip schedules.',
                  iconPath: 'assets/images/ic_manage_scheduled_trips.png',
                  fallbackIcon: Icons.event_note_rounded,
                  fallbackColor: const Color(0xFF7E22CE),
                  isArabic: isArabic,
                  gradientColors: const [
                    Color(0xFFFAF7FF),
                    Color(0xFFF3ECFF),
                  ],
                  borderColor: const Color(0xFFEDE9FE),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ScheduledTripsScreen()),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String iconPath,
    required IconData fallbackIcon,
    required Color fallbackColor,
    required bool isArabic,
    required List<Color> gradientColors,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Left Graphic Illustration
            SizedBox(
              width: 56,
              height: 56,
              child: Image.asset(
                iconPath,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Icon(
                  fallbackIcon,
                  size: 40,
                  color: fallbackColor,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Container(
              width: 1,
              height: 48,
              color: Colors.black.withOpacity(0.08),
            ),
            const SizedBox(width: 16),
            // Text Content
            Expanded(
              child: Column(
                crossAxisAlignment: isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: isArabic ? 'NotoKufiArabic' : null,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF1E1B4B),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: isArabic ? 'NotoKufiArabic' : null,
                      fontSize: 12,
                      height: 1.35,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              isArabic ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
              size: 26,
              color: const Color(0xFF1E1B4B),
            ),
          ],
        ),
      ),
    );
  }
}

