import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/providers/driver_locale_provider.dart';

class VerificationPendingScreen extends StatefulWidget {
  final String? phone;
  const VerificationPendingScreen({super.key, this.phone});

  @override
  State<VerificationPendingScreen> createState() => _VerificationPendingScreenState();
}

class _VerificationPendingScreenState extends State<VerificationPendingScreen> {
  bool _isChecking = false;

  Future<void> _checkStatus() async {
    setState(() => _isChecking = true);
    final api = Provider.of<ApiService>(context, listen: false);
    final storage = Provider.of<StorageService>(context, listen: false);
    final isArabic = Provider.of<DriverLocaleProvider>(context, listen: false).isArabic;

    try {
      final token = await storage.getToken();
      if (token != null) {
        final res = await api.getDriverVerificationStatus(token);
        if (res.statusCode == 200) {
          final data = res.data;
          final isVerified = data['isVerified'] == true;

          if (isVerified && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(isArabic ? 'تهانينا! تم تفعيل حسابك' : 'Congratulations! Your account is verified!'),
                backgroundColor: AppColors.success,
              ),
            );
            Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
            return;
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isArabic
                  ? 'طلبك قيد المراجعة حالياً من قبل الإدارة (24 - 48 ساعة)'
                  : 'Your application is still under review (24 - 48 hours)',
            ),
            backgroundColor: AppColors.primaryOrange,
          ),
        );
      }
    } catch (e) {
      debugPrint('Check verification error: $e');
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Provider.of<DriverLocaleProvider>(context).isArabic;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Yalla ',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 24),
            ),
            Text(
              'يَلَّا',
              style: TextStyle(color: AppColors.primaryOrange, fontWeight: FontWeight.bold, fontSize: 24),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Hourglass / Timer Icon Animation
              ZoomIn(
                duration: const Duration(milliseconds: 700),
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.primaryOrange.withOpacity(0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primaryOrange.withOpacity(0.3), width: 3),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.hourglass_top_rounded,
                      size: 60,
                      color: AppColors.primaryOrange,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              FadeInDown(
                delay: const Duration(milliseconds: 200),
                child: Text(
                  isArabic ? 'طلبك قيد المراجعة' : 'Account Under Review',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FadeInDown(
                delay: const Duration(milliseconds: 300),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFF59E0B)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.access_time_filled, color: Color(0xFFD97706), size: 18),
                      const SizedBox(width: 8),
                      Text(
                        isArabic ? 'وقت المراجعة: 24 إلى 48 ساعة' : 'Review Time: 24 to 48 Hours',
                        style: GoogleFonts.inter(
                          color: const Color(0xFFB45309),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FadeInUp(
                delay: const Duration(milliseconds: 400),
                child: Text(
                  isArabic
                      ? 'تم استلام مستنداتك بنجاح (البطاقة الموحدة، سنوية المركبة، وصورة السائق). يقوم فريقنا بالتدقيق لضمان سلامة وجودة الخدمة. ستصلك رسالة وإشعار فور الاعتماد.'
                      : 'Your Iraqi documents (National ID, Vehicle Registration, and Face Photo) have been submitted. Our security team is verifying them. You will receive an email & SMS once approved.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    height: 1.6,
                    color: Colors.black54,
                  ),
                ),
              ),
              const Spacer(),
              // Check Status Button
              FadeInUp(
                delay: const Duration(milliseconds: 500),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryOrange,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    icon: _isChecking
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh_rounded, color: Colors.white),
                    label: Text(
                      _isChecking
                          ? (isArabic ? 'جارٍ التحقق...' : 'Checking...')
                          : (isArabic ? 'تحديث حالة التفعيل' : 'Check Approval Status'),
                      style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    onPressed: _isChecking ? null : _checkStatus,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Back to Login
              TextButton(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(context, '/welcome', (route) => false);
                },
                child: Text(
                  isArabic ? 'تسجيل الخروج والعودة' : 'Sign Out & Return Later',
                  style: GoogleFonts.inter(color: Colors.black54, fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
