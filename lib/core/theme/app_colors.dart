import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors
  static const Color primaryOrange = Color(0xFFFF9900);
  static const Color primaryDark = Color(0xFFE68A00);
  static const Color accentBlue = Color(0xFF2980B9);
  
  // Luxury Palette
  static const Color surfaceBlack = Color(0xFF000000);
  static const Color backgroundDark = Color(0xFF0C1017);
  static const Color offWhite = Color(0xFFF9FAFB);
  
  // Gradients
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      primaryOrange,
      Color(0xFFFFB347),
      primaryDark,
    ],
  );

  static const LinearGradient glassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x33FFFFFF),
      Color(0x11FFFFFF),
    ],
  );
  
  // States
  static const Color success = Color(0xFF22C55E);
  static const Color danger = Color(0xFFEF4444);
}
