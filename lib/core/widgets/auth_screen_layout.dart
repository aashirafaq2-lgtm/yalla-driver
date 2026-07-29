import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
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
    return Scaffold(
      backgroundColor: AppColors.primaryOrange,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                child: FadeInDown(
                  duration: const Duration(milliseconds: 600),
                  child: Container(
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
                      children: [
                        const SizedBox(height: 15),
                        if (onBack != null || title != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                if (onBack != null)
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: IconButton(
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
                                        child: const Icon(Icons.arrow_back, color: Colors.black, size: 20),
                                      ),
                                    ),
                                  ),
                                if (title != null)
                                  Text(
                                    title!,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        Expanded(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
                            child: child,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (bottomButton != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(25, 10, 25, 30),
                child: FadeInUp(
                  duration: const Duration(milliseconds: 600),
                  child: bottomButton!,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
