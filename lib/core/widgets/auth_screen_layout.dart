import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../providers/driver_locale_provider.dart';
import 'package:animate_do/animate_do.dart';

class AuthScreenLayout extends StatelessWidget {
  final Widget child;
  final Widget? bottomButton;
  final VoidCallback? onBack;
  final String? title;

  const AuthScreenLayout({
    super.key,
    required this.child,
    this.bottomButton,
    this.onBack,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    final localeProvider = Provider.of<DriverLocaleProvider>(context);
    final isArabic = localeProvider.isArabic;

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: AppColors.primaryOrange,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                            child: FadeInDown(
                              duration: const Duration(milliseconds: 500),
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(40),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(height: 15),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 15),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          if (onBack != null)
                                            IconButton(
                                              onPressed: onBack,
                                              icon: Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  shape: BoxShape.circle,
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black.withOpacity(0.1),
                                                      blurRadius: 10,
                                                    ),
                                                  ],
                                                ),
                                                child: Icon(isArabic ? Icons.arrow_forward : Icons.arrow_back, color: Colors.black, size: 20),
                                              ),
                                            )
                                          else
                                            const SizedBox(width: 40),
                                          if (title != null)
                                            Text(
                                              title!,
                                              style: TextStyle(
                                                fontSize: 22,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black,
                                                fontFamily: isArabic ? 'NotoKufiArabic' : null,
                                              ),
                                            ),
                                          // Language dropdown
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.offWhite,
                                              borderRadius: BorderRadius.circular(20),
                                              border: Border.all(color: Colors.black12),
                                            ),
                                            child: DropdownButtonHideUnderline(
                                              child: DropdownButton<String>(
                                                value: isArabic ? 'ar' : 'en',
                                                isDense: true,
                                                icon: const Icon(Icons.language, size: 16, color: AppColors.primaryOrange),
                                                borderRadius: BorderRadius.circular(12),
                                                items: [
                                                  DropdownMenuItem(
                                                    value: 'ar',
                                                    child: Text('العربية', style: GoogleFonts.notoKufiArabic(fontSize: 12, fontWeight: FontWeight.bold)),
                                                  ),
                                                  DropdownMenuItem(
                                                    value: 'en',
                                                    child: Text('English', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold)),
                                                  ),
                                                ],
                                                onChanged: (lang) {
                                                  if (lang != null) localeProvider.setLocale(Locale(lang));
                                                },
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                                    child: child,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (bottomButton != null)
                        Padding(
                          padding: EdgeInsets.fromLTRB(25, 10, 25, isKeyboardOpen ? 12 : 25),
                          child: FadeInUp(
                            duration: const Duration(milliseconds: 500),
                            child: bottomButton!,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ));
  }
}
