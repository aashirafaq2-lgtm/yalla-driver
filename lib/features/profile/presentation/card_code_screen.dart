import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/driver_locale_provider.dart';

class CardCodeScreen extends StatelessWidget {
  const CardCodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = Provider.of<DriverLocaleProvider>(context);
    final isArabic = locale.isArabic;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            isArabic ? Icons.chevron_right : Icons.chevron_left,
            color: AppColors.primaryOrange,
            size: 32,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          isArabic ? 'بطاقة يَلَّا' : 'Yalla Card',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
            fontFamily: isArabic ? 'NotoKufiArabic' : null,
          ),
        ),
      ),
      body: Directionality(
        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30),
              FadeInDown(
                child: Text(
                  isArabic ? 'أدخل رمز بطاقة يَلَّا' : 'Enter the Yalla Card code',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontFamily: isArabic ? 'NotoKufiArabic' : null,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Code Input
              FadeInUp(
                delay: const Duration(milliseconds: 100),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: TextField(
                    textDirection: TextDirection.ltr,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      border: InputBorder.none,
                      hintText: isArabic ? 'رمز بطاقة يَلَّا' : 'Yalla Card code',
                      hintStyle: TextStyle(
                        color: Colors.black26,
                        fontSize: 14,
                        fontFamily: isArabic ? 'NotoKufiArabic' : null,
                      ),
                    ),
                  ),
                ),
              ),

              const Spacer(),

              // Apply Button
              FadeInUp(
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/card_success'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryOrange,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      isArabic ? 'تطبيق' : 'Apply',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: isArabic ? 'NotoKufiArabic' : null,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
