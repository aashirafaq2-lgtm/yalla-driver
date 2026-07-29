import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late Animation<double> _logoFade;
  late Animation<double> _logoScale;
  late AnimationController _subtitleController;
  late Animation<double> _subtitleFade;

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _logoFade = CurvedAnimation(parent: _logoController, curve: Curves.easeOut);
    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );

    _subtitleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _subtitleFade = CurvedAnimation(parent: _subtitleController, curve: Curves.easeIn);

    _runSequence();
  }

  Future<void> _runSequence() async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) _logoController.forward();
    await Future.delayed(const Duration(milliseconds: 1000));
    if (mounted) _subtitleController.forward();
    await Future.delayed(const Duration(milliseconds: 2000));
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/welcome');
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _subtitleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Scaffold(
      backgroundColor: AppColors.primaryOrange,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FadeTransition(
              opacity: _logoFade,
              child: ScaleTransition(
                scale: _logoScale,
                child: Container(
                  width: size.width * 0.55,
                  height: size.width * 0.55,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(size.width * 0.14),
                    border: Border.all(color: Colors.white.withOpacity(0.35), width: 2),
                  ),
                  child: Center(
                    child: Text(
                      'يَلَّا',
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        fontSize: size.width * 0.22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 2,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.2),
                            offset: const Offset(0, 4),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            FadeTransition(
              opacity: _subtitleFade,
              child: Column(
                children: [
                  Text(
                    'Yalla',
                    style: TextStyle(
                      fontSize: size.width * 0.1,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Driver',
                    style: TextStyle(
                      fontSize: size.width * 0.04,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.85),
                      letterSpacing: 3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


