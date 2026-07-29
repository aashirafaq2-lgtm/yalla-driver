import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/auth_screen_layout.dart';
import '../../../core/widgets/iq_widgets.dart';
import 'package:animate_do/animate_do.dart';

class SuccessScreen extends StatelessWidget {
  const SuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthScreenLayout(
      bottomButton: IQButton(
        label: "Let's Go !",
        onTap: () => Navigator.pushReplacementNamed(context, '/home'),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          FadeInDown(
            child: const Text(
              'Your account has been\nsuccessfully activated!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(height: 50),
          ZoomIn(
            duration: const Duration(milliseconds: 800),
            child: Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primaryOrange.withOpacity(0.5), width: 8),
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 80,
                color: AppColors.primaryOrange,
              ),
            ),
          ),
          const SizedBox(height: 50),
          FadeInUp(
            delay: const Duration(milliseconds: 400),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Thank you for registering with IQ ',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'يَلَّا',
                      style: TextStyle(
                        color: AppColors.primaryOrange,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                const Text(
                  'Would you like to book a ride now?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
