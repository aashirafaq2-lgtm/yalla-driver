import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/auth_screen_layout.dart';
import '../../../../core/widgets/iq_widgets.dart';
import 'package:animate_do/animate_do.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthScreenLayout(
      title: 'Sign in',
      bottomButton: FadeInUp(
        duration: const Duration(milliseconds: 1000),
        delay: const Duration(milliseconds: 200),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IQButton(
              label: 'Sign In',
              onTap: () => Navigator.pushNamed(context, '/signin'),
            ),
            const SizedBox(height: 15),
            IQButton(
              label: 'Create Account',
              isOutlined: true,
              onTap: () => Navigator.pushNamed(context, '/signup_personal'),
            ),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 100),
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
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}
