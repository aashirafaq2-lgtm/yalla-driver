import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  static TextStyle get h1Black => GoogleFonts.outfit(
        fontSize: 32,
        fontWeight: FontWeight.w900,
        letterSpacing: -1.5,
        color: Colors.black,
      );

  static TextStyle get h1White => h1Black.copyWith(color: Colors.white);

  static TextStyle get h2Bold => GoogleFonts.outfit(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
        color: AppColors.surfaceBlack,
      );

  static TextStyle get h3Bold => GoogleFonts.outfit(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
        color: AppColors.surfaceBlack,
      );

  static TextStyle get bodyMain => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: AppColors.backgroundDark,
      );

  static TextStyle get buttonText => GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      );
}
