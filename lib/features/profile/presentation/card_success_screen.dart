import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/driver_locale_provider.dart';

class CardSuccessScreen extends StatelessWidget {
  const CardSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = Provider.of<DriverLocaleProvider>(context);
    final isArabic = locale.isArabic;

    return Scaffold(
      backgroundColor: AppColors.primaryOrange,
      body: SafeArea(
        child: Directionality(
          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
            child: Column(
              children: [
                const Spacer(),

                // White Card
                FadeInDown(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Message
                        Text(
                          isArabic
                              ? 'تم إضافة بطاقة الكود بنجاح\nوتمت إضافة ٥٬٠٠٠ دينار\nإلى محفظتك'
                              : 'Your code card has been\nsuccessfully added 5,000 IQD\nto your wallet',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                            height: 1.5,
                            fontFamily: isArabic ? 'NotoKufiArabic' : null,
                          ),
                        ),
                        const SizedBox(height: 36),

                        // Animated Checkmark
                        ZoomIn(
                          duration: const Duration(milliseconds: 700),
                          child: Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.primaryOrange,
                                width: 5,
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.check,
                                size: 60,
                                color: AppColors.primaryOrange,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 36),

                        // Thank you line
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              isArabic ? 'شكراً لاستخدامك ' : 'Thank you for using with ',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                                fontFamily: isArabic ? 'NotoKufiArabic' : null,
                              ),
                            ),
                            Text(
                              'يَلَّا',
                              style: GoogleFonts.notoKufiArabic(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryOrange,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                // Back to Home Button
                FadeInUp(
                  delay: const Duration(milliseconds: 400),
                  child: SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/home', (r) => false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: Text(
                        isArabic ? 'العودة للرئيسية' : 'Back to Home',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          fontFamily: isArabic ? 'NotoKufiArabic' : null,
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
      ),
    );
  }
}
