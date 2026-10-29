import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/auth_screen_layout.dart';
import '../../../../core/widgets/iq_widgets.dart';
import '../../../../core/providers/driver_locale_provider.dart';
import 'package:animate_do/animate_do.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = Provider.of<DriverLocaleProvider>(context);
    final isArabic = locale.isArabic;

    return AuthScreenLayout(
      title: isArabic ? 'تسجيل الدخول' : 'Sign in',
      bottomButton: FadeInUp(
        duration: const Duration(milliseconds: 1000),
        delay: const Duration(milliseconds: 200),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IQButton(
              label: locale.tr('sign_in'),
              onTap: () => Navigator.pushNamed(context, '/signin'),
            ),
            const SizedBox(height: 15),
            IQButton(
              label: locale.tr('sign_up'),
              isOutlined: true,
              onTap: () => Navigator.pushNamed(context, '/signup_personal'),
            ),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 50),
          FadeInDown(
            duration: const Duration(milliseconds: 800),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Yalla ',
                  style: TextStyle(
                    fontSize: 60,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                    letterSpacing: -2,
                  ),
                ),
                Text(
                  'يَلَّا',
                  style: TextStyle(
                    fontSize: 55,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryOrange,
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ],
            ),
          ),
          const SizedBox(height: 25),
          // Prominent Language Switcher for Drivers
          FadeInUp(
            duration: const Duration(milliseconds: 600),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.black12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () => locale.setLocale(const Locale('ar')),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: isArabic ? AppColors.primaryOrange : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'العربية',
                        style: TextStyle(
                          color: isArabic ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          fontFamily: 'NotoKufiArabic',
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => locale.setLocale(const Locale('en')),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: !isArabic ? AppColors.primaryOrange : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'English',
                        style: TextStyle(
                          color: !isArabic ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }
}
