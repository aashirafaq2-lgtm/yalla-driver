import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';

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
      backgroundColor: const Color(0xFFFAFAFC),
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            children: [
              // ── 1. Publish Trips Card ──
              FadeInDown(
                duration: const Duration(milliseconds: 400),
                child: _ActionCardItem(
                  title: isArabic ? 'نشر رحلة' : 'Publish Trips',
                  subtitle: isArabic
                      ? 'أضف جدول رحلة جديد ليتمكن الركاب من الحجز.'
                      : 'Add a new trip schedule for passengers to book.',
                  iconPath: 'assets/images/ic_publish_trips_hd.png',
                  fallbackIconPath: 'assets/images/ic_publish_trips.png',
                  fallbackIcon: Icons.calendar_today_rounded,
                  fallbackColor: const Color(0xFFFF7A00),
                  isArabic: isArabic,
                  gradientColors: const [
                    Color(0xFFFFFBF7),
                    Color(0xFFFFF2E6),
                  ],
                  borderColor: const Color(0xFFFFDEC0),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ScheduleTripInfoScreen()),
                    );
                  },
                ),
              ),

              const SizedBox(height: 18),

              // ── 2. Scheduled Trips Card ──
              FadeInUp(
                duration: const Duration(milliseconds: 450),
                child: _ActionCardItem(
                  title: isArabic ? 'الرحلات المجدولة' : 'Scheduled Trips',
                  subtitle: isArabic
                      ? 'عرض وإدارة جداول رحلاتك المنشورة.'
                      : 'View and manage your published trip schedules.',
                  iconPath: 'assets/images/ic_manage_scheduled_trips_hd.png',
                  fallbackIconPath: 'assets/images/ic_manage_scheduled_trips.png',
                  fallbackIcon: Icons.event_note_rounded,
                  fallbackColor: const Color(0xFF7E22CE),
                  isArabic: isArabic,
                  gradientColors: const [
                    Color(0xFFFBF8FF),
                    Color(0xFFF2E8FF),
                  ],
                  borderColor: const Color(0xFFE3D3FD),
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
}

class _ActionCardItem extends StatefulWidget {
  final String title;
  final String subtitle;
  final String iconPath;
  final String? fallbackIconPath;
  final IconData fallbackIcon;
  final Color fallbackColor;
  final bool isArabic;
  final List<Color> gradientColors;
  final Color borderColor;
  final VoidCallback onTap;

  const _ActionCardItem({
    required this.title,
    required this.subtitle,
    required this.iconPath,
    this.fallbackIconPath,
    required this.fallbackIcon,
    required this.fallbackColor,
    required this.isArabic,
    required this.gradientColors,
    required this.borderColor,
    required this.onTap,
  });

  @override
  State<_ActionCardItem> createState() => _ActionCardItemState();
}

class _ActionCardItemState extends State<_ActionCardItem> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 140),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: widget.borderColor, width: 1.3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Left Graphic Illustration
              SizedBox(
                width: 58,
                height: 58,
                child: Image.asset(
                  widget.iconPath,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (context, error, stackTrace) {
                    if (widget.fallbackIconPath != null) {
                      return Image.asset(
                        widget.fallbackIconPath!,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                        errorBuilder: (_, __, ___) => Icon(
                          widget.fallbackIcon,
                          size: 42,
                          color: widget.fallbackColor,
                        ),
                      );
                    }
                    return Icon(
                      widget.fallbackIcon,
                      size: 42,
                      color: widget.fallbackColor,
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 1,
                height: 52,
                color: Colors.black.withOpacity(0.08),
              ),
              const SizedBox(width: 16),
              // Text Content
              Expanded(
                child: Column(
                  crossAxisAlignment: widget.isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontFamily: widget.isArabic ? 'NotoKufiArabic' : null,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF1E1B4B),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      widget.subtitle,
                      style: TextStyle(
                        fontFamily: widget.isArabic ? 'NotoKufiArabic' : null,
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
                widget.isArabic ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
                size: 26,
                color: const Color(0xFF1E1B4B),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
